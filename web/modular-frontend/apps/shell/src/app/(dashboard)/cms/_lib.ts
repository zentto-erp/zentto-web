"use client";

import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

export const VERTICALS = [
  { value: "corporate", label: "Corporate" },
  { value: "hotel", label: "Hotel" },
  { value: "medical", label: "Medical" },
  { value: "tickets", label: "Tickets" },
  { value: "restaurante", label: "Restaurante" },
  { value: "education", label: "Education" },
  { value: "inmobiliario", label: "Inmobiliario" },
  { value: "rental", label: "Rental" },
  { value: "pos", label: "POS" },
] as const;

export const CATEGORIES = [
  { value: "producto", label: "Producto" },
  { value: "casos", label: "Casos" },
  { value: "tutoriales", label: "Tutoriales" },
  { value: "noticias", label: "Noticias" },
  { value: "changelog", label: "Changelog" },
] as const;

export const STATUSES = [
  { value: "draft", label: "Borrador" },
  { value: "published", label: "Publicado" },
  { value: "archived", label: "Archivado" },
] as const;

export interface CmsPost {
  PostId: number;
  CompanyId: number;
  Slug: string;
  Vertical: string;
  Category: string;
  Locale: string;
  Title: string;
  Excerpt: string;
  Body: string;
  CoverUrl: string;
  AuthorName: string;
  AuthorSlug: string;
  AuthorAvatar: string;
  Tags: string;
  ReadingMin: number;
  SeoTitle: string;
  SeoDescription: string;
  SeoImageUrl: string;
  Status: string;
  PublishedAt: string | null;
  CreatedAt: string;
  UpdatedAt: string;
}

export interface CmsPage {
  PageId: number;
  CompanyId: number;
  Slug: string;
  Vertical: string;
  /** 'about' | 'contact' | 'press' | 'legal-terms' | 'legal-privacy' | 'case-study' | 'custom' */
  PageType?: string;
  Locale: string;
  Title: string;
  Body?: string;
  Meta?: Record<string, unknown>;
  SeoTitle: string;
  SeoDescription: string;
  Status: string;
  PublishedAt: string | null;
  CreatedAt?: string;
  UpdatedAt: string;
}

export interface PostListResponse {
  ok: boolean;
  data: CmsPost[];
  total: number;
  limit: number;
  offset: number;
}

export interface DetailResponse<T> {
  ok: boolean;
  data: T;
}

// ─── Posts ──────────────────────────────────────────────────────────────────
export async function listPosts(params: {
  vertical?: string;
  category?: string;
  locale?: string;
  status?: string;
  limit?: number;
  offset?: number;
} = {}): Promise<PostListResponse> {
  return apiGet("/v1/cms/posts", params as Record<string, unknown>);
}

export async function getPost(slug: string, locale = "es"): Promise<DetailResponse<CmsPost>> {
  return apiGet(`/v1/cms/posts/${encodeURIComponent(slug)}`, { locale });
}

export async function createPost(input: Partial<CmsPost> & { slug: string; title: string; vertical: string; category: string }) {
  return apiPost("/v1/cms/posts", toUpsertBody(input));
}

export async function updatePost(id: number, input: Partial<CmsPost> & { slug: string; title: string; vertical: string; category: string }) {
  return apiPut(`/v1/cms/posts/${id}`, toUpsertBody(input));
}

export async function publishPost(id: number) {
  return apiPost(`/v1/cms/posts/${id}/publish`, {});
}

export async function unpublishPost(id: number) {
  return apiPost(`/v1/cms/posts/${id}/unpublish`, {});
}

export async function deletePost(id: number) {
  return apiDelete(`/v1/cms/posts/${id}`);
}

function toUpsertBody(p: Partial<CmsPost> & { slug: string; title: string; vertical: string; category: string }) {
  return {
    slug: p.Slug ?? p.slug,
    vertical: p.Vertical ?? p.vertical,
    category: p.Category ?? p.category,
    locale: p.Locale ?? "es",
    title: p.Title ?? p.title,
    excerpt: p.Excerpt ?? "",
    body: p.Body ?? "",
    coverUrl: p.CoverUrl ?? "",
    authorName: p.AuthorName ?? "",
    authorSlug: p.AuthorSlug ?? "",
    authorAvatar: p.AuthorAvatar ?? "",
    tags: p.Tags ?? "",
    readingMin: p.ReadingMin ?? 5,
    seoTitle: p.SeoTitle ?? "",
    seoDescription: p.SeoDescription ?? "",
    seoImageUrl: p.SeoImageUrl ?? "",
  };
}

// ─── Pages ──────────────────────────────────────────────────────────────────
export async function listPages(params: { vertical?: string; locale?: string; status?: string } = {}) {
  return apiGet("/v1/cms/pages", params as Record<string, unknown>);
}

export async function getPage(slug: string, vertical = "corporate", locale = "es") {
  return apiGet(`/v1/cms/pages/${encodeURIComponent(slug)}`, { vertical, locale });
}

export async function createPage(input: Partial<CmsPage> & { slug: string; title: string }) {
  return apiPost("/v1/cms/pages", toPageBody(input));
}

export async function updatePage(id: number, input: Partial<CmsPage> & { slug: string; title: string }) {
  return apiPut(`/v1/cms/pages/${id}`, toPageBody(input));
}

export async function publishPage(id: number) {
  return apiPost(`/v1/cms/pages/${id}/publish`, {});
}

