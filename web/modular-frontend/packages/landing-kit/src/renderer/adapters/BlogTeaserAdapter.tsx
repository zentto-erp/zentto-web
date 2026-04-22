/**
 * BlogTeaserAdapter — Server Component.
 *
 * Mapea `BlogPreviewSectionConfig` → `<BlogTeaser>` existente del package.
 * El BlogTeaser ya hace su propio fetch al CMS (try/catch silent fail), así
 * que aquí solo traducimos el schema a sus props.
 *
 * Schema hotel usa `blogPreviewConfig.dataSource.{type, vertical, locale, limit}`
 * (no canónico de studio-core — lo aceptamos como extensión).
 */

import * as React from "react";
import { BlogTeaser } from "../../components/BlogTeaser";
import type { SectionAdapterProps } from "../types";

export async function BlogTeaserAdapter({
  section,
  tokens,
  locale,
  companyId,
  apiBaseUrl,
}: SectionAdapterProps) {
  const cfg = (section.blogPreviewConfig ?? {}) as {
    title?: string;
    headline?: string;
    description?: string;
    subtitle?: string;
    dataSource?: {
      type?: string;
      vertical?: string;
      locale?: string;
      limit?: number;
    };
    readMoreHref?: string;
    readMoreLabel?: string;
    ctaLabel?: string;
    ctaUrl?: string;
  };

  const ds = cfg.dataSource ?? {};
  const vertical = ds.vertical ?? tokens.vertical;
  const limit = ds.limit ?? 3;
  const resolvedLocale = ds.locale ?? locale ?? "es";

  // BlogTeaser devuelve null si no hay posts — cumple fallback strategy.
  return (
    <BlogTeaser
      tokens={tokens}
      vertical={vertical}
      theme={tokens.theme as "light" | "dark"}
      companyId={companyId ?? 1}
      apiUrl={apiBaseUrl ?? "https://api.zentto.net"}
      limit={limit}
      locale={resolvedLocale}
      id={section.anchor ?? "blog"}
      title={cfg.title ?? cfg.headline}
      description={cfg.description ?? cfg.subtitle}
      ctaHref={cfg.readMoreHref ?? cfg.ctaUrl}
      ctaLabel={cfg.readMoreLabel ?? cfg.ctaLabel}
    />
  );
}
