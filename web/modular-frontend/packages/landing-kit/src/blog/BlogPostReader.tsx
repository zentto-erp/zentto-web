/**
 * BlogPostReader — Server Component. Muestra un post del blog por slug.
 *
 * Fetch: GET /v1/public/cms/posts/:slug?vertical=X&companyId=Y&locale=es
 *
 * Renderiza:
 *  - breadcrumbs (Home > Blog > Título)
 *  - cover image (si hay)
 *  - título + meta (autor, fecha, read time)
 *  - body markdown → HTML con react-markdown + remark-gfm + rehype-sanitize
 *  - related posts (3 del mismo vertical)
 *  - CTA newsletter al footer
 *
 * Si el post no existe, delega al caller vía `onNotFound()` (default: throw
 * que debe capturar el consumer con notFound() de Next). Si el post existe
 * pero falla related, se omite silenciosamente (graceful degradation).
 *
 * Markdown deps son opcionales (peerDep). Si no están instaladas, cae a
 * texto plano — consumer decide si quiere enriquecer.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { BlogBreadcrumbs } from "./BlogBreadcrumbs";
import { BlogPostCard, type BlogTeaserPost } from "../components/BlogPostCard";
import type { LandingTokens } from "../tokens";

export interface BlogPostReaderProps {
  tokens: LandingTokens;
  apiBaseUrl: string;
  vertical: string;
  companyId: number;
  slug: string;
  locale?: string;
  /** Base URL para breadcrumb Home. Default: "/". */
  homeHref?: string;
  /** Base URL para index del blog. Default: "/blog". */
  blogHref?: string;
  /** Base URL para posts relacionados. Default: blogHref. */
  postBaseHref?: string;
  /** Handler llamado cuando el post no existe. Default: throw para que el consumer use notFound(). */
  onNotFound?: () => never;
}

export interface BlogPostFull extends BlogTeaserPost {
  Body?: string;
  Content?: string;
  Markdown?: string;
  Html?: string;
  Tags?: string[] | string;
  CoverAlt?: string;
  AuthorAvatar?: string;
}

interface PostResponse {
  ok: boolean;
  data?: BlogPostFull;
  error?: { code: string; message: string };
}

interface RelatedResponse {
  ok: boolean;
  data?: BlogTeaserPost[];
}

async function fetchPost(
  apiBaseUrl: string,
  slug: string,
  vertical: string,
  companyId: number,
  locale: string,
): Promise<BlogPostFull | undefined> {
  const base = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
  const qs = new URLSearchParams({
    vertical,
    locale,
    companyId: String(companyId),
  }).toString();
  try {
    const res = await fetch(
      `${base}/v1/public/cms/posts/${encodeURIComponent(slug)}?${qs}`,
      {
        headers: { Accept: "application/json" },
        // @ts-expect-error Next.js extended RequestInit — no está en el type stock.
        next: {
          revalidate: 300,
          tags: [`blog:${vertical}:post:${slug}`],
        },
      },
    );
    if (res.status === 404) return undefined;
    if (!res.ok) return undefined;
    const body = (await res.json()) as PostResponse;
    if (!body.ok || !body.data) return undefined;
    return body.data;
  } catch {
    return undefined;
  }
}

