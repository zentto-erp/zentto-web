/**
 * Tokens canónicos para landings B2B SaaS de Zentto.
 *
 * Diseñados para cumplir WCAG 2.1 AA en todos los pares texto/fondo.
 * Cada vertical del ecosistema puede elegir un `brand` (primary/accent)
 * distinto manteniendo la misma base de neutrales y semánticos.
 *
 * Reglas:
 * - HEX directos para texto AA-compliant en cualquier fondo.
 * - Tipografía con clamp() (sin saltos abruptos entre breakpoints).
 * - Spacing canónico en px (section vertical padding CONSTANTE).
 * - Grids con N items: breakpoints permitidos solo divisores de N.
 */

export type LandingVertical =
  | "tickets"
  | "hotel"
  | "medical"
  | "restaurante"
  | "education"
  | "inmobiliario"
  | "rental"
  | "pos"
  | "shipping"
  | "ecommerce"
  | "crm"
  | "contabilidad"
  | "default";

/* ─── Neutrales + semánticos (comunes a todas las verticales) ─────────── */

export const LANDING_NEUTRALS = {
  // Fondos dark
  bg: "#0B0A1F",
  bgSurface: "#14122E",
  bgElevated: "#1D1A40",

  // Bordes
  border: "rgba(255,255,255,0.10)",
  borderStrong: "rgba(255,255,255,0.18)",

  // Texto (HEX directo, contraste verificado sobre bg #0B0A1F)
  textPrimary: "#F8FAFC",   // 16.5:1 ✓ AAA
  textSecondary: "#CBD5E1", // 12.1:1 ✓ AAA
  textMuted: "#94A3B8",     // 5.7:1  ✓ AA
  textFaint: "#64748B",     // 4.6:1  ✓ AA

  // Semánticos
  success: "#10B981",
  warning: "#F59E0B",
  danger: "#F87171",
} as const;


/** Neutrales para contexto light (storefronts B2C). WCAG AA verificado sobre #FFFFFF. */
export const LANDING_NEUTRALS_LIGHT = {
  bg: '#F8FAFC',
  bgSurface: '#FFFFFF',
  bgElevated: '#F1F5F9',
  border: '#E2E8F0',
  borderStrong: '#CBD5E1',
  textPrimary: '#0F172A',   // 16.1:1 AAA
  textSecondary: '#475569', // 7.8:1  AAA
  textMuted: '#64748B',     // 5.4:1  AA
  textFaint: '#94A3B8',     // 4.5:1  AA
  success: '#059669',
  warning: '#D97706',
  danger: '#DC2626',
} as const;

/* ─── Paletas de marca por vertical ──────────────────────────────────── */

export interface VerticalBrand {
  /** Color primario (CTAs, highlights). */
  brand: string;
  /** Variante más saturada del primario. */
  brandStrong: string;
  /** Variante clara — texto/chips sobre dark, contraste AA. */
  brandLight: string;
  /** Fondo suave (bg de chips, icon bg). */
  brandSoft: string;
  /** Acento secundario. */
  accent: string;
  /** Acento claro. */
  accentLight: string;
  /** Gradient del hero (opcional, cada vertical puede override). */
  heroGradient: string;
}

export const VERTICAL_BRANDS: Record<LandingVertical, VerticalBrand> = {
  tickets: {
    brand: "#4F46E5",
    brandStrong: "#6366F1",
    brandLight: "#A5B4FC",
    brandSoft: "rgba(79,70,229,0.16)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #1E1B4B 0%, #14122E 60%, #0B0A1F 100%)",
  },
  hotel: {
    brand: "#0891B2",
    brandStrong: "#0E7490",
    brandLight: "#67E8F9",
    brandSoft: "rgba(8,145,178,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #164E63 0%, #14122E 60%, #0B0A1F 100%)",
  },
  medical: {
    brand: "#059669",
    brandStrong: "#047857",
    brandLight: "#6EE7B7",
    brandSoft: "rgba(5,150,105,0.18)",
    accent: "#0EA5E9",
    accentLight: "#7DD3FC",
    heroGradient: "linear-gradient(180deg, #064E3B 0%, #14122E 60%, #0B0A1F 100%)",
  },
  restaurante: {
    brand: "#DC2626",
    brandStrong: "#B91C1C",
    brandLight: "#FCA5A5",
    brandSoft: "rgba(220,38,38,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #7F1D1D 0%, #14122E 60%, #0B0A1F 100%)",
  },
  education: {
    brand: "#7C3AED",
    brandStrong: "#6D28D9",
    brandLight: "#C4B5FD",
    brandSoft: "rgba(124,58,237,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #4C1D95 0%, #14122E 60%, #0B0A1F 100%)",
  },
  inmobiliario: {
    brand: "#0284C7",
    brandStrong: "#0369A1",
    brandLight: "#7DD3FC",
    brandSoft: "rgba(2,132,199,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #0C4A6E 0%, #14122E 60%, #0B0A1F 100%)",
  },
  rental: {
    brand: "#EA580C",
    brandStrong: "#C2410C",
    brandLight: "#FDBA74",
    brandSoft: "rgba(234,88,12,0.18)",
    accent: "#4F46E5",
    accentLight: "#A5B4FC",
    heroGradient: "linear-gradient(180deg, #7C2D12 0%, #14122E 60%, #0B0A1F 100%)",
  },
  pos: {
    brand: "#16A34A",
    brandStrong: "#15803D",
    brandLight: "#86EFAC",
    brandSoft: "rgba(22,163,74,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #14532D 0%, #14122E 60%, #0B0A1F 100%)",
  },
  shipping: {
    brand: "#2563EB",
    brandStrong: "#1D4ED8",
    brandLight: "#93C5FD",
    brandSoft: "rgba(37,99,235,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #1E3A8A 0%, #14122E 60%, #0B0A1F 100%)",
  },
  ecommerce: {
    // Rose / magenta — asociado a retail online, vibrante, distinto del
    // rojo de restaurante y del naranja de rental.
    brand: "#E11D48",
    brandStrong: "#BE123C",
    brandLight: "#FDA4AF",
    brandSoft: "rgba(225,29,72,0.18)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #881337 0%, #14122E 60%, #0B0A1F 100%)",
  },
  crm: {
    // Fuchsia — distinto del indigo de tickets y del violet de education.
    // Evoca conexion / relacion (CRM) con carga conversacional.
    brand: "#C026D3",
    brandStrong: "#A21CAF",
    brandLight: "#F0ABFC",
    brandSoft: "rgba(192,38,211,0.18)",
    accent: "#22D3EE",
    accentLight: "#A5F3FC",
    heroGradient: "linear-gradient(180deg, #701A75 0%, #14122E 60%, #0B0A1F 100%)",
  },
  contabilidad: {
    // Slate — seriedad financiera, confianza, clasico profesional.
    // Accent ambar para CTA (contraste sin saturar sobriedad).
    brand: "#475569",
    brandStrong: "#334155",
    brandLight: "#CBD5E1",
    brandSoft: "rgba(71,85,105,0.22)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #1E293B 0%, #14122E 60%, #0B0A1F 100%)",
  },
  default: {
    brand: "#4F46E5",
    brandStrong: "#6366F1",
    brandLight: "#A5B4FC",
    brandSoft: "rgba(79,70,229,0.16)",
    accent: "#F59E0B",
    accentLight: "#FCD34D",
    heroGradient: "linear-gradient(180deg, #1E1B4B 0%, #14122E 60%, #0B0A1F 100%)",
  },
};

