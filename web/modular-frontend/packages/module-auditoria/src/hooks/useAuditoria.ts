"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPut } from "@zentto/shared-api";

function unwrapPayload<T>(payload: T | { ok?: boolean; data?: T }): T {
  if (payload && typeof payload === 'object' && 'data' in (payload as Record<string, unknown>)) {
    return ((payload as { data?: T }).data ?? payload) as T;
  }
  return payload as T;
}

// ─── Query Keys ───────────────────────────────────
const QK_AUDIT_LOGS = "auditoria-logs";
const QK_AUDIT_DASHBOARD = "auditoria-dashboard";
const QK_FISCAL_RECORDS = "auditoria-fiscal-records";
const QK_FISCAL_CONFIG = "fiscal-config";
const QK_FISCAL_COUNTRIES = "fiscal-countries";

// ─── Types ────────────────────────────────────────
export interface AuditLogFilter {
  fechaDesde?: string;
  fechaHasta?: string;
  moduleName?: string;
  userName?: string;
  actionType?: string;
  entityName?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface AuditLogEntry {
  AuditLogId: number;
  CompanyId: number;
  BranchId: number;
  UserId: number | null;
  UserName: string | null;
  ModuleName: string;
  EntityName: string;
  EntityId: string | null;
  ActionType: string;
  Summary: string | null;
  OldValues: string | null;
  NewValues: string | null;
  IpAddress: string | null;
  CreatedAt: string;
}

export interface AuditDashboard {
  totalLogs: number;
  totalCreates: number;
  totalUpdates: number;
  totalDeletes: number;
  totalVoids: number;
  totalLogins: number;
  logsUltimas24h: number;
  ultimosLogs: AuditLogEntry[];
}

export interface FiscalRecordFilter {
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

// ─── Audit Logs ───────────────────────────────────
export function useAuditLogs(filter?: AuditLogFilter) {
  return useQuery({
    queryKey: [QK_AUDIT_LOGS, filter],
    queryFn: () => apiGet("/v1/auditoria/logs", filter as any),
  });
}

export function useAuditLogDetail(id: number | null) {
  return useQuery({
    queryKey: [QK_AUDIT_LOGS, "detail", id],
    queryFn: () => apiGet(`/v1/auditoria/logs/${id}`),
    enabled: id != null,
  });
}

// ─── Dashboard ────────────────────────────────────
export function useAuditDashboard(fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery({
    queryKey: [QK_AUDIT_DASHBOARD, fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/auditoria/dashboard", { fechaDesde, fechaHasta }),
    enabled,
  });
}

// ─── Fiscal Records ───────────────────────────────
export function useFiscalRecords(filter?: FiscalRecordFilter) {
  return useQuery({
    queryKey: [QK_FISCAL_RECORDS, filter],
    queryFn: () => apiGet("/v1/auditoria/fiscal-records", filter as any),
  });
}

// ─── Fiscal Config (existing API) ─────────────────
export function useFiscalConfig(params?: { empresaId?: number; sucursalId?: number; countryCode?: string }) {
  return useQuery({
    queryKey: [QK_FISCAL_CONFIG, params],
    queryFn: async () => unwrapPayload(await apiGet("/v1/fiscal/config", params as any)),
  });
}

export function useSaveFiscalConfig() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: Record<string, any>) => apiPut("/v1/fiscal/config", payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_FISCAL_CONFIG] }),
  });
}

// ─── Fiscal Countries ─────────────────────────────
export function useFiscalCountries() {
  return useQuery({
    queryKey: [QK_FISCAL_COUNTRIES],
    queryFn: async () => unwrapPayload(await apiGet("/v1/fiscal/countries")),
    staleTime: 5 * 60 * 1000,
  });
}

export function useFiscalCountryProfile(code: string | null) {
  return useQuery({
    queryKey: [QK_FISCAL_COUNTRIES, "profile", code],
    queryFn: async () => unwrapPayload(await apiGet(`/v1/fiscal/countries/${code}`)),
    enabled: !!code,
  });
}

export function useFiscalTaxRates(code: string | null) {
  return useQuery({
    queryKey: [QK_FISCAL_COUNTRIES, "tax-rates", code],
    queryFn: async () => unwrapPayload(await apiGet(`/v1/fiscal/countries/${code}/tax-rates`)),
    enabled: !!code,
  });
}

export function useFiscalInvoiceTypes(code: string | null) {
  return useQuery({
    queryKey: [QK_FISCAL_COUNTRIES, "invoice-types", code],
    queryFn: async () => unwrapPayload(await apiGet(`/v1/fiscal/countries/${code}/invoice-types`)),
    enabled: !!code,
  });
}
