/**
 * SECTION_MAP — fuente única de resolución `section.type` → Component.
 *
 * Agregar un nuevo tipo de sección = agregar entrada aquí + crear adapter en
 * `./adapters/`. No hay magic imports ni convención de nombres — todo explícito.
 */

import * as React from "react";
import type { SectionAdapterProps } from "./types";

import { HeroAdapter } from "./adapters/HeroAdapter";
import { FeatureGridAdapter } from "./adapters/FeatureGridAdapter";
import { PricingSectionAdapter } from "./adapters/PricingSectionAdapter";
import { TestimonialsSectionAdapter } from "./adapters/TestimonialsSectionAdapter";
import { CTAFinalAdapter } from "./adapters/CTAFinalAdapter";
import { TrustBarAdapter } from "./adapters/TrustBarAdapter";
import { BlogTeaserAdapter } from "./adapters/BlogTeaserAdapter";
import { TimelineAdapter } from "./adapters/TimelineAdapter";
import { CustomSectionResolver } from "./adapters/CustomSectionResolver";

export const SECTION_MAP: Record<
  string,
  React.ComponentType<SectionAdapterProps>
> = {
  hero: HeroAdapter,
  features: FeatureGridAdapter,
  pricing: PricingSectionAdapter,
  testimonials: TestimonialsSectionAdapter,
  cta: CTAFinalAdapter,
  logos: TrustBarAdapter,
  "blog-preview": BlogTeaserAdapter,
  timeline: TimelineAdapter,
  custom: CustomSectionResolver,
};

/**
 * Resuelve el tipo de sección a su adapter. `null` si no hay adapter para
 * ese tipo — el renderer logueará warning y omitirá la sección (no rompe).
 */
export function resolveSection(
  type: string,
): React.ComponentType<SectionAdapterProps> | null {
  return SECTION_MAP[type] ?? null;
}
