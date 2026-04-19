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
