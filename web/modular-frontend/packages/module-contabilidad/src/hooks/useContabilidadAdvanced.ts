"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@datqbox/shared-api";

// ─── Query Keys ──────────────────────────────────────────────
const QK_PERIODOS = "contabilidad-periodos";
const QK_CENTROS_COSTO = "contabilidad-centros-costo";
const QK_PRESUPUESTOS = "contabilidad-presupuestos";
const QK_CONCILIACION = "contabilidad-conciliacion";
const QK_RECURRENTES = "contabilidad-recurrentes";
const QK_REPORTES_ADV = "contabilidad-reportes-adv";
const QK_ASIENTOS = "contabilidad-asientos";

// ─── Types ───────────────────────────────────────────────────

export interface Periodo {
  periodo: string;
  year: number;
  month: number;
  status: "OPEN" | "CLOSED";
  closedAt?: string;
  closedBy?: string;
}

export interface PeriodoChecklistItem {
  item: string;
  description: string;
  status: "OK" | "WARN" | "FAIL";
  count?: number;
  detail?: string;
}

export interface CentroCosto {
  code: string;
  name: string;
  parentCode?: string | null;
  level: number;
  active: boolean;
}

export interface CentroCostoInput {
  code: string;
  name: string;
  parentCode?: string | null;
}

export interface Presupuesto {
  id: number;
  name: string;
  fiscalYear: number;
  costCenterCode?: string;
  status: string;
  total: number;
  createdAt?: string;
}

export interface PresupuestoDetalle {
  id: number;
  name: string;
  fiscalYear: number;
  costCenterCode?: string;
  status: string;
  lines: PresupuestoLinea[];
}

export interface PresupuestoLinea {
  accountCode: string;
  accountName?: string;
  month01: number;
  month02: number;
  month03: number;
  month04: number;
  month05: number;
  month06: number;
  month07: number;
  month08: number;
  month09: number;
  month10: number;
  month11: number;
  month12: number;
  annualTotal: number;
}

export interface CreatePresupuestoInput {
  name: string;
  fiscalYear: number;
  costCenterCode?: string;
  lines: Omit<PresupuestoLinea, "accountName" | "annualTotal">[];
}

export interface BankStatement {
  id: number;
  bankAccountCode: string;
  bankAccountName?: string;
  statementDate: string;
  totalLines: number;
  matchedLines: number;
  pendingLines: number;
  pendingAmount: number;
}

export interface BankStatementLine {
  id: number;
  statementId: number;
  date: string;
  description: string;
  amount: number;
  status: "MATCHED" | "UNMATCHED";
  matchedEntryId?: number;
  matchedEntryRef?: string;
}

export interface BankReconSummary {
  totalLines: number;
  matched: number;
  unmatched: number;
  pendingAmount: number;
  matchedAmount: number;
}

export interface RecurrenteTemplate {
  id: number;
  name: string;
  frequency: "DAILY" | "WEEKLY" | "MONTHLY" | "QUARTERLY" | "YEARLY";
  nextExecution: string;
  lastExecution?: string;
  timesExecuted: number;
  active: boolean;
  concept: string;
  lines: RecurrenteLinea[];
}

export interface RecurrenteLinea {
  accountCode: string;
  accountName?: string;
  description?: string;
  debit: number;
  credit: number;
}

export interface CreateRecurrenteInput {
  name: string;
  frequency: string;
  nextExecution: string;
  concept: string;
  active?: boolean;
  lines: Omit<RecurrenteLinea, "accountName">[];
}

export interface VarianzaRow {
  accountCode: string;
  accountName: string;
  budget: number;
  actual: number;
  variance: number;
  variancePercent: number;
}

export interface CashFlowSection {
  section: string;
  items: { description: string; amount: number }[];
  total: number;
}

export interface AgingBucket {
  entity: string;
  entityName?: string;
  current: number;
  days30: number;
  days60: number;
  days90: number;
  over90: number;
  total: number;
}

export interface FinancialRatio {
  name: string;
  value: number;
  benchmark?: number;
  unit: string;
  category: string;
}

export interface TaxSummaryRow {
  taxType: string;
  taxName: string;
  base: number;
  taxAmount: number;
  total: number;
}

export interface DrillDownRow {
  fecha: string;
  numeroAsiento: string;
  tipoAsiento: string;
  concepto: string;
  debe: number;
  haber: number;
  saldoAcum: number;
}

// ═══════════════════════════════════════════════════════════════
// PERIODOS / CIERRE
// ═══════════════════════════════════════════════════════════════

export function usePeriodosList(year?: number, status?: string) {
  return useQuery({
    queryKey: [QK_PERIODOS, year, status],
    queryFn: () =>
      apiGet("/v1/contabilidad/periodos", {
        ...(year != null && { year }),
        ...(status && { status }),
      }),
  });
}

export function useEnsureYear() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (year?: number) =>
      apiPost("/v1/contabilidad/periodos/ensure-year", { year }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PERIODOS] }),
  });
}

