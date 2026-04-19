import type { DesignTokens } from '../types';

/**
 * Paleta de marca Zentto — derivada del ecommerce.
 * Fuente original: packages/shared-ui/src/theme.ts (pre-CRM-115).
 */
export const brand: DesignTokens['brand'] = {
  dark: '#131921',
  darkDeep: '#0f1419',
  darkPaper: '#12181f',
  darkSecondary: '#232f3e',
  accent: '#FFB547',
  accentHover: '#e6a23e',
  indigo: '#6C63FF',
  indigoHover: '#5b54e6',
  heroBackground: '#3b3699',
  teal: '#007185',
  tealHover: '#005F6B',
  success: '#067D62',
  danger: '#cc0c39',
  cta: '#ffd814',
  ctaHover: '#f7ca00',
  border: '#e3e6e6',
  borderDark: '#1f2937',
  bgPage: '#f9fafb',
  bgCard: '#ffffff',
  textDark: '#0f1111',
  textMuted: '#565959',
  link: '#007185',
  statBlue: '#232f3e',
  statTeal: '#007185',
  statOrange: '#FFB547',
  statRed: '#cc0c39',
  shortcutGreen: '#067D62',
  shortcutDark: '#232f3e',
  shortcutTeal: '#007185',
  shortcutSlate: '#37475a',
  shortcutNavy: '#131921',
  shortcutOrange: '#FFB547',
  shortcutViolet: '#6B3FA0',
};

/**
 * Escalas de color por esquema light/dark.
 *
 * Cada clave (primary, secondary, …) tiene `{ main, light, dark, contrastText }`
 * para que MUI lo consuma tal cual en `palette[role]`.
 *
 * `scheme` describe superficies generales (background/surface/text/…), usado
 * para generar CSS vars como `--zentto-color-background` que sirven al stack
 * Tailwind v4.
 */
export const color: DesignTokens['color'] = {
  light: {
    primary: {
      main: brand.accent,
      light: '#ffc76a',
      dark: brand.accentHover,
      contrastText: brand.dark,
    },
    secondary: {
      main: brand.darkSecondary,
      light: brand.shortcutSlate,
      dark: brand.dark,
      contrastText: '#ffffff',
    },
    success: {
      main: brand.success,
      light: '#2ea98c',
      dark: '#055a48',
      contrastText: '#ffffff',
    },
    warning: {
      main: brand.accent,
      light: '#ffc76a',
      dark: brand.accentHover,
      contrastText: brand.dark,
    },
    error: {
      main: brand.danger,
      light: '#e63b5a',
      dark: '#8c0a28',
      contrastText: '#ffffff',
    },
    info: {
      main: brand.teal,
      light: '#3296a8',
      dark: brand.tealHover,
      contrastText: '#ffffff',
    },
    scheme: {
      background: brand.bgPage,
      surface: brand.bgCard,
      text: brand.textDark,
      textSecondary: brand.textMuted,
      divider: brand.border,
    },
  },
  dark: {
    primary: {
      main: brand.accent,
      light: '#ffc76a',
      dark: brand.accentHover,
      contrastText: brand.dark,
    },
    secondary: {
      main: brand.shortcutSlate,
      light: '#485769',
      dark: brand.darkSecondary,
      contrastText: '#ffffff',
    },
    success: {
      main: '#2ea98c',
      light: '#4fc3a8',
      dark: brand.success,
      contrastText: brand.dark,
    },
    warning: {
      main: brand.accent,
      light: '#ffc76a',
      dark: brand.accentHover,
      contrastText: brand.dark,
    },
    error: {
      main: '#ff5370',
      light: '#ff7a91',
      dark: brand.danger,
      contrastText: '#ffffff',
    },
    info: {
      main: '#3296a8',
      light: '#5fb3c4',
      dark: brand.teal,
      contrastText: '#ffffff',
    },
    scheme: {
      background: brand.dark,
      surface: brand.darkPaper,
      text: '#F9FAFB',
      textSecondary: '#9CA3AF',
      divider: brand.borderDark,
    },
  },
  /**
   * Roles para el ciclo de vida de un lead — se resuelven con
   * `palette[paletteKey].main` en runtime para respetar el color scheme.
   */
  lead: {
    open: { paletteKey: 'primary' },
    won: { paletteKey: 'success' },
    lost: { paletteKey: 'error' },
  },
  /**
   * Prioridad normalizada a la escala `URGENT/HIGH/MEDIUM/LOW`.
   */
  priority: {
    urgent: { paletteKey: 'error' },
    high: { paletteKey: 'error' },
    medium: { paletteKey: 'warning' },
    low: { paletteKey: 'info' },
  },
};