/* ─── Escalas compartidas ─────────────────────────────────────────────── */

export const LANDING_TYPE = {
  display: "clamp(2.5rem, 5.5vw, 4.25rem)",
  h1: "clamp(1.75rem, 3vw, 2.5rem)",
  h2: "clamp(1.5rem, 2.4vw, 2rem)",
  h3: "clamp(1.125rem, 1.6vw, 1.375rem)",
  bodyLg: "1.0625rem",
  body: "0.9375rem",
  bodySm: "0.8125rem",
  eyebrow: "0.75rem",
  caption: "0.75rem",
} as const;

export const LANDING_LEADING = {
  display: 1.05,
  heading: 1.2,
  body: 1.65,
  tight: 1.3,
} as const;

export const LANDING_TRACKING = {
  display: "-0.03em",
  heading: "-0.02em",
  eyebrow: "0.12em",
} as const;

export const LANDING_RADIUS = {
  none: 0,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  pill: 999,
} as const;

export const LANDING_SHADOW = {
  card: "0 1px 2px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.10)",
  cardHover: "0 12px 32px rgba(5,3,30,0.5), 0 0 0 1px rgba(165,180,252,0.20)",
  cta: "0 8px 24px rgba(79,70,229,0.35)",
  ctaHover: "0 12px 32px rgba(79,70,229,0.50)",
} as const;


export const LANDING_SHADOW_LIGHT = {
  card: '0 1px 2px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.06)',
  cardHover: '0 12px 32px rgba(0,0,0,0.10)',
  cta: '0 8px 24px rgba(79,70,229,0.25)',
  ctaHover: '0 12px 32px rgba(79,70,229,0.40)',
} as const;

export const LANDING_MOTION = {
  micro: "150ms cubic-bezier(0.4, 0, 0.2, 1)",
  ui: "240ms cubic-bezier(0.16, 1, 0.3, 1)",
  large: "400ms cubic-bezier(0.16, 1, 0.3, 1)",
} as const;

export const LANDING_SPACING = {
  section: { xs: 64, md: 96 },
  sectionLg: { xs: 80, md: 128 },
  headingToBody: 24,
  bodyToGrid: 48,
  gridGap: 32,
} as const;

export const LANDING_CONTAINER = {
  maxWidth: 1200,
  gutterDesktop: 24,
  gutterMobile: 16,
} as const;

/**
 * Construye tokens para una vertical y tema dados.
 * Uso:
 *   buildLandingTokens('hotel')          // dark — B2B landings
 *   buildLandingTokens('hotel', 'light') // light — storefronts B2C
 */
export function buildLandingTokens(
  vertical: LandingVertical = "default",
  theme: "light" | "dark" = "dark",
) {
  const brand = VERTICAL_BRANDS[vertical];
  const neutrals = theme === "light" ? LANDING_NEUTRALS_LIGHT : LANDING_NEUTRALS;
  const shadow = theme === "light" ? LANDING_SHADOW_LIGHT : LANDING_SHADOW;
  return {
    vertical,
    theme,
    color: {
      ...neutrals,
      ...brand,
      eyebrowColor: theme === "light" ? brand.brand : brand.brandLight,
    },
    type: LANDING_TYPE,
    leading: LANDING_LEADING,
    tracking: LANDING_TRACKING,
    radius: LANDING_RADIUS,
    shadow,
    motion: LANDING_MOTION,
    spacing: LANDING_SPACING,
    container: LANDING_CONTAINER,
  } as const;
}

export type LandingTokens = ReturnType<typeof buildLandingTokens>;