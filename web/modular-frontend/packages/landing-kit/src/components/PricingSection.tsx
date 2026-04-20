/**
 * PricingSection — 3 planes (highlight scale 1.04 desktop, primero en mobile).
 * Server Component. Los planes se pasan como prop — cada vertical define copy.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import CheckRoundedIcon from "@mui/icons-material/CheckRounded";
import type { LandingTokens } from "../tokens";
import type { PricingPlan } from "../types";
import { SectionShell } from "./SectionShell";
import { CTAButton } from "./CTAButton";

export interface PricingSectionProps {
  tokens: LandingTokens;
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  plans: PricingPlan[];
  footerLink?: { label: string; href: string };
  /** Componente Link (Next.js) si las apps lo necesitan. */
  LinkComponent?: React.ElementType;
}

export function PricingSection({
  tokens,
  id = "pricing",
  eyebrow = "Planes",
  title = "Precios simples. Sin sorpresas.",
  description = "Empieza gratis y escala cuando crezcas. Cancela cuando quieras.",
  plans,
  footerLink,
  LinkComponent,
}: PricingSectionProps) {
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
            md: `repeat(${Math.min(plans.length, 3)}, 1fr)`,
          },
          gap: { xs: 3, md: `${tokens.spacing.gridGap}px` },
          alignItems: "stretch",
        }}
      >
        {plans.map((plan, idx) => (
          <Box
            key={plan.name}
            sx={{ order: { xs: plan.highlight ? -1 : idx, md: idx } }}
          >
            <PricingCard tokens={tokens} plan={plan} LinkComponent={LinkComponent} />
          </Box>
        ))}
      </Box>

      {footerLink ? (
        <Typography
          sx={{
            mt: 4,
            textAlign: "center",
            color: tokens.color.textMuted,
            fontSize: tokens.type.bodySm,
          }}
        >
          {footerLink.label.split("{link}")[0] ?? "¿Necesitas algo distinto? "}
          <Box
            component="a"
            href={footerLink.href}
            sx={{
              color: tokens.color.brandLight,
              textDecoration: "none",
              fontWeight: 600,
              "&:hover": { textDecoration: "underline" },
            }}
          >
            Hablemos →
          </Box>
        </Typography>
      ) : null}
    </SectionShell>
  );
}

function PricingCard({
  tokens,
  plan,
  LinkComponent,
}: {
  tokens: LandingTokens;
  plan: PricingPlan;
  LinkComponent?: React.ElementType;
}) {
  const isHighlight = !!plan.highlight;

  return (
    <Box
      sx={{
        position: "relative",
        bgcolor: tokens.color.bgSurface,
        border: isHighlight
          ? `2px solid ${tokens.color.brand}`
          : `1px solid ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: { xs: 3, md: 4 },
        height: "100%",
        display: "flex",
        flexDirection: "column",
        gap: 3,
        transform: { md: isHighlight ? "scale(1.04)" : "none" },
        boxShadow: isHighlight ? tokens.shadow.cta : tokens.shadow.card,
        zIndex: isHighlight ? 2 : 1,
      }}
    >
      {isHighlight ? (
        <Box
          sx={{
            position: "absolute",
            top: -14,
            left: "50%",
            transform: "translateX(-50%)",
            bgcolor: tokens.color.brand,
            color: "#fff",
            px: 2,
            py: 0.5,
            borderRadius: `${tokens.radius.pill}px`,
            fontSize: tokens.type.eyebrow,
            fontWeight: 700,
            letterSpacing: tokens.tracking.eyebrow,
            textTransform: "uppercase",
          }}
        >
          Recomendado
        </Box>
      ) : null}

      <Box>
        <Typography
          component="h3"
          sx={{
            color: tokens.color.textPrimary,
            fontSize: "1.125rem",
            fontWeight: 700,
            mb: 0.5,
          }}
        >
          {plan.name}
        </Typography>
        <Typography
          sx={{
            color: tokens.color.textMuted,
            fontSize: tokens.type.bodySm,
            lineHeight: tokens.leading.body,
          }}
        >
          {plan.description}
        </Typography>
      </Box>

      <Stack direction="row" alignItems="baseline" spacing={1}>
        <Typography
          sx={{
            color: tokens.color.textPrimary,
            fontSize: "2.25rem",
            fontWeight: 800,
            lineHeight: 1,
            letterSpacing: "-0.02em",
          }}
        >
          {plan.price}
        </Typography>
        <Typography
          sx={{ color: tokens.color.textMuted, fontSize: tokens.type.bodySm }}
        >
          {plan.period}
        </Typography>
      </Stack>

      <Box sx={{ flex: 1 }}>
        <Stack
          component="ul"
          spacing={1.5}
          sx={{ listStyle: "none", p: 0, m: 0 }}
        >
          {plan.bullets.map((b) => (
            <Stack
              key={b}
              component="li"
              direction="row"
              spacing={1.5}
              alignItems="flex-start"
            >
              <CheckRoundedIcon
                sx={{
                  fontSize: 18,
                  color: tokens.color.success,
                  mt: 0.25,
                  flexShrink: 0,
                }}
              />
              <Typography
                sx={{
                  color: tokens.color.textSecondary,
                  fontSize: tokens.type.body,
                  lineHeight: tokens.leading.body,
                }}
              >
                {b}
              </Typography>
            </Stack>
          ))}
        </Stack>
      </Box>

      <CTAButton
        tokens={tokens}
        href={plan.href}
        variant={isHighlight ? "primary" : "secondary"}
        external={plan.external}
        LinkComponent={LinkComponent}
        fullWidth
      >
        {plan.cta}
      </CTAButton>
    </Box>
  );
}
