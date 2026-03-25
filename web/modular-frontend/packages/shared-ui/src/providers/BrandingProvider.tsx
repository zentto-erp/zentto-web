'use client';

import React, { createContext, useMemo } from 'react';
import { useModuleSettings } from '@zentto/shared-api';
import { useAuthOptional } from '@zentto/shared-auth';
import { createBrandedTheme, DEFAULT_BRANDING, brandColors } from '../theme';
import type { BrandingColors } from '../theme';
import type { Theme } from '@mui/material/styles';

/* ── Full branding config (colors + logo + name) ── */
export interface BrandingConfig extends BrandingColors {
  logoUrl: string;
  appName: string;
  appSubtitle: string;
}

export interface BrandingContextValue {
  branding: BrandingConfig;
  /** Dynamic brand-colors object (same shape as static brandColors, overridden at runtime) */
  dynamicBrandColors: typeof brandColors;
  theme: Theme;
  isCustomized: boolean;
  isLoading: boolean;
}

const DEFAULTS: BrandingConfig = {
  ...DEFAULT_BRANDING,
  logoUrl: '',
  appName: '',
  appSubtitle: '',
};

export const BrandingContext = createContext<BrandingContextValue>({
  branding: DEFAULTS,
  dynamicBrandColors: brandColors,
  theme: createBrandedTheme(),
  isCustomized: false,
  isLoading: false,
});

export default function BrandingProvider({ children }: { children: React.ReactNode }) {
  const auth = useAuthOptional();
  const company = auth?.company;
  const companyId = company?.companyId ?? 0;
  const isAuthenticated = auth?.isAuthenticated ?? false;

  // No llamar a la API si no hay sesión — evita 401 loop en la página de login
  const { data: raw, isLoading } = useModuleSettings('branding', companyId || 1, isAuthenticated);

  const branding = useMemo<BrandingConfig>(() => {
    if (!raw || typeof raw !== 'object') return DEFAULTS;
    return {
      primaryColor: (raw.primaryColor as string) || DEFAULTS.primaryColor,
      primaryDark: (raw.primaryDark as string) || DEFAULTS.primaryDark,
      secondaryColor: (raw.secondaryColor as string) || DEFAULTS.secondaryColor,
      secondaryDark: (raw.secondaryDark as string) || DEFAULTS.secondaryDark,
      accentColor: (raw.accentColor as string) || DEFAULTS.accentColor,
      logoUrl: (raw.logoUrl as string) || '',
      appName: (raw.appName as string) || '',
      appSubtitle: (raw.appSubtitle as string) || '',
    };
  }, [raw]);

  const isCustomized = branding.primaryColor !== DEFAULTS.primaryColor
    || branding.secondaryColor !== DEFAULTS.secondaryColor
    || !!branding.logoUrl
    || !!branding.appName;

  const theme = useMemo(() => createBrandedTheme(branding), [branding]);

  const dynamicBrandColors = useMemo(() => ({
    ...brandColors,
    dark: branding.secondaryDark,
    darkSecondary: branding.secondaryColor,
    accent: branding.accentColor,
    accentHover: branding.primaryDark,
  }), [branding]);

  const value = useMemo<BrandingContextValue>(
    () => ({ branding, dynamicBrandColors, theme, isCustomized, isLoading }),
    [branding, dynamicBrandColors, theme, isCustomized, isLoading],
  );

  return (
    <BrandingContext.Provider value={value}>
      {children}
    </BrandingContext.Provider>
  );
}
