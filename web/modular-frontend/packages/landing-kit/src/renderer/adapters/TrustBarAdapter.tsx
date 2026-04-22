/**
 * TrustBarAdapter — Server Component.
 *
 * Mapea `LogosSectionConfig` → `<TrustBar>`. Acepta dos variantes:
 *  - `variant: "text-only"` + `logos[].name` (hotel)
 *  - `logos[].src/alt/url` (canónico studio-core)
 */

import * as React from "react";
import { TrustBar } from "../../components/TrustBar";
import type { SectionAdapterProps } from "../types";
import type { TrustLogo } from "../../types";

type LogoSchema = {
  name?: string;
  alt?: string;
  src?: string;
  url?: string;
  href?: string;
};

export function TrustBarAdapter({ section, tokens }: SectionAdapterProps) {
  const cfg = (section.logosConfig ?? {}) as {
    label?: string;
    headline?: string;
    variant?: string;
    logos?: LogoSchema[];
    grayscale?: boolean;
  };

  const logos = cfg.logos ?? [];
  if (logos.length === 0) return null;

  const isTextOnly = cfg.variant === "text-only";

  const mapped: TrustLogo[] = logos.map((l) => ({
    name: l.name ?? l.alt ?? "",
    // text-only variant: forzar sin src para renderizar como chip texto
    src: isTextOnly ? undefined : l.src,
    href: l.url ?? l.href,
  }));

  return (
    <TrustBar
      tokens={tokens}
      label={cfg.label ?? cfg.headline ?? "Confían en nosotros"}
      logos={mapped}
    />
  );
}
