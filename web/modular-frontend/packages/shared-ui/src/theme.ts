'use client';
import { createTheme } from '@mui/material/styles';
import { red } from '@mui/material/colors';
import { esES as coreEsES } from '@mui/material/locale';
import { designTokens } from '@zentto/design-tokens';

// @mui/x-data-grid theme augmentation and locale removed (legacy — migrated to native <zentto-grid>)

/* ── Zentto Design Tokens v2 (semánticos, no-breaking) ───────────────────────
 *
 * Referencia: docs/wiki/design-audits/2026-04-19-crm.md §4.3.
 *
 * A partir de CRM-115 (ADR-NOTIFY-001 Opción C), los valores subyacentes
 * provienen del paquete neutral `@zentto/design-tokens`. Este archivo
 * re-exporta la misma API (`token`, `brandColors`, `ZenttoTokens`, etc.)
 * para mantener retrocompatibilidad con todos los consumidores.
 */

/** Lead lifecycle roles (mapean a MUI palette keys). */
export type LeadColorRole = 'open' | 'won' | 'lost';
/** Priority scale consolidada (CRM y otras apps). */
export type PriorityColorRole = 'urgent' | 'high' | 'medium' | 'low';
/** Density modes para `<zentto-grid>` / RecordTable. */
export type DensityMode = 'compact' | 'default' | 'comfortable';
/** Tipografía semántica estilo Material 3 / Primer. */
export type TypographyRole = 'display' | 'headline' | 'title' | 'body' | 'label';

export interface ZenttoTokens {
  layout: {
    /** Separación entre secciones mayores de una vista (px). */
    sectionGap: number;
    /** Separación entre campos dentro de un formulario (px). */
    formGap: number;
    /** Separación entre chips / badges (px). */
    chipGap: number;
  };
  density: {
    /** Alturas de fila del RecordTable por densidad (px). */
    rowHeight: Record<DensityMode, number>;
  };
  color: {
    /**
     * Roles para el ciclo de vida de un lead. Se resuelven con
     * `theme.palette[key].main` en runtime para respetar dark mode.
     */
    lead: Record<LeadColorRole, { paletteKey: 'primary' | 'success' | 'error' }>;
    /**
     * Roles de prioridad. Normalizan la escala `URGENT/HIGH/MEDIUM/LOW`
     * para que todos los componentes rendericen el mismo color por valor.
     */
    priority: Record<PriorityColorRole, { paletteKey: 'error' | 'warning' | 'info' | 'success' }>;
  };
  typography: {
    /**
     * Tabla de referencia de roles tipográficos. Los valores exactos viven
     * en `typography.h*` / `typography.body*` de MUI; este mapa documenta
     * la intención semántica y la correspondencia con variantes MUI.
     */
    roles: Record<TypographyRole, { variant: string; size: string; weight: number }>;
  };
}

/**
 * API pública — coincide exactamente con la v1 previa (tipos y forma). Los
 * valores se derivan ahora del paquete neutral `@zentto/design-tokens` para
 * habilitar consumo desde stacks Tailwind v4 (dashboard notify) sin duplicar
 * la fuente de verdad. Ver ADR-NOTIFY-001 Opción C.
 */
export const token: ZenttoTokens = {
  layout: { ...designTokens.layout },
  density: {
    rowHeight: { ...designTokens.density.rowHeight },
  },
  color: {
    lead: { ...designTokens.color.lead },
    priority: { ...designTokens.color.priority },
  },
  typography: {
    roles: {
      display: {
        variant: designTokens.typography.roles.display.variant,
        size: designTokens.typography.roles.display.size,
        weight: designTokens.typography.roles.display.weight,
      },
      headline: {
        variant: designTokens.typography.roles.headline.variant,
        size: designTokens.typography.roles.headline.size,
        weight: designTokens.typography.roles.headline.weight,
      },
      title: {
        variant: designTokens.typography.roles.title.variant,
        size: designTokens.typography.roles.title.size,
        weight: designTokens.typography.roles.title.weight,
      },
      body: {
        variant: designTokens.typography.roles.body.variant,
        size: designTokens.typography.roles.body.size,
        weight: designTokens.typography.roles.body.weight,
      },
      label: {
        variant: designTokens.typography.roles.label.variant,
        size: designTokens.typography.roles.label.size,
        weight: designTokens.typography.roles.label.weight,
      },
    },
  },
};

