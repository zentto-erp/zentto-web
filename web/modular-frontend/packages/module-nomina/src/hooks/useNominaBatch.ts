"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const QK_BATCH = "nomina-batch";
const QK_BATCH_GRID = "nomina-batch-grid";
const QK_BATCH_SUMMARY = "nomina-batch-summary";
const QK_BATCH_EMPLOYEE = "nomina-batch-employee";

// ─── Types ────────────────────────────────────────────────────

export interface BatchDraftInput {
  nomina: string;
  fechaInicio: string;
  fechaHasta: string;
  departamento?: string;
}

export interface BatchFilter {
  nomina?: string;
  status?: string;
  page?: number;
  limit?: number;
  [key: string]: unknown;
}

export interface BatchGridFilter {
  search?: string;
  department?: string;
  onlyModified?: boolean;
  page?: number;
  limit?: number;
  [key: string]: unknown;
}

export interface SaveDraftLineInput {
  lineId: number;
  quantity: number;
  amount: number;
  notes?: string;
}

export interface BatchAddLineInput {
  batchId: number;
  employeeCode: string;
  conceptCode: string;
  conceptName: string;
  conceptType: "ASIGNACION" | "DEDUCCION" | "BONO";
  quantity: number;
  amount: number;
}

export interface BatchBulkUpdateInput {
  batchId: number;
  conceptCode: string;
  conceptType: "ASIGNACION" | "DEDUCCION" | "BONO";
  amount: number;
  employeeCodes?: string[];
}

export interface BatchSummary {
  batchId: number;
  payrollCode: string;
  fromDate: string;
  toDate: string;
  status: string;
  totalEmployees: number;
  totalGross: number;
  totalDeductions: number;
  totalNet: number;
  createdBy: string;
  createdAt: string;
  approvedBy?: string;
  approvedAt?: string;
  prevGross?: number;
  prevDeductions?: number;
  prevNet?: number;
  alertCount?: number;
}

export interface BatchGridRow {
  employeeId: number;
  employeeCode: string;
  employeeName: string;
  department?: string;
  sueldoBase: number;
  totalAsignaciones: number;
  totalDeducciones: number;
  totalNeto: number;
  isModified: boolean;
  hasAlerts: boolean;
  lineCount: number;
}

export interface EmployeeLine {
  lineId: number;
  conceptCode: string;
  conceptName: string;
  conceptType: string;
  quantity: number;
  amount: number;
  total: number;
  isModified: boolean;
  notes?: string;
}

// ─── Batch List ───────────────────────────────────────────────

export function useBatchList(filter?: BatchFilter) {
  return useQuery({
    queryKey: [QK_BATCH, filter],
    queryFn: () => apiGet("/v1/nomina/batch", filter),
  });
}

// ─── Generate Draft ───────────────────────────────────────────

export function useGenerateDraft() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: BatchDraftInput) =>
      apiPost("/v1/nomina/batch/draft", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_BATCH] }),
  });
}

// ─── Draft Summary (Pre-Nómina) ──────────────────────────────

export function useBatchSummary(batchId: number | null) {
  return useQuery({
    queryKey: [QK_BATCH_SUMMARY, batchId],
    queryFn: () => apiGet(`/v1/nomina/batch/${batchId}/summary`),
    enabled: !!batchId,
  });
}

// ─── Draft Grid ──────────────────────────────────────────────

export function useBatchGrid(batchId: number | null, filter?: BatchGridFilter) {
  return useQuery({
    queryKey: [QK_BATCH_GRID, batchId, filter],
    queryFn: () => apiGet(`/v1/nomina/batch/${batchId}/grid`, filter),
    enabled: !!batchId,
  });
}

// ─── Employee Lines (Panel) ──────────────────────────────────

export function useBatchEmployeeLines(batchId: number | null, employeeCode: string | null) {
  return useQuery({
    queryKey: [QK_BATCH_EMPLOYEE, batchId, employeeCode],
    queryFn: () => apiGet(`/v1/nomina/batch/${batchId}/employee/${employeeCode}`),
    enabled: !!batchId && !!employeeCode,
  });
}

// ─── Save Line (Autosave) ────────────────────────────────────

export function useSaveDraftLine() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: SaveDraftLineInput) =>
      apiPut("/v1/nomina/batch/line", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH_GRID] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_EMPLOYEE] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
    },
  });
}

// ─── Add Line ────────────────────────────────────────────────

export function useBatchAddLine() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: BatchAddLineInput) =>
      apiPost("/v1/nomina/batch/line", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH_GRID] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_EMPLOYEE] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
    },
  });
}

// ─── Remove Line ─────────────────────────────────────────────

export function useBatchRemoveLine() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (lineId: number) =>
      apiDelete(`/v1/nomina/batch/line/${lineId}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH_GRID] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_EMPLOYEE] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
    },
  });
}

// ─── Approve Draft ───────────────────────────────────────────

export function useApproveDraft() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (batchId: number) =>
      apiPost(`/v1/nomina/batch/${batchId}/approve`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
    },
  });
}

// ─── Process Batch ───────────────────────────────────────────

export function useProcessBatch() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (batchId: number) =>
      apiPost(`/v1/nomina/batch/${batchId}/process`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_GRID] });
    },
  });
}

// ─── Bulk Update ─────────────────────────────────────────────

export function useBatchBulkUpdate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: BatchBulkUpdateInput) =>
      apiPost("/v1/nomina/batch/bulk-update", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_BATCH_GRID] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_EMPLOYEE] });
      qc.invalidateQueries({ queryKey: [QK_BATCH_SUMMARY] });
    },
  });
}
