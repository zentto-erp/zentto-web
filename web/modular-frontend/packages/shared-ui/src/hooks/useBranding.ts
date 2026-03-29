'use client';

import { useContext } from 'react';
import { BrandingContext } from '../providers/BrandingProvider';
import type { BrandingContextValue } from '../providers/BrandingProvider';

/**
 * Access the tenant's runtime branding (colors, logo, app name).
 * Falls back to Zentto defaults if no customization is set.
 */
export function useBranding(): BrandingContextValue {
  return useContext(BrandingContext);
}
