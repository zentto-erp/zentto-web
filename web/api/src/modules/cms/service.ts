import { callSp } from "../../db/query.js";
import type { PostUpsertInput, PageUpsertInput } from "./schema.js";

// callSp(key) → toSnakeParam(key) que automáticamente prepends "p_".
// Por eso las keys aquí son PascalCase / camelCase sin prefijo — el helper
// las convierte a p_snake_case. Pasar "p_company_id" produce "p_p_company_id".

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
  companyId?: number;
  vertical?: string;
  category?: string;
  locale: string;
  status?: string;
  limit: number;
  offset: number;
}): Promise<{ rows: PostListItem[]; total: number }> {
  const rows = (await callSp("usp_cms_post_list", {
    CompanyId: opts.companyId ?? 1,
    Vertical: opts.vertical ?? null,
    Category: opts.category ?? null,
    Locale: opts.locale,
    Status: opts.status ?? "published",
    Limit: opts.limit,
    Offset: opts.offset,
  })) as PostListItem[];

  const total = rows[0]?.TotalCount ? Number(rows[0].TotalCount) : 0;
  return { rows, total };
}

export async function getPost(slug: string, locale: string, companyId = 1): Promise<PostDetail | null> {
  const rows = (await callSp("usp_cms_post_get", {
    Slug: slug,
    Locale: locale,
    CompanyId: companyId,
  })) as PostDetail[];
  return rows[0] ?? null;
}

export async function upsertPost(
  input: PostUpsertInput,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string; post_id: number }> {
  const rows = (await callSp("usp_cms_post_upsert", {
    PostId: input.postId ?? null,
    CompanyId: companyId,
    Slug: input.slug,
    Vertical: input.vertical,
    Category: input.category,
    Locale: input.locale,
    Title: input.title,
    Excerpt: input.excerpt,
    Body: input.body,
    CoverUrl: input.coverUrl,
    AuthorName: input.authorName,
    AuthorSlug: input.authorSlug,
    AuthorAvatar: input.authorAvatar,
    Tags: input.tags,
    ReadingMin: input.readingMin,
    SeoTitle: input.seoTitle,
    SeoDescription: input.seoDescription,
    SeoImageUrl: input.seoImageUrl,
  })) as Array<{ ok: boolean; mensaje: string; PostId: number }>;

  const r = rows[0] ?? { ok: false, mensaje: "no_result", PostId: 0 };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje), post_id: Number(r.PostId) };
}

export async function publishPost(
  postId: number,
  publish: boolean,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_post_publish", {
    PostId: postId,
    Publish: publish,
    CompanyId: companyId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

export async function deletePost(
  postId: number,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_post_delete", {
    PostId: postId,
    CompanyId: companyId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

// ─── Page service ────────────────────────────────────────────────────────────
export async function listPages(opts: {
  companyId?: number;
  vertical?: string;
  locale: string;
  status?: string;
}): Promise<PageListItem[]> {
  return (await callSp("usp_cms_page_list", {
    CompanyId: opts.companyId ?? 1,
    Vertical: opts.vertical ?? null,
    Locale: opts.locale,
    Status: opts.status ?? "published",
  })) as PageListItem[];
}

export async function getPage(
  slug: string,
  vertical: string,
  locale: string,
  companyId = 1,
): Promise<PageDetail | null> {
  const rows = (await callSp("usp_cms_page_get", {
    Slug: slug,
    Vertical: vertical,
    Locale: locale,
    CompanyId: companyId,
  })) as PageDetail[];
  return rows[0] ?? null;
}

export async function upsertPage(
  input: PageUpsertInput,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string; page_id: number }> {
  const rows = (await callSp("usp_cms_page_upsert", {
    PageId: input.pageId ?? null,
    CompanyId: companyId,
    Slug: input.slug,
    Vertical: input.vertical,
    Locale: input.locale,
    Title: input.title,
    Body: input.body,
    Meta: JSON.stringify(input.meta ?? {}),
    SeoTitle: input.seoTitle,
    SeoDescription: input.seoDescription,
  })) as Array<{ ok: boolean; mensaje: string; PageId: number }>;

  const r = rows[0] ?? { ok: false, mensaje: "no_result", PageId: 0 };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje), page_id: Number(r.PageId) };
}

export async function publishPage(
  pageId: number,
  publish: boolean,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_page_publish", {
    PageId: pageId,
    Publish: publish,
    CompanyId: companyId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}

export async function deletePage(
  pageId: number,
  companyId: number,
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = (await callSp("usp_cms_page_delete", {
    PageId: pageId,
    CompanyId: companyId,
  })) as Array<{ ok: boolean; mensaje: string }>;
  const r = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(r.ok), mensaje: String(r.mensaje) };
}
