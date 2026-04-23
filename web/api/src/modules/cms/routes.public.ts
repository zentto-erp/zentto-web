import { Router, type Request, type Response } from "express";
import {
  postListQuerySchema,
  pageListQuerySchema,
  contactSubmitSchema,
} from "./schema.js";
import {
  listPosts,
  getPost,
  listPages,
  getPage,
  submitContact,
} from "./service.js";
import { resolveTenantFromRequest } from "../_shared/scope.js";
import { obs } from "../integrations/observability.js";
import { notifyEmail } from "../_shared/notify.js";

// Router público: /v1/public/cms/* — sin JWT.
// Solo expone contenido con Status='published'.
//
// Tenant resolution: cada endpoint resuelve CompanyId via
// `resolveTenantFromRequest(req)` si no viene en query. Falla con 400
// `tenant_required` si no se puede inferir — nunca cae a un default global
// (fix del leak cross-tenant documentado en el integration review del
// dogfooding CMS 2026-04-22).

const MODULE_NAME = "cms-public";

function capitalize(s: string): string {
  if (!s) return s;
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function buildContactNotifyHtml(params: {
  vertical: string;
  name: string;
  email: string;
  subject: string;
  message: string;
  submissionId: number;
  ipAddress: string | null;
}): string {
  const adminLink = `https://appdev.zentto.net/cms/contact-submissions?highlight=${params.submissionId}`;
  const subjectLine = params.subject
    ? `<tr><td style="padding:6px 12px;font-weight:600;color:#555">Asunto</td><td style="padding:6px 12px">${escapeHtml(params.subject)}</td></tr>`
    : "";
  const ipLine = params.ipAddress
    ? `<tr><td style="padding:6px 12px;font-weight:600;color:#555">IP</td><td style="padding:6px 12px;color:#999;font-family:monospace">${escapeHtml(params.ipAddress)}</td></tr>`
    : "";
  return `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">
      <div style="background:#1a1a2e;color:#fff;padding:20px;text-align:center;border-radius:8px 8px 0 0">
        <h2 style="margin:0;font-size:18px">Nuevo mensaje de contacto — Zentto ${escapeHtml(capitalize(params.vertical))}</h2>
      </div>
      <div style="padding:20px;background:#fff;border:1px solid #eee">
        <table style="width:100%;border-collapse:collapse;font-size:14px">
          <tr><td style="padding:6px 12px;font-weight:600;color:#555;width:120px">Nombre</td><td style="padding:6px 12px">${escapeHtml(params.name)}</td></tr>
          <tr><td style="padding:6px 12px;font-weight:600;color:#555">Email</td><td style="padding:6px 12px"><a href="mailto:${escapeHtml(params.email)}" style="color:#6C63FF">${escapeHtml(params.email)}</a></td></tr>
          ${subjectLine}
          ${ipLine}
        </table>
        <div style="margin-top:16px;padding:16px;background:#f7f7fc;border-radius:6px;white-space:pre-wrap;font-size:14px;line-height:1.5;color:#333">${escapeHtml(params.message)}</div>
        <div style="margin-top:20px;text-align:center">
          <a href="${adminLink}" style="display:inline-block;padding:10px 20px;background:#6C63FF;color:#fff;text-decoration:none;border-radius:6px;font-weight:600">Ver en el inbox</a>
        </div>
      </div>
      <div style="padding:12px;text-align:center;color:#999;font-size:12px">
        Zentto CMS · submission #${params.submissionId}
      </div>
    </div>
  `;
}

export const cmsPublicRouter = Router();

// GET /v1/public/cms/posts — lista paginada + TotalCount
cmsPublicRouter.get("/posts", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const parsed = postListQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_query", details: parsed.error.format() });
      return;
    }
    const q = parsed.data;
    const companyId = q.companyId ?? resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const { rows, total } = await listPosts({
      companyId,
      vertical: q.vertical,
      category: q.category,
      locale: q.locale,
      status: "published",
      limit: q.limit,
      offset: q.offset,
    });

    obs.audit("cms.post.list", {
      module: MODULE_NAME,
      companyId,
      vertical: q.vertical,
      locale: q.locale,
      total,
    });
    obs.perf("cms.post.list", Date.now() - startedAt, {
      module: MODULE_NAME,
      vertical: q.vertical,
    });

    res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=600");
    res.json({
      ok: true,
      data: rows.map(({ TotalCount: _ignore, ...rest }) => rest),
      total,
      limit: q.limit,
      offset: q.offset,
    });
  } catch (err: any) {
    obs.error(`cms.post.list_failed: ${err?.message ?? String(err)}`, {
      module: MODULE_NAME,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/posts/:slug — detalle (solo published)
cmsPublicRouter.get("/posts/:slug", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const queryCompanyId = req.query.company_id ? Number(req.query.company_id) : null;
    const companyId =
      (queryCompanyId && Number.isFinite(queryCompanyId) && queryCompanyId > 0
        ? queryCompanyId
        : null) ?? resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const post = await getPost(req.params.slug, locale, companyId);
    if (!post || post.Status !== "published") {
      obs.audit("cms.post.get_miss", {
        module: MODULE_NAME,
        companyId,
        slug: req.params.slug,
        locale,
      });
      res.status(404).json({ ok: false, error: "post_not_found" });
      return;
    }

    obs.audit("cms.post.get", {
      module: MODULE_NAME,
      companyId,
      slug: req.params.slug,
      locale,
    });
    obs.perf("cms.post.get", Date.now() - startedAt, { module: MODULE_NAME });

    res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=600");
    res.json({ ok: true, data: post });
  } catch (err: any) {
    obs.error(`cms.post.get_failed: ${err?.message ?? String(err)}`, {
      module: MODULE_NAME,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/pages — lista de páginas institucionales publicadas
cmsPublicRouter.get("/pages", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const parsed = pageListQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_query" });
      return;
    }
    const companyId = parsed.data.companyId ?? resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const rows = await listPages({
      companyId,
      vertical: parsed.data.vertical,
      locale: parsed.data.locale,
      status: "published",
      pageType: parsed.data.pageType,
    });

    obs.audit("cms.page.list", {
      module: MODULE_NAME,
      companyId,
      vertical: parsed.data.vertical,
      pageType: parsed.data.pageType,
      locale: parsed.data.locale,
      total: rows.length,
    });
    obs.perf("cms.page.list", Date.now() - startedAt, { module: MODULE_NAME });

    res.setHeader("Cache-Control", "public, s-maxage=600, stale-while-revalidate=1200");
    res.json({ ok: true, data: rows });
  } catch (err: any) {
    obs.error(`cms.page.list_failed: ${err?.message ?? String(err)}`, {
      module: MODULE_NAME,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/pages/:slug — detalle de página institucional
cmsPublicRouter.get("/pages/:slug", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const vertical = typeof req.query.vertical === "string" ? req.query.vertical : "corporate";
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const queryCompanyId = req.query.company_id ? Number(req.query.company_id) : null;
    const companyId =
      (queryCompanyId && Number.isFinite(queryCompanyId) && queryCompanyId > 0
        ? queryCompanyId
        : null) ?? resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const page = await getPage(req.params.slug, vertical, locale, companyId);
    if (!page || page.Status !== "published") {
      obs.audit("cms.page.get_miss", {
        module: MODULE_NAME,
        companyId,
        slug: req.params.slug,
        vertical,
        locale,
      });
      res.status(404).json({ ok: false, error: "page_not_found" });
      return;
    }

    obs.audit("cms.page.get", {
      module: MODULE_NAME,
      companyId,
      slug: req.params.slug,
      vertical,
      locale,
    });
    obs.perf("cms.page.get", Date.now() - startedAt, { module: MODULE_NAME });

    res.setHeader("Cache-Control", "public, s-maxage=600, stale-while-revalidate=1200");
    res.json({ ok: true, data: page });
  } catch (err: any) {
    obs.error(`cms.page.get_failed: ${err?.message ?? String(err)}`, {
      module: MODULE_NAME,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// POST /v1/public/cms/contact/submit — envío del ContactFormAdapter.
// Tenant resuelto via subdomain/header/cookie. Rate-limit suave por IP
// implementado con Map in-memory (reset al reinicio del container — suficiente
// para capture bots; escalate a Redis cuando haga falta).
const CONTACT_RATE_WINDOW_MS = 60_000; // 1 minuto
const CONTACT_RATE_MAX = 5; // máx 5 submits/min/IP
const contactRateLimit = new Map<string, { count: number; resetAt: number }>();

function checkContactRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = contactRateLimit.get(ip);
  if (!entry || entry.resetAt <= now) {
    contactRateLimit.set(ip, { count: 1, resetAt: now + CONTACT_RATE_WINDOW_MS });
    return true;
  }
  if (entry.count >= CONTACT_RATE_MAX) return false;
  entry.count += 1;
  return true;
}

cmsPublicRouter.post("/contact/submit", async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    const parsed = contactSubmitSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        ok: false,
        error: "invalid_body",
        details: parsed.error.format(),
      });
      return;
    }

    const companyId = resolveTenantFromRequest(req);
    if (!companyId) {
      res.status(400).json({ ok: false, error: "tenant_required" });
      return;
    }

    const ip =
      (req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0]?.trim() ??
      req.socket?.remoteAddress ??
      null;
    const ua =
      typeof req.headers["user-agent"] === "string"
        ? req.headers["user-agent"].slice(0, 1000)
        : null;

    if (ip && !checkContactRateLimit(ip)) {
      obs.audit("cms.contact.rate_limited", {
        module: MODULE_NAME,
        companyId,
        ip,
        vertical: parsed.data.vertical,
      });
      res.status(429).json({ ok: false, error: "rate_limited" });
      return;
    }

    const result = await submitContact({
      companyId,
      vertical: parsed.data.vertical,
      slug: parsed.data.slug,
      name: parsed.data.name,
      email: parsed.data.email,
      subject: parsed.data.subject,
      message: parsed.data.message,
      ipAddress: ip,
      userAgent: ua,
    });

    if (!result.ok) {
      obs.error(`cms.contact.submit_failed: ${result.mensaje}`, {
        module: MODULE_NAME,
        companyId,
        vertical: parsed.data.vertical,
      });
      res.status(400).json({ ok: false, error: result.mensaje });
      return;
    }

    obs.audit("cms.contact.submit", {
      module: MODULE_NAME,
      companyId,
      vertical: parsed.data.vertical,
      slug: parsed.data.slug,
      submissionId: result.submission_id,
    });
    obs.perf("cms.contact.submit", Date.now() - startedAt, {
      module: MODULE_NAME,
    });

    // Notify admin — fire-and-forget. El destinatario sale de
    // `CMS_CONTACT_NOTIFY_TO` (con fallback a `hola@zentto.net`). No bloquea
    // la respuesta 201 al usuario — si notify está down el mensaje sigue
    // persistido en BD y visible en el inbox `/cms/contact-submissions`.
    const notifyTo =
      process.env.CMS_CONTACT_NOTIFY_TO ?? "hola@zentto.net";
    if (notifyTo) {
      const verticalLabel = parsed.data.vertical ?? "corporate";
      void notifyEmail(
        notifyTo,
        `[Zentto ${capitalize(verticalLabel)}] Nuevo mensaje de ${parsed.data.name}`,
        buildContactNotifyHtml({
          vertical: verticalLabel,
          name: parsed.data.name,
          email: parsed.data.email,
          subject: parsed.data.subject,
          message: parsed.data.message,
          submissionId: result.submission_id,
          ipAddress: ip,
        }),
        { track: false },
      ).catch((err) => {
        obs.error(`cms.contact.notify_failed: ${err?.message ?? String(err)}`, {
          module: MODULE_NAME,
          submissionId: result.submission_id,
        });
      });
    }

    res.status(201).json({
      ok: true,
      data: { submissionId: result.submission_id },
    });
  } catch (err: any) {
    obs.error(`cms.contact.submit_crashed: ${err?.message ?? String(err)}`, {
      module: MODULE_NAME,
    });
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});
