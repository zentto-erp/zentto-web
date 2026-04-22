/**
 * BlogIndex — Server Component. Listado paginado de posts de un vertical.
 *
 * Fetch al CMS público: GET /v1/public/cms/posts?vertical=X&companyId=Y&...
 * Si el fetch falla (CMS down), muestra mensaje genérico "Pronto publicaremos…"
 * en vez de romper la página (regla: nunca 500 por CMS caído).
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { BlogPostCard, type BlogTeaserPost } from "../components/BlogPostCard";
import { BlogBreadcrumbs } from "./BlogBreadcrumbs";
import { BlogPagination } from "./BlogPagination";
import type { LandingTokens } from "../tokens";

export interface BlogIndexProps {
  tokens: LandingTokens;
  /** URL base del API, sin trailing slash. */
  apiBaseUrl: string;
  /** Vertical para filtrar posts. */
  vertical: string;
  /** Tenant id. */
  companyId: number;
  /** Locale. Default: "es". */
  locale?: string;
  /** Página actual (1-indexed). */
  page?: number;
  /** Posts por página. Default: 12. */
  perPage?: number;
  /** Título principal. */
  title?: string;
  /** Descripción bajo el título. */
  description?: string;
  /** Base URL para construir los hrefs de paginación. Default: "/blog". */
  baseHref?: string;
  /** Base URL para los links de post individual. Default: "/blog". */
  postBaseHref?: string;
  /** Breadcrumb raíz. Default: [{label:"Home",href:"/"},{label:"Blog"}]. */
  breadcrumbs?: Array<{ label: string; href?: string }>;
}

interface ListResponse {
  ok: boolean;
  data?: BlogTeaserPost[];
  total?: number;
  error?: { code: string; message: string };
}

async function fetchList(
  apiBaseUrl: string,
  vertical: string,
  companyId: number,
  locale: string,
  page: number,
  perPage: number,
): Promise<{ posts: BlogTeaserPost[]; total: number } | undefined> {
  const base = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
  const qs = new URLSearchParams({
    vertical,
    locale,
    page: String(page),
    perPage: String(perPage),
    companyId: String(companyId),
  }).toString();
  try {
    const res = await fetch(`${base}/v1/public/cms/posts?${qs}`, {
      headers: { Accept: "application/json" },
      // @ts-expect-error Next.js extended RequestInit — no está en el type stock.
      next: {
        revalidate: 300,
        tags: [`blog:${vertical}:index`],
      },
    });
    if (!res.ok) return undefined;
    const body = (await res.json()) as ListResponse;
    if (!body.ok || !Array.isArray(body.data)) return undefined;
    return { posts: body.data, total: body.total ?? body.data.length };
  } catch {
    return undefined;
  }
}

export async function BlogIndex({
  tokens,
  apiBaseUrl,
  vertical,
  companyId,
  locale = "es",
  page = 1,
  perPage = 12,
  title,
  description,
  baseHref = "/blog",
  postBaseHref = "/blog",
  breadcrumbs,
}: BlogIndexProps) {
  const result = await fetchList(
    apiBaseUrl,
    vertical,
    companyId,
    locale,
    page,
    perPage,
  );

  const effectiveTitle = title ?? "Ideas del blog";
  const effectiveDescription =
    description ??
    "Estrategia, operación y producto — escribimos sobre el oficio real.";
  const effectiveBreadcrumbs = breadcrumbs ?? [
    { label: "Home", href: "/" },
    { label: "Blog" },
  ];

  const posts = result?.posts ?? [];
  const total = result?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / perPage));

  return (
    <Box
      component="section"
      sx={{
        bgcolor: tokens.color.bg,
        py: { xs: 8, md: 10 },
        minHeight: "60vh",
      }}
    >
      <Container
        maxWidth={false}
        sx={{
          maxWidth: tokens.container.maxWidth,
          px: {
            xs: `${tokens.container.gutterMobile}px`,
            md: `${tokens.container.gutterDesktop}px`,
          },
        }}
      >
        <BlogBreadcrumbs tokens={tokens} items={effectiveBreadcrumbs} />

        <Stack spacing={2} sx={{ mb: 5 }}>
          <Typography
            component="h1"
            sx={{
              color: tokens.color.textPrimary,
              fontSize: tokens.type.h1,
              fontWeight: 800,
              lineHeight: tokens.leading.heading,
              letterSpacing: tokens.tracking.heading,
            }}
          >
            {effectiveTitle}
          </Typography>
          <Typography
            sx={{
              color: tokens.color.textSecondary,
              fontSize: tokens.type.bodyLg,
              lineHeight: tokens.leading.body,
              maxWidth: 680,
            }}
          >
            {effectiveDescription}
          </Typography>
        </Stack>

        {!result ? (
          <EmptyState
            tokens={tokens}
            message="Estamos preparando contenido nuevo. Vuelve pronto."
          />
        ) : posts.length === 0 ? (
          <EmptyState
            tokens={tokens}
            message="Aún no tenemos artículos publicados para este tema. ¡Pronto llegarán!"
          />
        ) : (
          <>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: {
                  xs: "1fr",
                  sm: "1fr 1fr",
                  md: "repeat(3, 1fr)",
                },
                gap: `${tokens.spacing.gridGap}px`,
              }}
            >
              {posts.map((post) => (
                <BlogPostCard
                  key={post.PostId}
                  tokens={tokens}
                  post={post}
                  locale={locale}
                  blogBaseHref={postBaseHref}
                />
              ))}
            </Box>

            <BlogPagination
              tokens={tokens}
              currentPage={page}
              totalPages={totalPages}
              baseHref={baseHref}
            />
          </>
        )}
      </Container>
    </Box>
  );
}

function EmptyState({
  tokens,
  message,
}: {
  tokens: LandingTokens;
  message: string;
}) {
  return (
    <Box
      sx={{
        bgcolor: tokens.color.bgSurface,
        border: `1px dashed ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: { xs: 4, md: 6 },
        textAlign: "center",
      }}
    >
      <Typography
        sx={{
          color: tokens.color.textSecondary,
          fontSize: tokens.type.bodyLg,
          lineHeight: tokens.leading.body,
          maxWidth: 480,
          mx: "auto",
        }}
      >
        {message}
      </Typography>
    </Box>
  );
}
