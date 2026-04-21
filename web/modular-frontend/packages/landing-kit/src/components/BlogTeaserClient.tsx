"use client";

/**
 * BlogTeaserClient — versión Client Component de BlogTeaser.
 *
 * Usa la misma UI (BlogPostCard) que BlogTeaser pero hace fetch en el cliente
 * con useEffect. Diseñado para páginas que son Client Components ('use client')
 * y no pueden importar el Server Component BlogTeaser.
 *
 * Para páginas Server Component, usa BlogTeaser (mejor rendimiento + ISR).
 *
 * Uso en storefront B2C (light theme):
 *   <BlogTeaserClient theme="light" vertical="hotel" blogBaseHref="/blog" />
 *   <BlogTeaserClient theme="light" vertical="medical" companyId={42} />
 */

import * as React from "react";
import { useState, useEffect, useMemo } from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import Container from "@mui/material/Container";
import type { LandingTokens, LandingVertical } from "../tokens";
import { buildLandingTokens } from "../tokens";
import { CTAButton } from "./CTAButton";
import { BlogPostCard, type BlogTeaserPost } from "./BlogPostCard";
import type { BlogTeaserProps } from "./BlogTeaser";

export interface BlogTeaserClientProps extends Omit<BlogTeaserProps, "tokens"> {
  tokens?: LandingTokens;
}

export function BlogTeaserClient({
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
}: BlogTeaserClientProps) {
  const [posts, setPosts] = useState<BlogTeaserPost[]>([]);
  const [loaded, setLoaded] = useState(false);

  const tokens = useMemo(
    () =>
      tokensProp ?? buildLandingTokens(vertical as LandingVertical, theme),
    [tokensProp, vertical, theme],
  );

  const defaultTitle =
    theme === "light" ? "Noticias y consejos" : "Ideas del ecosistema";
  const defaultCtaLabel =
    theme === "light" ? "Ver todos en el blog" : "Ver todos los posts";
  const hrefAll =
    ctaHref ??
    (theme === "light"
      ? blogBaseHref
      : `https://zentto.net/blog?producto=${vertical}`);

  useEffect(() => {
    const base = apiUrl.endsWith("/") ? apiUrl.slice(0, -1) : apiUrl;
    const qs = new URLSearchParams({
      vertical,
      locale,
      limit: String(limit),
      companyId: String(companyId),
    }).toString();

    fetch(`${base}/v1/public/cms/posts?${qs}`, {
      headers: { Accept: "application/json" },
    })
      .then((r) => r.json())
      .then((d) => {
        setPosts(d.ok && Array.isArray(d.data) ? d.data : []);
        setLoaded(true);
      })
      .catch(() => setLoaded(true));
  }, [apiUrl, vertical, locale, limit, companyId]);

  if (!loaded || posts.length === 0) return null;

  const padding = tokens.spacing.section;
  const bg = tokens.color.bg;
  const eyebrowColor = (tokens.color as Record<string, string>).eyebrowColor ?? tokens.color.brand;

  return (
    <Box
      component="section"
      id={id}
      sx={{
        bgcolor: bg,
        py: { xs: `${padding.xs}px`, md: `${padding.md}px` },
        borderTop: `1px solid ${tokens.color.border}`,
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
        <Stack
          spacing={1}
          sx={{ mb: `${tokens.spacing.bodyToGrid}px` }}
        >
          {eyebrow && (
            <Typography
              component="span"
              sx={{
                color: eyebrowColor,
                fontSize: tokens.type.eyebrow,
                fontWeight: 700,
                letterSpacing: tokens.tracking.eyebrow,
                textTransform: "uppercase",
                lineHeight: 1,
              }}
            >
              {eyebrow}
            </Typography>
          )}
          {(title ?? defaultTitle) && (
            <Typography
              component="h2"
              sx={{
                color: tokens.color.textPrimary,
                fontSize: tokens.type.h1,
                fontWeight: 800,
                lineHeight: tokens.leading.heading,
                letterSpacing: tokens.tracking.heading,
              }}
            >
              {title ?? defaultTitle}
            </Typography>
          )}
          {description && (
            <Typography
              sx={{
                color: tokens.color.textSecondary,
                fontSize: tokens.type.bodyLg,
                lineHeight: tokens.leading.body,
              }}
            >
              {description}
            </Typography>
          )}
        </Stack>

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
      </Container>
    </Box>
  );
}
