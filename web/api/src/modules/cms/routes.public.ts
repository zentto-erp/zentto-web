import { Router, type Request, type Response } from "express";
import { postListQuerySchema, pageListQuerySchema } from "./schema.js";
import { listPosts, getPost, listPages, getPage } from "./service.js";

// Router público: /v1/public/cms/* — sin JWT.
// Solo expone contenido con Status='published'.
export const cmsPublicRouter = Router();

// GET /v1/public/cms/posts — lista paginada + TotalCount
cmsPublicRouter.get("/posts", async (req: Request, res: Response) => {
  try {
    const parsed = postListQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_query", details: parsed.error.format() });
      return;
    }
    const q = parsed.data;
    const { rows, total } = await listPosts({
      vertical: q.vertical,
      category: q.category,
      locale: q.locale,
      status: "published",
      limit: q.limit,
      offset: q.offset,
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
    console.error("[cms/public/posts]", err.message);
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/posts/:slug — detalle (solo published)
cmsPublicRouter.get("/posts/:slug", async (req: Request, res: Response) => {
  try {
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const post = await getPost(req.params.slug, locale);
    if (!post || post.Status !== "published") {
      res.status(404).json({ ok: false, error: "post_not_found" });
      return;
    }
    res.setHeader("Cache-Control", "public, s-maxage=300, stale-while-revalidate=600");
    res.json({ ok: true, data: post });
  } catch (err: any) {
    console.error("[cms/public/posts/:slug]", err.message);
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/pages — lista de páginas institucionales publicadas
cmsPublicRouter.get("/pages", async (req: Request, res: Response) => {
  try {
    const parsed = pageListQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ ok: false, error: "invalid_query" });
      return;
    }
    const rows = await listPages({
      vertical: parsed.data.vertical,
      locale: parsed.data.locale,
      status: "published",
    });
    res.setHeader("Cache-Control", "public, s-maxage=600, stale-while-revalidate=1200");
    res.json({ ok: true, data: rows });
  } catch (err: any) {
    console.error("[cms/public/pages]", err.message);
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});

// GET /v1/public/cms/pages/:slug — detalle de página institucional
cmsPublicRouter.get("/pages/:slug", async (req: Request, res: Response) => {
  try {
    const vertical = typeof req.query.vertical === "string" ? req.query.vertical : "corporate";
    const locale = typeof req.query.locale === "string" ? req.query.locale : "es";
    const page = await getPage(req.params.slug, vertical, locale);
    if (!page || page.Status !== "published") {
      res.status(404).json({ ok: false, error: "page_not_found" });
      return;
    }
    res.setHeader("Cache-Control", "public, s-maxage=600, stale-while-revalidate=1200");
    res.json({ ok: true, data: page });
  } catch (err: any) {
    console.error("[cms/public/pages/:slug]", err.message);
    res.status(500).json({ ok: false, error: "internal_error" });
  }
});
