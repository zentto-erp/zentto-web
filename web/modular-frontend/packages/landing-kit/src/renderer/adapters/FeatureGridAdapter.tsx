/**
 * FeatureGridAdapter — Server Component.
 *
 * Mapea `FeaturesSectionConfig` (items con `iconId` string) → `<FeatureGrid>`
 * resolviendo cada icono vía `resolveIcon`.
 *
 * Acepta tanto el schema canónico de studio-core (`headline`, `subtitle`,
 * `items[].icon`) como el enriquecido del hotel (`eyebrow`, `title`,
 * `description`, `items[].iconId`).
 */

import * as React from "react";
import { FeatureGrid } from "../../components/FeatureGrid";
import { resolveIcon } from "../icon-registry";
import type { SectionAdapterProps } from "../types";

type FeatureItemSchema = {
  iconId?: string;
  icon?: string;
  title: string;
  description: string;
  link?: string;
};

export function FeatureGridAdapter({ section, tokens }: SectionAdapterProps) {
  const cfg = (section.featuresConfig ?? {}) as {
    eyebrow?: string;
    title?: string;
    headline?: string;
    description?: string;
    subtitle?: string;
    items?: FeatureItemSchema[];
    columns?: 2 | 3 | 4;
    layout?: string;
    variant?: string;
  };

  const items = cfg.items ?? [];
  if (items.length === 0) return null;

  // Decide columnas: layout explícito "grid-2"/"grid-3" → n; fallback a `columns` o 3.
  let columns: 2 | 3 = 3;
  if (cfg.layout === "grid-2" || cfg.columns === 2) columns = 2;
  else if (cfg.layout === "grid-3" || cfg.columns === 3) columns = 3;

  const features = items.map((f) => ({
    icon: resolveIcon(f.iconId ?? f.icon, 24),
    title: f.title,
    description: f.description,
    href: f.link,
  }));

  return (
    <FeatureGrid
      tokens={tokens}
      id={section.anchor ?? "features"}
      eyebrow={cfg.eyebrow ?? "Producto"}
      title={cfg.title ?? cfg.headline ?? "Todo lo que necesitas"}
      description={cfg.description ?? cfg.subtitle}
      features={features}
      columns={columns}
    />
  );
}
