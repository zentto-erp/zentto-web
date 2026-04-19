/**
 * Zentto Design Tokens — type surface.
 *
 * These types describe the canonical design token schema consumed by both
 * MUI (`ThemeProvider`) and Tailwind v4 (`@theme`). See the root `index.ts`
 * for the exported values.
 */

/** Lead lifecycle role (CRM). */
export type LeadColorRole = 'open' | 'won' | 'lost';

/** Priority role — used across CRM, tickets, notifications. */
export type PriorityColorRole = 'urgent' | 'high' | 'medium' | 'low';

/** Density modes for grids / RecordTable. */
export type DensityMode = 'compact' | 'default' | 'comfortable';

/** Semantic typography roles (Material 3 / Primer inspired). */
export type TypographyRole =
  | 'display'
  | 'headline'
  | 'title'
  | 'body'
  | 'label';

/** Palette role mapped to MUI palette keys. */
export type PaletteRoleKey =
  | 'primary'
  | 'secondary'
  | 'success'
  | 'warning'
  | 'error'
  | 'info';

/** A color scale for light / dark color schemes. */
export interface ColorScheme {
  /** Page background. */
  background: string;
  /** Raised surface (card / paper). */
  surface: string;
  /** Default text color. */
  text: string;
  /** Secondary / muted text. */
  textSecondary: string;
  /** Divider / border. */
  divider: string;
}

/** Palette role with the four shades MUI expects. */
export interface PaletteRole {
  main: string;
  light: string;
  dark: string;
  contrastText: string;
}

/** Palette grouped by color scheme (light/dark). */
export interface SchemePalette extends Record<PaletteRoleKey, PaletteRole> {
  scheme: ColorScheme;
}

/** Full set of Zentto tokens. */
export interface DesignTokens {
  /** Brand palette (derived from the ecommerce brand). */
  brand: {
    dark: string;
    darkDeep: string;
    darkPaper: string;
    darkSecondary: string;
    accent: string;
    accentHover: string;
    indigo: string;
    indigoHover: string;
    heroBackground: string;
    teal: string;
    tealHover: string;
    success: string;
    danger: string;
    cta: string;
    ctaHover: string;
    border: string;
    borderDark: string;
    bgPage: string;
    bgCard: string;
    textDark: string;
    textMuted: string;
    link: string;
    statBlue: string;
    statTeal: string;
    statOrange: string;
    statRed: string;
    shortcutGreen: string;
    shortcutDark: string;
    shortcutTeal: string;
    shortcutSlate: string;
    shortcutNavy: string;
    shortcutOrange: string;
    shortcutViolet: string;
  };
  color: {
    /** Resolved role colors for the light scheme. */
    light: SchemePalette;
    /** Resolved role colors for the dark scheme. */
    dark: SchemePalette;
    /** Lead lifecycle → palette key. */
    lead: Record<LeadColorRole, { paletteKey: 'primary' | 'success' | 'error' }>;
    /** Priority → palette key. */
    priority: Record<PriorityColorRole, { paletteKey: 'error' | 'warning' | 'info' | 'success' }>;
  };
  layout: {
    /** Separación entre secciones mayores de una vista (px). */
    sectionGap: number;
    /** Separación entre campos dentro de un formulario (px). */
    formGap: number;
    /** Separación entre chips / badges (px). */
    chipGap: number;
  };
  density: {
    rowHeight: Record<DensityMode, number>;
    columnHeaderHeight: number;
  };
  typography: {
    fontFamily: string;
    roles: Record<
      TypographyRole,
      { variant: string; size: string; weight: number; lineHeight: string }
    >;
  };
  radius: {
    none: number;
    sm: number;
    md: number;
    lg: number;
    pill: number;
  };
  elevation: {
    0: string;
    1: string;
    2: string;
    3: string;
    4: string;
  };
  zIndex: {
    base: number;
    dropdown: number;
    sticky: number;
    fixed: number;
    modalBackdrop: number;
    modal: number;
    popover: number;
    tooltip: number;
  };
  breakpoints: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
  };
}
