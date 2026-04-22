/**
 * Helpers de metadata para las páginas de blog.
 *
 * Exporta:
 *  - `buildBlogIndexMetadata` → `Metadata` para `/blog/page.tsx`
 *  - `buildBlogPostMetadata`  → `Metadata` para `/blog/[slug]/page.tsx`
 *
 * JSON-LD Article schema se incluye en `other.jsonLd` como string — el
 * consumer debe renderizar un `<script type="application/ld+json">` con
 * ese contenido manualmente o usar `Next.js` `generateStaticParams` tooling.
 */

import type { BuiltLandingMetadata } from "../renderer/metadata";
import type { BlogPostFull } from "./BlogPostReader";

export interface BuildBlogIndexMetadataOpts {
  verticalName: string;
  description?: string;
  canonical?: string;
  ogImage?: string;
}

export function buildBlogIndexMetadata(
  opts: BuildBlogIndexMetadataOpts,
): BuiltLandingMetadata {
  const { verticalName, description, canonical, ogImage } = opts;
  const title = `Blog — Ideas para ${verticalName}`;
  const desc =
    description ??
    `Estrategia, operación y producto sobre ${verticalName}. Escribimos sobre el oficio real de operar un negocio ${verticalName.toLowerCase()}.`;
  return {
    title,
    description: desc,
    openGraph: {
      title,
      description: desc,
      images: ogImage
        ? [{ url: ogImage, width: 1200, height: 630, alt: title }]
        : undefined,
      type: "website",
    },
    alternates: canonical ? { canonical } : undefined,
  };
}

export interface BuildBlogPostMetadataOpts {
  post: BlogPostFull;
  verticalName: string;
  canonical?: string;
  siteName?: string;
}

export function buildBlogPostMetadata(
  opts: BuildBlogPostMetadataOpts,
): BuiltLandingMetadata & {
  other?: { jsonLd?: string };
} {
  const { post, verticalName, canonical, siteName } = opts;
  const title = post.Title;
  const description = post.Excerpt ?? `Artículo del blog de Zentto ${verticalName}`;
  const ogImage = post.CoverUrl;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.Title,
    description,
    image: ogImage ? [ogImage] : undefined,
    datePublished: post.PublishedAt ?? undefined,
    author: post.AuthorName
      ? { "@type": "Person", name: post.AuthorName }
      : undefined,
    publisher: {
      "@type": "Organization",
      name: siteName ?? `Zentto ${verticalName}`,
      logo: {
        "@type": "ImageObject",
        url: "https://zentto.net/og-image.png",
      },
    },
    mainEntityOfPage: canonical ?? undefined,
  };

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      images: ogImage
        ? [{ url: ogImage, width: 1200, height: 630, alt: title }]
        : undefined,
      type: "article",
    },
    alternates: canonical ? { canonical } : undefined,
    other: {
      jsonLd: JSON.stringify(jsonLd),
    },
  };
}
