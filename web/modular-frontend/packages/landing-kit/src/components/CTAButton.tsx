/**
 * CTAButton — botón canónico para CTAs de landing.
 *
 * Variantes: primary (gradient brand) · secondary (outlined) · ghost (solo texto).
 * Sizes: sm (36) · md (44) · lg (52). Focus-visible AA garantizado.
 *
 * NOTA: como el kit es framework-agnostic, usa `<a>` nativo por default. Las
 * apps Next.js pueden pasar su propio `Link` via `asChild`/`component` prop
 * (a futuro) o simplemente dejar href absoluto/relativo — navegación normal.
 */

"use client";

import * as React from "react";
import Button from "@mui/material/Button";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import type { LandingTokens } from "../tokens";

export interface CTAButtonProps {
  tokens: LandingTokens;
  href: string;
  children: React.ReactNode;
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  fullWidth?: boolean;
  showArrow?: boolean;
  external?: boolean;
  ariaLabel?: string;
  /** Componente de enlace (ej. Next.js `Link`). Default: "a" nativo. */
  LinkComponent?: React.ElementType;
}

const SIZES = {
  sm: { height: 36, px: 2, fontSize: "0.8125rem" },
  md: { height: 44, px: 2.5, fontSize: "0.9375rem" },
  lg: { height: 52, px: 3.5, fontSize: "1rem" },
} as const;

export function CTAButton({
  tokens,
  href,
  children,
  variant = "primary",
  size = "md",
  fullWidth = false,
  showArrow = false,
  external = false,
  ariaLabel,
  LinkComponent,
}: CTAButtonProps) {
  const sz = SIZES[size];

  const base = {
    textTransform: "none" as const,
    fontWeight: 700,
    fontSize: sz.fontSize,
    height: sz.height,
    px: sz.px,
    borderRadius: `${tokens.radius.md}px`,
    letterSpacing: "-0.005em",
    whiteSpace: "nowrap" as const,
    transition: `transform ${tokens.motion.micro}, box-shadow ${tokens.motion.micro}, background-color ${tokens.motion.micro}, border-color ${tokens.motion.micro}, color ${tokens.motion.micro}`,
    "&:focus-visible": {
      outline: `2px solid ${tokens.color.brandLight}`,
      outlineOffset: 2,
    },
    ...(fullWidth ? { width: "100%" } : {}),
  };

  const sx =
    variant === "primary"
      ? {
          ...base,
          color: "#fff",
          background: `linear-gradient(135deg, ${tokens.color.brand}, ${tokens.color.brandStrong})`,
          boxShadow: tokens.shadow.cta,
          "&:hover": {
            background: `linear-gradient(135deg, ${tokens.color.brand}, ${tokens.color.brandStrong})`,
            boxShadow: tokens.shadow.ctaHover,
            transform: "translateY(-1px)",
          },
          "&:focus-visible": base["&:focus-visible"],
        }
      : variant === "secondary"
      ? {
          ...base,
          color: tokens.color.textPrimary,
          bgcolor: "transparent",
          border: `1px solid ${tokens.color.borderStrong}`,
          "&:hover": {
            bgcolor: "rgba(255,255,255,0.04)",
            borderColor: tokens.color.brandLight,
            color: tokens.color.brandLight,
          },
          "&:focus-visible": base["&:focus-visible"],
        }
      : {
          ...base,
          color: tokens.color.brandLight,
          bgcolor: "transparent",
          px: 1,
          "&:hover": {
            bgcolor: "rgba(165,180,252,0.08)",
            color: tokens.color.textPrimary,
          },
          "&:focus-visible": base["&:focus-visible"],
        };

  const content = (
    <>
      {children}
      {showArrow ? <ArrowForwardIcon sx={{ fontSize: 16, ml: 0.75 }} /> : null}
    </>
  );

  if (external) {
    return (
      <Button
        component="a"
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        aria-label={ariaLabel}
        sx={sx}
      >
        {content}
      </Button>
    );
  }

  // Permite inyectar Link de Next.js sin que el kit lo importe directo
  const LinkEl = (LinkComponent ?? "a") as React.ElementType;

  return (
    <Button component={LinkEl} href={href} aria-label={ariaLabel} sx={sx}>
      {content}
    </Button>
  );
}
