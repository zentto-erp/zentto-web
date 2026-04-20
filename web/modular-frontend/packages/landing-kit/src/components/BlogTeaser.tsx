/**
 * BlogTeaser — sección "Últimos del blog" para landings B2B.
 *
 * Consume el API público del CMS Zentto (ADR-CMS-001):
 *   GET /v1/public/cms/posts?vertical=<vertical>&limit=3
 *
 * Server Component async. Usa Next.js fetch con revalidate para ISR (cache 5 min).
 * Empty state si no hay posts publicados; error state silencioso (no rompe la landing).
 *
 * Uso:
 *   <BlogTeaser tokens={tokens} vertical="hotel" />
 *   <BlogTeaser tokens={tokens} vertical="medical" apiUrl="https://api.zentto.net" limit={3} />
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import { SectionShell } from "./SectionShell";
import { CTAButton } from "./CTAButton";

export interface BlogTeaserPost {
  PostId: number;
  Slug: string;
  Vertical: string;
  Category: string;
  Title: string;
  Excerpt: string;
  CoverUrl: string;
  AuthorName: string;
  ReadingMin: number;
  PublishedAt: string | null;
}

export interface BlogTeaserProps {
  tokens: LandingTokens;
  /** Vertical para filtrar posts. Default: 'corporate' */
  vertical?: string;
  /** URL base del API. Default: https://api.zentto.net */
  apiUrl?: string;
  /** Cantidad de posts a mostrar. Default: 3 */
  limit?: number;
  /** Idioma. Default: 'es' */
  locale?: string;
  /** URL del blog completo (CTA final). Default: https://zentto.net/blog?producto={vertical} */
  ctaHref?: string;
  /** Eyebrow de la sección. Default: 'Blog' */
  eyebrow?: string;
  /** Título de la sección. Default: 'Ideas del ecosistema' */
  title?: string;
  /** Descripción opcional bajo el título. */
  description?: string;
  /** ID del elemento section para anclas. Default: 'blog' */
  id?: string;
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
): Promise<BlogTeaserPost[]> {
  const base = apiUrl.replace(/\/$/, "");
  const qs = new URLSearchParams({ vertical, locale, limit: String(limit) }).toString();
  try {
    // Next.js 14+ fetch extiende RequestInit con `next.revalidate`. En entornos
    // que no sean Next (SSR genérico, Node raw), el campo se ignora silencioso.
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

function formatDate(iso: string | null, locale = "es"): string {
  if (!iso) return "";
  try {
    return new Date(iso).toLocaleDateString(locale, {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch {
    return "";
  }
}

export async function BlogTeaser({
  tokens,
  vertical = "corporate",
  apiUrl = "https://api.zentto.net",
  limit = 3,
  locale = "es",
  ctaHref,
  eyebrow = "Blog",
  title = "Ideas del ecosistema",
  description,
  id = "blog",
}: BlogTeaserProps) {
  const posts = await fetchPosts(apiUrl, vertical, locale, limit);
  const hrefAll = ctaHref ?? `https://zentto.net/blog?producto=${vertical}`;

  // Empty state: no renderiza la sección. Mantiene la landing limpia hasta que
  // haya contenido real. Volver a render cuando se publique el primer post
  // requiere rebuild de la app (ISR 5 min mitiga).
  if (posts.length === 0) {
    return null;
  }

  return (
    <SectionShell
      tokens={tokens}
      id={id}
      eyebrow={eyebrow}
      title={title}
      description={description}
      align="left"
    >
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: {
            xs: "1fr",
            sm: "1fr 1fr",
            md: "repeat(3, 1fr)",
          },
          gap: `${tokens.spacing.gridGap}px`,
          mb: 5,
        }}
      >
        {posts.map((post) => (
          <PostCard key={post.PostId} tokens={tokens} post={post} locale={locale} />
        ))}
      </Box>

      <Stack direction="row" justifyContent={{ xs: "center", md: "flex-start" }}>
        <CTAButton tokens={tokens} variant="ghost" href={hrefAll} showArrow>
          Ver todos los posts
        </CTAButton>
      </Stack>
    </SectionShell>
  );
}

interface PostCardProps {
  tokens: LandingTokens;
  post: BlogTeaserPost;
  locale: string;
}

function PostCard({ tokens, post, locale }: PostCardProps) {
  const href = `https://zentto.net/blog/${post.Slug}`;
  const categoryLabel = post.Category
    ? post.Category.charAt(0).toUpperCase() + post.Category.slice(1)
    : "";

  return (
    <Box
      component="a"
      href={href}
      sx={{
        display: "flex",
        flexDirection: "column",
        textDecoration: "none",
        color: "inherit",
        p: 3,
        borderRadius: `${tokens.radius.lg}px`,
        border: `1px solid ${tokens.color.border}`,
        background: tokens.color.bgSurface,
        transition: tokens.motion.ui,
        height: "100%",
        "&:hover": {
          borderColor: tokens.color.borderStrong,
          transform: "translateY(-2px)",
          boxShadow: tokens.shadow.cardHover,
        },
        "&:focus-visible": {
          outline: `2px solid ${tokens.color.brand}`,
          outlineOffset: 2,
        },
      }}
    >
      {post.CoverUrl && (
        <Box
          component="img"
          src={post.CoverUrl}
          alt=""
          loading="lazy"
          sx={{
            width: "100%",
            aspectRatio: "16/9",
            objectFit: "cover",
            borderRadius: `${tokens.radius.md}px`,
            mb: 2.5,
            display: "block",
          }}
        />
      )}

      {categoryLabel && (
        <Typography
          sx={{
            fontSize: "0.75rem",
            fontWeight: 600,
            color: tokens.color.brand,
            textTransform: "uppercase",
            letterSpacing: "0.06em",
            mb: 1,
          }}
        >
          {categoryLabel}
        </Typography>
      )}

      <Typography
        component="h3"
        sx={{
          fontSize: "1.125rem",
          fontWeight: 700,
          color: tokens.color.textPrimary,
          lineHeight: 1.3,
          mb: 1.5,
          display: "-webkit-box",
          WebkitLineClamp: 2,
          WebkitBoxOrient: "vertical",
          overflow: "hidden",
        }}
      >
        {post.Title}
      </Typography>

      {post.Excerpt && (
        <Typography
          sx={{
            fontSize: "0.9375rem",
            color: tokens.color.textSecondary,
            lineHeight: 1.6,
            mb: 2.5,
            display: "-webkit-box",
            WebkitLineClamp: 3,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            flex: 1,
          }}
        >
          {post.Excerpt}
        </Typography>
      )}

      <Stack
        direction="row"
        justifyContent="space-between"
        alignItems="center"
        sx={{
          mt: "auto",
          pt: 2,
          borderTop: `1px solid ${tokens.color.border}`,
          fontSize: "0.75rem",
          color: tokens.color.textMuted,
        }}
      >
        <Typography sx={{ fontSize: "inherit", color: "inherit" }}>
          {formatDate(post.PublishedAt, locale)}
        </Typography>
        <Typography sx={{ fontSize: "inherit", color: "inherit" }}>
          {post.ReadingMin} min
        </Typography>
      </Stack>
    </Box>
  );
}