async function fetchRelated(
  apiBaseUrl: string,
  vertical: string,
  companyId: number,
  locale: string,
  excludeSlug: string,
  limit = 3,
): Promise<BlogTeaserPost[]> {
  const base = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
  const qs = new URLSearchParams({
    vertical,
    locale,
    limit: String(limit + 1),
    companyId: String(companyId),
  }).toString();
  try {
    const res = await fetch(`${base}/v1/public/cms/posts?${qs}`, {
      headers: { Accept: "application/json" },
      // @ts-expect-error Next.js extended RequestInit.
      next: { revalidate: 300 },
    });
    if (!res.ok) return [];
    const body = (await res.json()) as RelatedResponse;
    if (!body.ok || !Array.isArray(body.data)) return [];
    return body.data
      .filter((p) => p.Slug !== excludeSlug)
      .slice(0, limit);
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

function parseTags(tags: BlogPostFull["Tags"]): string[] {
  if (!tags) return [];
  if (Array.isArray(tags)) return tags.filter((t) => typeof t === "string");
  if (typeof tags === "string") {
    return tags.split(",").map((t) => t.trim()).filter(Boolean);
  }
  return [];
}

/**
 * Render del body markdown. Usa `react-markdown` si está instalado
 * (peerDependency opcional). Fallback a render plain-text con saltos de línea.
 */
async function renderMarkdownBody(
  body: string,
): Promise<React.ReactNode> {
  try {
    // Dynamic import opcional para no forzar la dep en consumers que no usan blog.
    // @ts-ignore — peerDependency opcional, puede no estar instalada.
    const reactMarkdownMod: any = await import("react-markdown");
    // @ts-ignore — peerDependency opcional.
    const gfmMod: any = await import("remark-gfm");
    // @ts-ignore — peerDependency opcional.
    const sanitizeMod: any = await import("rehype-sanitize");
    const ReactMarkdown = reactMarkdownMod.default ?? reactMarkdownMod;
    const gfm = gfmMod.default ?? gfmMod;
    const sanitize = sanitizeMod.default ?? sanitizeMod;
    return (
      <ReactMarkdown
        remarkPlugins={[gfm]}
        rehypePlugins={[sanitize]}
      >
        {body}
      </ReactMarkdown>
    );
  } catch {
    // Fallback: render plano con <br />
    return (
      <>
        {body.split("\n").map((line, idx) => (
          <React.Fragment key={idx}>
            {line}
            <br />
          </React.Fragment>
        ))}
      </>
    );
  }
}

export async function BlogPostReader({
  tokens,
  apiBaseUrl,
  vertical,
  companyId,
  slug,
  locale = "es",
  homeHref = "/",
  blogHref = "/blog",
  postBaseHref,
  onNotFound,
}: BlogPostReaderProps) {
  const post = await fetchPost(apiBaseUrl, slug, vertical, companyId, locale);

  if (!post) {
    if (onNotFound) onNotFound();
    // Fallback defensivo si el consumer no pasó onNotFound — el caller DEBE
    // usar notFound() idealmente, pero no queremos crashear el render entero.
    return (
      <Box
        component="section"
        sx={{ bgcolor: tokens.color.bg, py: { xs: 8, md: 10 } }}
      >
        <Container
          maxWidth={false}
          sx={{
            maxWidth: 720,
            px: {
              xs: `${tokens.container.gutterMobile}px`,
              md: `${tokens.container.gutterDesktop}px`,
            },
            textAlign: "center",
          }}
        >
          <Typography
            component="h1"
            sx={{
              color: tokens.color.textPrimary,
              fontSize: tokens.type.h1,
              fontWeight: 800,
              mb: 2,
            }}
          >
            Artículo no encontrado
          </Typography>
          <Typography
            sx={{
              color: tokens.color.textSecondary,
              fontSize: tokens.type.bodyLg,
              lineHeight: tokens.leading.body,
            }}
          >
            Este artículo ya no está disponible o nunca fue publicado.
          </Typography>
        </Container>
      </Box>
    );
  }

  const related = await fetchRelated(
    apiBaseUrl,
    vertical,
    companyId,
    locale,
    slug,
    3,
  );

  const body = post.Body ?? post.Content ?? post.Markdown ?? post.Html ?? "";
  const tags = parseTags(post.Tags);
  const publishedLabel = formatDate(post.PublishedAt, locale);
  const effectivePostBaseHref = postBaseHref ?? blogHref;

  const bodyNode = body ? await renderMarkdownBody(body) : null;

  return (
    <Box
      component="article"
      sx={{ bgcolor: tokens.color.bg, py: { xs: 6, md: 10 } }}
    >
      <Container
        maxWidth={false}
        sx={{
          maxWidth: 820,
          px: {
            xs: `${tokens.container.gutterMobile}px`,
            md: `${tokens.container.gutterDesktop}px`,
          },
        }}
      >
        <BlogBreadcrumbs
          tokens={tokens}
          items={[
            { label: "Home", href: homeHref },
            { label: "Blog", href: blogHref },
            { label: post.Title },
          ]}
        />

        {post.CoverUrl ? (
          <Box
            component="img"
            src={post.CoverUrl}
            alt={post.CoverAlt ?? post.Title}
            loading="eager"
            sx={{
              width: "100%",
              aspectRatio: "16/9",
              objectFit: "cover",
              borderRadius: `${tokens.radius.lg}px`,
              mb: 4,
              border: `1px solid ${tokens.color.border}`,
            }}
          />
        ) : null}

        {post.Category ? (
          <Typography
            sx={{
              color: tokens.color.brandLight,
              fontSize: tokens.type.eyebrow,
              fontWeight: 700,
              letterSpacing: tokens.tracking.eyebrow,
              textTransform: "uppercase",
              mb: 2,
            }}
          >
            {post.Category}
          </Typography>
        ) : null}

        <Typography
          component="h1"
          sx={{
            color: tokens.color.textPrimary,
            fontSize: tokens.type.display,
            fontWeight: 800,
            lineHeight: tokens.leading.display,
            letterSpacing: tokens.tracking.display,
            mb: 3,
          }}
        >
          {post.Title}
        </Typography>

        <Stack
          direction="row"
          spacing={2}
          alignItems="center"
          useFlexGap
          flexWrap="wrap"
          sx={{
            mb: 5,
            pb: 3,
            borderBottom: `1px solid ${tokens.color.border}`,
          }}
        >
          {post.AuthorName ? (
            <Typography
              sx={{
                color: tokens.color.textSecondary,
                fontSize: tokens.type.body,
                fontWeight: 600,
              }}
            >
              {post.AuthorName}
            </Typography>
          ) : null}
          {publishedLabel ? (
            <>
              <Box
                sx={{
                  width: 4,
                  height: 4,
                  borderRadius: "50%",
                  bgcolor: tokens.color.textFaint,
                }}
                aria-hidden
              />
              <Typography
                component="time"
                dateTime={post.PublishedAt ?? undefined}
                sx={{
                  color: tokens.color.textMuted,
                  fontSize: tokens.type.body,
                }}
              >
                {publishedLabel}
              </Typography>
            </>
          ) : null}
          {post.ReadingMin ? (
            <>
              <Box
                sx={{
                  width: 4,
                  height: 4,
                  borderRadius: "50%",
                  bgcolor: tokens.color.textFaint,
                }}
                aria-hidden
              />
              <Typography
                sx={{
                  color: tokens.color.textMuted,
                  fontSize: tokens.type.body,
                }}
              >
                {post.ReadingMin} min de lectura
              </Typography>
            </>
          ) : null}
          {tags.length > 0 ? (
            <>
              <Box
                sx={{
                  width: 4,
                  height: 4,
                  borderRadius: "50%",
                  bgcolor: tokens.color.textFaint,
                }}
                aria-hidden
              />
              <Stack direction="row" spacing={0.75} flexWrap="wrap" useFlexGap>
                {tags.map((t) => (
                  <Box
                    key={t}
                    component="span"
                    sx={{
                      color: tokens.color.textSecondary,
                      fontSize: tokens.type.bodySm,
                      bgcolor: tokens.color.bgSurface,
                      border: `1px solid ${tokens.color.border}`,
                      borderRadius: `${tokens.radius.sm}px`,
                      px: 1.25,
                      py: 0.375,
                    }}
                  >
                    {t}
                  </Box>
                ))}
              </Stack>
            </>
          ) : null}
        </Stack>

        <Box
          sx={{
            color: tokens.color.textSecondary,
            fontSize: tokens.type.bodyLg,
            lineHeight: tokens.leading.body,
            "& h2": {
              color: tokens.color.textPrimary,
              fontSize: tokens.type.h2,
              fontWeight: 700,
              mt: 5,
              mb: 2,
              lineHeight: tokens.leading.heading,
            },
            "& h3": {
              color: tokens.color.textPrimary,
              fontSize: tokens.type.h3,
              fontWeight: 700,
              mt: 4,
              mb: 1.5,
            },
            "& p": { mb: 2.5 },
            "& a": {
              color: tokens.color.brandLight,
              textDecoration: "underline",
              textUnderlineOffset: "3px",
              "&:hover": { color: tokens.color.accent },
            },
            "& ul, & ol": { mb: 2.5, pl: 3 },
            "& li": { mb: 1 },
            "& code": {
              bgcolor: tokens.color.bgSurface,
              color: tokens.color.textPrimary,
              px: 0.75,
              py: 0.25,
              borderRadius: `${tokens.radius.sm}px`,
              fontSize: "0.875em",
              fontFamily: "ui-monospace, monospace",
            },
            "& pre": {
              bgcolor: tokens.color.bgSurface,
              border: `1px solid ${tokens.color.border}`,
              borderRadius: `${tokens.radius.md}px`,
              p: 2.5,
              overflow: "auto",
              fontSize: tokens.type.bodySm,
              mb: 2.5,
            },
            "& pre code": {
              bgcolor: "transparent",
              p: 0,
            },
            "& blockquote": {
              borderLeft: `3px solid ${tokens.color.brand}`,
              pl: 2.5,
              ml: 0,
              my: 3,
              color: tokens.color.textPrimary,
              fontStyle: "italic",
            },
            "& img": {
              maxWidth: "100%",
              borderRadius: `${tokens.radius.md}px`,
              my: 2.5,
            },
            "& hr": {
              border: 0,
              borderTop: `1px solid ${tokens.color.border}`,
              my: 4,
            },
            "& table": {
              width: "100%",
              borderCollapse: "collapse",
              mb: 3,
              fontSize: tokens.type.body,
            },
            "& th, & td": {
              border: `1px solid ${tokens.color.border}`,
              padding: "8px 12px",
              textAlign: "left",
            },
            "& th": {
              bgcolor: tokens.color.bgSurface,
              color: tokens.color.textPrimary,
              fontWeight: 700,
            },
          }}
        >
          {bodyNode ?? (
            <Typography sx={{ color: tokens.color.textMuted, fontStyle: "italic" }}>
              (Este artículo aún no tiene contenido.)
            </Typography>
          )}
        </Box>

        {/* CTA newsletter */}
        <Box
          sx={{
            mt: 6,
            p: { xs: 3, md: 4 },
            borderRadius: `${tokens.radius.lg}px`,
            bgcolor: tokens.color.bgSurface,
            border: `1px solid ${tokens.color.border}`,
            textAlign: "center",
          }}
        >
          <Typography
            sx={{
              color: tokens.color.textPrimary,
              fontSize: tokens.type.h3,
              fontWeight: 700,
              mb: 1,
            }}
          >
            ¿Te gustó este artículo?
          </Typography>
          <Typography
            sx={{
              color: tokens.color.textSecondary,
              fontSize: tokens.type.body,
              lineHeight: tokens.leading.body,
              mb: 2.5,
              maxWidth: 480,
              mx: "auto",
            }}
          >
            Recibe nuestros próximos artículos, guías y casos de estudio
            directamente en tu bandeja de entrada.
          </Typography>
          <Box
            component="a"
            href="mailto:hola@zentto.net?subject=Suscripci%C3%B3n%20newsletter"
            sx={{
              display: "inline-flex",
              alignItems: "center",
              gap: 0.75,
              color: tokens.color.brandLight,
              fontWeight: 600,
              fontSize: tokens.type.body,
              textDecoration: "none",
              "&:hover": { textDecoration: "underline" },
            }}
          >
            Suscribirme →
          </Box>
        </Box>

        {related.length > 0 ? (
          <Box sx={{ mt: 8 }}>
            <Typography
              component="h2"
              sx={{
                color: tokens.color.textPrimary,
                fontSize: tokens.type.h2,
                fontWeight: 800,
                letterSpacing: tokens.tracking.heading,
                mb: 3,
              }}
            >
              Seguir leyendo
            </Typography>
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: {
                  xs: "1fr",
                  md: `repeat(${related.length}, 1fr)`,
                },
                gap: `${tokens.spacing.gridGap}px`,
              }}
            >
              {related.map((p) => (
                <BlogPostCard
                  key={p.PostId}
                  tokens={tokens}
                  post={p}
                  locale={locale}
                  blogBaseHref={effectivePostBaseHref}
                />
              ))}
            </Box>
          </Box>
        ) : null}
      </Container>
    </Box>
  );
}
