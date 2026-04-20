/**
 * CTAFinal — banner full-width al final de la landing con dual-CTA.
 * Server Component.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import { CTAButton } from "./CTAButton";

export interface CTAFinalProps {
  tokens: LandingTokens;
  title: string;
  subtitle?: string;
  primaryCta: { label: string; href: string; external?: boolean };
  secondaryCta?: { label: string; href: string; external?: boolean };
  LinkComponent?: React.ElementType;
}

export function CTAFinal({
  tokens,
  title,
  subtitle,
  primaryCta,
  secondaryCta,
  LinkComponent,
}: CTAFinalProps) {
  return (
    <Box
      component="section"
      sx={{
        bgcolor: tokens.color.bg,
        py: { xs: 8, md: 12 },
        position: "relative",
        overflow: "hidden",
      }}
    >
      <Box
        aria-hidden
        sx={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at center, ${tokens.color.brandSoft} 0%, transparent 60%)`,
        }}
      />
      <Container
        maxWidth={false}
        sx={{
          maxWidth: 920,
          px: {
            xs: `${tokens.container.gutterMobile}px`,
            md: `${tokens.container.gutterDesktop}px`,
          },
          position: "relative",
          textAlign: "center",
        }}
      >
        <Box
          sx={{
            background: `linear-gradient(135deg, ${tokens.color.bgElevated} 0%, ${tokens.color.bgSurface} 100%)`,
            border: `1px solid ${tokens.color.borderStrong}`,
            borderRadius: `${tokens.radius.xl}px`,
            p: { xs: 4, md: 7 },
            boxShadow: "0 24px 64px rgba(5,3,30,0.6)",
          }}
        >
          <Typography
            component="h2"
            sx={{
              color: tokens.color.textPrimary,
              fontSize: tokens.type.display,
              fontWeight: 800,
              lineHeight: tokens.leading.display,
              letterSpacing: tokens.tracking.display,
              mb: 2,
              maxWidth: 700,
              mx: "auto",
            }}
          >
            {title}
          </Typography>
          {subtitle ? (
            <Typography
              sx={{
                color: tokens.color.textSecondary,
                fontSize: tokens.type.bodyLg,
                lineHeight: tokens.leading.body,
                mb: 4,
                maxWidth: 540,
                mx: "auto",
              }}
            >
              {subtitle}
            </Typography>
          ) : null}

          <Stack
            direction={{ xs: "column", sm: "row" }}
            spacing={1.5}
            justifyContent="center"
            alignItems="center"
          >
            <CTAButton
              tokens={tokens}
              href={primaryCta.href}
              external={primaryCta.external}
              LinkComponent={LinkComponent}
              variant="primary"
              size="lg"
            >
              {primaryCta.label}
            </CTAButton>
            {secondaryCta ? (
              <CTAButton
                tokens={tokens}
                href={secondaryCta.href}
                external={secondaryCta.external}
                LinkComponent={LinkComponent}
                variant="secondary"
                size="lg"
              >
                {secondaryCta.label}
              </CTAButton>
            ) : null}
          </Stack>
        </Box>
      </Container>
    </Box>
  );
}
