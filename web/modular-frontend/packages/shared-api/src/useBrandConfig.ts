'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPut } from './api';

// ── Types ────────────────────────────────────────────────────────

export interface BrandConfig {
  BrandConfigId?: number;
  CompanyId: number;
  LogoUrl: string;
  FaviconUrl: string;
  PrimaryColor: string;
  SecondaryColor: string;
  AccentColor: string;
  AppName: string;
  SupportEmail: string;
  SupportPhone: string;
  CustomDomain: string;
  CustomCss: string;
  FooterText: string;
  LoginBgUrl: string;
  IsActive: boolean;
}

export interface BrandConfigInput {
  logoUrl?: string;
  faviconUrl?: string;
  primaryColor?: string;
  secondaryColor?: string;
  accentColor?: string;
  appName?: string;
  supportEmail?: string;
  supportPhone?: string;
  customDomain?: string;
  customCss?: string;
  footerText?: string;
  loginBgUrl?: string;
  isActive?: boolean;
}

const QK = 'brand-config';

/**
 * Fetch brand config for the current tenant/company.
 * Cached with 60s staleTime (matches backend cache TTL).
 */
export function useBrandConfig(enabled = true) {
  return useQuery<BrandConfig>({
    queryKey: [QK],
    queryFn: () => apiGet('/v1/brand/config'),
    staleTime: 60_000,
    enabled,
  });
}

/**
 * Upsert brand config (admin).
 * Invalidates the cache on success.
 */
export function useSaveBrandConfig() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: BrandConfigInput) => apiPut('/v1/brand/config', input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK] });
    },
  });
}
