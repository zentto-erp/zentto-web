'use client';
import { createTheme } from '@mui/material/styles';
import { red } from '@mui/material/colors';
import { esES as coreEsES } from '@mui/material/locale';

// @mui/x-data-grid theme augmentation and locale removed (legacy — migrated to native <zentto-grid>)

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
    }
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
          border: `1px solid ${brandColors.border}`,
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

