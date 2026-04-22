import { Router, type Response } from "express";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import {
  postUpsertSchema,
  pageUpsertSchema,
  contactListQuerySchema,
} from "./schema.js";
import {
  listPosts,
  getPost,
  upsertPost,
  publishPost,
  deletePost,
  listPages,
  getPage,
  upsertPage,
  publishPage,
  deletePage,
  listContactSubmissions,
  type ContactSubmissionItem,
} from "./service.js";

// Router privado: /v1/cms/* — requiere JWT (montado después del auth middleware global).
export const cmsAdminRouter = Router();

function requireCmsEditor(req: AuthenticatedRequest, res: Response, next: () => void) {
  const companyId = req.scope?.companyId;
  if (!companyId) {
    res.status(401).json({ ok: false, error: "unauthenticated" });
    return;
  }
  const isAdmin = req.user?.isAdmin === true;
  const hasCmsRole = Array.isArray(req.user?.roles) && req.user.roles.includes("CMS_EDITOR");
  if (!isAdmin && !hasCmsRole) {
    res.status(403).json({ ok: false, error: "cms_editor_required" });
    return;
  }
  next();
}

cmsAdminRouter.use(requireCmsEditor as any);

// ─── Posts ───────────────────────────────────────────────────────────────────
cmsAdminRouter.get("/posts", async (req, res) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope!.companyId;
    const vertical = typeof req.query.vertical === "string" ? req.query.vertical : undefined;
    const category = typeof req.query.category === "string" ? req.query.category : undefined;
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const status = typeof req.query.status === "string" ? req.query.status : undefined;
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
    const offset = Math.max(Number(req.query.offset) || 0, 0);

    const { rows, total } = await listPosts({ companyId, vertical, category, locale, status, limit, offset });
    res.json({ ok: true, data: rows.map(({ TotalCount: _t, ...r }) => r), total, limit, offset });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.get("/posts/:slug", async (req, res) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope!.companyId;
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const post = await getPost(req.params.slug, locale, companyId);
    if (!post) {
      res.status(404).json({ ok: false, error: "post_not_found" });
      return;
    }
    res.json({ ok: true, data: post });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.post("/posts", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const parsed = postUpsertSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ ok: false, error: "invalid_body", details: parsed.error.format() });
    return;
  }
  try {
    const result = await upsertPost(parsed.data, companyId);
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.put("/posts/:id", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const postId = Number(req.params.id);
  if (!Number.isFinite(postId) || postId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  const parsed = postUpsertSchema.safeParse({ ...req.body, postId });
  if (!parsed.success) {
    res.status(400).json({ ok: false, error: "invalid_body", details: parsed.error.format() });
    return;
  }
  try {
    const result = await upsertPost(parsed.data, companyId);
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.post("/posts/:id/publish", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const postId = Number(req.params.id);
  if (!Number.isFinite(postId) || postId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  try {
    const result = await publishPost(postId, true, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.post("/posts/:id/unpublish", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const postId = Number(req.params.id);
  if (!Number.isFinite(postId) || postId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  try {
    const result = await publishPost(postId, false, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.delete("/posts/:id", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const postId = Number(req.params.id);
  if (!Number.isFinite(postId) || postId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  try {
    const result = await deletePost(postId, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ─── Pages ───────────────────────────────────────────────────────────────────
cmsAdminRouter.get("/pages", async (req, res) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope!.companyId;
    const vertical = typeof req.query.vertical === "string" ? req.query.vertical : undefined;
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const status = typeof req.query.status === "string" ? req.query.status : undefined;
    const pageType = typeof req.query.pageType === "string" ? req.query.pageType : undefined;
    const rows = await listPages({ companyId, vertical, locale, status, pageType });
    res.json({ ok: true, data: rows });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.get("/pages/:slug", async (req, res) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope!.companyId;
    const vertical = typeof req.query.vertical === "string" ? req.query.vertical : "corporate";
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const page = await getPage(req.params.slug, vertical, locale, companyId);
    if (!page) {
      res.status(404).json({ ok: false, error: "page_not_found" });
      return;
    }
    res.json({ ok: true, data: page });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.post("/pages", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const parsed = pageUpsertSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ ok: false, error: "invalid_body", details: parsed.error.format() });
    return;
  }
  try {
    const result = await upsertPage(parsed.data, companyId);
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.put("/pages/:id", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const pageId = Number(req.params.id);
  if (!Number.isFinite(pageId) || pageId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  const parsed = pageUpsertSchema.safeParse({ ...req.body, pageId });
  if (!parsed.success) {
    res.status(400).json({ ok: false, error: "invalid_body", details: parsed.error.format() });
    return;
  }
  try {
    const result = await upsertPage(parsed.data, companyId);
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.post("/pages/:id/publish", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const pageId = Number(req.params.id);
  if (!Number.isFinite(pageId) || pageId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  try {
    const result = await publishPage(pageId, true, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

cmsAdminRouter.delete("/pages/:id", async (req, res) => {
  const companyId = (req as AuthenticatedRequest).scope!.companyId;
  const pageId = Number(req.params.id);
  if (!Number.isFinite(pageId) || pageId <= 0) {
    res.status(400).json({ ok: false, error: "invalid_id" });
    return;
  }
  try {
    const result = await deletePage(pageId, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// ─── Contact Submissions (inbox admin) ───────────────────────────────────────
cmsAdminRouter.get("/contact-submissions", async (req, res) => {
  try {
    const companyId = (req as AuthenticatedRequest).scope!.companyId;
    const parsed = contactListQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({
        ok: false,
        error: "invalid_query",
        details: parsed.error.format(),
      });
      return;
    }
    const { rows, total } = await listContactSubmissions({
      companyId,
      vertical: parsed.data.vertical,
      status: parsed.data.status,
      limit: parsed.data.limit,
      offset: parsed.data.offset,
    });
    res.json({
      ok: true,
      data: rows.map((r: ContactSubmissionItem) => {
        const { TotalCount: _t, ...rest } = r;
        return rest;
      }),
      total,
      limit: parsed.data.limit,
      offset: parsed.data.offset,
    });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});
