import type { DesignTokens } from '../types';

/**
 * Sombras / elevaciones — armonizadas con `MuiCard` y `MuiPaper` actuales.
 */
export const elevation: DesignTokens['elevation'] = {
  0: 'none',
  1: '0 1px 2px rgba(0,0,0,0.04)',
  2: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
  3: '0 4px 6px rgba(0,0,0,0.07), 0 2px 4px rgba(0,0,0,0.05)',
  4: '0 10px 15px rgba(0,0,0,0.08), 0 4px 6px rgba(0,0,0,0.05)',
};

/**
 * Z-index base — alineado con MUI default z-index scale.
 */
export const zIndex: DesignTokens['zIndex'] = {
  base: 0,
  dropdown: 1000,
  sticky: 1100,
  fixed: 1200,
  modalBackdrop: 1300,
  modal: 1400,
  popover: 1500,
  tooltip: 1600,
};
