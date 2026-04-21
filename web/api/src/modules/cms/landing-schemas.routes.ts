/**
 * landing-schemas.routes.ts — CMS Landing Schemas
 *
 * Foundation backend del plan "landing schemas en CMS" (Opción 3: studio schema + landing-kit renderer).
 * Primer PR de 13; sin tocar frontends verticales.
 *
 * Endpoints:
 *   GET  /v1/public/cms/landings/by-slug    — público (SSG) devuelve PublishedSchema
 *   GET  /v1/public/cms/landings/preview    — público (token UUID) devuelve DraftSchema
 *   GET  /v1/cms/landings                   — admin list (CMS_EDITOR)
 *   GET  /v1/cms/landings/:id               — admin detalle
 *   PUT  /v1/cms/landings/:id               — admin upsert draft (Zod)
 *   POST /v1/cms/landings/:id/publish       — admin publish + revalidate opt-in
 *   GET  /v1/cms/landings/:id/versions      — admin historial
 *   POST /v1/cms/landings/:id/preview-token — admin rota PreviewToken (opcional helper)
 *
 * Observabilidad: obs.audit/error/perf vía @zentto/obs (primer wiring del módulo cms).
 */

import {
  Router,
  type Request,
  type Response,
} from "express";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import { callSp } from "../../db/query.js";
import { resolveTenantFromRequest } from "../_shared/scope.js";
import { obs } from "../integrations/observability.js";
import { env } from "../../config/env.js";

const MODULE_NAME = "cms-landing";

// ─── Zod schemas ─────────────────────────────────────────────────────────────
//
// Mantenemos la validación permisiva en `sections[].*`: landing-kit (y studio)
// evolucionan tipos de sección y no queremos romper el upsert cuando se agrega
// un nuevo type. Validamos estructura esencial y delegamos semantics al renderer.

const landingSectionSchema = z
  .object({
    id: z.string().min(1).max(200),
    type: z.string().min(1).max(100),
  })
  .passthrough(); // permite campos extra sin falla

const landingConfigSchema = z
  .object({
    id: z.string().min(1).max(200),
    version: z.string().min(1).max(50),
    appMode: z.literal("landing").optional(),
    branding: z.record(z.unknown()).optional(),
    landingConfig: z
      .object({
        navbar: z.record(z.unknown()).optional(),
        footer: z.record(z.unknown()).optional(),
        sections: z.array(landingSectionSchema).default([]),
      })
      .passthrough(),
  })
  .passthrough();

export type LandingConfig = z.infer<typeof landingConfigSchema>;

const upsertDraftBody = z.object({
  vertical: z.string().min(1).max(50).optional(),
  slug: z.string().min(1).max(100).default("default"),
  locale: z.string().min(2).max(10).default("es"),
  draftSchema: landingConfigSchema,
  themeTokens: z.record(z.unknown()).nullable().optional(),
  seoMeta: z.record(z.unknown()).nullable().optional(),
});

