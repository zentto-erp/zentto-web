import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

/**
 * Resuelve el `companyId` para operaciones ADMIN (con JWT).
 * Si no hay scope activo, lanza error — un endpoint admin nunca debe
 * caer silenciosamente al tenant 1.
 */
function adminScope(): { companyId: number } {
  const s = getActiveScope();
  if (!s?.companyId) {
    throw new Error("admin_scope_required");
  }
  return { companyId: s.companyId };
}

/**
 * Para endpoints **públicos** el caller debe pasar explícitamente el
 * `companyId` resuelto mediante `resolveTenantFromRequest(req)`.
 */

// ─── Tipos ─────────────────────────────────────────────

export interface CmsPageSummary {
  cmsPageId: number;
  slug: string;
  title: string;
  subtitle: string | null;
  templateKey: string | null;
  status: string;
  publishedAt: string | null;
  updatedAt: string;
  createdAt: string;
}

export interface CmsPageFull extends CmsPageSummary {
  config: unknown;
  seo: unknown;
}

export interface PressReleaseSummary {
  pressReleaseId: number;
  slug: string;
  title: string;
  excerpt: string | null;
  coverImageUrl: string | null;
  tags: string[];
  status: string;
  publishedAt: string | null;
  updatedAt: string;
  createdAt: string;
}

export interface PressReleaseFull extends PressReleaseSummary {
  body: string | null;
}

// Normaliza tags — PG envía text[] nativo; MSSQL envía CSV string.
function normalizeTags(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw.map(String).filter(Boolean);
  if (typeof raw === "string" && raw.trim()) {
    return raw.split(",").map((s) => s.trim()).filter(Boolean);
  }
  return [];
}

function mapCmsRow(r: any): CmsPageFull {
  return {
    cmsPageId: Number(r.CmsPageId ?? r.cmsPageId),
    slug: String(r.Slug ?? r.slug ?? ""),
    title: String(r.Title ?? r.title ?? ""),
    subtitle: r.Subtitle ?? r.subtitle ?? null,
    templateKey: r.TemplateKey ?? r.templateKey ?? null,
    status: String(r.Status ?? r.status ?? "draft"),
    publishedAt: r.PublishedAt ?? r.publishedAt ?? null,
    updatedAt: r.UpdatedAt ?? r.updatedAt ?? "",
    createdAt: r.CreatedAt ?? r.createdAt ?? "",
    config: r.Config ?? r.config ?? { sections: [] },
    seo: r.Seo ?? r.seo ?? {},
  };
}

function mapCmsSummary(r: any): CmsPageSummary {
  return {
    cmsPageId: Number(r.CmsPageId ?? r.cmsPageId),
    slug: String(r.Slug ?? r.slug ?? ""),
    title: String(r.Title ?? r.title ?? ""),
    subtitle: r.Subtitle ?? r.subtitle ?? null,
    templateKey: r.TemplateKey ?? r.templateKey ?? null,
    status: String(r.Status ?? r.status ?? "draft"),
    publishedAt: r.PublishedAt ?? r.publishedAt ?? null,
    updatedAt: r.UpdatedAt ?? r.updatedAt ?? "",
    createdAt: r.CreatedAt ?? r.createdAt ?? "",
  };
}

function mapPressRow(r: any): PressReleaseFull {
  return {
    pressReleaseId: Number(r.PressReleaseId ?? r.pressReleaseId),
    slug: String(r.Slug ?? r.slug ?? ""),
    title: String(r.Title ?? r.title ?? ""),
    excerpt: r.Excerpt ?? r.excerpt ?? null,
    body: r.Body ?? r.body ?? null,
    coverImageUrl: r.CoverImageUrl ?? r.coverImageUrl ?? null,
    tags: normalizeTags(r.Tags ?? r.tags),
    status: String(r.Status ?? r.status ?? "draft"),
    publishedAt: r.PublishedAt ?? r.publishedAt ?? null,
    updatedAt: r.UpdatedAt ?? r.updatedAt ?? "",
    createdAt: r.CreatedAt ?? r.createdAt ?? "",
  };
}

function mapPressSummary(r: any): PressReleaseSummary {
  return {
    pressReleaseId: Number(r.PressReleaseId ?? r.pressReleaseId),
    slug: String(r.Slug ?? r.slug ?? ""),
    title: String(r.Title ?? r.title ?? ""),
    excerpt: r.Excerpt ?? r.excerpt ?? null,
    coverImageUrl: r.CoverImageUrl ?? r.coverImageUrl ?? null,
    tags: normalizeTags(r.Tags ?? r.tags),
    status: String(r.Status ?? r.status ?? "draft"),
    publishedAt: r.PublishedAt ?? r.publishedAt ?? null,
    updatedAt: r.UpdatedAt ?? r.updatedAt ?? "",
    createdAt: r.CreatedAt ?? r.createdAt ?? "",
  };
}

