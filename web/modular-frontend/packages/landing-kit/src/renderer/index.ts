/**
 * `@zentto/landing-kit/renderer` — public exports.
 *
 * Uso:
 *   import {
 *     LandingRenderer,
 *     fetchLandingSchema,
 *     buildMetadataFromSchema,
 *   } from "@zentto/landing-kit/renderer";
 */

export { LandingRenderer } from "./LandingRenderer";
export { SECTION_MAP, resolveSection } from "./section-map";
export { ICON_MAP, resolveIcon, hasIcon } from "./icon-registry";
export {
  LandingSchemaZod,
  safeParseSchema,
  type ValidLandingSchema,
  type ValidLandingSection,
  type ValidLandingNavbar,
  type ValidLandingFooter,
  type ValidLandingSeo,
} from "./schema.zod";
export {
  buildMetadataFromSchema,
  type BuiltLandingMetadata,
} from "./metadata";
export { fetchLandingSchema, type FetchSchemaOpts } from "./fetch-schema";
export {
  createRevalidateHandler,
  type CreateRevalidateHandlerOptions,
  type RevalidateRequestBody,
} from "./createRevalidateHandler";
export type {
  LandingRegistry,
  LandingRendererProps,
  SectionAdapterProps,
  LandingKitHeroExtensions,
} from "./types";
