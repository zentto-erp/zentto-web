/**
 * Tipos públicos del landing-kit. Los catálogos (FEATURES, PRICING, etc.)
 * NO viven aquí — cada vertical define su propio catálogo con copy B2B
 * específico y lo pasa como prop a los componentes.
 */

import type { ReactNode } from "react";

export interface TrustLogo {
  name: string;
  /** Path absoluto a SVG monocromo en `/public/landing/clients/`. */
  src?: string;
  href?: string;
}

export interface FeatureItem {
  /** ReactNode renderizable (icono MUI, SVG, etc.). */
  icon: ReactNode;
  title: string;
  description: string;
  href?: string;
}

export interface HowItWorksStep {
  /** "01", "02", ... o número tal cual. */
  step: string;
  title: string;
  description: string;
}

export interface PricingPlan {
  name: string;
  /** "Gratis", "$49", "A medida". */
  price: string;
  /** "por mes", "para siempre", "contactar ventas". */
  period: string;
  description: string;
  bullets: string[];
  cta: string;
  /** Ruta interna o externa. */
  href: string;
  /** Plan destacado (scale 1.04 desktop + badge "Recomendado"). */
  highlight?: boolean;
  /** Si el CTA abre externa (target=_blank). */
  external?: boolean;
}

export interface TestimonialItem {
  quote: string;
  author: string;
  role: string;
  company: string;
  /** Uno solo puede ser featured → queda grande a la izquierda. */
  featured?: boolean;
}

export interface NavLink {
  label: string;
  href: string;
}

export interface LandingHeaderBrandingProps {
  /** Nombre mostrado: "Zentto <accent>{verticalName}</accent>". */
  verticalName: string;
  /** Icono de la marca (ConfirmationNumberIcon, HotelIcon, etc.). */
  logoIcon: ReactNode;
}

export interface SocialLink {
  label: string;
  icon: ReactNode;
  href: string;
}

export interface FooterColumn {
  title: string;
  links: Array<{
    label: string;
    href: string;
    external?: boolean;
  }>;
}
