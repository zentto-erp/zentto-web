'use client';

import React from 'react';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import BrandingProvider from '../providers/BrandingProvider';
import { useBranding } from '../hooks/useBranding';

/**
 * Inner component that reads branding context and provides the dynamic theme.
 * This must be a child of BrandingProvider so useBranding() works.
 */
function ThemedContent({ children, defaultMode }: { children: React.ReactNode; defaultMode?: 'light' | 'dark' | 'system' }) {
  const { theme } = useBranding();
  return (
    <ThemeProvider theme={theme} defaultMode={defaultMode}>
      <CssBaseline />
      {children}
    </ThemeProvider>
  );
}

/**
 * Drop-in replacement for <ThemeProvider theme={theme}>.
 * Loads tenant branding from API, generates dynamic MUI theme, and provides it.
 *
 * Usage in layout.tsx:
 *   <BrandedThemeProvider defaultMode="system">
 *     {children}
 *   </BrandedThemeProvider>
 */
export default function BrandedThemeProvider({
  children,
  defaultMode = 'system',
}: {
  children: React.ReactNode;
  defaultMode?: 'light' | 'dark' | 'system';
}) {
  return (
    <BrandingProvider>
      <ThemedContent defaultMode={defaultMode}>
        {children}
      </ThemedContent>
    </BrandingProvider>
  );
}
