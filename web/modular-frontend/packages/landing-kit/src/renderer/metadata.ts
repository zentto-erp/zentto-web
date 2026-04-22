/**
 * Helper para construir `Metadata` de Next.js App Router a partir de un
 * schema de landing del CMS.
 *
 * Uso en la app vertical:
 *   export async function generateMetadata() {
 *     const schema = await fetchLandingSchema({...});
 *     return buildMetadataFromSchema(schema, FALLBACK_METADATA);
 *   }
 *
 * No importamos el type `Metadata` de Next.js para no forzar la dep al
 * paquete — los consumers hacen el tipado desde su lado.
 */

import type { ValidLandingSchema } from "./schema.zod";

/**
 * Shape mínimo del `Metadata` de Next.js que nosotros producimos.
 * Los consumers pueden hacer cast: `as Metadata`.
 */
export interface BuiltLandingMetadata {
  title?: string | { default: string; template?: string } | null;
  description?: string | null;
  keywords?: string[];
  openGraph?: {
    title?: string;
    description?: string;
    images?: Array<string | { url: string; width?: number; height?: number; alt?: string }>;
    type?: string;
  };
  alternates?: {
    canonical?: string;
  };
  other?: Record<string, string | number | Array<string | number>>;
}

export function buildMetadataFromSchema(
  schema: ValidLandingSchema | undefined | null,
  fallback: BuiltLandingMetadata,
): BuiltLandingMetadata {
  const seo = schema?.landingConfig?.seo;
  if (!seo) return fallback;

  const title =
    typeof seo.title === "string" && seo.title.length > 0
      ? seo.title
      : typeof fallback.title === "string"
        ? fallback.title
        : (fallback.title as any)?.default;

  const description = seo.description ?? fallback.description ?? undefined;
  const ogTitle = seo.ogTitle ?? seo.title ?? title ?? undefined;
  const ogDescription = seo.ogDescription ?? seo.description ?? description;
  const canonical = seo.canonical ?? seo.canonicalUrl ?? undefined;

  return {
    ...fallback,
    title: title ?? fallback.title,
    description: description ?? fallback.description,
    keywords: seo.keywords ?? fallback.keywords,
    openGraph: {
      ...(fallback.openGraph ?? {}),
      title: ogTitle,
      description: ogDescription,
      images: seo.ogImage
        ? [
            {
              url: seo.ogImage,
              width: 1200,
              height: 630,
              alt: ogTitle ?? "Zentto",
            },
          ]
        : fallback.openGraph?.images,
      type: seo.ogType ?? fallback.openGraph?.type ?? "website",
    },
    alternates: canonical
      ? { ...(fallback.alternates ?? {}), canonical }
      : fallback.alternates,
  };
}
