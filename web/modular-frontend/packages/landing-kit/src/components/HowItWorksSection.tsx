/**
 * HowItWorksSection — 3 pasos numerados de igual altura.
 * Server Component.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import type { HowItWorksStep } from "../types";
import { SectionShell } from "./SectionShell";

export interface HowItWorksSectionProps {
  tokens: LandingTokens;
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  steps: HowItWorksStep[];
}

export function HowItWorksSection({
  tokens,
  id = "how",
  eyebrow = "Workflow",
  title = "De la idea al resultado en 3 pasos",
  description,
  steps,
}: HowItWorksSectionProps) {
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
          gridTemplateColumns: {
            xs: "1fr",
            md: `repeat(${steps.length}, 1fr)`,
          },
          gap: `${tokens.spacing.gridGap}px`,
        }}
      >
        {steps.map((s) => (
          <StepCard key={s.step} tokens={tokens} {...s} />
        ))}
      </Box>
    </SectionShell>
  );
}

function StepCard({
  tokens,
  step,
  title,
  description,
}: {
  tokens: LandingTokens;
} & HowItWorksStep) {
  return (
    <Box
      sx={{
        position: "relative",
        bgcolor: tokens.color.bgSurface,
        border: `1px solid ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: { xs: 3, md: 4 },
        minHeight: 220,
        display: "flex",
        flexDirection: "column",
      }}
    >
      <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 2 }}>
        <Box
          sx={{
            width: 44,
            height: 44,
            borderRadius: "50%",
            bgcolor: tokens.color.brandSoft,
            color: tokens.color.brandLight,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: "0.875rem",
            fontWeight: 800,
            letterSpacing: "0.04em",
          }}
        >
          {step}
        </Box>
        <Box
          aria-hidden
          sx={{ flex: 1, height: 1, bgcolor: tokens.color.border }}
        />
      </Stack>
      <Typography
        component="h3"
        sx={{
          color: tokens.color.textPrimary,
          fontSize: tokens.type.h3,
          fontWeight: 700,
          lineHeight: tokens.leading.tight,
          mb: 1.25,
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
    </Box>
  );
}
