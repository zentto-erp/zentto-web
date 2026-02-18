"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";

const QK_CONCEPTOS = "nomina-conceptos";
const QK_NOMINAS = "nomina-list";
const QK_VACACIONES = "nomina-vacaciones";
const QK_LIQUIDACIONES = "nomina-liquidaciones";
const QK_CONSTANTES = "nomina-constantes";

// ─── Types ────────────────────────────────────────────────────

export interface ConceptoFilter {
  coNomina?: string;
  tipo?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface ConceptoInput {
  codigo: string;
  codigoNomina: string;
  nombre: string;
  formula?: string;
  sobre?: string;
  clase?: string;
  tipo?: "ASIGNACION" | "DEDUCCION" | "BONO";
  uso?: string;
  bonificable?: string;
  esAntiguedad?: string;
  cuentaContable?: string;
  aplica?: string;
  valorDefecto?: number;
}

export interface NominaFilter {
  nomina?: string;
  cedula?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  soloAbiertas?: boolean;
  page?: number;
  limit?: number;
}

export interface ProcesarEmpleadoInput {
  nomina: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
}

export interface ProcesarNominaInput {
  nomina: string;
  fechaInicio: string;
  fechaHasta: string;
  soloActivos?: boolean;
}

export interface VacacionesInput {
  vacacionId: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  fechaReintegro?: string;
}

export interface LiquidacionInput {
  liquidacionId: string;
  cedula: string;
  fechaRetiro: string;
  causaRetiro?: "RENUNCIA" | "DESPIDO" | "DESPIDO_JUSTIFICADO";
}

export interface ConstanteInput {
  codigo: string;
  nombre?: string;
  valor?: number;
  origen?: string;
}

// ─── Conceptos ────────────────────────────────────────────────

export function useConceptosList(filter?: ConceptoFilter) {
  return useQuery({
    queryKey: [QK_CONCEPTOS, filter],
    queryFn: () => apiGet("/v1/nomina/conceptos", filter),
  });
}

export function useSaveConcepto() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ConceptoInput) => apiPost("/v1/nomina/conceptos", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONCEPTOS] }),
  });
}

// ─── Nóminas ──────────────────────────────────────────────────

export function useNominasList(filter?: NominaFilter) {
  return useQuery({
    queryKey: [QK_NOMINAS, filter],
    queryFn: () => apiGet("/v1/nomina", filter),
  });
}

export function useNominaDetalle(nomina: string | null, cedula: string | null) {
  return useQuery({
    queryKey: [QK_NOMINAS, "detalle", nomina, cedula],
    queryFn: () => apiGet(`/v1/nomina/${nomina}/${cedula}`),
    enabled: !!nomina && !!cedula,
  });
}

export function useProcesarNominaEmpleado() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ProcesarEmpleadoInput) =>
      apiPost("/v1/nomina/procesar-empleado", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_NOMINAS] }),
  });
}

export function useProcesarNominaCompleta() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ProcesarNominaInput) =>
      apiPost("/v1/nomina/procesar", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_NOMINAS] }),
  });
}

export function useCerrarNomina() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { nomina: string; cedula?: string }) =>
      apiPost("/v1/nomina/cerrar", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_NOMINAS] }),
  });
}

// ─── Vacaciones ───────────────────────────────────────────────

export function useVacacionesList(filter?: { cedula?: string; page?: number; limit?: number }) {
  return useQuery({
    queryKey: [QK_VACACIONES, filter],
    queryFn: () => apiGet("/v1/nomina/vacaciones/list", filter),
  });
}

export function useVacacionDetalle(id: string | null) {
  return useQuery({
    queryKey: [QK_VACACIONES, "detalle", id],
    queryFn: () => apiGet(`/v1/nomina/vacaciones/${id}`),
    enabled: !!id,
  });
}

export function useProcesarVacaciones() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: VacacionesInput) =>
      apiPost("/v1/nomina/vacaciones/procesar", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_VACACIONES] }),
  });
}

// ─── Liquidaciones ────────────────────────────────────────────

export function useLiquidacionesList(filter?: { cedula?: string; page?: number; limit?: number }) {
  return useQuery({
    queryKey: [QK_LIQUIDACIONES, filter],
    queryFn: () => apiGet("/v1/nomina/liquidaciones/list", filter),
  });
}

export function useLiquidacionDetalle(id: string | null) {
  return useQuery({
    queryKey: [QK_LIQUIDACIONES, "detalle", id],
    queryFn: () => apiGet(`/v1/nomina/liquidaciones/${id}`),
    enabled: !!id,
  });
}

export function useCalcularLiquidacion() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: LiquidacionInput) =>
      apiPost("/v1/nomina/liquidacion/calcular", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_LIQUIDACIONES] }),
  });
}

// ─── Constantes ───────────────────────────────────────────────

export function useConstantesList(filter?: { page?: number; limit?: number }) {
  return useQuery({
    queryKey: [QK_CONSTANTES, filter],
    queryFn: () => apiGet("/v1/nomina/constantes", filter),
  });
}

export function useSaveConstante() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: ConstanteInput) => apiPost("/v1/nomina/constantes", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK_CONSTANTES] }),
  });
}
