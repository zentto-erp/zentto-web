'use client';

/**
 * DatqBox Payment Gateway — Shared React hooks (TanStack Query)
 *
 * Reusable across Shell, POS, Restaurante and any micro-frontend.
 * Consumes the `/v1/payments/*` API endpoints.
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost, apiPut, apiDelete } from './api';

// ═══════════════════════════════════════════════════════════
// Types (mirror of API types, lightweight for frontend)
// ═══════════════════════════════════════════════════════════

export interface PaymentMethod {
  id: number;
  code: string;
  name: string;
  category: string;
  countryCode: string | null;
  iconName: string | null;
  requiresGateway: boolean;
  isActive: boolean;
  sortOrder: number;
}

export interface PaymentProvider {
  id: number;
  code: string;
  name: string;
  countryCode: string | null;
  providerType: string;
  baseUrlSandbox: string | null;
  baseUrlProd: string | null;
  authType: string | null;
  docsUrl: string | null;
  logoUrl: string | null;
  isActive: boolean;
  capabilities?: ProviderCapability[];
  configFields?: ConfigField[];
}

export interface ProviderCapability {
  id: number;
  capability: string;
  paymentMethod: string | null;
  endpointPath: string | null;
  httpMethod: string;
  isActive: boolean;
}

export interface ConfigField {
  key: string;
  label: string;
  type: 'text' | 'password' | 'select' | 'boolean';
  required: boolean;
  options?: { value: string; label: string }[];
  placeholder?: string;
  helpText?: string;
}

export interface CompanyPaymentConfig {
  id: number;
  empresaId: number;
  sucursalId: number;
  countryCode: string;
  providerId: number;
  providerCode: string;
  providerName: string;
  environment: 'sandbox' | 'production';
  clientId: string | null;
  clientSecret: string | null;
  merchantId: string | null;
  terminalId: string | null;
  integratorId: string | null;
  certificatePath: string | null;
  extraConfig: Record<string, unknown> | null;
  autoCapture: boolean;
  allowRefunds: boolean;
  maxRefundDays: number;
  isActive: boolean;
}

export interface AcceptedPaymentMethod {
  id: number;
  empresaId: number;
  sucursalId: number;
  paymentMethodId: number;
  providerId: number | null;
  methodCode: string;
  methodName: string;
  methodCategory: string;
  iconName: string | null;
  providerCode: string | null;
  providerName: string | null;
  appliesToPOS: boolean;
  appliesToWeb: boolean;
  appliesToRestaurant: boolean;
  sortOrder: number;
  isActive: boolean;
}

export interface PaymentTransaction {
  id: number;
  transactionUUID: string;
  empresaId: number;
  sucursalId: number;
  sourceType: string;
  sourceId: number | null;
  sourceNumber: string | null;
  paymentMethodCode: string;
  currency: string;
  amount: number;
  trxType: string;
  status: string;
  gatewayTrxId: string | null;
  gatewayAuthCode: string | null;
  gatewayMessage: string | null;
  createdAt: string;
}

// ═══════════════════════════════════════════════════════════
// Query Keys
// ═══════════════════════════════════════════════════════════

const QK = {
  methods: ['payment-methods'],
  providers: ['payment-providers'],
  provider: (code: string) => ['payment-providers', code],
  plugins: ['payment-plugins'],
  config: (empresaId: number, sucursalId?: number) => ['payment-config', empresaId, sucursalId],
  accepted: (empresaId: number, sucursalId: number, channel?: string) => ['payment-accepted', empresaId, sucursalId, channel],
  transactions: (params: Record<string, unknown>) => ['payment-transactions', params],
};

// ═══════════════════════════════════════════════════════════
// Payment Methods (catálogo global)
// ═══════════════════════════════════════════════════════════

export function usePaymentMethods(countryCode?: string) {
  return useQuery({
    queryKey: [...QK.methods, countryCode],
    queryFn: () => apiGet('/v1/payments/methods', countryCode ? { countryCode } : undefined) as Promise<PaymentMethod[]>,
  });
}

// ═══════════════════════════════════════════════════════════
// Payment Providers
// ═══════════════════════════════════════════════════════════

export function usePaymentProviders(countryCode?: string) {
  return useQuery({
    queryKey: [...QK.providers, countryCode],
    queryFn: () => apiGet('/v1/payments/providers', countryCode ? { countryCode } : undefined) as Promise<PaymentProvider[]>,
  });
}

export function usePaymentProvider(code: string) {
  return useQuery({
    queryKey: QK.provider(code),
    queryFn: () => apiGet(`/v1/payments/providers/${code}`) as Promise<PaymentProvider>,
    enabled: !!code,
  });
}

export function usePaymentPlugins() {
  return useQuery({
    queryKey: QK.plugins,
    queryFn: () => apiGet('/v1/payments/plugins') as Promise<{ providerCode: string; fields: ConfigField[] }[]>,
  });
}

// ═══════════════════════════════════════════════════════════
// Company Payment Config (CRUD)
// ═══════════════════════════════════════════════════════════

export function useCompanyPaymentConfigs(empresaId: number, sucursalId?: number) {
  return useQuery({
    queryKey: QK.config(empresaId, sucursalId),
    queryFn: () => apiGet('/v1/payments/config', { empresaId, sucursalId }) as Promise<CompanyPaymentConfig[]>,
    enabled: empresaId > 0,
  });
}

export function useSaveCompanyPaymentConfig() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPost('/v1/payments/config', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payment-config'] }),
  });
}

export function useDeleteCompanyPaymentConfig() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/payments/config/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payment-config'] }),
  });
}

// ═══════════════════════════════════════════════════════════
// Accepted Payment Methods per Company
// ═══════════════════════════════════════════════════════════

export function useAcceptedPaymentMethods(empresaId: number, sucursalId: number, channel?: 'POS' | 'WEB' | 'RESTAURANT') {
  return useQuery({
    queryKey: QK.accepted(empresaId, sucursalId, channel),
    queryFn: () => apiGet('/v1/payments/accepted', { empresaId, sucursalId, channel }) as Promise<AcceptedPaymentMethod[]>,
    enabled: empresaId > 0,
  });
}

export function useSaveAcceptedPaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPost('/v1/payments/accepted', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payment-accepted'] }),
  });
}

export function useRemoveAcceptedPaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/payments/accepted/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payment-accepted'] }),
  });
}

// ═══════════════════════════════════════════════════════════
// Transactions (search / read)
// ═══════════════════════════════════════════════════════════

export function usePaymentTransactions(params: {
  empresaId: number;
  sucursalId?: number;
  providerCode?: string;
  sourceType?: string;
  status?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  limit?: number;
}) {
  return useQuery({
    queryKey: QK.transactions(params),
    queryFn: () => apiGet('/v1/payments/transactions', params as Record<string, unknown>) as Promise<{
      rows: PaymentTransaction[];
      total: number;
      page: number;
      limit: number;
    }>,
    enabled: params.empresaId > 0,
  });
}

// ═══════════════════════════════════════════════════════════
// Process Payment (mutation)
// ═══════════════════════════════════════════════════════════

export function useProcessPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPost('/v1/payments/process', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payment-transactions'] }),
  });
}