export function useClosePeriod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (periodo: string) =>
      apiPost(`/v1/contabilidad/periodos/${encodeURIComponent(periodo)}/cerrar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PERIODOS] }),
  });
}

export function useReopenPeriod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (periodo: string) =>
      apiPost(`/v1/contabilidad/periodos/${encodeURIComponent(periodo)}/reabrir`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PERIODOS] }),
  });
}

export function useGenerateClosingEntries() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (periodo: string) =>
      apiPost(`/v1/contabilidad/periodos/${encodeURIComponent(periodo)}/generar-cierre`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_PERIODOS] });
      qc.invalidateQueries({ queryKey: [QK_ASIENTOS] });
    },
  });
}

export function usePeriodoChecklist(periodo: string, enabled = true) {
  return useQuery({
    queryKey: [QK_PERIODOS, "checklist", periodo],
    queryFn: () =>
      apiGet(`/v1/contabilidad/periodos/${encodeURIComponent(periodo)}/checklist`),
    enabled: enabled && !!periodo,
  });
}

// ═══════════════════════════════════════════════════════════════
// CENTROS DE COSTO
// ═══════════════════════════════════════════════════════════════

export function useCentrosCostoList(search?: string) {
  return useQuery({
    queryKey: [QK_CENTROS_COSTO, search],
    queryFn: () =>
      apiGet("/v1/contabilidad/centros-costo", { ...(search && { search }) }),
  });
}

export function useCentroCostoGet(code: string) {
  return useQuery({
    queryKey: [QK_CENTROS_COSTO, "detalle", code],
    queryFn: () => apiGet(`/v1/contabilidad/centros-costo/${encodeURIComponent(code)}`),
    enabled: !!code,
  });
}

export function useCreateCentroCosto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CentroCostoInput) =>
      apiPost("/v1/contabilidad/centros-costo", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CENTROS_COSTO] }),
  });
}

export function useUpdateCentroCosto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ code, ...data }: CentroCostoInput) =>
      apiPut(`/v1/contabilidad/centros-costo/${encodeURIComponent(code)}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CENTROS_COSTO] }),
  });
}

export function useDeleteCentroCosto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (code: string) =>
      apiDelete(`/v1/contabilidad/centros-costo/${encodeURIComponent(code)}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CENTROS_COSTO] }),
  });
}

// ═══════════════════════════════════════════════════════════════
// PRESUPUESTOS
// ═══════════════════════════════════════════════════════════════

export function usePresupuestosList(fiscalYear?: number) {
  return useQuery({
    queryKey: [QK_PRESUPUESTOS, fiscalYear],
    queryFn: () =>
      apiGet("/v1/contabilidad/presupuestos", {
        ...(fiscalYear != null && { fiscalYear }),
      }),
  });
}

export function usePresupuestoGet(id: number | null) {
  return useQuery({
    queryKey: [QK_PRESUPUESTOS, "detalle", id],
    queryFn: () => apiGet(`/v1/contabilidad/presupuestos/${id}`),
    enabled: id != null && id > 0,
  });
}

export function useCreatePresupuesto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePresupuestoInput) =>
      apiPost("/v1/contabilidad/presupuestos", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PRESUPUESTOS] }),
  });
}

export function useUpdatePresupuesto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: CreatePresupuestoInput & { id: number }) =>
      apiPut(`/v1/contabilidad/presupuestos/${id}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PRESUPUESTOS] }),
  });
}

export function useDeletePresupuesto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      apiDelete(`/v1/contabilidad/presupuestos/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_PRESUPUESTOS] }),
  });
}

export function usePresupuestoVarianza(
  id: number | null,
  fechaDesde?: string,
  fechaHasta?: string,
) {
  return useQuery({
    queryKey: [QK_PRESUPUESTOS, "varianza", id, fechaDesde, fechaHasta],
    queryFn: () =>
      apiGet(`/v1/contabilidad/presupuestos/${id}/varianza`, {
        ...(fechaDesde && { fechaDesde }),
        ...(fechaHasta && { fechaHasta }),
      }),
    enabled: id != null && id > 0,
  });
}

// ═══════════════════════════════════════════════════════════════
// CONCILIACION BANCARIA
// ═══════════════════════════════════════════════════════════════

export function useBankStatementsList(bankAccountCode?: string) {
  return useQuery({
    queryKey: [QK_CONCILIACION, "extractos", bankAccountCode],
    queryFn: () =>
      apiGet("/v1/contabilidad/conciliacion/extractos", {
        ...(bankAccountCode && { bankAccountCode }),
      }),
  });
}

export function useBankStatementLines(statementId: number | null) {
  return useQuery({
    queryKey: [QK_CONCILIACION, "lineas", statementId],
    queryFn: () =>
      apiGet(`/v1/contabilidad/conciliacion/extractos/${statementId}/lineas`),
    enabled: statementId != null && statementId > 0,
  });
}

export function useImportBankStatement() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { bankAccountCode: string; lines: unknown[] }) =>
      apiPost("/v1/contabilidad/conciliacion/importar", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCILIACION] }),
  });
}

export function useMatchBankLine() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { lineId: number; entryId: number }) =>
      apiPost("/v1/contabilidad/conciliacion/match", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCILIACION] }),
  });
}

export function useUnmatchBankLine() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (lineId: number) =>
      apiPost("/v1/contabilidad/conciliacion/unmatch", { lineId }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCILIACION] }),
  });
}

export function useAutoMatch() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (statementId: number) =>
      apiPost(`/v1/contabilidad/conciliacion/auto-match/${statementId}`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCILIACION] }),
  });
}

export function useBankReconSummary(statementId: number | null) {
  return useQuery({
    queryKey: [QK_CONCILIACION, "resumen", statementId],
    queryFn: () =>
      apiGet(`/v1/contabilidad/conciliacion/resumen/${statementId}`),
    enabled: statementId != null && statementId > 0,
  });
}

// ═══════════════════════════════════════════════════════════════
// ASIENTOS RECURRENTES
// ═══════════════════════════════════════════════════════════════

export function useRecurrentesList() {
  return useQuery({
    queryKey: [QK_RECURRENTES],
    queryFn: () => apiGet("/v1/contabilidad/recurrentes"),
  });
}

export function useRecurrenteGet(id: number | null) {
  return useQuery({
    queryKey: [QK_RECURRENTES, "detalle", id],
    queryFn: () => apiGet(`/v1/contabilidad/recurrentes/${id}`),
    enabled: id != null && id > 0,
  });
}

export function useCreateRecurrente() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateRecurrenteInput) =>
      apiPost("/v1/contabilidad/recurrentes", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RECURRENTES] }),
  });
}

export function useUpdateRecurrente() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: CreateRecurrenteInput & { id: number }) =>
      apiPut(`/v1/contabilidad/recurrentes/${id}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RECURRENTES] }),
  });
}

