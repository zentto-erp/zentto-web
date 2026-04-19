import type { DesignTokens } from '../types';

/**
 * Border radius scale — alineada con `MuiButton`/`MuiCard`/`MuiPaper` (12px).
 */
export const radius: DesignTokens['radius'] = {
  none: 0,
  sm: 4,
  md: 8,
  lg: 12,
  pill: 9999,
};

/**
 * Breakpoints — alineados con MUI `theme.breakpoints.values`.
 */
export const breakpoints: DesignTokens['breakpoints'] = {
  xs: 0,
  sm: 600,
  md: 600,
  lg: 1200,
  xl: 1536,
};
