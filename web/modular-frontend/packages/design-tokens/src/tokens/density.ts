import type { DesignTokens } from '../types';

/**
 * Densidad visual — altura de filas para `<zentto-grid>` / RecordTable.
 *
 * Usado por `DensityToggle` de `@zentto/shared-ui`. `columnHeaderHeight`
 * queda fijo (48) porque el toggle de densidad solo afecta a las filas
 * para mantener el header legible.
 */
export const density: DesignTokens['density'] = {
  rowHeight: {
    compact: 28,
    default: 36,
    comfortable: 46,
  },
  columnHeaderHeight: 48,
};