/* ── Zentto Brand Colors (derivados del ecommerce) ──
 *
 * Re-export de `designTokens.brand` con la misma forma que la v1, para
 * que consumidores como `brandColors.accent`, `brandColors.textDark`, etc.
 * sigan compilando sin cambios.
 */
export const brandColors = { ...designTokens.brand };

const baseThemeOptions = {
  cssVariables: {
    colorSchemeSelector: 'data-toolpad-color-scheme',
  },
  colorSchemes: {
    light: {
      palette: {
        primary: { main: brandColors.accent, light: '#ffc76a', dark: brandColors.accentHover, contrastText: brandColors.dark },
        secondary: { main: brandColors.darkSecondary, light: brandColors.shortcutSlate, dark: brandColors.dark, contrastText: '#fff' },
        error: { main: red.A400 },
        background: { default: brandColors.bgPage, paper: brandColors.bgCard },
        text: { primary: brandColors.textDark, secondary: brandColors.textMuted },
        divider: brandColors.border,
      }
    },
    dark: {
      palette: {
        mode: 'dark',
        primary: { main: brandColors.accent, light: '#ffc76a', dark: brandColors.accentHover, contrastText: brandColors.dark },
        secondary: { main: brandColors.shortcutSlate, light: '#485769', dark: brandColors.darkSecondary, contrastText: '#fff' },
        error: { main: red.A200 },
        background: { default: brandColors.dark, paper: brandColors.darkPaper },
        text: { primary: '#F9FAFB', secondary: '#9CA3AF' },
        divider: brandColors.borderDark,
      }
    }
  },
  breakpoints: {
    values: { xs: 0, sm: 600, md: 600, lg: 1200, xl: 1536 },
  },
  typography: {
    fontFamily: [
      'Inter',
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    button: {
      textTransform: 'none',
      fontWeight: 500,
    },
    h6: {
      fontWeight: 600,
      fontSize: '1.125rem',
    },
    // Roles semánticos (display/headline/title/body/label) — ver `token.typography.roles`.
    // Se mantienen los defaults existentes de MUI; documentados aquí para
    // referencia del design system (no breaking).
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none',
          },
        },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 500,
          '&.Mui-selected': {
            color: 'var(--mui-palette-primary-main, #FFB547)',
          },
        },
      },
    },
    MuiTabs: {
      styleOverrides: {
        indicator: {
          backgroundColor: 'var(--mui-palette-primary-main, #FFB547)',
        },
      },
    },
    MuiDataGrid: {
      defaultProps: {
        density: 'compact',
        disableColumnMenu: false,
        showCellVerticalBorder: false,
        rowHeight: 44,
        columnHeaderHeight: 48,
        localeText: {
          toolbarDensity: 'Tamaño',
          toolbarDensityLabel: 'Tamaño de fila',
          toolbarDensityCompact: 'Compacto',
          toolbarDensityStandard: 'Estándar',
          toolbarDensityComfortable: 'Grande',
        },
      },
      styleOverrides: {
        root: {
          border: 'none',
          borderRadius: 0,
          backgroundColor: 'transparent',
          fontSize: '0.875rem',
          '& .MuiDataGrid-columnHeaders': {
            backgroundColor: 'var(--mui-palette-background-paper)',
            borderBottom: '1px solid var(--mui-palette-divider)',
            fontWeight: 600,
            color: 'var(--mui-palette-text-primary)',
          },
          '& .MuiDataGrid-cell': {
            borderBottom: '1px solid var(--mui-palette-divider)',
            color: 'var(--mui-palette-text-secondary)',
          },
          '& .MuiDataGrid-row:hover': {
            backgroundColor: 'var(--mui-palette-action-hover)',
          },
          '& .MuiDataGrid-footerContainer': {
            borderTop: '1px solid var(--mui-palette-divider)',
            backgroundColor: 'var(--mui-palette-background-paper)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
          border: '1px solid var(--mui-palette-divider)',
          backgroundImage: 'none',
        },
      },
    },
    MuiCardHeader: {
      styleOverrides: {
        root: {
          paddingBottom: 0,
        },
        title: {
          fontSize: '1rem',
          fontWeight: 600,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          backgroundImage: 'none',
          border: '1px solid var(--mui-palette-divider)',
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          border: 'none',
        },
      },
    },
    MuiMenu: {
      styleOverrides: {
        paper: {
          border: 'none',
        },
      },
    },
    MuiPopover: {
      styleOverrides: {
        paper: {
          border: 'none',
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          borderRadius: 0,
        },
      },
    },
    // Inputs: defaults funcionales — sin sobreescribir estilos de MUI
    MuiFormControl: {
      defaultProps: { size: 'small', fullWidth: true },
    },
    MuiInputLabel: {
      defaultProps: { size: 'small' },
    },
    MuiSelect: {
      defaultProps: { size: 'small' },
    },
    MuiTextField: {
      defaultProps: {
        variant: 'outlined',
        size: 'small',
        fullWidth: true,
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        input: {
          // Ocultar spinners en inputs numéricos
          '&[type="number"]': {
            textAlign: 'left',
            MozAppearance: 'textfield',
          },
          '&[type="number"]::-webkit-outer-spin-button, &[type="number"]::-webkit-inner-spin-button': {
            WebkitAppearance: 'none',
            margin: 0,
          },
        },
      },
    },
    // DatePicker — misma altura y estilo que TextField
    MuiPickersTextField: {
      defaultProps: { size: 'medium', fullWidth: true },
    },
    MuiAutocomplete: {
      defaultProps: { size: 'medium', fullWidth: true },
    },
    MuiCheckbox: {
      defaultProps: { color: 'primary' },
    },
    MuiRadio: {
      defaultProps: { color: 'primary' },
    },
    MuiSwitch: {
      defaultProps: { color: 'primary' },
    },
    MuiFab: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 8px rgba(255,181,71,0.3)',
        },
      },
    },
  },
};

