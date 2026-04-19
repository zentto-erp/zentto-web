"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiDelete } from "@zentto/shared-api";

export interface ProviderDescriptor {
  code: string;
  name: string;
  providerType: string;
  category: string[];
  countries: string[];
  supportedCurrencies: string[];
  capabilities: string[];
  logoUrl?: string;
  docsUrl?: string;
}

export interface ConfigField {
  key: string;
  label: string;
  type: "text" | "password" | "email" | "url" | "select" | "number" | "boolean" | "json" | "file";
  required: boolean;
  placeholder?: string;
  helpText?: string;
  options?: { value: string; label: string }[];
  defaultValue?: string | number | boolean;
  sensitive?: boolean;
}

export interface PaymentAccount {
  accountId: number;
  companyId: number;
  ownerApp: string;
  providerCode: string;
  environment: string;
  countryCode: string | null;
  displayName: string | null;
  isDefault: boolean;
  isActive: boolean;
  hasCredentials: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateAccountInput {
  providerCode: string;
  environment: "sandbox" | "production";
  countryCode?: string;
  displayName?: string;
  credentials: Record<string, string>;
  extraConfig?: Record<string, unknown>;
  isDefault?: boolean;
}

export function usePaymentProviders(filters?: { country?: string; capability?: string; category?: string }) {
  const qs = new URLSearchParams(filters as Record<string, string> | undefined).toString();
  return useQuery({
    queryKey: ["payment-providers", filters],
    queryFn: () => apiGet(`/v1/payment-accounts/providers${qs ? `?${qs}` : ""}`) as Promise<{ providers: ProviderDescriptor[] }>,
    staleTime: 5 * 60_000,
  });
}

export function usePaymentProviderConfig(providerCode: string | null) {
  return useQuery({
    queryKey: ["payment-provider-config", providerCode],
    queryFn: () => apiGet(
      `/v1/payment-accounts/providers/${providerCode}/config`
    ) as Promise<{ code: string; name: string; fields: ConfigField[] }>,
    enabled: Boolean(providerCode),
  });
}

export function usePaymentAccounts() {
  return useQuery({
    queryKey: ["payment-accounts"],
    queryFn: () => apiGet(`/v1/payment-accounts`) as Promise<{ accounts: PaymentAccount[] }>,
  });
}

export function usePaymentAccountPreview(accountId: number | null) {
  return useQuery({
    queryKey: ["payment-account-preview", accountId],
    queryFn: () => apiGet(`/v1/payment-accounts/${accountId}/preview`) as Promise<{ accountId: number; preview: Record<string, string> }>,
    enabled: Boolean(accountId),
  });
}

export function useUpsertPaymentAccount() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateAccountInput) => apiPost(`/v1/payment-accounts`, input) as Promise<{ accountId: number }>,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["payment-accounts"] }),
  });
}

export function useDeletePaymentAccount() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (accountId: number) => apiDelete(`/v1/payment-accounts/${accountId}`) as Promise<{ deactivated: boolean }>,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["payment-accounts"] }),
  });
}

// ─── Cobros Online ───────────────────────────────────────────────────

export interface PaymentTransaction {
  TransactionId: string;
  Provider: string;
  ProviderTxnId: string;
  OwnerApp: string;
  CompanyId: number | null;
  Amount: number;
  Currency: string;
  CustomerEmail: string | null;
  CustomerName: string | null;
  Status: "pending" | "processing" | "paid" | "failed" | "cancelled" | "refunded" | "expired";
  CallbackUrl: string;
  Metadata: Record<string, unknown> | null;
  CheckoutUrl: string | null;
  CreatedAt: string;
  UpdatedAt: string;
  PaidAt: string | null;
}

export interface TransactionsFilters {
  status?: string;
  provider?: string;
  customerEmail?: string;
  from?: string;
  to?: string;
  limit?: number;
  offset?: number;
}

export function usePaymentTransactions(filters: TransactionsFilters = {}) {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(filters)) {
    if (v !== undefined && v !== null && v !== "") qs.set(k, String(v));
  }
  const qsStr = qs.toString();
  return useQuery({
    queryKey: ["payment-transactions", filters],
    queryFn: () => apiGet(`/v1/payment-accounts/transactions${qsStr ? `?${qsStr}` : ""}`) as Promise<{ rows: PaymentTransaction[]; total: number }>,
    staleTime: 30_000,
  });
}

export interface DashboardSummary {
  totalTransactions: number;
  totalPaid: number;
  totalPending: number;
  totalFailed: number;
  amountPaidByMonth: Array<{ month: string; amount: number; currency: string; count: number }>;
  amountByProvider: Array<{ provider: string; amount: number; count: number }>;
  amountByApp: Array<{ ownerApp: string; amount: number; count: number }>;
  recentTransactions: PaymentTransaction[];
}

export function usePaymentsDashboard(filters: { from?: string; to?: string } = {}) {
  const qs = new URLSearchParams();
  if (filters.from) qs.set("from", filters.from);
  if (filters.to) qs.set("to", filters.to);
  const qsStr = qs.toString();
  return useQuery({
    queryKey: ["payments-dashboard", filters],
    queryFn: () => apiGet(`/v1/payment-accounts/dashboard${qsStr ? `?${qsStr}` : ""}`) as Promise<DashboardSummary>,
    staleTime: 60_000,
  });
}
