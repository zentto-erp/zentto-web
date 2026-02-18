'use client';
import { createTheme } from '@mui/material/styles';
import { red } from '@mui/material/colors';
import type {} from '@mui/x-data-grid/themeAugmentation';
/*import getMPTheme from './theme/getMPTheme';

const lightTheme = createTheme(getMPTheme('light'));
const darkTheme = createTheme(getMPTheme('dark'));

const theme = {
  light: lightTheme,
  dark: darkTheme,
};*/

const theme = createTheme({
  cssVariables: {
    colorSchemeSelector: 'data-toolpad-color-scheme',
  },
  colorSchemes: { light: true, dark: true },
  breakpoints: {
    values: {
      xs: 0,
      sm: 600,
      md: 600,
      lg: 1200,
      xl: 1536,
    },
  },
  palette: {
    primary: {
      main: '#aa1816', // Color principal de la marca (rojo)
      light: '#e04a48',
      dark: '#7a100e',
      contrastText: '#fff',
    },
    secondary: {
      main: '#d32f2f', // Color secundario
      light: '#ef5350',
      dark: '#c62828',
      contrastText: '#fff',
    },
    error: {
      main: red.A400,
    },
    background: {
      default: '#fafafa',
    },
  },
  typography: {
    fontFamily: [
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    button: {
      textTransform: 'none', // Evitar texto en mayúsculas en botones por defecto
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 4,
          textTransform: 'none',
        },
        contained: {
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
          '&.Mui-selected': {
            color: '#aa1816',
          },
        },
      },
    },
    MuiTabs: {
      styleOverrides: {
        indicator: {
          backgroundColor: '#aa1816',
        },
      },
    },
    MuiDataGrid: {
      defaultProps: {
        density: 'compact',
        disableColumnMenu: false,
        showCellVerticalBorder: false,
      },
      styleOverrides: {
        root: {
          border: 'none',
          borderRadius: 8,
          fontSize: '0.875rem',
          '& .MuiDataGrid-columnHeaders': {
            backgroundColor: '#f5f5f5',
            borderBottom: '1px solid #e0e0e0',
            fontWeight: 600,
          },
          '& .MuiDataGrid-cell': {
            borderBottom: '1px solid #f0f0f0',
          },
          '& .MuiDataGrid-row:hover': {
            backgroundColor: '#fafafa',
          },
          '& .MuiDataGrid-footerContainer': {
            borderTop: '1px solid #e0e0e0',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
          border: '1px solid #e8e8e8',
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
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 12,
        },
      },
    },
    MuiAlert: {
      styleOverrides: {
        root: {
          borderRadius: 8,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 6,
        },
      },
    },
    MuiTextField: {
      defaultProps: {
        variant: 'outlined',
      },
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 6,
            minHeight: 48,
            '&.Mui-focused fieldset': {
              borderColor: '#aa1816',
            },
            '&.MuiInputBase-sizeSmall': {
              minHeight: 42,
            },
          },
        },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          minHeight: 48,
          '&.MuiInputBase-sizeSmall': {
            minHeight: 42,
          },
        },
        input: {
          paddingTop: 13,
          paddingBottom: 13,
          '&.MuiInputBase-inputSizeSmall': {
            paddingTop: 10,
            paddingBottom: 10,
          },
        },
      },
    },
    MuiSelect: {
      defaultProps: {},
      styleOverrides: {
        select: {
          display: 'flex',
          alignItems: 'center',
        },
      },
    },
    MuiFormControl: {
      defaultProps: {},
    },
    MuiInputLabel: {
      styleOverrides: {
        root: {
          '&.MuiInputLabel-outlined': {
            transform: 'translate(14px, 14px) scale(1)',
          },
          '&.MuiInputLabel-outlined.MuiInputLabel-sizeSmall': {
            transform: 'translate(14px, 10px) scale(1)',
          },
          '&.MuiInputLabel-outlined.MuiInputLabel-shrink': {
            transform: 'translate(14px, -9px) scale(0.75)',
          },
        },
      },
    },
  },
});

export default theme;
