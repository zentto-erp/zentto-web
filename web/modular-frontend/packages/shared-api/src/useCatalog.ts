'use client';

import { useQuery, useMutation } from '@tanstack/react-query';
import { apiGet, apiPost, apiPublicGet, apiPublicPost } from './api';

// ─── Tipos ──────────────────────────────────────────────────────────────────

export interface PricingPlan {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: string;
  ProductCode: string;
  Description: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  BillingCycleDefault: 'monthly' | 'annual' | 'both';
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  ModuleCodes: string[];
  Limits: Record<string, number>;
  IsAddon: boolean;
  IsTrialOnly: boolean;
  TrialDays: number;
  SortOrder: number;
  PaddlePriceIdMonthly: string;
  PaddlePriceIdAnnual: string;
  PaddleSyncStatus: 'draft' | 'syncing' | 'synced' | 'error' | 'skip';
  IsActive: boolean;
}

export interface CatalogProduct {
  ProductCode: string;
  VerticalType: string;
  IsAddon: boolean;
  Plans: PricingPlan[];
}

export interface SubscriptionItem {
  SubscriptionItemId: number;
  PricingPlanId: number;
  PlanSlug: string;
  PlanName: string;
  ProductCode: string;
  VerticalType: string;
  IsAddon: boolean;
  Quantity: number;
  UnitPrice: number;
  BillingCycle: 'monthly' | 'annual';
  PaddleSubscriptionItemId: string;
  Status: string;
  AddedAt: string;
}

export interface SubscriptionSummary {
  SubscriptionId: number;
  CompanyId: number;
  Source: 'paddle' | 'trial' | 'manual';
  Status: 'trialing' | 'active' | 'past_due' | 'paused' | 'cancelled' | 'expired';
  PaddleSubscriptionId: string;
  PaddleCustomerId: string;
  CurrentPeriodStart: string | null;
  CurrentPeriodEnd: string | null;
  TrialEndsAt: string | null;
  CancelledAt: string | null;
  ItemsJson: SubscriptionItem[];
}

export interface Entitlements {
  CompanyId: number;
  ModuleCodes: string[];
  Plans: string[];
  ExpiresAt: string | null;
  IsActive: boolean;
}

// ─── Hooks de catálogo (públicos, sin auth) ─────────────────────────────────

export function useCatalogPlans(opts: { vertical?: string; product?: string; includeTrial?: boolean } = {}) {
  const params = new URLSearchParams();
  if (opts.vertical) params.set('vertical', opts.vertical);
  if (opts.product) params.set('product', opts.product);
  if (opts.includeTrial !== undefined) params.set('includeTrial', String(opts.includeTrial));
  const qs = params.toString();
  return useQuery<{ ok: boolean; plans: PricingPlan[] }>({
    queryKey: ['catalog', 'plans', opts],
    queryFn: () => apiPublicGet(`/v1/catalog/plans${qs ? `?${qs}` : ''}`),
    staleTime: 5 * 60 * 1000,
  });
}

export function useCatalogPlan(slug: string | undefined) {
  return useQuery<{ ok: boolean; plan: PricingPlan }>({
    queryKey: ['catalog', 'plan', slug],
    queryFn: () => apiPublicGet(`/v1/catalog/plans/${slug}`),
    enabled: Boolean(slug),
    staleTime: 5 * 60 * 1000,
  });
}

export function useCatalogProducts(vertical?: string) {
  const qs = vertical ? `?vertical=${vertical}` : '';
  return useQuery<{ ok: boolean; products: CatalogProduct[] }>({
    queryKey: ['catalog', 'products', vertical],
    queryFn: () => apiPublicGet(`/v1/catalog/products${qs}`),
    staleTime: 5 * 60 * 1000,
  });
}

export function useCheckSubdomain(slug: string) {
  return useQuery<{ ok: boolean; available: boolean; mensaje: string }>({
    queryKey: ['catalog', 'subdomain-check', slug],
    queryFn: () => apiPublicGet(`/v1/catalog/subdomain-check/${slug}`),
    enabled: slug.length >= 3,
    staleTime: 30 * 1000,
    retry: false,
  });
}

// ─── Hooks de registro (públicos) ────────────────────────────────────────────

export interface RegistroBody {
  email: string;
  fullName: string;
  companyName: string;
  countryCode: string;
  subdomain: string;
  planSlug: string;
  addonSlugs?: string[];
  utm?: { source?: string; medium?: string; campaign?: string };
  vertical?: string;
}

export function useStartTrial() {
  return useMutation<
    { ok: boolean; mensaje: string; companyId?: number; subdomain?: string; expiresAt?: string; magicLinkSent?: boolean },
    Error,
    RegistroBody
  >({
    mutationFn: (body) => apiPublicPost('/v1/registro/trial', body),
  });
}

export function useStartCheckout() {
  return useMutation<
    { ok: boolean; mensaje: string; transactionId?: string; checkoutUrl?: string },
    Error,
    RegistroBody & { billingCycle: 'monthly' | 'annual' }
  >({
    mutationFn: (body) => apiPublicPost('/v1/registro/checkout', body),
  });
}

export function useResendMagicLink() {
  return useMutation<
    { ok: boolean; mensaje: string; magicLinkSent?: boolean },
    Error,
    { email: string }
  >({
    mutationFn: (body) => apiPublicPost('/v1/registro/resend-magic-link', body),
  });
}

export function useCaptureLead() {
  return useMutation<
    { ok: boolean; leadId?: number },
    Error,
    Partial<RegistroBody> & { source?: string }
  >({
    mutationFn: (body) => apiPublicPost('/v1/registro/lead', body),
  });
}

// ─── Hooks de subscriptions (tenant autenticado) ────────────────────────────

export function useMySubscription() {
  return useQuery<{ ok: boolean; subscription: SubscriptionSummary | null }>({
    queryKey: ['subscriptions', 'me'],
    queryFn: () => apiGet('/v1/subscriptions/me'),
    staleTime: 60 * 1000,
  });
}

export function useMyEntitlements() {
  return useQuery<{ ok: boolean; entitlements: Entitlements }>({
    queryKey: ['subscriptions', 'entitlements'],
    queryFn: () => apiGet('/v1/subscriptions/entitlements'),
    staleTime: 60 * 1000,
  });
}

export function useAddSubscriptionItem() {
  return useMutation<
    { ok: boolean; mode?: string; mensaje?: string; transactionId?: string; checkoutUrl?: string },
    Error,
    { addonSlug: string; billingCycle?: 'monthly' | 'annual' }
  >({
    mutationFn: (body) => apiPost('/v1/subscriptions/items', body),
  });
}
