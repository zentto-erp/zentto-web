/**
 * CTAFinalAdapter — Server Component.
 *
 * Mapea `CtaSectionConfig` → `<CTAFinal>`. Acepta:
 *  - canónico studio-core: `headline` + `primaryCta`
 *  - enriquecido hotel: `title` + `subtitle` + `ctaPrimary` + `ctaSecondary`
 */

import * as React from "react";
import { CTAFinal } from "../../components/CTAFinal";
import type { SectionAdapterProps } from "../types";

type CtaSchema = { label: string; href: string; external?: boolean };

export function CTAFinalAdapter({ section, tokens }: SectionAdapterProps) {
  const cfg = (section.ctaConfig ?? {}) as {
    title?: string;
    headline?: string;
    subtitle?: string;
    description?: string;
    primaryCta?: CtaSchema;
    secondaryCta?: CtaSchema;
    ctaPrimary?: CtaSchema;
    ctaSecondary?: CtaSchema;
  };

  const title = cfg.title ?? cfg.headline;
  if (!title) return null;

  const primary = cfg.ctaPrimary ?? cfg.primaryCta;
  if (!primary) return null;

  return (
    <CTAFinal
      tokens={tokens}
      title={title}
      subtitle={cfg.subtitle ?? cfg.description}
      primaryCta={primary}
      secondaryCta={cfg.ctaSecondary ?? cfg.secondaryCta}
    />
  );
}
