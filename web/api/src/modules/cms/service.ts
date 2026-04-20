import { callSp } from "../../db/query.js";
import type { PostUpsertInput, PageUpsertInput } from "./schema.js";

// ─── Post types ──────────────────────────────────────────────────────────────
export interface PostListItem {
  PostId: number;
  CompanyId: number;
  Slug: string;
  Vertical: string;
  Category: string;
  Locale: string;
  Title: string;
  Excerpt: string;
  CoverUrl: string;
  AuthorName: string;
  AuthorSlug: string;
  AuthorAvatar: string;
  Tags: string;
  ReadingMin: number;
  Status: string;
  PublishedAt: string | null;
  TotalCount?: string | number;
}

export interface PostDetail extends PostListItem {
  Body: string;
  SeoTitle: string;
  SeoDescription: string;
  SeoImageUrl: string;
  CreatedAt: string;
  UpdatedAt: string;
}

// ─── Page types ──────────────────────────────────────────────────────────────
export interface PageListItem {
  PageId: number;
  CompanyId: number;
  Slug: string;
  Vertical: string;
  Locale: string;
  Title: string;
  Status: string;
  PublishedAt: string | null;
  UpdatedAt: string;
}

export interface PageDetail extends PageListItem {
  Body: string;
  Meta: Record<string, unknown>;
  SeoTitle: string;
  SeoDescription: string;
  CreatedAt: string;
}

// ─── Post service ────────────────────────────────────────────────────────────
export async function listPosts(opts: {
  vertical?: string;
  category?: string;
  locale: string;
  status?: string;
  limit: number;
  offset: number;
}): Promise<{ rows: PostListItem[]; total: number }> {
  const rows = (await callSp("usp_cms_post_list", {
    p_vertical: opts.vertical ?? null,
    p_category: opts.category ?? null,
    p_locale: opts.locale,
    p_status: opts.status ?? "published",
    p_limit: opts.limit,
    p_offset: opts.offset,
  })) as PostListItem[];

  const total = rows[0]?.TotalCount ? Number(rows[0].TotalCount) : 0;
  return { rows, total };
}

export async function getPost(slug: string, locale: string): Promise<PostDetail | null> {
  const rows = (await callSp("usp_cms_post_get", {
    p_slug: slug,
    p_locale: locale,
  })) as PostDetail[];
  return rows[0] ?? null;
}

export async function upsertPost(input: PostUpsertInput): Promise<{ ok: boolean; mensaje: string; post_id: number }> {
  const rows = (await callSp("usp_cms_post_upsert", {
    p_post_id: input.postId ?? null,
    p_company_id: 1,
    p_slug: input.slug,
    p_vertical: input.vertical,
    p_category: input.category,
    p_locale: input.locale,
    p_title: input.title,
    p_excerpt: input.excerpt,
    p_body: input.body,
    p_cover_url: input.coverUrl,
    p_author_name: input.authorName,
    p_author_slug: input.authorSlug,
    p_author_avatar: input.authorAvatar,
    p_tags: input.tags,
    p_reading_min: input.readingMin,
    p_seo_title: input.seoTitle,
    p_seo_description: input.seoDescription,
    p_seo_image_url: input.seoImageUrl,
  })) as Array<{ ok: boolean; mensaje: string; post_id: number }>;

  const r = rows[0] ?? { ok: false, mensaje: "no_result", post_id: 0 };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje), post_id: Number(r.post_id) };
}

export async function publishPost(postId: number, publish: boolean): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_post_publish", {
    p_post_id: postId,
    p_publish: publish,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

export async function deletePost(postId: number): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_post_delete", {
    p_post_id: postId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

// ─── Page service ────────────────────────────────────────────────────────────
export async function listPages(opts: {
  vertical?: string;
  locale: string;
  status?: string;
}): Promise<PageListItem[]> {
  return (await callSp("usp_cms_page_list", {
    p_vertical: opts.vertical ?? null,
    p_locale: opts.locale,
    p_status: opts.status ?? "published",
  })) as PageListItem[];
}

export async function getPage(
  slug: string,
  vertical: string,
  locale: string,
): Promise<PageDetail | null> {
  const rows = (await callSp("usp_cms_page_get", {
    p_slug: slug,
    p_vertical: vertical,
    p_locale: locale,
  })) as PageDetail[];
  return rows[0] ?? null;
}

export async function upsertPage(input: PageUpsertInput): Promise<{ ok: boolean; mensaje: string; page_id: number }> {
  const rows = (await callSp("usp_cms_page_upsert", {
    p_page_id: input.pageId ?? null,
    p_company_id: 1,
    p_slug: input.slug,
    p_vertical: input.vertical,
    p_locale: input.locale,
    p_title: input.title,
    p_body: input.body,
    p_meta: JSON.stringify(input.meta ?? {}),
    p_seo_title: input.seoTitle,
    p_seo_description: input.seoDescription,
  })) as Array<{ ok: boolean; mensaje: string; page_id: number }>;

  const r = rows[0] ?? { ok: false, mensaje: "no_result", page_id: 0 };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje), page_id: Number(r.page_id) };
}

export async function publishPage(pageId: number, publish: boolean): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_page_publish", {
    p_page_id: pageId,
    p_publish: publish,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

export async function deletePage(pageId: number): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_page_delete", {
    p_page_id: pageId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}
