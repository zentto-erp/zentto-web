/**
 * PricingSectionAdapter — Server Component.
 *
 * Mapea `PricingSectionConfig` → `<PricingSection>`. Acepta ambos schemas:
 * el canónico (studio-core `plans[].features` + `plans[].highlighted`) y el
 * enriquecido del hotel (`plans[].bullets` + `plans[].highlight` + `plans[].cta`).
 */

import * as React from "react";
import { PricingSection } from "../../components/PricingSection";
import type { SectionAdapterProps } from "../types";
import type { PricingPlan } from "../../types";

type PlanSchema = {
  name: string;
  price: string;
  period?: string;
  description?: string;
  bullets?: string[];
  features?: string[];
  cta?: { label: string; href: string; external?: boolean };
  highlight?: boolean;
  highlighted?: boolean;
  badge?: string;
};

export function PricingSectionAdapter({
  section,
  tokens,
}: SectionAdapterProps) {
  const cfg = (section.pricingConfig ?? {}) as {
    eyebrow?: string;
    title?: string;
    headline?: string;
    description?: string;
    subtitle?: string;
    plans?: PlanSchema[];
    footerLink?: { label: string; href: string };
  };

  const plans = cfg.plans ?? [];
  if (plans.length === 0) return null;

  const mapped: PricingPlan[] = plans.map((p) => ({
    name: p.name,
    price: p.price,
    period: p.period ?? "",
    description: p.description ?? "",
    bullets: p.bullets ?? p.features ?? [],
    cta: p.cta?.label ?? "Empezar",
    href: p.cta?.href ?? "#",
    highlight: p.highlight ?? p.highlighted ?? false,
    external: p.cta?.external,
  }));

  return (
    <PricingSection
      tokens={tokens}
      id={section.anchor ?? "pricing"}
      eyebrow={cfg.eyebrow ?? "Planes"}
      title={cfg.title ?? cfg.headline ?? "Precios simples. Sin sorpresas."}
      description={cfg.description ?? cfg.subtitle}
      plans={mapped}
      footerLink={cfg.footerLink}
    />
  );
}
