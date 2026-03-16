"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

// ─── Query Keys ──────────────────────────────────────────────
const QK_AF = "activos-fijos";
const QK_AF_CATEGORIAS = "activos-fijos-categorias";
const QK_AF_DEPRECIACIONES = "activos-fijos-depreciaciones";

const BASE = "/v1/contabilidad/activos-fijos";

// ─── Types ───────────────────────────────────────────────────

export interface FixedAssetCategory {
  CategoryId: number;
  CategoryCode: string;
  CategoryName: string;
  DefaultUsefulLifeMonths: number;
  DefaultDepreciationMethod: string;
  DefaultResidualPercent: number;
  DefaultAssetAccountCode?: string;
  DefaultDeprecAccountCode?: string;
  DefaultExpenseAccountCode?: string;
  CountryCode?: string;
}

export interface FixedAsset {
  AssetId: number;
  AssetCode: string;
  Description: string;
  CategoryId: number;
  CategoryName?: string;
  AcquisitionDate: string;
  AcquisitionCost: number;
  ResidualValue: number;
  UsefulLifeMonths: number;
  DepreciationMethod: string;
  AssetAccountCode: string;
  DeprecAccountCode: string;
  ExpenseAccountCode: string;
  CostCenterCode?: string;
  Location?: string;
  SerialNumber?: string;
  Status: string;
  BookValue?: number;
  AccumulatedDepreciation?: number;
}

export interface DepreciationRecord {
  DepreciationId: number;
  AssetId: number;
  PeriodCode: string;
  DepreciationDate: string;
  Amount: number;
  AccumulatedDepreciation: number;
  BookValue: number;
  Status: string;
}

export interface AssetFilter {
  categoryCode?: string;
  status?: string;
  costCenterCode?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface CreateAssetInput {
  assetCode: string;
  description: string;
  categoryId: number;
  acquisitionDate: string;
  acquisitionCost: number;
  residualValue?: number;
  usefulLifeMonths: number;
  depreciationMethod?: string;
  assetAccountCode: string;
  deprecAccountCode: string;
  expenseAccountCode: string;
  costCenterCode?: string;
  location?: string;
  serialNumber?: string;
  currencyCode?: string;
}

export interface DisposeAssetInput {
  disposalDate: string;
  disposalAmount?: number;
  disposalReason?: string;
}

export interface ImprovementInput {
  improvementDate: string;
  description: string;
  amount: number;
  additionalLifeMonths?: number;
}

export interface RevalueInput {
  revaluationDate: string;
  indexFactor: number;
  countryCode: string;
}

// ─── Categories ──────────────────────────────────────────────

export function useCategoriasList(search?: string) {
  return useQuery({
    queryKey: [QK_AF_CATEGORIAS, search],
    queryFn: () => apiGet(`${BASE}/categorias`, { search, limit: 100 }) as Promise<{ rows: FixedAssetCategory[]; total: number }>,
  });
}

export function useCategoriaDetalle(code: string | null) {
  return useQuery({
    queryKey: [QK_AF_CATEGORIAS, "detalle", code],
    queryFn: () => apiGet(`${BASE}/categorias/${code}`) as Promise<FixedAssetCategory>,
    enabled: !!code,
  });
}

export function useUpsertCategoria() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<FixedAssetCategory> & { categoryCode: string; categoryName: string; defaultUsefulLifeMonths: number }) =>
      apiPost(`${BASE}/categorias`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_AF_CATEGORIAS] }),
  });
}

// ─── Assets CRUD ─────────────────────────────────────────────

export function useActivosFijosList(filter?: AssetFilter) {
  return useQuery({
    queryKey: [QK_AF, filter],
    queryFn: () => apiGet(BASE, filter as Record<string, unknown>) as Promise<{ rows: FixedAsset[]; total: number }>,
  });
}

export function useActivoFijoDetalle(id: number | null) {
  return useQuery({
    queryKey: [QK_AF, "detalle", id],
    queryFn: () => apiGet(`${BASE}/${id}`) as Promise<FixedAsset>,
    enabled: !!id,
  });
}

export function useCreateActivoFijo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateAssetInput) => apiPost(BASE, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_AF] }),
  });
}

export function useUpdateActivoFijo(id: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) => apiPut(`${BASE}/${id}`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_AF] });
      qc.invalidateQueries({ queryKey: [QK_AF, "detalle", id] });
    },
  });
}

export function useDisposeActivoFijo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: DisposeAssetInput & { id: number }) =>
      apiPost(`${BASE}/${id}/disponer`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_AF] }),
  });
}

// ─── Depreciation ────────────────────────────────────────────

export function useCalcularDepreciacion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { periodo: string; costCenterCode?: string }) =>
      apiPost(`${BASE}/depreciacion/calcular`, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK_AF] });
      qc.invalidateQueries({ queryKey: [QK_AF_DEPRECIACIONES] });
    },
  });
}

export function usePreviewDepreciacion() {
  return useMutation({
    mutationFn: (data: { periodo: string; costCenterCode?: string }) =>
      apiPost(`${BASE}/depreciacion/preview`, data) as Promise<{ rows: DepreciationRecord[]; entriesGenerated: number }>,
  });
}

export function useDepreciacionHistorial(assetId: number | null, page = 1, limit = 50) {
  return useQuery({
    queryKey: [QK_AF_DEPRECIACIONES, assetId, page],
    queryFn: () => apiGet(`${BASE}/${assetId}/depreciaciones`, { page, limit }) as Promise<{ rows: DepreciationRecord[]; total: number }>,
    enabled: !!assetId,
  });
}

// ─── Improvements ────────────────────────────────────────────

export function useAddMejora() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: ImprovementInput & { id: number }) =>
      apiPost(`${BASE}/${id}/mejoras`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_AF] }),
  });
}

// ─── Revaluation ─────────────────────────────────────────────

export function useRevaluarActivo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: RevalueInput & { id: number }) =>
      apiPost(`${BASE}/${id}/revaluar`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_AF] }),
  });
}

// ─── Reports ─────────────────────────────────────────────────

export function useReporteLibroActivos(fechaCorte: string, categoryCode?: string) {
  return useQuery({
    queryKey: [QK_AF, "reporte-libro", fechaCorte, categoryCode],
    queryFn: () => apiGet(`${BASE}/reportes/libro`, { fechaCorte, categoryCode }) as Promise<{ rows: any[] }>,
    enabled: !!fechaCorte,
  });
}

export function useReporteCuadroDepreciacion(assetId: number | null) {
  return useQuery({
    queryKey: [QK_AF, "reporte-cuadro", assetId],
    queryFn: () => apiGet(`${BASE}/reportes/cuadro/${assetId}`) as Promise<{ rows: any[] }>,
    enabled: !!assetId,
  });
}

export function useReporteActivosPorCategoria(fechaCorte: string) {
  return useQuery({
    queryKey: [QK_AF, "reporte-categoria", fechaCorte],
    queryFn: () => apiGet(`${BASE}/reportes/por-categoria`, { fechaCorte }) as Promise<{ rows: any[] }>,
    enabled: !!fechaCorte,
  });
}