export function useDeleteRecurrente() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      apiDelete(`/v1/contabilidad/recurrentes/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RECURRENTES] }),
  });
}

export function useExecuteRecurrente() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      apiPost(`/v1/contabilidad/recurrentes/${id}/ejecutar`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_RECURRENTES] });
      qc.invalidateQueries({ queryKey: [QK_ASIENTOS] });
    },
  });
}

export function useDueRecurrentes() {
  return useQuery({
    queryKey: [QK_RECURRENTES, "due"],
    queryFn: () => apiGet("/v1/contabilidad/recurrentes/due"),
  });
}

// ═══════════════════════════════════════════════════════════════
// REVERSION
// ═══════════════════════════════════════════════════════════════

export function useReverseEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, motivo }: { id: number; motivo: string }) =>
      apiPost(`/v1/contabilidad/asientos/${id}/revertir`, { motivo }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ASIENTOS] }),
  });
}

// ═══════════════════════════════════════════════════════════════
// REPORTES AVANZADOS
// ═══════════════════════════════════════════════════════════════

export function useCashFlowReport(fechaDesde?: string, fechaHasta?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "flujo-efectivo", fechaDesde, fechaHasta],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/flujo-efectivo", { fechaDesde, fechaHasta }),
    enabled: enabled && !!fechaDesde && !!fechaHasta,
  });
}

export function useBalanceCompMultiPeriod(periodos?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "balance-comp-multiperiodo", periodos],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/balance-comp-multiperiodo", { periodos }),
    enabled: enabled && !!periodos,
  });
}

export function usePnLMultiPeriod(periodos?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "pnl-multiperiodo", periodos],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/pnl-multiperiodo", { periodos }),
    enabled: enabled && !!periodos,
  });
}

export function useAgingCxC(fechaCorte?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "aging-cxc", fechaCorte],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/aging-cxc", { fechaCorte }),
    enabled: enabled && !!fechaCorte,
  });
}

export function useAgingCxP(fechaCorte?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "aging-cxp", fechaCorte],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/aging-cxp", { fechaCorte }),
    enabled: enabled && !!fechaCorte,
  });
}

export function useFinancialRatios(fechaCorte?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "ratios-financieros", fechaCorte],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/ratios-financieros", { fechaCorte }),
    enabled: enabled && !!fechaCorte,
  });
}

export function useTaxSummary(fechaDesde?: string, fechaHasta?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "impuestos", fechaDesde, fechaHasta],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/impuestos", { fechaDesde, fechaHasta }),
    enabled: enabled && !!fechaDesde && !!fechaHasta,
  });
}

export function useDrillDown(
  accountCode?: string,
  fechaDesde?: string,
  fechaHasta?: string,
  enabled = true,
) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "drill-down", accountCode, fechaDesde, fechaHasta],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/drill-down", {
        accountCode,
        fechaDesde,
        fechaHasta,
      }),
    enabled: enabled && !!accountCode && !!fechaDesde && !!fechaHasta,
  });
}

export function usePnLByCostCenter(fechaDesde?: string, fechaHasta?: string, enabled = true) {
  return useQuery({
    queryKey: [QK_REPORTES_ADV, "pnl-centro-costo", fechaDesde, fechaHasta],
    queryFn: () =>
      apiGet("/v1/contabilidad/reportes/pnl-centro-costo", { fechaDesde, fechaHasta }),
    enabled: enabled && !!fechaDesde && !!fechaHasta,
  });
}
