"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut } from "@zentto/shared-api";

// ─── Query Keys ──────────────────────────────────────────────
const QK_LIBROS = "fiscal-libros";
const QK_DECLARACIONES = "fiscal-declaraciones";
const QK_RETENCIONES = "fiscal-retenciones";

const BASE = "/v1/contabilidad/fiscal";

// ─── Types ───────────────────────────────────────────────────

export interface TaxBookEntry {
  EntryId: number;
  BookType: string;
  PeriodCode: string;
  EntryDate: string;
  DocumentNumber: string;
  DocumentType: string;
  ControlNumber?: string;
  ThirdPartyId: string;
  ThirdPartyName: string;
  TaxableBase: number;
  ExemptAmount: number;
  TaxRate: number;
  TaxAmount: number;
  WithholdingRate: number;
  WithholdingAmount: number;
  TotalAmount: number;
  CountryCode: string;
}

export interface TaxBookSummary {
  TaxRate: number;
  TaxableBase: number;
  TaxAmount: number;
  WithholdingAmount: number;
  EntryCount: number;
}

export interface TaxDeclaration {
  DeclarationId: number;
  DeclarationType: string;
  PeriodCode: string;
  CountryCode: string;
  SalesBase: number;
  SalesTax: number;
  PurchasesBase: number;
  PurchasesTax: number;
  TaxableBase: number;
  TaxAmount: number;
  WithholdingsCredit: number;
  PreviousBalance: number;
  NetPayable: number;
  Status: string;
  SubmittedAt?: string;
  Notes?: string;
}

export interface WithholdingVoucher {
  VoucherId: number;
  VoucherNumber: string;
  VoucherDate: string;
  WithholdingType: string;
  ThirdPartyId: string;
  ThirdPartyName: string;
  DocumentNumber: string;
  TaxableBase: number;
  WithholdingRate: number;
  WithholdingAmount: number;
  PeriodCode: string;
  Status: string;
  CountryCode: string;
}

export interface TaxBookFilter {
  bookType: string;
  periodCode: string;
  countryCode: string;
  page?: number;
  limit?: number;
}

export interface DeclarationFilter {
  declarationType?: string;
  year?: number;
  status?: string;
  page?: number;
  limit?: number;
}

export interface WithholdingFilter {
  withholdingType?: string;
  periodCode?: string;
  countryCode?: string;
  page?: number;
  limit?: number;
}

// ─── Tax Books ───────────────────────────────────────────────

export function useGenerarLibroFiscal() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { bookType: string; periodCode: string; countryCode: string }) =>
      apiPost(`${BASE}/libros/generar`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LIBROS] }),
  });
}

export function useLibroFiscal(filter: TaxBookFilter | null) {
  return useQuery({
    queryKey: [QK_LIBROS, filter],
    queryFn: () => apiGet(`${BASE}/libros`, filter as Record<string, any>) as Promise<{ rows: TaxBookEntry[]; total: number }>,
    enabled: !!filter?.bookType && !!filter?.periodCode && !!filter?.countryCode,
  });
}

export function useResumenLibroFiscal(bookType: string, periodCode: string, countryCode: string) {
  return useQuery({
    queryKey: [QK_LIBROS, "resumen", bookType, periodCode, countryCode],
    queryFn: () => apiGet(`${BASE}/libros/resumen`, { bookType, periodCode, countryCode }) as Promise<{ rows: TaxBookSummary[] }>,
    enabled: !!bookType && !!periodCode && !!countryCode,
  });
}

export function useExportarLibro(bookType: string, periodCode: string, countryCode: string) {
  return useQuery({
    queryKey: [QK_LIBROS, "exportar", bookType, periodCode, countryCode],
    queryFn: () => apiGet(`${BASE}/libros/exportar`, { bookType, periodCode, countryCode }) as Promise<{ rows: any[] }>,
    enabled: false, // manual trigger
  });
}

// ─── Declarations ────────────────────────────────────────────

export function useCalcularDeclaracion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { declarationType: string; periodCode: string; countryCode: string }) =>
      apiPost(`${BASE}/declaraciones/calcular`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DECLARACIONES] }),
  });
}

export function useDeclaracionesList(filter?: DeclarationFilter) {
  return useQuery({
    queryKey: [QK_DECLARACIONES, filter],
    queryFn: () => apiGet(`${BASE}/declaraciones`, filter as Record<string, any>) as Promise<{ rows: TaxDeclaration[]; total: number }>,
  });
}

