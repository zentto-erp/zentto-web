/**
 * @zentto/design-tokens — source of truth for the Zentto design system.
 *
 * Consumido por:
 *   - MUI `@zentto/shared-ui` (ThemeProvider) → `designTokens.color.light.primary.main`, etc.
 *   - Tailwind v4 dashboards standalone (notify, futuros auditoria/cobros-online)
 *     → `@import '@zentto/design-tokens/css'` + `@theme`.
 *
 * Ver ADR-NOTIFY-001 Opción C.
 */

import { brand, color } from './tokens/color';
import { layout } from './tokens/spacing';
import { density } from './tokens/density';
import { typography } from './tokens/typography';
import { elevation, zIndex } from './tokens/elevation';
import { radius, breakpoints } from './tokens/radius';
import type { DesignTokens } from './types';

export const designTokens: DesignTokens = {
  brand,
  color,
  layout,
  density,
  typography,
  radius,
  elevation,
  zIndex,
  breakpoints,
};

export { tokensToCss } from './css';

export type {
  DesignTokens,
  LeadColorRole,
  PriorityColorRole,
  DensityMode,
  TypographyRole,
  PaletteRoleKey,
  PaletteRole,
  SchemePalette,
  ColorScheme,
} from './types';

// Re-export individual buckets para consumidores que solo necesitan uno.
export { brand, color } from './tokens/color';
export { layout } from './tokens/spacing';
export { density } from './tokens/density';
export { typography } from './tokens/typography';
export { elevation, zIndex } from './tokens/elevation';
export { radius, breakpoints } from './tokens/radius';

export default designTokens;
