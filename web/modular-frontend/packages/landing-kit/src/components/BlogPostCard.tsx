import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";

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

export function formatBlogDate(iso: string | null, locale = "es"): string {
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

export interface BlogPostCardProps {
  tokens: LandingTokens;
  post: BlogTeaserPost;
  locale?: string;
  /** Base URL for post links. Default: "https://zentto.net/blog" */
  blogBaseHref?: string;
}

export function BlogPostCard({
  tokens,
  post,
  locale = "es",
  blogBaseHref = "https://zentto.net/blog",
}: BlogPostCardProps) {
  const href = `${blogBaseHref.replace(/\/$/, "")}/${post.Slug}`;
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
          borderColor: tokens.color.brand,
          transform: "translateY(-2px)",
          boxShadow: tokens.shadow.cardHover,
        },
        "&:focus-visible": {
          outline: `2px solid ${tokens.color.brand}`,
          outlineOffset: 2,
        },
      }}
    >
      {post.CoverUrl ? (
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
      ) : (
        <Box
          sx={{
            width: "100%",
            aspectRatio: "16/9",
            borderRadius: `${tokens.radius.md}px`,
            mb: 2.5,
            bgcolor: tokens.color.bgElevated,
            borderLeft: `4px solid ${tokens.color.brand}`,
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
          {formatBlogDate(post.PublishedAt, locale)}
        </Typography>
        <Typography sx={{ fontSize: "inherit", color: "inherit" }}>
          {post.ReadingMin} min
        </Typography>
      </Stack>
    </Box>
  );
}
