/**
 * TrustBar — barra de logos clientes en escala de grises con scroll horizontal
 * en mobile. Server Component.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import type { TrustLogo } from "../types";

export interface TrustBarProps {
  tokens: LandingTokens;
  label?: string;
  logos: TrustLogo[];
}

export function TrustBar({ tokens, label = "Confían en nosotros", logos }: TrustBarProps) {
  if (!logos || logos.length === 0) return null;

  return (
    <Box
      component="section"
      aria-label="Clientes que confían en la plataforma"
      sx={{
        bgcolor: tokens.color.bg,
        borderTop: `1px solid ${tokens.color.border}`,
        borderBottom: `1px solid ${tokens.color.border}`,
        py: { xs: 4, md: 6 },
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
        <Typography
          sx={{
            textAlign: "center",
            color: tokens.color.textMuted,
            fontSize: tokens.type.eyebrow,
            fontWeight: 600,
            letterSpacing: tokens.tracking.eyebrow,
            textTransform: "uppercase",
            mb: 3,
          }}
        >
          {label}
        </Typography>

        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: { xs: "flex-start", md: "space-between" },
            gap: { xs: 4, md: 5 },
            overflowX: { xs: "auto", md: "visible" },
            scrollbarWidth: "none",
            "&::-webkit-scrollbar": { display: "none" },
            maskImage: {
              xs:
                "linear-gradient(to right, transparent 0, #000 24px, #000 calc(100% - 24px), transparent 100%)",
              md: "none",
            },
            WebkitMaskImage: {
              xs:
                "linear-gradient(to right, transparent 0, #000 24px, #000 calc(100% - 24px), transparent 100%)",
              md: "none",
            },
            px: { xs: 2, md: 0 },
          }}
        >
          {logos.map((logo) => (
            <LogoSlot key={logo.name} tokens={tokens} logo={logo} />
          ))}
        </Box>
      </Container>
    </Box>
  );
}

function LogoSlot({ tokens, logo }: { tokens: LandingTokens; logo: TrustLogo }) {
  const inner = logo.src ? (
    <Box
      component="img"
      src={logo.src}
      alt={logo.name}
      loading="lazy"
      sx={{
        height: { xs: 22, md: 28 },
        width: "auto",
        opacity: 0.65,
        filter: "grayscale(100%)",
        transition: `all ${tokens.motion.ui}`,
        "&:hover": { opacity: 1, filter: "grayscale(0%)" },
      }}
    />
  ) : (
    <Stack
      direction="row"
      alignItems="center"
      spacing={1}
      sx={{
        opacity: 0.55,
        transition: `opacity ${tokens.motion.ui}`,
        "&:hover": { opacity: 0.85 },
      }}
    >
      <Box
        sx={{
          width: 8,
          height: 8,
          borderRadius: "50%",
          bgcolor: tokens.color.textMuted,
        }}
      />
      <Typography
        sx={{
          color: tokens.color.textSecondary,
          fontSize: { xs: "0.8125rem", md: "0.9375rem" },
          fontWeight: 700,
          letterSpacing: "-0.01em",
          whiteSpace: "nowrap",
        }}
      >
        {logo.name}
      </Typography>
    </Stack>
  );

  if (logo.href) {
    return (
      <a
        href={logo.href}
        target="_blank"
        rel="noopener noreferrer"
        aria-label={logo.name}
        style={{ textDecoration: "none", flexShrink: 0 }}
      >
        {inner}
      </a>
    );
  }

  return <Box sx={{ flexShrink: 0 }}>{inner}</Box>;
}
