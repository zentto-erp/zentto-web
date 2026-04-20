/**
 * TestimonialsSection — 1 quote grande + 2 compactos (layout asymmetric).
 * Server Component. Acepta cualquier cantidad de testimonios, destaca el
 * primero con `featured: true`.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import FormatQuoteRoundedIcon from "@mui/icons-material/FormatQuoteRounded";
import type { LandingTokens } from "../tokens";
import type { TestimonialItem } from "../types";
import { SectionShell } from "./SectionShell";

export interface TestimonialsSectionProps {
  tokens: LandingTokens;
  id?: string;
  eyebrow?: string;
  title?: string;
  description?: string;
  testimonials: TestimonialItem[];
}

export function TestimonialsSection({
  tokens,
  id = "stories",
  eyebrow = "Casos de éxito",
  title = "Equipos que ya migraron",
  description,
  testimonials,
}: TestimonialsSectionProps) {
  if (!testimonials || testimonials.length === 0) return null;

  const featured = testimonials.find((t) => t.featured) ?? testimonials[0];
  const others = testimonials.filter((t) => t !== featured).slice(0, 2);

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
          gridTemplateColumns: { xs: "1fr", md: "2fr 1fr" },
          gap: { xs: 3, md: `${tokens.spacing.gridGap}px` },
          alignItems: "stretch",
        }}
      >
        <FeaturedQuote tokens={tokens} t={featured} />
        {others.length > 0 ? (
          <Stack spacing={`${tokens.spacing.gridGap}px`}>
            {others.map((t) => (
              <CompactQuote key={t.author} tokens={tokens} t={t} />
            ))}
          </Stack>
        ) : null}
      </Box>
    </SectionShell>
  );
}

function FeaturedQuote({
  tokens,
  t,
}: {
  tokens: LandingTokens;
  t: TestimonialItem;
}) {
  return (
    <Box
      sx={{
        bgcolor: tokens.color.bgSurface,
        border: `1px solid ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: { xs: 3.5, md: 5 },
        position: "relative",
        display: "flex",
        flexDirection: "column",
        gap: 3,
        height: "100%",
      }}
    >
      <FormatQuoteRoundedIcon
        sx={{
          color: tokens.color.brandLight,
          fontSize: 48,
          opacity: 0.25,
          transform: "scaleX(-1)",
        }}
      />
      <Typography
        component="blockquote"
        sx={{
          color: tokens.color.textPrimary,
          fontSize: { xs: "1.125rem", md: "1.375rem" },
          fontWeight: 500,
          lineHeight: 1.45,
          letterSpacing: "-0.01em",
          flex: 1,
          m: 0,
        }}
      >
        “{t.quote}”
      </Typography>
      <AuthorBlock tokens={tokens} t={t} />
    </Box>
  );
}

function CompactQuote({
  tokens,
  t,
}: {
  tokens: LandingTokens;
  t: TestimonialItem;
}) {
  return (
    <Box
      sx={{
        bgcolor: tokens.color.bgSurface,
        border: `1px solid ${tokens.color.border}`,
        borderRadius: `${tokens.radius.lg}px`,
        p: 3,
        flex: 1,
        display: "flex",
        flexDirection: "column",
        gap: 2,
      }}
    >
      <Typography
        component="blockquote"
        sx={{
          color: tokens.color.textSecondary,
          fontSize: tokens.type.body,
          lineHeight: tokens.leading.body,
          flex: 1,
          m: 0,
        }}
      >
        “{t.quote}”
      </Typography>
      <AuthorBlock tokens={tokens} t={t} compact />
    </Box>
  );
}

function AuthorBlock({
  tokens,
  t,
  compact = false,
}: {
  tokens: LandingTokens;
  t: TestimonialItem;
  compact?: boolean;
}) {
  const initial = t.author.charAt(0).toUpperCase();
  return (
    <Stack direction="row" spacing={1.5} alignItems="center">
      <Box
        sx={{
          width: compact ? 32 : 40,
          height: compact ? 32 : 40,
          borderRadius: "50%",
          background: `linear-gradient(135deg, ${tokens.color.brand}, ${tokens.color.accent})`,
          color: "#fff",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: compact ? "0.8125rem" : "0.9375rem",
          fontWeight: 700,
          flexShrink: 0,
        }}
        aria-hidden
      >
        {initial}
      </Box>
      <Box>
        <Typography
          sx={{
            color: tokens.color.textPrimary,
            fontSize: compact ? "0.8125rem" : tokens.type.body,
            fontWeight: 600,
            lineHeight: 1.3,
          }}
        >
          {t.author}
        </Typography>
        <Typography
          sx={{
            color: tokens.color.textMuted,
            fontSize: tokens.type.bodySm,
            lineHeight: 1.4,
          }}
        >
          {t.role} · {t.company}
        </Typography>
      </Box>
    </Stack>
  );
}
