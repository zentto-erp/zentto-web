/**
 * FeatureGrid — grid 3×2 simétrico (altura mínima garantizada).
 * Server Component. Las features se pasan como prop — cada vertical
 * define su propio catálogo con iconos específicos.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import type { FeatureItem } from "../types";
import { SectionShell } from "./SectionShell";

export interface FeatureGridProps {
  tokens: LandingTokens;
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  features: FeatureItem[];
  /** Columnas en desktop (2 o 3). Default: 3. */
  columns?: 2 | 3;
}

export function FeatureGrid({
  tokens,
  id = "features",
  eyebrow = "Producto",
  title = "Todo lo que un profesional necesita",
  description,
  features,
  columns = 3,
}: FeatureGridProps) {
  const gridTemplate =
    columns === 2
      ? { xs: "1fr", sm: "repeat(2, 1fr)" }
      : { xs: "1fr", sm: "1fr 1fr", md: "repeat(3, 1fr)" };

  return (
    <SectionShell
      tokens={tokens}
      id={id}
      eyebrow={eyebrow}
      title={title}
      description={description}
      align="center"
    >
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: gridTemplate,
          gap: `${tokens.spacing.gridGap}px`,
        }}
      >
        {features.map((f) => (
          <FeatureCard
            key={f.title}
            tokens={tokens}
            icon={f.icon}
            title={f.title}
            description={f.description}
          />
        ))}
      </Box>
    </SectionShell>
  );
}

function FeatureCard({
  tokens,
  icon,
  title,
  description,
}: {
  tokens: LandingTokens;
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <Box
      sx={{
        bgcolor: tokens.color.bgSurface,
        border: `1px solid ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: { xs: 3, md: 4 },
        minHeight: 240,
        display: "flex",
        flexDirection: "column",
        gap: 2,
        transition: `transform ${tokens.motion.ui}, border-color ${tokens.motion.ui}, box-shadow ${tokens.motion.ui}`,
        "&:hover": {
          transform: "translateY(-2px)",
          borderColor: "rgba(165,180,252,0.32)",
          boxShadow: tokens.shadow.cardHover,
        },
      }}
    >
      <Box
        sx={{
          width: 48,
          height: 48,
          borderRadius: `${tokens.radius.md}px`,
          bgcolor: tokens.color.brandSoft,
          color: tokens.color.brandLight,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {icon}
      </Box>
      <Stack spacing={1.25}>
        <Typography
          component="h3"
          sx={{
            color: tokens.color.textPrimary,
            fontSize: tokens.type.h3,
            fontWeight: 700,
            lineHeight: tokens.leading.tight,
            letterSpacing: tokens.tracking.heading,
          }}
        >
          {title}
        </Typography>
        <Typography
          sx={{
            color: tokens.color.textSecondary,
            fontSize: tokens.type.body,
            lineHeight: tokens.leading.body,
          }}
        >
          {description}
        </Typography>
      </Stack>
    </Box>
  );
}
