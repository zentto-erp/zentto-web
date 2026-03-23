'use client';
import { createTheme } from '@mui/material/styles';
import { red } from '@mui/material/colors';
import type { } from '@mui/x-data-grid/themeAugmentation';

/* ── Zentto Brand Colors (derivados del ecommerce) ── */
export const brandColors = {
  dark: '#131921',
  darkSecondary: '#232f3e',
  accent: '#ff9900',
  accentHover: '#e68a00',
  teal: '#007185',
  tealHover: '#005F6B',
  success: '#067D62',
  danger: '#cc0c39',
  cta: '#ffd814',
  ctaHover: '#f7ca00',
  border: '#e3e6e6',
  bgPage: '#eaeded',
  bgCard: '#ffffff',
  textDark: '#0f1111',
  textMuted: '#565959',
  link: '#007185',
  // Stats semantic colors
  statBlue: '#232f3e',
  statTeal: '#007185',
  statOrange: '#ff9900',
  statRed: '#cc0c39',
  // Shortcut backgrounds
  shortcutGreen: '#067D62',
  shortcutDark: '#232f3e',
  shortcutTeal: '#007185',
  shortcutSlate: '#37475a',
  shortcutNavy: '#131921',
  shortcutOrange: '#ff9900',
};

const theme = createTheme({
  cssVariables: {
    colorSchemeSelector: 'data-toolpad-color-scheme',
  },
  colorSchemes: {
    light: {
      palette: {
        primary: { main: '#ff9900', light: '#ffad33', dark: '#e68a00', contrastText: '#131921' },
        secondary: { main: '#232f3e', light: '#37475a', dark: '#131921', contrastText: '#fff' },
        error: { main: red.A400 },
        background: { default: '#eaeded', paper: '#FFFFFF' },
        text: { primary: '#0f1111', secondary: '#565959' },
      }
    },
    dark: {
      palette: {
        mode: 'dark',
        primary: { main: '#ff9900', light: '#ffad33', dark: '#e68a00', contrastText: '#131921' },
        secondary: { main: '#37475a', light: '#485769', dark: '#232f3e', contrastText: '#fff' },
        error: { main: red.A200 },
        background: { default: '#131921', paper: '#1a2332' },
        text: { primary: '#F9FAFB', secondary: '#9CA3AF' },
        divider: 'rgba(255, 255, 255, 0.12)',
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
          borderRadius: 20,
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
            color: 'var(--mui-palette-primary-main, #ff9900)',
          },
        },
      },
    },
    MuiTabs: {
      styleOverrides: {
        indicator: {
          backgroundColor: 'var(--mui-palette-primary-main, #ff9900)',
        },
      },
    },
    MuiDataGrid: {
      defaultProps: {
        density: 'compact',
        disableColumnMenu: false,
        showCellVerticalBorder: false,
        rowHeight: 40,
        columnHeaderHeight: 48,
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
          borderRadius: 8,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)',
          border: '1px solid #e3e6e6',
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
          borderRadius: 8,
        },
      },
    },
    // Inputs: size small global + padding 12px → altura ~46px uniforme (TextField, Select, DatePicker)
    // Label no-shrink reposicionado a translateY(13px) para centrar en el nuevo padding
    // Fondo blanco explícito en OutlinedInput para que DatePickers no hereden el gris de la página
    MuiFormControl: {
      defaultProps: { size: 'small', fullWidth: true },
    },
    MuiInputLabel: {
      defaultProps: { size: 'small' },
      styleOverrides: {
        outlined: {
          '&.MuiInputLabel-sizeSmall': {
            // Centrar label — alineado al padding MUI default 8.5px
            transform: 'translate(14px, 9px) scale(1)',
            '&.MuiInputLabel-shrink': {
              transform: 'translate(14px, -9px) scale(0.75)',
            },
          },
        },
      },
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
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 6,
            '& fieldset': {
              borderColor: 'var(--mui-palette-divider)',
            },
            '&:hover fieldset': {
              borderColor: 'var(--mui-palette-text-secondary)',
            },
            '&.Mui-focused fieldset': {
              borderColor: 'var(--mui-palette-primary-main)',
              borderWidth: '1px',
            },
          },
        },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 6,
          backgroundColor: 'var(--mui-palette-background-paper, #ffffff)',
        },
        input: {
          // Padding MUI default — misma altura que Select size="small"
          padding: '8.5px 14px',
        },
      },
    },
    // DatePicker — misma altura y estilo que TextField
    MuiPickersTextField: {
      defaultProps: { size: 'small', fullWidth: true },
    },
    // Autocomplete — misma altura que TextField (padding ajustado para el input interno)
    MuiAutocomplete: {
      defaultProps: { size: 'small', fullWidth: true },
      styleOverrides: {
        inputRoot: {
          padding: '3px 14px !important',
          '& .MuiOutlinedInput-input': {
            padding: '7px 0 !important',
          },
        },
      },
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
          boxShadow: '0 2px 8px rgba(255,153,0,0.3)',
        },
      },
    },
  },
});

export default theme;

