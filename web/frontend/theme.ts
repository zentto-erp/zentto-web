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
      styleOverrides: {
        root: {
          border: 'none',
          '& .MuiDataGrid-columnHeaders': {
            backgroundColor: '#f5f5f5',
            borderBottom: '1px solid #e0e0e0',
          },
          '& .MuiDataGrid-cell': {
            borderBottom: '1px solid #f0f0f0',
          },
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 8,
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
    MuiSelect: {
      styleOverrides: {
        select: {
          display: 'flex',
          alignItems: 'center',
        },
      },
    },
  },
});

export default theme;
