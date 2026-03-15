"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut } from "@datqbox/shared-api";

const QK = "vacaciones-solicitudes";
const QK_DIAS = "vacaciones-dias-disponibles";

export interface SolicitudVacacionesInput {
  employeeCode: string;
  startDate: string;
  endDate: string;
  totalDays: number;
  isPartial: boolean;
  notes?: string;
  days: Array<{ date: string; dayType: string }>;
}

export interface SolicitudFilter {
  employeeCode?: string;
  status?: string;
  page?: number;
  limit?: number;
  [key: string]: unknown;
}

export interface DiasDisponibles {
  DiasBase: number;
  AnosServicio: number;
  DiasAdicionales: number;
  DiasDisponibles: number;
  DiasTomados: number;
  DiasPendientes: number;
}

export function useVacacionSolicitudesList(filter?: SolicitudFilter) {
  return useQuery({
    queryKey: [QK, filter],
    queryFn: () => apiGet("/v1/nomina/vacaciones/solicitudes", filter),
  });
}

export function useVacacionSolicitudDetalle(id: string | number | null) {
  return useQuery({
    queryKey: [QK, "detalle", id],
    queryFn: () => apiGet(`/v1/nomina/vacaciones/solicitudes/${id}`),
    enabled: id != null,
  });
}

export function useDiasDisponibles(cedula: string | null) {
  return useQuery<DiasDisponibles>({
    queryKey: [QK_DIAS, cedula],
    queryFn: () => apiGet(`/v1/nomina/vacaciones/dias-disponibles/${encodeURIComponent(cedula!)}`),
    enabled: !!cedula,
  });
}

export function useCrearSolicitudVacaciones() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: SolicitudVacacionesInput) =>
      apiPost("/v1/nomina/vacaciones/solicitar", data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK] });
      qc.invalidateQueries({ queryKey: [QK_DIAS] });
    },
  });
}

export function useAprobarSolicitud() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number | string) =>
      apiPut(`/v1/nomina/vacaciones/solicitudes/${id}/aprobar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useRechazarSolicitud() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }: { id: number | string; reason: string }) =>
      apiPut(`/v1/nomina/vacaciones/solicitudes/${id}/rechazar`, { reason }),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useCancelarSolicitud() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number | string) =>
      apiPut(`/v1/nomina/vacaciones/solicitudes/${id}/cancelar`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useProcesarPagoVacaciones() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number | string) =>
      apiPost(`/v1/nomina/vacaciones/solicitudes/${id}/procesar-pago`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [QK] });
      qc.invalidateQueries({ queryKey: ["nomina-vacaciones"] });
    },
  });
}