export function useDeclaracionDetalle(id: number | null) {
  return useQuery({
    queryKey: [QK_DECLARACIONES, "detalle", id],
    queryFn: () => apiGet(`${BASE}/declaraciones/${id}`) as Promise<TaxDeclaration>,
    enabled: !!id,
  });
}

export function usePresentarDeclaracion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { id: number; filePath?: string }) =>
      apiPost(`${BASE}/declaraciones/${data.id}/presentar`, { filePath: data.filePath }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DECLARACIONES] }),
  });
}

export function useEnmendarDeclaracion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => apiPost(`${BASE}/declaraciones/${id}/enmendar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_DECLARACIONES] }),
  });
}

export function useExportarDeclaracion(id: number | null) {
  return useQuery({
    queryKey: [QK_DECLARACIONES, "exportar", id],
    queryFn: () => apiGet(`${BASE}/declaraciones/${id}/exportar`) as Promise<{ rows: any[] }>,
    enabled: false, // manual trigger
  });
}

// ─── Withholdings ────────────────────────────────────────────

export function useGenerarRetencion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { documentId: number; withholdingType: string; countryCode: string }) =>
      apiPost(`${BASE}/retenciones/generar`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_RETENCIONES] }),
  });
}

export function useRetencionesList(filter?: WithholdingFilter) {
  return useQuery({
    queryKey: [QK_RETENCIONES, filter],
    queryFn: () => apiGet(`${BASE}/retenciones`, filter as Record<string, any>) as Promise<{ rows: WithholdingVoucher[]; total: number }>,
  });
}

export function useRetencionDetalle(id: number | null) {
  return useQuery({
    queryKey: [QK_RETENCIONES, "detalle", id],
    queryFn: () => apiGet(`${BASE}/retenciones/${id}`) as Promise<WithholdingVoucher>,
    enabled: !!id,
  });
}

// ─── Withholding Concepts ───────────────────────────────────

const QK_CONCEPTOS = "fiscal-conceptos";
const QK_UT = "fiscal-ut";

export interface WithholdingConcept {
  ConceptId: number;
  ConceptCode: string;
  Description: string;
  SupplierType: string;
  ActivityCode: string;
  RetentionType: string;
  Rate: number;
  SubtrahendUT: number;
  MinBaseUT: number;
  SeniatCode: string;
  CountryCode: string;
  IsActive: boolean;
}

export interface TaxUnit {
  TaxUnitId: number;
  CountryCode: string;
  TaxYear: number;
  UnitValue: number;
  Currency: string;
  EffectiveDate: string;
  IsActive: boolean;
}

export interface ConceptoFilter {
  countryCode?: string;
  retentionType?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export function useConceptosList(filter?: ConceptoFilter) {
  return useQuery({
    queryKey: [QK_CONCEPTOS, filter],
    queryFn: () => apiGet(`${BASE}/retenciones/conceptos`, filter as Record<string, any>) as Promise<{ rows: WithholdingConcept[]; total: number }>,
  });
}

export function useConceptoUpsert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<WithholdingConcept> & { conceptCode: string; description: string }) =>
      apiPost(`${BASE}/retenciones/conceptos`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCEPTOS] }),
  });
}

export function useTaxUnitList(countryCode?: string, taxYear?: number) {
  return useQuery({
    queryKey: [QK_UT, countryCode, taxYear],
    queryFn: () => apiGet(`${BASE}/unidad-tributaria`, {
      ...(countryCode && { countryCode }),
      ...(taxYear && { taxYear }),
    }) as Promise<{ rows: TaxUnit[] }>,
  });
}

export function useTaxUnitUpsert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { countryCode: string; taxYear: number; unitValue: number; currency?: string; effectiveDate?: string }) =>
      apiPut(`${BASE}/unidad-tributaria`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_UT] }),
  });
}

export function useCalcularRetencion() {
  return useMutation({
    mutationFn: (data: { supplierCode: string; taxableBase: number; withholdingType?: string; countryCode?: string }) =>
      apiPost(`${BASE}/retenciones/calcular`, data) as Promise<{
        rate: number; amount: number; conceptCode: string; subtrahend: number; description: string;
      }>,
  });
}
