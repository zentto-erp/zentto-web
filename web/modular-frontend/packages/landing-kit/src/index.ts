/**
 * @zentto/landing-kit — componentes enterprise B2B SaaS portables.
 *
 * Uso:
 *   import {
 *     buildLandingTokens,
 *     SectionShell, CTAButton, TrustBar,
 *     FeatureGrid, HowItWorksSection, PricingSection,
 *     TestimonialsSection, CTAFinal,
 *     LandingHeader, LandingFooter,
 *   } from "@zentto/landing-kit";
 *
 *   const tokens = buildLandingTokens("hotel"); // tickets, medical, restaurante, ...
 *   return <SectionShell tokens={tokens} ...>...</SectionShell>;
 */

// Tokens y builder
export {
  buildLandingTokens,
  LANDING_NEUTRALS,
  VERTICAL_BRANDS,
  LANDING_TYPE,
  LANDING_LEADING,
  LANDING_TRACKING,
  LANDING_RADIUS,
  LANDING_SHADOW,
  LANDING_MOTION,
  LANDING_SPACING,
  LANDING_CONTAINER,
} from "./tokens";
export type { LandingTokens, LandingVertical, VerticalBrand } from "./tokens";

// Types
export type {
  TrustLogo,
  FeatureItem,
  HowItWorksStep,
  PricingPlan,
  TestimonialItem,
  NavLink,
  LandingHeaderBrandingProps,
  SocialLink,
  FooterColumn,
} from "./types";

// Componentes
export { SectionShell } from "./components/SectionShell";
export type { SectionShellProps } from "./components/SectionShell";

export { CTAButton } from "./components/CTAButton";
export type { CTAButtonProps } from "./components/CTAButton";

export { TrustBar } from "./components/TrustBar";
export type { TrustBarProps } from "./components/TrustBar";

export { FeatureGrid } from "./components/FeatureGrid";
export type { FeatureGridProps } from "./components/FeatureGrid";

export { HowItWorksSection } from "./components/HowItWorksSection";
export type { HowItWorksSectionProps } from "./components/HowItWorksSection";

export { PricingSection } from "./components/PricingSection";
export type { PricingSectionProps } from "./components/PricingSection";

export { TestimonialsSection } from "./components/TestimonialsSection";
export type { TestimonialsSectionProps } from "./components/TestimonialsSection";

export { CTAFinal } from "./components/CTAFinal";
export type { CTAFinalProps } from "./components/CTAFinal";

export { LandingHeader } from "./components/LandingHeader";
export type { LandingHeaderProps } from "./components/LandingHeader";

export { LandingFooter } from "./components/LandingFooter";
export type { LandingFooterProps } from "./components/LandingFooter";

export { BlogTeaser } from "./components/BlogTeaser";
export type { BlogTeaserProps, BlogTeaserPost } from "./components/BlogTeaser";

// Metadata helpers (también disponible en @zentto/landing-kit/metadata)
export {
  buildLandingMetadata,
  buildLandingViewport,
  buildLandingRobots,
  buildLandingSitemap,
} from "./metadata";
export type {
  BuildLandingMetadataOptions,
  BuildLandingViewportOptions,
  BuildLandingRobotsOptions,
  BuildLandingSitemapOptions,
} from "./metadata";
