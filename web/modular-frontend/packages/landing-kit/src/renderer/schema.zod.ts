/**
 * Zod schema permisivo para validar landings del CMS.
 *
 * Estrategia: validación ESTRUCTURAL estricta (navbar + footer + sections[]),
 * contenido PERMISIVO (`z.any().optional()`). Los adapters específicos
 * validan su subset de config en runtime.
 *
 * Permite que el schema de `@zentto/studio-core` evolucione (agregar nuevos
 * `LandingSectionType`) sin romper el renderer.
 */

import { z } from "zod";

const ctaZod = z
  .object({
    label: z.string(),
    href: z.string(),
    external: z.boolean().optional(),
    variant: z.enum(["primary", "secondary", "ghost"]).optional(),
  })
  .passthrough();

const navLinkZod = z
  .object({
    label: z.string(),
    href: z.string(),
    external: z.boolean().optional(),
  })
  .passthrough();

const footerColumnZod = z
  .object({
    title: z.string(),
    links: z.array(navLinkZod).default([]),
  })
  .passthrough();

const navbarZod = z
  .object({
    verticalName: z.string().optional(),
    title: z.string().optional(),
    logo: z.string().optional(),
    logoAlt: z.string().optional(),
    logoIconId: z.string().optional(),
    links: z.array(navLinkZod).default([]),
    primaryCta: ctaZod.optional(),
    ctaButton: ctaZod.optional(),
    loginHref: z.string().optional(),
    homeHref: z.string().optional(),
    sticky: z.boolean().optional(),
  })
  .passthrough();

const footerZod = z
  .object({
    verticalName: z.string().optional(),
    logoIconId: z.string().optional(),
    brandTagline: z.string().optional(),
    columns: z.array(footerColumnZod).default([]),
    social: z
      .array(
        z
          .object({
            label: z.string().optional(),
            iconId: z.string().optional(),
            icon: z.string().optional(),
            href: z.string().optional(),
            url: z.string().optional(),
          })
          .passthrough(),
      )
      .optional(),
    legalLinks: z
      .array(
        z
          .object({ label: z.string(), href: z.string() })
          .passthrough(),
      )
      .optional(),
    statusLink: z
      .object({ label: z.string(), href: z.string() })
      .passthrough()
      .optional(),
  })
  .passthrough();

const seoZod = z
  .object({
    title: z.string().optional(),
    description: z.string().optional(),
    ogTitle: z.string().optional(),
    ogDescription: z.string().optional(),
    ogImage: z.string().optional(),
    ogType: z.string().optional(),
    canonical: z.string().optional(),
    canonicalUrl: z.string().optional(),
    keywords: z.array(z.string()).optional(),
    jsonLd: z.record(z.unknown()).optional(),
  })
  .passthrough();

const sectionZod = z
  .object({
    id: z.string(),
    type: z.string(),
    variant: z.string().optional(),
    anchor: z.string().optional(),
    background: z.any().optional(),
    padding: z.enum(["none", "sm", "md", "lg", "xl"]).optional(),
    animation: z.string().optional(),
    // Configs por tipo — todos permisivos, validación estricta en cada adapter.
    heroConfig: z.any().optional(),
    featuresConfig: z.any().optional(),
    pricingConfig: z.any().optional(),
    testimonialsConfig: z.any().optional(),
    ctaConfig: z.any().optional(),
    statsConfig: z.any().optional(),
    faqConfig: z.any().optional(),
    teamConfig: z.any().optional(),
    galleryConfig: z.any().optional(),
    logosConfig: z.any().optional(),
    contentConfig: z.any().optional(),
    videoConfig: z.any().optional(),
    contactConfig: z.any().optional(),
    htmlContent: z.string().optional(),
    socialLinksConfig: z.any().optional(),
    mapConfig: z.any().optional(),
    countdownConfig: z.any().optional(),
    carouselConfig: z.any().optional(),
    ctaFormConfig: z.any().optional(),
    comparisonConfig: z.any().optional(),
    timelineConfig: z.any().optional(),
    tabsSectionConfig: z.any().optional(),
    socialProofConfig: z.any().optional(),
    beforeAfterConfig: z.any().optional(),
    popupConfig: z.any().optional(),
    blogPreviewConfig: z.any().optional(),
    socialFeedConfig: z.any().optional(),
    // Extensión landing-kit (fuera del schema canónico de studio-core):
    customConfig: z
      .object({
        componentId: z.string(),
        props: z.record(z.unknown()).optional(),
      })
      .passthrough()
      .optional(),
  })
  .passthrough();

const brandingZod = z
  .object({
    title: z.string(),
    subtitle: z.string().optional(),
    primaryColor: z.string().optional(),
    accentColor: z.string().optional(),
    homeSegment: z.string().optional(),
    logoIconId: z.string().optional(),
  })
  .passthrough();

export const LandingSchemaZod = z
  .object({
    id: z.string(),
    version: z.string(),
    appMode: z.literal("landing"),
    branding: brandingZod,
    landingConfig: z
      .object({
        navbar: navbarZod.optional(),
        footer: footerZod.optional(),
        sections: z.array(sectionZod).default([]),
        seo: seoZod.optional(),
        globalStyles: z.any().optional(),
        locale: z.string().optional(),
        i18n: z.record(z.record(z.string())).optional(),
      })
      .passthrough(),
  })
  .passthrough();

export type ValidLandingSchema = z.infer<typeof LandingSchemaZod>;
export type ValidLandingSection = z.infer<typeof sectionZod>;
export type ValidLandingNavbar = z.infer<typeof navbarZod>;
export type ValidLandingFooter = z.infer<typeof footerZod>;
export type ValidLandingSeo = z.infer<typeof seoZod>;

/**
 * Parsea un schema con log silencioso. Devuelve `undefined` si falla, para
 * que el caller use el fallback del renderer sin romper el build.
 */
export function safeParseSchema(
  input: unknown,
): ValidLandingSchema | undefined {
  const result = LandingSchemaZod.safeParse(input);
  if (!result.success) {
    if (typeof console !== "undefined" && typeof console.warn === "function") {
      // Resumen corto: primer issue. Evitamos loguear el schema entero.
      const first = result.error.issues[0];
      console.warn(
        `[landing-kit] Schema inválido, usando fallback. ${
          first ? `Primer error: ${first.path.join(".")} — ${first.message}` : ""
        }`,
      );
    }
    return undefined;
  }
  return result.data;
}
