import { Router, type Request, type Response } from "express";
import { postListQuerySchema, pageListQuerySchema } from "./schema.js";
import { listPosts, getPost, listPages, getPage } from "./service.js";
import { resolveTenantFromRequest } from "../_shared/scope.js";
import { obs } from "../integrations/observability.js";

// Router público: /v1/public/cms/* — sin JWT.
// Solo expone contenido con Status='published'.
//
// Tenant resolution: cada endpoint resuelve CompanyId via
// `resolveTenantFromRequest(req)` si no viene en query. Falla con 400
// `tenant_required` si no se puede inferir — nunca cae a un default global
// (fix del leak cross-tenant documentado en el integration review del
// dogfooding CMS 2026-04-22).

const MODULE_NAME = "cms-public";

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
    });

    obs.audit("cms.page.list", {
      module: MODULE_NAME,
      companyId,
      vertical: parsed.data.vertical,
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
