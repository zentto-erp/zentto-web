/**
 * HeroAdapter — Server Component.
 *
 * Mapea `HeroSectionConfig` de studio-core + `extensions.__landingKit` a la
 * estética de `<Hero>` del hotel (pill eyebrow con dot, headline con gradient,
 * trust badges inline, mockup custom via `registry`).
 *
 * Decisión: renderizamos HTML propio en vez de consumir un componente `Hero`
 * del paquete — la mayoría de landing-kit no exporta un Hero genérico (cada
 * vertical tenía su Hero hardcoded). Este adapter es el nuevo Hero canónico.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import { CTAButton } from "../../components/CTAButton";
import { resolveIcon } from "../icon-registry";
import type { SectionAdapterProps, LandingKitHeroExtensions } from "../types";
import type { LandingTokens } from "../../tokens";

type HeroCta = { label: string; href: string; external?: boolean };

function pickCtaColor(
  tokens: LandingTokens,
  token: LandingKitHeroExtensions["eyebrow"] extends infer T
    ? T extends { dotColorToken: infer C }
      ? C
      : string
    : string,
): string {
  switch (token) {
    case "warning":
      return tokens.color.warning;
    case "brand":
      return tokens.color.brand;
    case "accent":
      return tokens.color.accent;
    case "danger":
      return tokens.color.danger;
    case "success":
    default:
      return tokens.color.success;
  }
}

export function HeroAdapter({
  section,
  tokens,
  registry,
}: SectionAdapterProps) {
  const cfg = (section.heroConfig ?? {}) as {
    headline?: string;
    subheadline?: string;
    description?: string;
    image?: string;
    video?: string;
    primaryCta?: HeroCta;
    secondaryCta?: HeroCta;
    ctaPrimary?: HeroCta;
    ctaSecondary?: HeroCta;
    alignment?: "left" | "center" | "right";
    extensions?: { __landingKit?: LandingKitHeroExtensions };
  };

  const ext = cfg.extensions?.__landingKit ?? {};
  const primaryCta = cfg.ctaPrimary ?? cfg.primaryCta;
  const secondaryCta = cfg.ctaSecondary ?? cfg.secondaryCta;

  const MockupComponent =
    ext.mockupComponentId && registry[ext.mockupComponentId]
      ? registry[ext.mockupComponentId]
      : null;

  const hasImage = !MockupComponent && (cfg.image || cfg.video);
  const alignment = cfg.alignment ?? "left";

  return (
    <Box
      component="section"
      id={section.anchor ?? "hero"}
      sx={{
        position: "relative",
        overflow: "hidden",
        background: tokens.color.heroGradient,
        pt: {
          xs: `${tokens.spacing.sectionLg.xs}px`,
          md: `${tokens.spacing.sectionLg.md}px`,
        },
        pb: {
          xs: `${tokens.spacing.section.xs}px`,
          md: `${tokens.spacing.sectionLg.md}px`,
        },
      }}
    >
      {/* Dotgrid background decorativo */}
      <Box
        aria-hidden
        sx={{
          position: "absolute",
          inset: 0,
          backgroundImage:
            "radial-gradient(circle at 1px 1px, rgba(255,255,255,0.05) 1px, transparent 0)",
          backgroundSize: "32px 32px",
          opacity: 0.4,
          maskImage: "radial-gradient(circle at center, #000 0%, transparent 80%)",
          WebkitMaskImage:
            "radial-gradient(circle at center, #000 0%, transparent 80%)",
          pointerEvents: "none",
        }}
      />

      <Container
        maxWidth={false}
        sx={{
          maxWidth: tokens.container.maxWidth,
          px: {
            xs: `${tokens.container.gutterMobile}px`,
            md: `${tokens.container.gutterDesktop}px`,
          },
          position: "relative",
        }}
      >
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: MockupComponent || hasImage
              ? { xs: "1fr", lg: "minmax(0, 7fr) minmax(0, 5fr)" }
              : "1fr",
            gap: { xs: 5, lg: 7 },
            alignItems: "center",
          }}
        >
          <Stack
            spacing={3.5}
            sx={{
              maxWidth: { xs: "100%", lg: 600 },
              textAlign: alignment,
              alignItems: alignment === "center" ? "center" : "flex-start",
            }}
          >
            {ext.eyebrow ? (
              <Box
                component="span"
                sx={{
                  alignSelf: alignment === "center" ? "center" : "flex-start",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: 1,
                  bgcolor: tokens.color.brandSoft,
                  color: tokens.color.brandLight,
                  px: 1.5,
                  py: 0.625,
                  borderRadius: `${tokens.radius.pill}px`,
                  fontSize: tokens.type.eyebrow,
                  fontWeight: 700,
                  letterSpacing: tokens.tracking.eyebrow,
                  textTransform: "uppercase",
                  border: "1px solid rgba(103,232,249,0.28)",
                }}
              >
                {ext.eyebrow.dot !== false ? (
                  <Box
                    aria-hidden
                    sx={{
                      width: 6,
                      height: 6,
                      borderRadius: "50%",
                      bgcolor: pickCtaColor(
                        tokens,
                        ext.eyebrow.dotColorToken ?? "success",
                      ),
                      boxShadow: "0 0 0 3px rgba(16,185,129,0.18)",
                    }}
                  />
                ) : null}
                {ext.eyebrow.label}
              </Box>
            ) : null}

            <Typography
              component="h1"
              sx={{
                color: tokens.color.textPrimary,
                fontSize: tokens.type.display,
                fontWeight: 800,
                lineHeight: tokens.leading.display,
                letterSpacing: tokens.tracking.display,
              }}
            >
              {cfg.headline ? cfg.headline + " " : null}
              {cfg.subheadline ? (
                ext.headlineAccentGradient ? (
                  <Box
                    component="span"
                    sx={{
                      background: `linear-gradient(135deg, ${tokens.color.brandLight} 0%, ${tokens.color.accentLight} 100%)`,
                      WebkitBackgroundClip: "text",
                      WebkitTextFillColor: "transparent",
                      backgroundClip: "text",
                    }}
                  >
                    {cfg.subheadline}
                  </Box>
                ) : (
                  <Box component="span">{cfg.subheadline}</Box>
                )
              ) : null}
            </Typography>

            {cfg.description ? (
              <Typography
                sx={{
                  color: tokens.color.textSecondary,
                  fontSize: tokens.type.bodyLg,
                  lineHeight: tokens.leading.body,
                  maxWidth: 540,
                }}
              >
                {cfg.description}
              </Typography>
            ) : null}

            {primaryCta || secondaryCta ? (
              <Stack direction={{ xs: "column", sm: "row" }} spacing={1.5}>
                {primaryCta ? (
                  <CTAButton
                    tokens={tokens}
                    href={primaryCta.href}
                    external={primaryCta.external}
                    variant="primary"
                    size="lg"
                  >
                    {primaryCta.label}
                  </CTAButton>
                ) : null}
                {secondaryCta ? (
                  <CTAButton
                    tokens={tokens}
                    href={secondaryCta.href}
                    external={secondaryCta.external}
                    variant="secondary"
                    size="lg"
                  >
                    {secondaryCta.label}
                  </CTAButton>
                ) : null}
              </Stack>
            ) : null}

            {ext.trustBadges && ext.trustBadges.length > 0 ? (
              <Stack
                direction="row"
                flexWrap="wrap"
                useFlexGap
                spacing={2.5}
                sx={{ pt: 1, rowGap: 1 }}
              >
                {ext.trustBadges.map((b) => (
                  <Stack
                    key={b.label}
                    direction="row"
                    alignItems="center"
                    spacing={0.875}
                  >
                    <Box sx={{ color: tokens.color.success, display: "flex" }}>
                      {resolveIcon(b.iconId, 16)}
                    </Box>
                    <Typography
                      sx={{
                        color: tokens.color.textMuted,
                        fontSize: tokens.type.bodySm,
                        fontWeight: 500,
                      }}
                    >
                      {b.label}
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            ) : null}
          </Stack>

          {MockupComponent ? (
            <Box sx={{ position: "relative" }}>
              <MockupComponent tokens={tokens} />
            </Box>
          ) : hasImage ? (
            <Box sx={{ position: "relative" }}>
              {cfg.video ? (
                <Box
                  component="video"
                  src={cfg.video}
                  autoPlay
                  muted
                  loop
                  playsInline
                  sx={{
                    width: "100%",
                    borderRadius: `${tokens.radius.xl}px`,
                    border: `1px solid ${tokens.color.borderStrong}`,
                    boxShadow:
                      "0 30px 80px rgba(5,3,30,0.6), 0 0 0 1px rgba(103,232,249,0.08)",
                  }}
                />
              ) : cfg.image ? (
                <Box
                  component="img"
                  src={cfg.image}
                  alt={cfg.headline ?? ""}
                  loading="eager"
                  sx={{
                    width: "100%",
                    borderRadius: `${tokens.radius.xl}px`,
                    border: `1px solid ${tokens.color.borderStrong}`,
                    boxShadow:
                      "0 30px 80px rgba(5,3,30,0.6), 0 0 0 1px rgba(103,232,249,0.08)",
                  }}
                />
              ) : null}
            </Box>
          ) : null}
        </Box>
      </Container>
    </Box>
  );
}
