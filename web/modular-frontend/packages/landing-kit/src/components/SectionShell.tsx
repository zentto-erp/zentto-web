/**
 * SectionShell — wrapper canónico de sección con padding vertical constante.
 *
 * Todas las secciones de una landing usan este envoltorio para garantizar
 * ritmo vertical homogéneo. Server Component.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";

export interface SectionShellProps {
  tokens: LandingTokens;
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  size?: "default" | "lg";
  surface?: "bg" | "bgSurface";
  divider?: "top" | "bottom" | "both" | "none";
  align?: "left" | "center";
  children: React.ReactNode;
  bleed?: boolean;
}

export function SectionShell({
  tokens,
  id,
  eyebrow,
  title,
  description,
  size = "default",
  surface = "bg",
  divider = "none",
  align = "left",
  children,
  bleed = false,
}: SectionShellProps) {
  const padding = size === "lg" ? tokens.spacing.sectionLg : tokens.spacing.section;
  const bg = surface === "bgSurface" ? tokens.color.bgSurface : tokens.color.bg;
  const showHeader = !!eyebrow || !!title || !!description;

  return (
    <Box
      component="section"
      id={id}
      sx={{
        bgcolor: bg,
        position: "relative",
        py: { xs: `${padding.xs}px`, md: `${padding.md}px` },
        borderTop:
          divider === "top" || divider === "both"
            ? `1px solid ${tokens.color.border}`
            : "none",
        borderBottom:
          divider === "bottom" || divider === "both"
            ? `1px solid ${tokens.color.border}`
            : "none",
      }}
    >
      {bleed ? (
        children
      ) : (
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
          {showHeader ? (
            <Stack
              spacing={2}
              sx={{
                textAlign: align,
                alignItems: align === "center" ? "center" : "flex-start",
                maxWidth: align === "center" ? 720 : 760,
                mx: align === "center" ? "auto" : undefined,
                mb: `${tokens.spacing.bodyToGrid}px`,
              }}
            >
              {eyebrow ? (
                <Typography
                  component="span"
                  sx={{
                    color: (tokens.color as Record<string, string>).eyebrowColor ?? tokens.color.brandLight,
                    fontSize: tokens.type.eyebrow,
                    fontWeight: 700,
                    letterSpacing: tokens.tracking.eyebrow,
                    textTransform: "uppercase",
                    lineHeight: 1,
                  }}
                >
                  {eyebrow}
                </Typography>
              ) : null}
              {title ? (
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
                  {title}
                </Typography>
              ) : null}
              {description ? (
                <Typography
                  sx={{
                    color: tokens.color.textSecondary,
                    fontSize: tokens.type.bodyLg,
                    lineHeight: tokens.leading.body,
                  }}
                >
                  {description}
                </Typography>
              ) : null}
            </Stack>
          ) : null}
          {children}
        </Container>
      )}
    </Box>
  );
}
