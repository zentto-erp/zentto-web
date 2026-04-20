/**
 * Helpers para generar `metadata` + `robots` + `sitemap` de Next.js App Router.
 *
 * Uso típico en la app consumidora:
 *   // app/layout.tsx
 *   import { buildLandingMetadata } from "@zentto/landing-kit/metadata";
 *   export const metadata = buildLandingMetadata({ ... });
 *
 *   // app/robots.ts
 *   import { buildLandingRobots } from "@zentto/landing-kit/metadata";
 *   export default buildLandingRobots({ publicUrl: "https://tickets.zentto.net" });
 *
 *   // app/sitemap.ts
 *   import { buildLandingSitemap } from "@zentto/landing-kit/metadata";
 *   export default () => buildLandingSitemap({ publicUrl, routes: [...] });
 */

/* ─── Types mínimos (compatibles con next 14+) ──────────────────────────
 * No importamos los types de Next.js para no forzar la dep al paquete.
 * Las apps consumidoras hacen cast si es necesario.
 */

interface RobotsRule {
  userAgent: string;
  allow?: string | string[];
  disallow?: string | string[];
}

interface RobotsResult {
  rules: RobotsRule[];
  sitemap?: string;
  host?: string;
}

interface SitemapEntry {
  url: string;
  lastModified?: Date;
  changeFrequency?:
    | "always"
    | "hourly"
    | "daily"
    | "weekly"
    | "monthly"
    | "yearly"
    | "never";
  priority?: number;
}

/* ─── Metadata ─────────────────────────────────────────────────────────── */

export interface BuildLandingMetadataOptions {
  publicUrl: string;
  titleDefault: string;
  titleTemplate?: string;
  description: string;
  applicationName: string;
  keywords?: string[];
  ogImage?: string;
  twitterHandle?: string;
  isDevEnv?: boolean;
  locale?: string;
  themeColor?: string;
}

/**
 * Construye el objeto `metadata` de Next.js. El resultado es compatible con
 * el export `metadata` de `app/layout.tsx` (el type exacto `Metadata` se
 * resuelve en la app consumidora).
 */
export function buildLandingMetadata(opts: BuildLandingMetadataOptions) {
  const {
    publicUrl,
    titleDefault,
    titleTemplate = "%s · " + opts.applicationName,
    description,
    applicationName,
    keywords = [],
    ogImage = "/og-image.png",
    twitterHandle = "@zenttohq",
    isDevEnv = detectDevEnv(publicUrl),
    locale = "es_ES",
  } = opts;

  return {
    metadataBase: new URL(publicUrl),
    title: { default: titleDefault, template: titleTemplate },
    description,
    applicationName,
    keywords: [...keywords, "Zentto", "SaaS", "enterprise"],
    authors: [{ name: "Zentto", url: "https://zentto.net" }],
    creator: "Zentto",
    publisher: "Zentto",
    alternates: { canonical: "/" },
    robots: isDevEnv
      ? { index: false, follow: false, nocache: true }
      : {
          index: true,
          follow: true,
          googleBot: {
            index: true,
            follow: true,
            "max-image-preview": "large" as const,
            "max-snippet": -1 as const,
          },
        },
    openGraph: {
      type: "website" as const,
      locale,
      url: publicUrl,
      siteName: applicationName,
      title: titleDefault,
      description,
      images: [
        { url: ogImage, width: 1200, height: 630, alt: applicationName },
      ],
    },
    twitter: {
      card: "summary_large_image" as const,
      title: titleDefault,
      description,
      images: [ogImage],
      creator: twitterHandle,
    },
    icons: {
      icon: "/favicon.ico",
      shortcut: "/favicon.ico",
      apple: "/apple-touch-icon.png",
    },
  };
}

/* ─── Viewport ─────────────────────────────────────────────────────────── */

export interface BuildLandingViewportOptions {
  themeColor?: string;
  colorScheme?: "light" | "dark" | "light dark";
}

export function buildLandingViewport(opts: BuildLandingViewportOptions = {}) {
  return {
    themeColor: opts.themeColor ?? "#0B0A1F",
    colorScheme: opts.colorScheme ?? "dark",
    width: "device-width",
    initialScale: 1,
  };
}

/* ─── robots.txt ───────────────────────────────────────────────────────── */

export interface BuildLandingRobotsOptions {
  publicUrl: string;
  isDevEnv?: boolean;
  disallowPaths?: string[];
}

export function buildLandingRobots(
  opts: BuildLandingRobotsOptions,
): RobotsResult {
  const {
    publicUrl,
    isDevEnv = detectDevEnv(publicUrl),
    disallowPaths = [
      "/api/",
      "/dashboard",
      "/dashboard/",
      "/scan",
      "/configuracion",
    ],
  } = opts;

  if (isDevEnv) {
    return { rules: [{ userAgent: "*", disallow: "/" }] };
  }

  return {
    rules: [{ userAgent: "*", allow: "/", disallow: disallowPaths }],
    sitemap: `${publicUrl}/sitemap.xml`,
    host: publicUrl,
  };
}

/* ─── sitemap.xml ──────────────────────────────────────────────────────── */

export interface BuildLandingSitemapOptions {
  publicUrl: string;
  isDevEnv?: boolean;
  routes: Array<{
    path: string;
    changeFrequency?: SitemapEntry["changeFrequency"];
    priority?: number;
    lastModified?: Date;
  }>;
}

export function buildLandingSitemap(
  opts: BuildLandingSitemapOptions,
): SitemapEntry[] {
  const {
    publicUrl,
    isDevEnv = detectDevEnv(publicUrl),
    routes,
  } = opts;

  if (isDevEnv) return [];

  const now = new Date();
  return routes.map((r) => ({
    url: `${publicUrl}${r.path}`,
    lastModified: r.lastModified ?? now,
    changeFrequency: r.changeFrequency ?? "monthly",
    priority: r.priority ?? 0.5,
  }));
}

/* ─── Internals ────────────────────────────────────────────────────────── */

function detectDevEnv(publicUrl: string): boolean {
  if (process.env.NEXT_PUBLIC_DEV_NOINDEX === "true") return true;
  if (publicUrl.includes("localhost")) return true;
  if (/\bdev\b/.test(publicUrl)) return true;
  return false;
}
