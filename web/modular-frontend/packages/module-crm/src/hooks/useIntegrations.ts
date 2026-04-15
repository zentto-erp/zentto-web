"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiDelete } from "@zentto/shared-api";

const QK_WEBHOOKS = "crm-webhooks";
const QK_PUBLIC_KEYS = "crm-public-keys";

// ── Webhooks ─────────────────────────────────────────────────────────────
export interface TenantWebhook {
  WebhookId: number;
  Url: string;
  Label: string;
  EventFilter: string;
  IsActive: boolean;
  ConsecutiveFailures: number;
  DisabledReason: string | null;
  LastDeliveredAt: string | null;
  CreatedAt: string;
}

export function useWebhooksList() {
  return useQuery({
    queryKey: [QK_WEBHOOKS],
    queryFn: async () => {
      const r = (await apiGet("/api/v1/crm/webhooks")) as { ok: boolean; webhooks: TenantWebhook[] };
      return r.webhooks ?? [];
    },
  });
}

export function useCreateWebhook() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: { url: string; label?: string; eventFilter?: string }) =>
      apiPost("/api/v1/crm/webhooks", input) as Promise<{
        ok: boolean;
        webhookId: number;
        secret: string;
        warning: string;
      }>,
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_WEBHOOKS] }),
  });
}

export function useRevokeWebhook() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (webhookId: number) => apiDelete(`/api/v1/crm/webhooks/${webhookId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_WEBHOOKS] }),
  });
}

// ── Public API Keys ──────────────────────────────────────────────────────
export interface PublicApiKey {
  KeyId: number;
  KeyPrefix: string;
  Label: string;
  Scopes: string;
  IsActive: boolean;
  LastUsedAt: string | null;
  ExpiresAt: string | null;
  CreatedAt: string;
}

export function usePublicKeysList() {
  return useQuery({
    queryKey: [QK_PUBLIC_KEYS],
    queryFn: async () => {
      const r = (await apiGet("/api/v1/crm/public-keys")) as { ok: boolean; keys: PublicApiKey[] };
      return r.keys ?? [];
    },
  });
}

export function useCreatePublicKey() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: { label: string; scopes?: string; expiresAt?: string }) =>
      apiPost("/api/v1/crm/public-keys", input) as Promise<{
        ok: boolean;
        keyId: number;
        key: string;
        keyPrefix: string;
        warning: string;
      }>,
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PUBLIC_KEYS] }),
  });
}

export function useRevokePublicKey() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (keyId: number) => apiDelete(`/api/v1/crm/public-keys/${keyId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PUBLIC_KEYS] }),
  });
}
