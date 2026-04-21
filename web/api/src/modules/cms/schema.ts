import { z } from "zod";

// ─── Post ────────────────────────────────────────────────────────────────────
export const postListQuerySchema = z.object({
  companyId: z.coerce.number().int().positive().default(1),
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
export const pageListQuerySchema = z.object({
  companyId: z.coerce.number().int().positive().default(1),
  vertical: z.string().max(50).optional(),
  locale: z.string().max(10).default("es"),
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
});
export type PageUpsertInput = z.infer<typeof pageUpsertSchema>;
