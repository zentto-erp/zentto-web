"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

// ─── Query Keys ──────────────────────────────────────────────
const QK_INFLACION = "contabilidad-inflacion";
const QK_CLASIFICACION = "contabilidad-clasificacion-monetaria";
const QK_PLANTILLAS = "contabilidad-plantillas";
const QK_PATRIMONIO = "contabilidad-patrimonio";
const QK_REPORTE_LEGAL = "contabilidad-reporte-legal";

// ─── Types ───────────────────────────────────────────────────

export interface InflationIndex {
  InflationIndexId: number;
  CountryCode: string;
  IndexName: string;
  PeriodCode: string;
  IndexValue: number;
  SourceReference?: string;
}

export interface MonetaryClassification {
  AccountMonetaryClassId: number;
  AccountId: number;
  AccountCode: string;
  AccountName: string;
  AccountType: string;
  Classification: "MONETARY" | "NON_MONETARY";
  SubClassification?: string;
  ReexpressionAccountId?: number;
}

export interface ReportTemplate {
  ReportTemplateId: number;
  CountryCode: string;
  ReportCode: string;
  ReportName: string;
  LegalFramework: string;
  LegalReference?: string;
  TemplateContent?: string;
  HeaderJson?: string;
  FooterJson?: string;
  IsDefault: boolean;
  Version: number;
}

export interface EquityMovement {
  EquityMovementId: number;
  AccountId: number;
  AccountCode: string;
  AccountName: string;
  MovementType: string;
  MovementDate: string;
  Amount: number;
  JournalEntryId?: number;
  Description?: string;
}

export interface EquityMovementInput {
  fiscalYear: number;
  accountCode: string;
  movementType: string;
  movementDate: string;
  amount: number;
  journalEntryId?: number;
  description?: string;
}

// ─── Inflación: Indices INPC ─────────────────────────────────

export function useInflationIndices(countryCode = "VE", yearFrom?: number, yearTo?: number) {
  return useQuery<any>({
    queryKey: [QK_INFLACION, "indices", countryCode, yearFrom, yearTo],
    queryFn: () => apiGet("/v1/contabilidad/inflacion/indices", { countryCode, yearFrom, yearTo }),
  });
}

export function useUpsertInflationIndex() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { countryCode: string; indexName: string; periodCode: string; indexValue: number; sourceReference?: string }) =>
      apiPost("/v1/contabilidad/inflacion/indices", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_INFLACION] }),
  });
}

export function useBulkLoadIndices() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { countryCode: string; indexName: string; xmlData: string }) =>
      apiPost("/v1/contabilidad/inflacion/indices/bulk", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_INFLACION] }),
  });
}

// ─── Inflación: Clasificación Monetaria ──────────────────────

export function useMonetaryClassifications(classification?: string, search?: string) {
  return useQuery<any>({
    queryKey: [QK_CLASIFICACION, classification, search],
    queryFn: () => apiGet("/v1/contabilidad/inflacion/clasificaciones", { classification, search }),
  });
}

export function useUpsertMonetaryClass() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { accountId: number; classification: string; subClassification?: string }) =>
      apiPost("/v1/contabilidad/inflacion/clasificaciones", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CLASIFICACION] }),
  });
}

export function useAutoClassifyAccounts() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => apiPost("/v1/contabilidad/inflacion/auto-clasificar", {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CLASIFICACION] }),
  });
}

// ─── Inflación: Cálculo y publicación ────────────────────────

export function useCalculateInflation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { periodCode: string; fiscalYear: number }) =>
      apiPost("/v1/contabilidad/inflacion/calcular", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_INFLACION] }),
  });
}

export function usePostInflation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      apiPost(`/v1/contabilidad/inflacion/${id}/publicar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_INFLACION] }),
  });
}

export function useVoidInflation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { id: number; motivo?: string }) =>
      apiPost(`/v1/contabilidad/inflacion/${data.id}/anular`, { motivo: data.motivo }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_INFLACION] }),
  });
}

// ─── Reportes Legales ────────────────────────────────────────

export function useBalanceReexpresado(fechaCorte: string, enabled = true) {
  return useQuery<any>({
    queryKey: [QK_REPORTE_LEGAL, "balance-reexpresado", fechaCorte],
    queryFn: () => apiGet("/v1/contabilidad/reportes-legales/balance-reexpresado", { fechaCorte }),
    enabled: enabled && !!fechaCorte,
  });
}

export function useREME(fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery<any>({
    queryKey: [QK_REPORTE_LEGAL, "reme", fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/contabilidad/reportes-legales/reme", { fechaDesde, fechaHasta }),
    enabled: enabled && !!fechaDesde && !!fechaHasta,
  });
}

export function useEquityChangesReport(fiscalYear: number, enabled = true) {
  return useQuery<any>({
    queryKey: [QK_REPORTE_LEGAL, "cambios-patrimonio", fiscalYear],
    queryFn: () => apiGet("/v1/contabilidad/reportes-legales/cambios-patrimonio", { fiscalYear: String(fiscalYear) }),
    enabled: enabled && !!fiscalYear,
  });
}

// ─── Plantillas ──────────────────────────────────────────────

export function useTemplates(countryCode?: string) {
  return useQuery<any>({
    queryKey: [QK_PLANTILLAS, countryCode],
    queryFn: () => apiGet("/v1/contabilidad/plantillas", { countryCode }),
  });
}

export function useTemplate(templateId: number | null) {
  return useQuery<any>({
    queryKey: [QK_PLANTILLAS, "detail", templateId],
    queryFn: () => apiGet(`/v1/contabilidad/plantillas/${templateId}`),
    enabled: !!templateId,
  });
}

export function useUpsertTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<ReportTemplate>) =>
      apiPost("/v1/contabilidad/plantillas", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PLANTILLAS] }),
  });
}

export function useDeleteTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/contabilidad/plantillas/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PLANTILLAS] }),
  });
}

export function useRenderTemplate() {
  return useMutation({
    mutationFn: (data: { templateId: number; fechaDesde?: string; fechaHasta?: string; fechaCorte?: string }) =>
      apiPost(`/v1/contabilidad/plantillas/${data.templateId}/render`, data),
  });
}

// ─── Patrimonio ──────────────────────────────────────────────

export function useEquityMovements(fiscalYear: number) {
  return useQuery<any>({
    queryKey: [QK_PATRIMONIO, fiscalYear],
    queryFn: () => apiGet("/v1/contabilidad/patrimonio/movimientos", { fiscalYear: String(fiscalYear) }),
    enabled: !!fiscalYear,
  });
}

export function useInsertEquityMovement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: EquityMovementInput) =>
      apiPost("/v1/contabilidad/patrimonio/movimientos", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PATRIMONIO] }),
  });
}

export function useUpdateEquityMovement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { id: number } & Partial<EquityMovementInput>) =>
      apiPut(`/v1/contabilidad/patrimonio/movimientos/${data.id}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PATRIMONIO] }),
  });
}

export function useDeleteEquityMovement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiDelete(`/v1/contabilidad/patrimonio/movimientos/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PATRIMONIO] }),
  });
}
