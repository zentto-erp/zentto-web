/**
 * BlogTeaser — sección blog para landings. Server Component async con ISR 5 min.
 *
 * Para páginas Client Component, usa BlogTeaserClient.
 *
 * Uso:
 *   <BlogTeaser vertical="hotel" theme="dark" />
 *   <BlogTeaser vertical="medical" theme="light" companyId={42} blogBaseHref="/blog" />
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import type { LandingTokens, LandingVertical } from "../tokens";
import { buildLandingTokens } from "../tokens";
import { SectionShell } from "./SectionShell";
import { CTAButton } from "./CTAButton";
import { BlogPostCard, type BlogTeaserPost } from "./BlogPostCard";

export type { BlogTeaserPost } from "./BlogPostCard";

export interface BlogTeaserProps {
  /** Tokens de la vertical. Si se omite, se construyen desde vertical + theme. */
  tokens?: LandingTokens;
  /** Vertical para filtrar posts. Default: 'corporate' */
  vertical?: string;
  /** "light" para storefront B2C, "dark" para landing B2B. Default: "dark" */
  theme?: "light" | "dark";
  /** CompanyId del tenant. Default: 1 (Zentto corporate). */
  companyId?: number;
  /** URL base del API. Default: https://api.zentto.net */
  apiUrl?: string;
  /** Cantidad de posts a mostrar. Default: 3 */
  limit?: number;
  /** Idioma. Default: 'es' */
  locale?: string;
  /** URL del blog completo (CTA). Por defecto varía según theme. */
  ctaHref?: string;
  /** Base URL para links internos de posts. Default: https://zentto.net/blog */
  blogBaseHref?: string;
  /** Eyebrow de la sección. Default: 'Blog' */
  eyebrow?: string;
  /** Título de la sección. Por defecto varía según theme. */
  title?: string;
  /** Descripción opcional bajo el título. */
  description?: string;
  /** ID del elemento section para anclas. Default: 'blog' */
  id?: string;
  /** Texto del CTA. Por defecto varía según theme. */
  ctaLabel?: string;
}

interface ListResponse {
  ok: boolean;
  data: BlogTeaserPost[];
  total: number;
}

async function fetchPosts(
  apiUrl: string,
  vertical: string,
  locale: string,
  limit: number,
  companyId: number,
): Promise<BlogTeaserPost[]> {
  const base = apiUrl.endsWith("/") ? apiUrl.slice(0, -1) : apiUrl;
  const qs = new URLSearchParams({
    vertical,
    locale,
    limit: String(limit),
    companyId: String(companyId),
  }).toString();
  try {
    const res = await fetch(`${base}/v1/public/cms/posts?${qs}`, {
      headers: { Accept: "application/json" },
      // @ts-expect-error Next.js extended RequestInit
      next: { revalidate: 300 },
    });
    if (!res.ok) return [];
    const body = (await res.json()) as ListResponse;
    return body.ok && Array.isArray(body.data) ? body.data : [];
  } catch {
    return [];
  }
}

export async function BlogTeaser({
  tokens: tokensProp,
  vertical = "corporate",
  theme = "dark",
  companyId = 1,
  apiUrl = "https://api.zentto.net",
  limit = 3,
  locale = "es",
  ctaHref,
  blogBaseHref = "https://zentto.net/blog",
  eyebrow = "Blog",
  title,
  description,
  id = "blog",
  ctaLabel,
}: BlogTeaserProps) {
  const posts = await fetchPosts(apiUrl, vertical, locale, limit, companyId);
  if (posts.length === 0) return null;

  const tokens =
    tokensProp ?? buildLandingTokens(vertical as LandingVertical, theme);
  const defaultTitle =
    theme === "light" ? "Noticias y consejos" : "Ideas del ecosistema";
  const defaultCtaLabel =
    theme === "light" ? "Ver todos en el blog" : "Ver todos los posts";
  const hrefAll =
    ctaHref ??
    (theme === "light"
      ? blogBaseHref
      : `https://zentto.net/blog?producto=${vertical}`);

  return (
    <SectionShell
      tokens={tokens}
      id={id}
      eyebrow={eyebrow}
      title={title ?? defaultTitle}
      description={description}
      align="left"
    >
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "repeat(3, 1fr)" },
          gap: `${tokens.spacing.gridGap}px`,
          mb: 5,
        }}
      >
        {posts.map((post) => (
          <BlogPostCard
            key={post.PostId}
            tokens={tokens}
            post={post}
            locale={locale}
            blogBaseHref={blogBaseHref}
          />
        ))}
      </Box>

      <Stack direction="row" justifyContent={{ xs: "center", md: "flex-start" }}>
        <CTAButton tokens={tokens} variant="ghost" href={hrefAll} showArrow>
          {ctaLabel ?? defaultCtaLabel}
        </CTAButton>
      </Stack>
    </SectionShell>
  );
}
