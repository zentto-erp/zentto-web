/**
 * TestimonialsSectionAdapter — Server Component.
 *
 * Mapea `TestimonialsSectionConfig` → `<TestimonialsSection>`. Acepta:
 *  - canónico studio-core: `items[].name` / `items[].title`
 *  - enriquecido hotel: `items[].author` / `items[].role` + `featured`
 */

import * as React from "react";
import { TestimonialsSection } from "../../components/TestimonialsSection";
import type { SectionAdapterProps } from "../types";
import type { TestimonialItem } from "../../types";

type ItemSchema = {
  quote: string;
  author?: string;
  name?: string;
  role?: string;
  title?: string;
  company?: string;
  featured?: boolean;
  avatar?: string;
  rating?: number;
};

export function TestimonialsSectionAdapter({
  section,
  tokens,
}: SectionAdapterProps) {
  const cfg = (section.testimonialsConfig ?? {}) as {
    eyebrow?: string;
    title?: string;
    headline?: string;
    description?: string;
    subtitle?: string;
    items?: ItemSchema[];
    variant?: string;
  };

  const items = cfg.items ?? [];
  if (items.length === 0) return null;

  const mapped: TestimonialItem[] = items.map((t) => ({
    quote: t.quote,
    author: t.author ?? t.name ?? "",
    role: t.role ?? t.title ?? "",
    company: t.company ?? "",
    featured: t.featured,
  }));

  return (
    <TestimonialsSection
      tokens={tokens}
      id={section.anchor ?? "stories"}
      eyebrow={cfg.eyebrow ?? "Casos de éxito"}
      title={cfg.title ?? cfg.headline ?? "Equipos que ya migraron"}
      description={cfg.description ?? cfg.subtitle}
      testimonials={mapped}
    />
  );
}