// ─── CmsPage ───────────────────────────────────────────

export async function listCmsPages(params: {
  status?: string;
  page?: number;
  limit?: number;
}) {
  const rows = await callSp<any>("usp_Store_CmsPage_List", {
    CompanyId: adminScope().companyId,
    Status: params.status ?? null,
    Page: params.page ?? 1,
    Limit: params.limit ?? 50,
  });
  const totalCount = rows.length > 0 ? Number(rows[0].TotalCount ?? rows[0].totalCount ?? 0) : 0;
  return {
    items: rows.map(mapCmsSummary),
    totalCount,
    page: params.page ?? 1,
    limit: params.limit ?? 50,
  };
}

/**
 * Endpoint público: resolución de slug para visitante anónimo.
 * El `companyId` lo inyecta la ruta vía `resolveTenantFromRequest(req)`.
 */
export async function getCmsPageBySlug(companyId: number, slug: string): Promise<CmsPageFull | null> {
  const rows = await callSp<any>("usp_Store_CmsPage_GetBySlug", {
    CompanyId: companyId,
    Slug: slug,
  });
  if (!rows.length) return null;
  return mapCmsRow(rows[0]);
}

export async function getCmsPageByIdAdmin(cmsPageId: number): Promise<CmsPageFull | null> {
  const rows = await callSp<any>("usp_Store_CmsPage_GetByIdAdmin", {
    CompanyId: adminScope().companyId,
    CmsPageId: cmsPageId,
  });
  if (!rows.length) return null;
  return mapCmsRow(rows[0]);
}