export async function deletePage(id: number) {
  return apiDelete(`/v1/cms/pages/${id}`);
}

function toPageBody(p: Partial<CmsPage> & { slug: string; title: string }) {
  return {
    slug: p.Slug ?? p.slug,
    vertical: p.Vertical ?? "corporate",
    locale: p.Locale ?? "es",
    title: p.Title ?? p.title,
    body: p.Body ?? "",
    meta: p.Meta ?? {},
    seoTitle: p.SeoTitle ?? "",
    seoDescription: p.SeoDescription ?? "",
  };
}

// ─── Markdown preview helper ────────────────────────────────────────────────
// Renderer simple (regex) suficiente para blog posts Zentto. Soporta:
// headings, bold/italic, code inline/block, links, imágenes, listas
// bullet/numeradas, blockquote, hr, tables GFM.
// Si los posts crecen en complejidad (footnotes, task lists, syntax
// highlight), migrar a `marked` (ya disponible en module-nomina).
export function markdownToHtml(md: string): string {
  if (!md) return "";
  let html = md
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  // Code blocks (antes que inline code para no cortar fences).
  html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, (_, _l, code) =>
    `<pre style="background:rgba(0,0,0,0.08);padding:12px;border-radius:8px;overflow-x:auto;font-size:0.875rem;"><code>${code}</code></pre>`,
  );
  html = html.replace(/`([^`]+)`/g, '<code style="background:rgba(0,0,0,0.08);padding:2px 6px;border-radius:4px;font-size:0.875rem;">$1</code>');

  // Tables GFM — header row + separator + body rows.
  html = html.replace(
    /^(\|.+\|)\n(\|[\s\-:|]+\|)\n((?:\|.*\|\n?)+)/gm,
    (_, header: string, _sep: string, body: string) => {
      const headerCells = header
        .trim().slice(1, -1).split("|").map((c) => c.trim());
      const bodyRows = body
        .trim().split("\n").map((row) =>
          row.trim().slice(1, -1).split("|").map((c) => c.trim()),
        );
      const th = headerCells
        .map((c) => `<th style="padding:8px 12px;border:1px solid rgba(0,0,0,0.1);text-align:left;background:rgba(0,0,0,0.04);">${c}</th>`)
        .join("");
      const tb = bodyRows
        .map((row) =>
          `<tr>${row.map((c) => `<td style="padding:8px 12px;border:1px solid rgba(0,0,0,0.1);">${c}</td>`).join("")}</tr>`,
        )
        .join("");
      return `<table style="border-collapse:collapse;margin:16px 0;width:100%;font-size:0.9rem;"><thead><tr>${th}</tr></thead><tbody>${tb}</tbody></table>`;
    },
  );

  html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width:100%;border-radius:8px;margin:12px 0;"/>');
  html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color:#6C63FF;text-decoration:underline;">$1</a>');
  html = html.replace(/^#### (.+)$/gm, '<h4 style="font-size:1rem;font-weight:700;margin:16px 0 6px;">$1</h4>');
  html = html.replace(/^### (.+)$/gm, '<h3 style="font-size:1.1rem;font-weight:700;margin:20px 0 8px;">$1</h3>');
  html = html.replace(/^## (.+)$/gm, '<h2 style="font-size:1.35rem;font-weight:700;margin:24px 0 10px;">$1</h2>');
  html = html.replace(/^# (.+)$/gm, '<h1 style="font-size:1.6rem;font-weight:700;margin:28px 0 12px;">$1</h1>');

  // Blockquote.
  html = html.replace(/^&gt; (.+)$/gm, '<blockquote style="border-left:3px solid #6C63FF;padding:4px 12px;margin:12px 0;color:rgba(0,0,0,0.7);font-style:italic;">$1</blockquote>');

  // HR.
  html = html.replace(/^---+$/gm, '<hr style="border:0;border-top:1px solid rgba(0,0,0,0.1);margin:20px 0;"/>');

  // Listas numeradas.
  html = html.replace(/^(\d+)\. (.+)$/gm, '<li data-ol="1" style="margin-left:1.5rem;list-style:decimal;">$2</li>');
  // Listas bullet.
  html = html.replace(/^- (.+)$/gm, '<li style="margin-left:1.5rem;list-style:disc;">$1</li>');
  // Wrap groups of <li>.
  html = html.replace(/(<li data-ol="1"[^>]*>.*?<\/li>\n?)+/g, (m) => `<ol style="margin:10px 0;">${m}</ol>`);
  html = html.replace(/(<li(?![^>]*data-ol)[^>]*>.*?<\/li>\n?)+/g, (m) => `<ul style="margin:10px 0;">${m}</ul>`);

  html = html.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  html = html.replace(/\*([^*]+)\*/g, "<em>$1</em>");

  html = html
    .split(/\n\n+/)
    .map((chunk) => {
      const t = chunk.trim();
      if (!t) return "";
      if (/^<(h\d|ul|ol|pre|img|div|section|article|blockquote|hr|table)/.test(t)) return t;
      return `<p style="margin:10px 0;line-height:1.7;">${t.replace(/\n/g, "<br/>")}</p>`;
    })
    .join("\n");

  return html;
}

// Slugify simple: lower, trim, whitespace/special → '-'
export function slugify(s: string): string {
  return s
    .toLowerCase()
    .trim()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 200);
}