const listQuery = z.object({
  vertical: z.string().max(50).optional(),
  status: z.enum(["draft", "published", "archived"]).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

const publicBySlugQuery = z.object({
  vertical: z.string().min(1).max(50),
  slug: z.string().min(1).max(100).default("default"),
  locale: z.string().min(2).max(10).default("es"),
  companyId: z.coerce.number().int().positive().optional(),
});

const previewQuery = z.object({
  token: z.string().min(8).max(64),
});

// ─── Auth helper (CMS_EDITOR) ────────────────────────────────────────────────

function requireCmsEditor(req: AuthenticatedRequest, res: Response): number | null {
  const companyId = req.scope?.companyId;
  if (!companyId) {
    res.status(401).json({ ok: false, error: "unauthenticated" });
    return null;
  }
  const isAdmin = req.user?.isAdmin === true;
  const hasCmsRole =
    Array.isArray(req.user?.roles) && req.user.roles.includes("CMS_EDITOR");
  if (!isAdmin && !hasCmsRole) {
    res.status(403).json({ ok: false, error: "cms_editor_required" });
    return null;
  }
  return companyId;
}

// ─── Revalidate webhook (opt-in) ─────────────────────────────────────────────

const REVALIDATE_RATE_MS = 10_000; // 1 request / 10s / vertical
const revalidateLastFired = new Map<string, number>();

/**
 * Fire-and-forget POST al frontend vertical para invalidar el cache Next.js.
 * No bloquea la respuesta del publish. Errores → obs.error silenciosamente.
 */
function fireRevalidateWebhook(vertical: string, landingSchemaId: number): void {
  if (!env.landingRevalidate.enabled) return;
  const url = env.landingRevalidate.urls[vertical];
  if (!url) {
    obs.audit("cms.landing.revalidate_skipped_no_url", {
      module: MODULE_NAME,
      vertical,
      landingSchemaId,
    });
    return;
  }
  if (!env.landingRevalidate.secret) {
    obs.error("cms.landing.revalidate_missing_secret", {
      module: MODULE_NAME,
      vertical,
    });
    return;
  }

  const now = Date.now();
  const last = revalidateLastFired.get(vertical) ?? 0;
  if (now - last < REVALIDATE_RATE_MS) {
    obs.audit("cms.landing.revalidate_rate_limited", {
      module: MODULE_NAME,
      vertical,
      landingSchemaId,
    });
    return;
  }
  revalidateLastFired.set(vertical, now);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);

  void (async () => {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-revalidate-token": env.landingRevalidate.secret,
        },
        body: JSON.stringify({ tag: `landing:${vertical}` }),
        signal: controller.signal,
      });
      clearTimeout(timeout);
      obs.audit("cms.landing.revalidate_fired", {
        module: MODULE_NAME,
        vertical,
        landingSchemaId,
        status: res.status,
      });
    } catch (err: any) {
      clearTimeout(timeout);
      obs.error(`cms.landing.revalidate_failed: ${err?.message ?? String(err)}`, {
        module: MODULE_NAME,
        vertical,
        landingSchemaId,
      });
    }
  })();
}

// ─── Row mappers ─────────────────────────────────────────────────────────────
// PG callSp ya normaliza snake_case → PascalCase; en SQL Server viene así ya.
// JSONB en PG se devuelve como objeto; NVARCHAR(MAX) JSON en MSSQL viene como string.
function parseJsonMaybe(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (typeof v === "object") return v;
  if (typeof v === "string") {
    try {
      return JSON.parse(v);
    } catch {
      return null;
    }
  }
  return null;
}

function mapLandingRow(row: Record<string, any>): Record<string, any> {
  return {
    landingSchemaId: row.LandingSchemaId,
    companyId: row.CompanyId,
    vertical: row.Vertical,
    slug: row.Slug,
    locale: row.Locale,
    version: row.Version,
    status: row.Status,
    publishedAt: row.PublishedAt ?? null,
    updatedAt: row.UpdatedAt ?? null,
    // Campos opcionales en detalle:
    draftSchema: "DraftSchema" in row ? parseJsonMaybe(row.DraftSchema) : undefined,
    publishedSchema:
      "PublishedSchema" in row ? parseJsonMaybe(row.PublishedSchema) : undefined,
    schema: "Schema" in row ? parseJsonMaybe(row.Schema) : undefined,
    themeTokens: "ThemeTokens" in row ? parseJsonMaybe(row.ThemeTokens) : undefined,
    seoMeta: "SeoMeta" in row ? parseJsonMaybe(row.SeoMeta) : undefined,
    previewToken: "PreviewToken" in row ? row.PreviewToken ?? null : undefined,
    createdAt: "CreatedAt" in row ? row.CreatedAt ?? null : undefined,
    createdBy: "CreatedBy" in row ? row.CreatedBy ?? null : undefined,
    publishedBy: "PublishedBy" in row ? row.PublishedBy ?? null : undefined,
    updatedBy: "UpdatedBy" in row ? row.UpdatedBy ?? null : undefined,
  };
}

