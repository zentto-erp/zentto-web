import { Router } from "express";
import { z } from "zod";
import { requireJwt } from "../../middleware/auth.js";
import {
  listCmsPages,
  getCmsPageBySlug,
  getCmsPageByIdAdmin,
  upsertCmsPage,
  deleteCmsPage,
  publishCmsPage,
  listPressReleases,
  getPressReleaseBySlug,
  getPressReleaseByIdAdmin,
  upsertPressRelease,
  deletePressRelease,
  publishPressRelease,
  createContactMessage,
  listContactMessages,
} from "./cms.service.js";

export const cmsRouter = Router();

// ─── Público: páginas CMS ──────────────────────────────
cmsRouter.get("/cms/pages/:slug", async (req, res) => {
  try {
    const page = await getCmsPageBySlug(String(req.params.slug));
    if (!page) return res.status(404).json({ error: "not_found" });
    res.json({ page });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Público: press releases ───────────────────────────
cmsRouter.get("/press/releases", async (req, res) => {
  try {
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const out = await listPressReleases({ status: "published", page, limit });
    res.json(out);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.get("/press/releases/:slug", async (req, res) => {
  try {
    const item = await getPressReleaseBySlug(String(req.params.slug));
    if (!item) return res.status(404).json({ error: "not_found" });
    res.json({ item });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Público: contact form ─────────────────────────────
const contactSchema = z.object({
  name: z.string().min(1).max(160),
  email: z.string().email(),
  phone: z.string().max(40).optional().nullable(),
  subject: z.string().max(240).optional().nullable(),
  message: z.string().min(1),
  source: z.string().max(60).optional(),
});

cmsRouter.post("/contact/message", async (req, res) => {
  try {
    const parsed = contactSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    }
    const out = await createContactMessage(parsed.data);
    if (!out.ok) return res.status(400).json({ error: out.mensaje });
    res.status(201).json({ ok: true, contactMessageId: out.contactMessageId });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Admin: CMS pages CRUD ─────────────────────────────
cmsRouter.get("/admin/cms/pages", requireJwt, async (req, res) => {
  try {
    const status = (req.query.status as string) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    const out = await listCmsPages({ status, page, limit });
    res.json(out);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.get("/admin/cms/pages/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const page = await getCmsPageByIdAdmin(id);
    if (!page) return res.status(404).json({ error: "not_found" });
    res.json({ page });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

const cmsUpsertSchema = z.object({
  slug: z.string().min(1).max(120),
  title: z.string().min(1).max(200),
  subtitle: z.string().max(300).optional().nullable(),
  templateKey: z.string().max(80).optional().nullable(),
  config: z.any().optional(),
  seo: z.any().optional(),
  status: z.enum(["draft", "published", "archived"]).default("draft"),
});

cmsRouter.post("/admin/cms/pages", requireJwt, async (req, res) => {
  try {
    const parsed = cmsUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const out = await upsertCmsPage(parsed.data);
    if (!out.ok) return res.status(400).json({ error: out.mensaje });
    res.status(201).json({ ok: true, cmsPageId: out.cmsPageId });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.put("/admin/cms/pages/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const parsed = cmsUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const out = await upsertCmsPage({ ...parsed.data, cmsPageId: id });
    if (!out.ok) return res.status(400).json({ error: out.mensaje });
    res.json({ ok: true, cmsPageId: out.cmsPageId });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.delete("/admin/cms/pages/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const out = await deleteCmsPage(id);
    if (!out.ok) return res.status(404).json({ error: out.mensaje });
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.post("/admin/cms/pages/:id/publish", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const out = await publishCmsPage(id);
    if (!out.ok) return res.status(404).json({ error: out.mensaje });
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Admin: press releases CRUD ────────────────────────
cmsRouter.get("/admin/press/releases", requireJwt, async (req, res) => {
  try {
    const status = (req.query.status as string) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    const out = await listPressReleases({ status, page, limit });
    res.json(out);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.get("/admin/press/releases/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const item = await getPressReleaseByIdAdmin(id);
    if (!item) return res.status(404).json({ error: "not_found" });
    res.json({ item });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

const pressUpsertSchema = z.object({
  slug: z.string().min(1).max(160),
  title: z.string().min(1).max(240),
  excerpt: z.string().max(600).optional().nullable(),
  body: z.string().optional().nullable(),
  coverImageUrl: z.string().max(500).optional().nullable(),
  tags: z.array(z.string()).optional(),
  status: z.enum(["draft", "published", "archived"]).default("draft"),
});

cmsRouter.post("/admin/press/releases", requireJwt, async (req, res) => {
  try {
    const parsed = pressUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const out = await upsertPressRelease(parsed.data);
    if (!out.ok) return res.status(400).json({ error: out.mensaje });
    res.status(201).json({ ok: true, pressReleaseId: out.pressReleaseId });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.put("/admin/press/releases/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const parsed = pressUpsertSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const out = await upsertPressRelease({ ...parsed.data, pressReleaseId: id });
    if (!out.ok) return res.status(400).json({ error: out.mensaje });
    res.json({ ok: true, pressReleaseId: out.pressReleaseId });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.delete("/admin/press/releases/:id", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const out = await deletePressRelease(id);
    if (!out.ok) return res.status(404).json({ error: out.mensaje });
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

cmsRouter.post("/admin/press/releases/:id/publish", requireJwt, async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "invalid_id" });
    const out = await publishPressRelease(id);
    if (!out.ok) return res.status(404).json({ error: out.mensaje });
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Admin: contact messages ───────────────────────────
cmsRouter.get("/admin/contact/messages", requireJwt, async (req, res) => {
  try {
    const status = (req.query.status as string) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    const out = await listContactMessages({ status, page, limit });
    res.json(out);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
