import type { DesignTokens } from '../types';

/**
 * Tipografía semántica (inspirada en Material 3 / Primer).
 *
 * `variant` coincide con la variante equivalente de MUI — esto permite
 * consumir `<Typography variant={token.typography.roles.title.variant}>`
 * sin perder los defaults de MUI.
 */
export const typography: DesignTokens['typography'] = {
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
  roles: {
    display: { variant: 'h4', size: '1.75rem', weight: 700, lineHeight: '2rem' },
    headline: { variant: 'h5', size: '1.25rem', weight: 700, lineHeight: '1.5rem' },
    title: { variant: 'h6', size: '1rem', weight: 600, lineHeight: '1.375rem' },
    body: { variant: 'body1', size: '0.875rem', weight: 400, lineHeight: '1.25rem' },
    label: { variant: 'caption', size: '0.75rem', weight: 600, lineHeight: '1rem' },
  },
};