// ─── Helpers BD: JSON → string para MSSQL ────────────────────────────────────
//
// JSONB en PG acepta objetos nativos; MSSQL usa NVARCHAR(MAX) → necesitamos
// stringificar. callSp con PG acepta tanto JSONB object como string (node-pg
// lo serializa). Unificamos pasando siempre string para ambos motores.
function jsonParam(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

// ============================================================================
// Router PÚBLICO — se monta bajo /v1/public/cms (ver app.ts)
// ============================================================================

export const cmsLandingPublicRouter = Router();

/**
 * GET /v1/public/cms/landings/by-slug
 * Query: vertical, slug?, locale?, companyId?
 *
 * Devuelve el PublishedSchema del landing. CompanyId se resuelve del request
 * (subdomain/header/cookie/env) si no viene en query.
 */
cmsLandingPublicRouter.get("/landings/by-slug", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const parsed = publicBySlugQuery.safeParse(req.query);
    if (!parsed.success) {
      obs.error("cms.landing.get_published_invalid_query", { module: MODULE_NAME });
      res.status(400).json({ ok: false, error: "invalid_query", details: parsed.error.format() });
      return;
    }
    const q = parsed.data;
    const companyId = q.companyId ?? resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const rows = await callSp<Record<string, any>>("usp_cms_landingschema_get_published", {
      CompanyId: companyId,
      Vertical: q.vertical,
      Slug: q.slug,
      Locale: q.locale,
    });

    if (!rows.length) {
      obs.audit("cms.landing.get_published_miss", {
        module: MODULE_NAME,
        companyId,
        vertical: q.vertical,
        slug: q.slug,
        locale: q.locale,
      });
      res.status(404).json({ ok: false, error: "landing_not_found" });
      return;
    }

    const data = mapLandingRow(rows[0]);
    obs.audit("cms.landing.get_published", {
      module: MODULE_NAME,
      companyId,
      vertical: q.vertical,
      slug: q.slug,
      locale: q.locale,
      version: data.version,
    });
    obs.perf("cms.landing.get_published", Date.now() - startedAt, {
      module: MODULE_NAME,
      vertical: q.vertical,
    });

    res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=600");
    res.json({ ok: true, data });
  } catch (err: any) {
    obs.error(`cms.landing.get_published_failed: ${err?.message}`, { module: MODULE_NAME });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

/**
 * GET /v1/public/cms/landings/preview?token=UUID
 * Devuelve DraftSchema si el token coincide. Sin auth (cross-subdomain).
 */
cmsLandingPublicRouter.get("/landings/preview", async (req: Request, res: Response) => {
  try {
    const parsed = previewQuery.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_token" });
      return;
    }
    const rows = await callSp<Record<string, any>>(
      "usp_cms_landingschema_get_by_preview_token",
      { PreviewToken: parsed.data.token },
    );
    if (!rows.length) {
      obs.audit("cms.landing.preview_miss", { module: MODULE_NAME });
      res.status(404).json({ ok: false, error: "preview_not_found" });
      return;
    }

    const data = mapLandingRow(rows[0]);
    obs.audit("cms.landing.preview_hit", {
      module: MODULE_NAME,
      companyId: data.companyId,
      vertical: data.vertical,
      landingSchemaId: data.landingSchemaId,
    });
    // No cachear preview — siempre fresh.
    res.setHeader("Cache-Control", "no-store");
    res.json({ ok: true, data });
  } catch (err: any) {
    obs.error(`cms.landing.preview_failed: ${err?.message}`, { module: MODULE_NAME });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// ============================================================================
// Router ADMIN — se monta bajo /v1/cms (ver app.ts), detrás del JWT middleware.
// ============================================================================

export const cmsLandingAdminRouter = Router();

cmsLandingAdminRouter.use(((
  req: AuthenticatedRequest,
  res: Response,
  next: () => void,
) => {
  if (!requireCmsEditor(req, res)) return;
  next();
}) as any);

/** GET /v1/cms/landings?vertical=X&status=Y */
cmsLandingAdminRouter.get("/landings", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const companyId = req.scope!.companyId;
    const parsed = listQuery.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_query", details: parsed.error.format() });
      return;
    }

    const q = parsed.data;
    const rows = await callSp<Record<string, any>>("usp_cms_landingschema_list", {
      CompanyId: companyId,
      Vertical: q.vertical ?? null,
      Status: q.status ?? null,
      Limit: q.limit,
      Offset: q.offset,
    });
    const total = rows[0]?.TotalCount ? Number(rows[0].TotalCount) : 0;
    const data = rows.map((r) => {
      const { TotalCount: _t, ...rest } = r;
      return mapLandingRow(rest);
    });
    res.json({ ok: true, data, total, limit: q.limit, offset: q.offset });
  } catch (err: any) {
    obs.error(`cms.landing.list_failed: ${err?.message}`, { module: MODULE_NAME });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

/** GET /v1/cms/landings/:id — detalle completo */
cmsLandingAdminRouter.get("/landings/:id", async (req: AuthenticatedRequest, res: Response) => {
  try {
    const companyId = req.scope!.companyId;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ ok: false, error: "invalid_id" });
      return;
    }
    const rows = await callSp<Record<string, any>>("usp_cms_landingschema_get_by_id", {
      LandingSchemaId: id,
      CompanyId: companyId,
    });
    if (!rows.length) {
      res.status(404).json({ ok: false, error: "landing_not_found" });
      return;
    }
    res.json({ ok: true, data: mapLandingRow(rows[0]) });
  } catch (err: any) {
    obs.error(`cms.landing.get_by_id_failed: ${err?.message}`, { module: MODULE_NAME });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

/** PUT /v1/cms/landings/:id — upsert draft */
cmsLandingAdminRouter.put("/landings/:id", async (req: AuthenticatedRequest, res: Response) => {
  const companyId = req.scope!.companyId;
  const userId = req.user?.sub ? Number(req.user.sub) || null : null;
  const rawId = req.params.id;
  // Permitimos "new" o "0" para creación; cualquier otra cosa debe ser un entero > 0.
  let id: number | null = null;
  if (rawId !== "new" && rawId !== "0") {
    const n = Number(rawId);
    if (!Number.isFinite(n) || n <= 0) {
      res.status(400).json({ ok: false, error: "invalid_id" });
      return;
    }
    id = n;
  }

  const parsed = upsertDraftBody.safeParse(req.body);
  if (!parsed.success) {
    obs.error(`cms.landing.validation_failed: ${parsed.error.message}`, {
      module: MODULE_NAME,
      companyId,
    });
    res.status(400).json({ ok: false, error: "invalid_body", details: parsed.error.format() });
    return;
  }
  const body = parsed.data;

  if (!id && !body.vertical) {
    res.status(400).json({ ok: false, error: "vertical_required_on_create" });
    return;
  }

  try {
    const rows = await callSp<Record<string, any>>("usp_Cms_LandingSchema_UpsertDraft", {
      LandingSchemaId: id,
      CompanyId: companyId,
      Vertical: body.vertical ?? null,
      Slug: body.slug,
      Locale: body.locale,
      DraftSchema: jsonParam(body.draftSchema),
      ThemeTokens: jsonParam(body.themeTokens ?? null),
      SeoMeta: jsonParam(body.seoMeta ?? null),
      UserId: userId,
    });

    const r = rows[0] ?? { ok: false, mensaje: "no_result", LandingSchemaId: null };
    const ok = Boolean(r.ok);
    const mensaje = String(r.mensaje ?? "");
    const landingSchemaId = r.LandingSchemaId != null ? Number(r.LandingSchemaId) : null;

    if (!ok) {
      obs.error(`cms.landing.upsert_failed: ${mensaje}`, {
        module: MODULE_NAME,
        companyId,
        userId,
      });
      res.status(400).json({ ok: false, error: mensaje });
      return;
    }

    obs.audit("cms.landing.upsert_draft", {
      module: MODULE_NAME,
      companyId,
      userId,
      landingSchemaId,
      vertical: body.vertical,
      slug: body.slug,
      locale: body.locale,
    });

    const status = mensaje === "landing_draft_created" ? 201 : 200;
    res.status(status).json({
      ok: true,
      mensaje,
      data: { landingSchemaId },
    });
  } catch (err: any) {
    obs.error(`cms.landing.upsert_crashed: ${err?.message}`, {
      module: MODULE_NAME,
      companyId,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

/** POST /v1/cms/landings/:id/publish */
cmsLandingAdminRouter.post(
  "/landings/:id/publish",
  async (req: AuthenticatedRequest, res: Response) => {
    const companyId = req.scope!.companyId;
    const userId = req.user?.sub ? Number(req.user.sub) || null : null;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ ok: false, error: "invalid_id" });
      return;
    }

    try {
      const rows = await callSp<Record<string, any>>("usp_Cms_LandingSchema_Publish", {
        LandingSchemaId: id,
        CompanyId: companyId,
        UserId: userId,
      });

      const r = rows[0] ?? { ok: false, mensaje: "no_result", Version: 0 };
      const ok = Boolean(r.ok);
      const mensaje = String(r.mensaje ?? "");
      const version = r.Version ? Number(r.Version) : 0;

      if (!ok) {
        obs.error(`cms.landing.publish_failed: ${mensaje}`, {
          module: MODULE_NAME,
          companyId,
          userId,
          landingSchemaId: id,
        });
        res.status(404).json({ ok: false, error: mensaje });
        return;
      }

      // Obtener vertical para revalidate (lookup rápido)
      const detail = await callSp<Record<string, any>>("usp_cms_landingschema_get_by_id", {
        LandingSchemaId: id,
        CompanyId: companyId,
      });
      const vertical = detail[0]?.Vertical;

      obs.audit("cms.landing.publish", {
        module: MODULE_NAME,
        companyId,
        userId,
        landingSchemaId: id,
        version,
        vertical,
      });

      if (vertical) {
        fireRevalidateWebhook(vertical, id);
      }

      res.json({ ok: true, mensaje, data: { landingSchemaId: id, version, vertical } });
    } catch (err: any) {
      obs.error(`cms.landing.publish_crashed: ${err?.message}`, {
        module: MODULE_NAME,
        companyId,
        landingSchemaId: id,
      });
      res.status(500).json({ ok: false, error: "internal_error" });
    }
  },
);

/** GET /v1/cms/landings/:id/versions */
cmsLandingAdminRouter.get(
  "/landings/:id/versions",
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const companyId = req.scope!.companyId;
      const id = Number(req.params.id);
      if (!Number.isFinite(id) || id <= 0) {
        res.status(400).json({ ok: false, error: "invalid_id" });
        return;
      }
      const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
      const offset = Math.max(Number(req.query.offset) || 0, 0);

      const rows = await callSp<Record<string, any>>(
        "usp_cms_landingschema_list_versions",
        {
          LandingSchemaId: id,
          CompanyId: companyId,
          Limit: limit,
          Offset: offset,
        },
      );
      const total = rows[0]?.TotalCount ? Number(rows[0].TotalCount) : 0;
      const data = rows.map((r) => ({
        landingSchemaHistoryId: r.LandingSchemaHistoryId,
        landingSchemaId: r.LandingSchemaId,
        version: r.Version,
        publishedAt: r.PublishedAt ?? null,
        publishedBy: r.PublishedBy ?? null,
      }));
      res.json({ ok: true, data, total, limit, offset });
    } catch (err: any) {
      obs.error(`cms.landing.list_versions_failed: ${err?.message}`, {
        module: MODULE_NAME,
      });
      res.status(500).json({ ok: false, error: "internal_error" });
    }
  },
);

/**
 * POST /v1/cms/landings/:id/preview-token
 * Genera/rota un token UUID para preview cross-subdomain. Body `{ clear: true }`
 * lo limpia.
 */
cmsLandingAdminRouter.post(
  "/landings/:id/preview-token",
  async (req: AuthenticatedRequest, res: Response) => {
    const companyId = req.scope!.companyId;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ ok: false, error: "invalid_id" });
      return;
    }
    const clear = req.body?.clear === true;
    const token = clear ? null : randomUUID();
    try {
      const rows = await callSp<Record<string, any>>(
        "usp_Cms_LandingSchema_SetPreviewToken",
        { LandingSchemaId: id, CompanyId: companyId, Token: token },
      );

      const r = rows[0] ?? { ok: false, mensaje: "no_result", PreviewToken: null };
      const ok = Boolean(r.ok);
      const mensaje = String(r.mensaje ?? "");
      if (!ok) {
        res.status(404).json({ ok: false, error: mensaje });
        return;
      }

      obs.audit("cms.landing.preview_token_rotated", {
        module: MODULE_NAME,
        companyId,
        landingSchemaId: id,
        cleared: clear,
      });
      res.json({
        ok: true,
        data: {
          landingSchemaId: id,
          previewToken: r.PreviewToken ?? null,
        },
      });
    } catch (err: any) {
      obs.error(`cms.landing.preview_token_failed: ${err?.message}`, {
        module: MODULE_NAME,
      });
      res.status(500).json({ ok: false, error: "internal_error" });
    }
  },
);
