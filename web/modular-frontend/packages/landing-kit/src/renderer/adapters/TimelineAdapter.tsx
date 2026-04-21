/**
 * TimelineAdapter — Server Component.
 *
 * Mapea `TimelineSectionConfig` con `variant: "numbered-horizontal"` al
 * `<HowItWorksSection>` existente (3 pasos numerados). Otras variantes
 * (alternating, left, right) podrían tener adapters distintos en Fase B.3 —
 * por ahora caen al mismo renderer como fallback sensato.
 *
 * Acepta:
 *  - canónico studio-core: `items[].date/title/description`
 *  - enriquecido hotel: `steps[].step/title/description` + `eyebrow` + `title`
 */

import * as React from "react";
import { HowItWorksSection } from "../../components/HowItWorksSection";
import type { SectionAdapterProps } from "../types";
import type { HowItWorksStep } from "../../types";

type StepSchema = {
  step?: string;
  title: string;
  description?: string;
  date?: string;
  icon?: string;
};

export function TimelineAdapter({ section, tokens }: SectionAdapterProps) {
  const cfg = (section.timelineConfig ?? {}) as {
    eyebrow?: string;
    title?: string;
    headline?: string;
    description?: string;
    subtitle?: string;
    variant?: string;
    steps?: StepSchema[];
    items?: StepSchema[];
  };

  const rawSteps = cfg.steps ?? cfg.items ?? [];
  if (rawSteps.length === 0) return null;

  const steps: HowItWorksStep[] = rawSteps.map((s, idx) => ({
    step: s.step ?? s.date ?? String(idx + 1).padStart(2, "0"),
    title: s.title,
    description: s.description ?? "",
  }));

  return (
    <HowItWorksSection
      tokens={tokens}
      id={section.anchor ?? "how"}
      eyebrow={cfg.eyebrow ?? "Cómo funciona"}
      title={cfg.title ?? cfg.headline ?? "En 3 pasos"}
      description={cfg.description ?? cfg.subtitle}
      steps={steps}
    />
  );
}