export async function upsertCmsPage(input: {
  cmsPageId?: number | null;
  slug: string;
  title: string;
  subtitle?: string | null;
  templateKey?: string | null;
  config?: unknown;
  seo?: unknown;
  status?: string;
}) {
  const configJson = typeof input.config === "string"
    ? input.config
    : JSON.stringify(input.config ?? { sections: [] });
  const seoJson = typeof input.seo === "string"
    ? input.seo
    : JSON.stringify(input.seo ?? {});
  const { output } = await callSpOut<any>("usp_Store_CmsPage_Upsert", {
    CompanyId: adminScope().companyId,
    CmsPageId: input.cmsPageId ?? null,
    Slug: input.slug,
    Title: input.title,
    Subtitle: input.subtitle ?? null,
    TemplateKey: input.templateKey ?? null,
    Config: configJson,
    Seo: seoJson,
    Status: input.status ?? "draft",
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
    OutCmsPageId: sql.BigInt,
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
    cmsPageId: output?.OutCmsPageId ?? output?.CmsPageId ?? output?.cmsPageId ?? null,
  };
}

export async function deleteCmsPage(cmsPageId: number) {
  const { output } = await callSpOut<any>("usp_Store_CmsPage_Delete", {
    CompanyId: adminScope().companyId,
    CmsPageId: cmsPageId,
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
  };
}

export async function publishCmsPage(cmsPageId: number) {
  const { output } = await callSpOut<any>("usp_Store_CmsPage_Publish", {
    CompanyId: adminScope().companyId,
    CmsPageId: cmsPageId,
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
  };
}

// ─── PressRelease ──────────────────────────────────────

/**
 * listPressReleases tiene dos modos:
 *   - Admin (con scope JWT): no pasar `companyId`, usa adminScope().
 *   - Público (visitante anónimo): pasar `companyId` explícito resuelto por ruta.
 */
export async function listPressReleases(params: {
  companyId?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const companyId = params.companyId ?? adminScope().companyId;
  const rows = await callSp<any>("usp_Store_PressRelease_List", {
    CompanyId: companyId,
    Status: params.status ?? null,
    Page: params.page ?? 1,
    Limit: params.limit ?? 20,
  });
  const totalCount = rows.length > 0 ? Number(rows[0].TotalCount ?? rows[0].totalCount ?? 0) : 0;
  return {
    items: rows.map(mapPressSummary),
    totalCount,
    page: params.page ?? 1,
    limit: params.limit ?? 20,
  };
}

export async function getPressReleaseBySlug(companyId: number, slug: string): Promise<PressReleaseFull | null> {
  const rows = await callSp<any>("usp_Store_PressRelease_GetBySlug", {
    CompanyId: companyId,
    Slug: slug,
  });
  if (!rows.length) return null;
  return mapPressRow(rows[0]);
}

export async function getPressReleaseByIdAdmin(pressReleaseId: number): Promise<PressReleaseFull | null> {
  const rows = await callSp<any>("usp_Store_PressRelease_GetByIdAdmin", {
    CompanyId: adminScope().companyId,
    PressReleaseId: pressReleaseId,
  });
  if (!rows.length) return null;
  return mapPressRow(rows[0]);
}

export async function upsertPressRelease(input: {
  pressReleaseId?: number | null;
  slug: string;
  title: string;
  excerpt?: string | null;
  body?: string | null;
  coverImageUrl?: string | null;
  tags?: string[];
  status?: string;
}) {
  // Para PG pasamos array, para MSSQL pasamos CSV. callSp adapta parametros
  // por driver; un CSV funciona para ambos a nivel de texto (PG lo parseará
  // en el SP como text[]?). Enviamos como CSV por compat; el SP PG espera text[]
  // — ambos casos cubiertos pasando el parámetro como Tags tipo text[]/string.
  // El driver pg de node convierte string → text[] vía cast cuando la signature lo pide.
  const tags = input.tags ?? [];
  // Para SQL Server Tags es NVARCHAR(1000) CSV; para PG es text[].
  // Pasamos según motor: el driver pg respeta arrays, mssql espera string.
  const tagsParam = Array.isArray(tags) ? tags : [];
  const { output } = await callSpOut<any>("usp_Store_PressRelease_Upsert", {
    CompanyId: adminScope().companyId,
    PressReleaseId: input.pressReleaseId ?? null,
    Slug: input.slug,
    Title: input.title,
    Excerpt: input.excerpt ?? null,
    Body: input.body ?? null,
    CoverImageUrl: input.coverImageUrl ?? null,
    Tags: tagsParam,
    Status: input.status ?? "draft",
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
    OutPressId: sql.BigInt,
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
    pressReleaseId: output?.OutPressId ?? output?.PressReleaseId ?? output?.pressReleaseId ?? null,
  };
}

export async function deletePressRelease(pressReleaseId: number) {
  const { output } = await callSpOut<any>("usp_Store_PressRelease_Delete", {
    CompanyId: adminScope().companyId,
    PressReleaseId: pressReleaseId,
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
  };
}

export async function publishPressRelease(pressReleaseId: number) {
  const { output } = await callSpOut<any>("usp_Store_PressRelease_Publish", {
    CompanyId: adminScope().companyId,
    PressReleaseId: pressReleaseId,
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
  };
}

// ─── ContactMessage ────────────────────────────────────

export async function createContactMessage(input: {
  companyId: number;
  name: string;
  email: string;
  phone?: string | null;
  subject?: string | null;
  message: string;
  source?: string;
}) {
  const { output } = await callSpOut<any>("usp_Store_ContactMessage_Create", {
    CompanyId: input.companyId,
    Name: input.name,
    Email: input.email,
    Phone: input.phone ?? null,
    Subject: input.subject ?? null,
    Message: input.message,
    Source: input.source ?? "contact",
  }, {
    Resultado: sql.Int,
    Mensaje: sql.NVarChar(500),
    OutId: sql.BigInt,
  });
  return {
    ok: Number(output?.Resultado ?? output?.resultado ?? 0) === 1,
    mensaje: String(output?.Mensaje ?? output?.mensaje ?? ""),
    contactMessageId: output?.OutId ?? output?.ContactMessageId ?? output?.contactMessageId ?? null,
  };
}

export async function listContactMessages(params: {
  status?: string;
  page?: number;
  limit?: number;
}) {
  const rows = await callSp<any>("usp_Store_ContactMessage_List", {
    CompanyId: adminScope().companyId,
    Status: params.status ?? null,
    Page: params.page ?? 1,
    Limit: params.limit ?? 50,
  });
  const totalCount = rows.length > 0 ? Number(rows[0].TotalCount ?? rows[0].totalCount ?? 0) : 0;
  return {
    items: rows.map((r: any) => ({
      contactMessageId: Number(r.ContactMessageId ?? r.contactMessageId),
      name: String(r.Name ?? r.name ?? ""),
      email: String(r.Email ?? r.email ?? ""),
      phone: r.Phone ?? r.phone ?? null,
      subject: r.Subject ?? r.subject ?? null,
      message: String(r.Message ?? r.message ?? ""),
      source: r.Source ?? r.source ?? null,
      status: String(r.Status ?? r.status ?? "new"),
      createdAt: r.CreatedAt ?? r.createdAt ?? "",
    })),
    totalCount,
    page: params.page ?? 1,
    limit: params.limit ?? 50,
  };
}