const theme = createTheme(baseThemeOptions as any, coreEsES);

export default theme;

/* ── Runtime branding: theme factory ── */

export interface BrandingColors {
  primaryColor: string;
  primaryDark: string;
  secondaryColor: string;
  secondaryDark: string;
  accentColor: string;
}

const DEFAULT_BRANDING: BrandingColors = {
  primaryColor: '#FFB547',
  primaryDark: '#e6a23e',
  secondaryColor: '#232f3e',
  secondaryDark: '#131921',
  accentColor: '#FFB547',
};

export { DEFAULT_BRANDING, baseThemeOptions };

/** Create a MUI theme with tenant-specific colors (runtime, no rebuild). */
export function createBrandedTheme(overrides: Partial<BrandingColors> = {}) {
  const b = { ...DEFAULT_BRANDING, ...overrides };
  const opts = structuredClone(baseThemeOptions) as typeof baseThemeOptions;
  // Light
  opts.colorSchemes.light.palette.primary = {
    main: b.primaryColor, light: b.primaryColor + '33', dark: b.primaryDark, contrastText: b.secondaryDark,
  };
  opts.colorSchemes.light.palette.secondary = {
    main: b.secondaryColor, light: b.secondaryColor + '1a', dark: b.secondaryDark, contrastText: '#fff',
  };
  // Dark
  opts.colorSchemes.dark.palette.primary = {
    main: b.primaryColor, light: b.primaryColor + '33', dark: b.primaryDark, contrastText: b.secondaryDark,
  };
  opts.colorSchemes.dark.palette.background = { default: '#131921', paper: '#12181f' };
  return createTheme(opts as any, coreEsES);
}

