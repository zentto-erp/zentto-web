/**
 * BlogBreadcrumbs — Server Component simple.
 *
 * Renderiza Home > Blog [> Current]. Usa anchors nativos (no `next/link`
 * porque en landings el host puede ser subdomain de otra app).
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import ChevronRight from "@mui/icons-material/ChevronRight";
import type { LandingTokens } from "../tokens";

export interface BlogBreadcrumbItem {
  label: string;
  href?: string;
}

export interface BlogBreadcrumbsProps {
  tokens: LandingTokens;
  items: BlogBreadcrumbItem[];
}

export function BlogBreadcrumbs({ tokens, items }: BlogBreadcrumbsProps) {
  if (!items || items.length === 0) return null;

  return (
    <Box
      component="nav"
      aria-label="Breadcrumb"
      sx={{
        mb: 3,
      }}
    >
      <Stack
        direction="row"
        alignItems="center"
        spacing={0.75}
        sx={{
          flexWrap: "wrap",
          rowGap: 0.5,
        }}
      >
        {items.map((item, idx) => {
          const isLast = idx === items.length - 1;
          const inner = (
            <Typography
              component="span"
              sx={{
                color: isLast
                  ? tokens.color.textPrimary
                  : tokens.color.textMuted,
                fontSize: tokens.type.bodySm,
                fontWeight: isLast ? 600 : 500,
                textDecoration: "none",
                transition: `color ${tokens.motion.micro}`,
                "&:hover": !isLast && item.href
                  ? { color: tokens.color.textPrimary }
                  : undefined,
              }}
            >
              {item.label}
            </Typography>
          );
          return (
            <Stack
              key={`${item.label}-${idx}`}
              direction="row"
              alignItems="center"
              spacing={0.75}
            >
              {item.href && !isLast ? (
                <Box
                  component="a"
                  href={item.href}
                  sx={{ textDecoration: "none" }}
                >
                  {inner}
                </Box>
              ) : (
                inner
              )}
              {!isLast ? (
                <ChevronRight
                  aria-hidden
                  sx={{
                    color: tokens.color.textFaint,
                    fontSize: 16,
                  }}
                />
              ) : null}
            </Stack>
          );
        })}
      </Stack>
    </Box>
  );
}
