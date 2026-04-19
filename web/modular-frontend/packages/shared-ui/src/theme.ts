'use client';
import { createTheme } from '@mui/material/styles';
import { red } from '@mui/material/colors';
import { esES as coreEsES } from '@mui/material/locale';

// @mui/x-data-grid theme augmentation and locale removed (legacy — migrated to native <zentto-grid>)

/* ── Zentto Design Tokens v2 (semánticos, no-breaking) ───────────────────────
 *
 * Referencia: docs/wiki/design-audits/2026-04-19-crm.md §4.3.
 *
 * Estos tokens viven en paralelo a `theme.spacing` / `theme.palette` para
 * habilitar uso consistente entre módulos (CRM, hotel, medical, tickets…).
 * Consumirlos en componentes mediante `import { token } from '@zentto/shared-ui'`.
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

export const token: ZenttoTokens = {
  layout: {
    sectionGap: 24,
    formGap: 16,
    chipGap: 6,
  },
  density: {
    rowHeight: { compact: 28, default: 36, comfortable: 46 },
  },
  color: {
    lead: {
      open: { paletteKey: 'primary' },
      won: { paletteKey: 'success' },
      lost: { paletteKey: 'error' },
    },
    priority: {
      urgent: { paletteKey: 'error' },
      high: { paletteKey: 'error' },
      medium: { paletteKey: 'warning' },
      low: { paletteKey: 'info' },
    },
  },
  typography: {
    roles: {
      display: { variant: 'h4', size: '1.75rem', weight: 700 },   // 28 / 32 700
      headline: { variant: 'h5', size: '1.25rem', weight: 700 },  // 20 / 24 700
      title: { variant: 'h6', size: '1rem', weight: 600 },        // 16 / 22 600
      body: { variant: 'body1', size: '0.875rem', weight: 400 },  // 14 / 20 400
      label: { variant: 'caption', size: '0.75rem', weight: 600 },// 12 / 16 600
    },
  },
};

/* ── Zentto Brand Colors (derivados del ecommerce) ── */
export const brandColors = {
  // Core palette
  dark: '#131921',
  darkDeep: '#0f1419',
  darkPaper: '#12181f',
  darkSecondary: '#232f3e',
  accent: '#FFB547',
  accentHover: '#e6a23e',
  indigo: '#6C63FF',
  indigoHover: '#5b54e6',
  heroBackground: '#3b3699',
  // Functional
  teal: '#007185',
  tealHover: '#005F6B',
  success: '#067D62',
  danger: '#cc0c39',
  cta: '#ffd814',
  ctaHover: '#f7ca00',
  // Surfaces & borders
  border: '#e3e6e6',
  borderDark: '#1f2937',
  bgPage: '#f9fafb',
  bgCard: '#ffffff',
  // Text
  textDark: '#0f1111',
  textMuted: '#565959',
  link: '#007185',
  // Stats semantic colors
  statBlue: '#232f3e',
  statTeal: '#007185',
  statOrange: '#FFB547',
  statRed: '#cc0c39',
  // Shortcut backgrounds
  shortcutGreen: '#067D62',
  shortcutDark: '#232f3e',
  shortcutTeal: '#007185',
  shortcutSlate: '#37475a',
  shortcutNavy: '#131921',
  shortcutOrange: '#FFB547',
  shortcutViolet: '#6B3FA0',
};

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

