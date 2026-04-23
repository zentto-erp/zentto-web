import { z } from "zod";

// ─── Post ────────────────────────────────────────────────────────────────────
// `companyId` es opcional en query; endpoints públicos lo resuelven via
// `resolveTenantFromRequest` (subdomain/header/cookie/env) y 400 si es null.
export const postListQuerySchema = z.object({
  companyId: z.coerce.number().int().positive().optional(),
  vertical: z.string().max(50).optional(),
  category: z.string().max(50).optional(),
  locale: z.string().max(10).default("es"),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export const postUpsertSchema = z.object({
  postId: z.number().int().positive().optional(),
  slug: z.string().min(1).max(200),
  vertical: z.string().min(1).max(50),
  category: z.string().min(1).max(50),
  locale: z.string().max(10).default("es"),
  title: z.string().min(1).max(300),
  excerpt: z.string().max(500).default(""),
  body: z.string().default(""),
  coverUrl: z.string().max(500).default(""),
  authorName: z.string().max(200).default(""),
  authorSlug: z.string().max(100).default(""),
  authorAvatar: z.string().max(500).default(""),
  tags: z.string().max(500).default(""),
  readingMin: z.number().int().min(1).max(300).default(5),
  seoTitle: z.string().max(300).default(""),
  seoDescription: z.string().max(500).default(""),
  seoImageUrl: z.string().max(500).default(""),
});
export type PostUpsertInput = z.infer<typeof postUpsertSchema>;

// ─── Page ────────────────────────────────────────────────────────────────────
// Tipos canónicos de página corporativa — soft enum. Valores aceptados por la
// BD (CHECK constraint) y usados por el editor CMS para ofrecer plantillas.
export const CMS_PAGE_TYPES = [
  "about",
  "contact",
  "press",
  "legal-terms",
  "legal-privacy",
  "case-study",
  "custom",
] as const;
export type CmsPageType = (typeof CMS_PAGE_TYPES)[number];

export const pageListQuerySchema = z.object({
  companyId: z.coerce.number().int().positive().optional(),
  vertical: z.string().max(50).optional(),
  locale: z.string().max(10).default("es"),
  pageType: z.enum(CMS_PAGE_TYPES).optional(),
});

export const pageUpsertSchema = z.object({
  pageId: z.number().int().positive().optional(),
  slug: z.string().min(1).max(100),
  vertical: z.string().max(50).default("corporate"),
  locale: z.string().max(10).default("es"),
  title: z.string().min(1).max(300),
  body: z.string().default(""),
  meta: z.record(z.unknown()).default({}),
  seoTitle: z.string().max(300).default(""),
  seoDescription: z.string().max(500).default(""),
  pageType: z.enum(CMS_PAGE_TYPES).default("custom"),
});
export type PageUpsertInput = z.infer<typeof pageUpsertSchema>;

// ─── Contact Submission ──────────────────────────────────────────────────────
// Endpoint público POST /v1/public/cms/contact/submit — consumido por el
// `ContactFormAdapter` del `@zentto/landing-kit`. Multi-tenant: CompanyId
// se resuelve via `resolveTenantFromRequest`, NO viene en body.
export const contactSubmitSchema = z.object({
  vertical: z.string().min(1).max(50).default("corporate"),
  slug: z.string().min(1).max(100).default("contacto"),
  name: z.string().min(1).max(200),
  email: z.string().email().max(200),
  subject: z.string().max(200).default(""),
  message: z.string().min(1).max(5000),
});
export type ContactSubmitInput = z.infer<typeof contactSubmitSchema>;

export const contactListQuerySchema = z.object({
  vertical: z.string().max(50).optional(),
  status: z.string().max(20).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

// Estados aceptados para PATCH de ContactSubmission.Status (CHECK constraint
// en BD). El endpoint admin valida contra este enum; el SP también defiende.
export const CMS_CONTACT_STATUSES = ["pending", "read", "archived"] as const;
export type CmsContactStatus = (typeof CMS_CONTACT_STATUSES)[number];

export const contactUpdateStatusSchema = z.object({
  status: z.enum(CMS_CONTACT_STATUSES),
});
