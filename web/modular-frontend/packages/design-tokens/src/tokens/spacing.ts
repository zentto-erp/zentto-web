import type { DesignTokens } from '../types';

/**
 * Tokens de layout / spacing semántico.
 *
 * `sectionGap` = separación entre secciones mayores de una vista (px).
 * `formGap`    = separación entre campos dentro de un formulario (px).
 * `chipGap`    = separación entre chips / badges (px).
 *
 * Consumidor MUI: `theme.spacing(gap / 8)` o pasarlo raw en `sx`.
 * Consumidor Tailwind: `--zentto-spacing-section-gap: 24px` →
 *                       `gap-[var(--zentto-spacing-section-gap)]`.
 */
export const layout: DesignTokens['layout'] = {
  sectionGap: 24,
  formGap: 16,
  chipGap: 6,
};
