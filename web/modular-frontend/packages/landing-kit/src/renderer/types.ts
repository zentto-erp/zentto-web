/**
 * Tipos públicos del runtime renderer de `@zentto/landing-kit`.
 *
 * El renderer consume un schema JSON de tipo landing (definido en
 * `@zentto/studio-core`) y lo transforma a React Server Components. Las apps
 * consumidoras (zentto-hotel, zentto-medical, etc.) pasan el schema + tokens
 * + un `registry` opcional de componentes custom para escape hatches
 * (mockups ilustrativos, embeds específicos, etc.).
 */

import type * as React from "react";
import type { LandingTokens } from "../tokens";
import type { ValidLandingSchema, ValidLandingSection } from "./schema.zod";

/**
 * Mapa `componentId` -> Component. Usado por el resolver de secciones
 * `type: "custom"` y por el HeroAdapter cuando el schema declara un
 * `mockupComponentId` en `heroConfig.extensions.__landingKit`.
 *
 * Patrón "Builder.io": el schema transporta strings (serializables) y el
 * host resuelve a componentes concretos en server-side.
 */
export interface LandingRegistry {
  [componentId: string]: React.ComponentType<any>;
}

/**
 * Props del `<LandingRenderer>`. Server Component.
 */
export interface LandingRendererProps {
  /**
   * Schema JSON ya validado. Si viene `undefined` o falla la validación
   * interna se renderiza `fallback` en su lugar.
   */
  schema: ValidLandingSchema | undefined;

  /**
   * Schema fallback obligatorio — nunca renderizamos una página vacía. Este
   * schema suele ser un snapshot embebido en el repo de la vertical para no
   * bloquear build-time cuando el CMS está caído.
   */
  fallback: ValidLandingSchema;

  /** Tokens construidos con `buildLandingTokens(vertical, theme)`. */
  tokens: LandingTokens;

  /** Componentes custom inyectables por `componentId`. Opcional. */
  registry?: LandingRegistry;

  /** Idioma activo — aplicado a diccionarios `landingConfig.i18n` si existen. */
  locale?: "es" | "en" | "pt";

  /** CompanyId propagado a componentes que hacen fetch (BlogTeaser). */
  companyId?: number;

  /** URL base del API — se usa en BlogTeaserAdapter. Default: https://api.zentto.net */
  apiBaseUrl?: string;
}

/**
 * Props que recibe cada adapter de sección. El adapter hace cast interno del
 * `section.*Config` que le corresponda — el schema es permisivo (passthrough),
 * así que un adapter debe validar su subset propio antes de renderizar.
 */
export interface SectionAdapterProps {
  section: ValidLandingSection;
  tokens: LandingTokens;
  registry: LandingRegistry;
  locale: string;
  companyId?: number;
  apiBaseUrl?: string;
}

/**
 * Estructura del bloque `extensions.__landingKit` — campos propietarios que
 * landing-kit añade al schema canónico de studio-core sin romper su Zod.
 */
export interface LandingKitHeroExtensions {
  /** Pill con dot arriba del headline. */
  eyebrow?: {
    dot?: boolean;
    label: string;
    /** Color del dot. Default: tokens.color.success */
    dotColorToken?: "success" | "warning" | "brand" | "accent" | "danger";
  };
  /** Si el subheadline debe renderizarse con gradient brand→accent. */
  headlineAccentGradient?: boolean;
  /** Badges inline debajo de los CTAs (14 días gratis, Setup <1 día, etc.). */
  trustBadges?: Array<{ iconId: string; label: string }>;
  /** ID del componente custom (buscado en `registry`) para el mockup del hero. */
  mockupComponentId?: string;
}

export type { ValidLandingSchema, ValidLandingSection } from "./schema.zod";
