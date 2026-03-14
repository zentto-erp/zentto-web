"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@datqbox/shared-api";

const QK_ASIENTOS = "contabilidad-asientos";
const QK_CUENTAS = "contabilidad-cuentas";

// ─── Types ────────────────────────────────────────────────────

export interface AsientoFilter {
  fechaDesde?: string;
  fechaHasta?: string;
  tipoAsiento?: string;
  estado?: string;
  origenModulo?: string;
  origenDocumento?: string;
  page?: number;
  limit?: number;
  [key: string]: unknown;
}

export interface AsientoDetalle {
  codCuenta: string;
  descripcion?: string;
  centroCosto?: string;
  auxiliarTipo?: string;
  auxiliarCodigo?: string;
  documento?: string;
  debe: number;
  haber: number;
}

export interface CreateAsientoInput {
  fecha: string;
  tipoAsiento: string;
  referencia?: string;
  concepto: string;
  moneda?: string;
  tasa?: number;
  origenModulo?: string;
  origenDocumento?: string;
  detalle: AsientoDetalle[];
}

export interface CreateAjusteInput {
  fecha: string;
  tipoAjuste: string;
  referencia?: string;
  motivo: string;
  detalle: AsientoDetalle[];
}

export interface CuentaContable {
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
}

// ─── Asientos ─────────────────────────────────────────────────

export function useAsientosList(filter?: AsientoFilter) {
  return useQuery({
    queryKey: [QK_ASIENTOS, filter],
    queryFn: () => apiGet("/v1/contabilidad/asientos", filter),
  });
}

export function useAsientoDetalle(id: number | null) {
  return useQuery({
    queryKey: [QK_ASIENTOS, "detalle", id],
    queryFn: () => apiGet(`/v1/contabilidad/asientos/${id}`),
    enabled: id != null && id > 0,
  });
}

export function useCreateAsiento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateAsientoInput) =>
      apiPost("/v1/contabilidad/asientos", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ASIENTOS] }),
  });
}

export function useAnularAsiento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, motivo }: { id: number; motivo: string }) =>
      apiPost(`/v1/contabilidad/asientos/${id}/anular`, { motivo }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ASIENTOS] }),
  });
}

// ─── Ajustes ──────────────────────────────────────────────────

export function useCrearAjuste() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateAjusteInput) =>
      apiPost("/v1/contabilidad/ajustes", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ASIENTOS] }),
  });
}

// ─── Depreciaciones ───────────────────────────────────────────

export function useGenerarDepreciacion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { periodo: string; centroCosto?: string }) =>
      apiPost("/v1/contabilidad/depreciaciones/generar", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_ASIENTOS] }),
  });
}

// ─── Reportes ─────────────────────────────────────────────────

export function useLibroMayor(fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery({
    queryKey: ["contabilidad-libro-mayor", fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/contabilidad/reportes/libro-mayor", { fechaDesde, fechaHasta }),
    enabled,
  });
}

export function useMayorAnalitico(codCuenta: string, fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery({
    queryKey: ["contabilidad-mayor-analitico", codCuenta, fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/contabilidad/reportes/mayor-analitico", { codCuenta, fechaDesde, fechaHasta }),
    enabled,
  });
}

export function useBalanceComprobacion(fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery({
    queryKey: ["contabilidad-balance-comprobacion", fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/contabilidad/reportes/balance-comprobacion", { fechaDesde, fechaHasta }),
    enabled,
  });
}

export function useEstadoResultados(fechaDesde: string, fechaHasta: string, enabled = true) {
  return useQuery({
    queryKey: ["contabilidad-estado-resultados", fechaDesde, fechaHasta],
    queryFn: () => apiGet("/v1/contabilidad/reportes/estado-resultados", { fechaDesde, fechaHasta }),
    enabled,
  });
}

export function useBalanceGeneral(fechaCorte: string, enabled = true) {
  return useQuery({
    queryKey: ["contabilidad-balance-general", fechaCorte],
    queryFn: () => apiGet("/v1/contabilidad/reportes/balance-general", { fechaCorte }),
    enabled,
  });
}

// ─── Plan de Cuentas ──────────────────────────────────────────

export function usePlanCuentas(filter?: { search?: string; tipo?: string }) {
  return useQuery({
    queryKey: [QK_CUENTAS, filter],
    queryFn: () => apiGet("/v1/contabilidad/cuentas", filter),
  });
}

export function useCuentaDetalle(codCuenta: string | null) {
  return useQuery({
    queryKey: [QK_CUENTAS, "detalle", codCuenta],
    queryFn: () => apiGet(`/v1/contabilidad/cuentas/${codCuenta}`),
    enabled: !!codCuenta,
  });
}

export function useSeedPlanCuentas() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => apiPost("/v1/contabilidad/setup/seed-plan-cuentas", {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CUENTAS] }),
  });
}

// ─── CRUD Cuentas ────────────────────────────────────────────────

export interface CuentaInput {
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
}

export function useCreateCuenta() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CuentaInput) =>
      apiPost("/v1/contabilidad/cuentas", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CUENTAS] }),
  });
}

export function useUpdateCuenta() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ codCuenta, ...data }: CuentaInput) =>
      apiPut(`/v1/contabilidad/cuentas/${encodeURIComponent(codCuenta)}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CUENTAS] }),
  });
}

export function useDeleteCuenta() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (codCuenta: string) =>
      apiDelete(`/v1/contabilidad/cuentas/${encodeURIComponent(codCuenta)}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CUENTAS] }),
  });
}
