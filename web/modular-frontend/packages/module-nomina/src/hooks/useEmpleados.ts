"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const QK = "empleados";

export interface EmpleadoFilter {
  search?: string;
  grupo?: string;
  status?: string;
  nomina?: string;
  page?: number;
  limit?: number;
  [key: string]: unknown;
}

export interface EmpleadoInput {
  CEDULA: string;
  NOMBRE: string;
  GRUPO?: string;
  DIRECCION?: string;
  TELEFONO?: string;
  CARGO?: string;
  NOMINA?: string;
  SUELDO?: number;
  STATUS?: string;
  SEXO?: string;
  NACIONALIDAD?: string;
  Autoriza?: boolean;
}

/**
 * Lista de empleados desde la API /v1/empleados.
 */
export function useEmpleadosList(filter?: EmpleadoFilter) {
  return useQuery<any>({
    queryKey: [QK, filter],
    queryFn: () => apiGet("/v1/empleados", filter),
  });
}

/**
 * Detalle de un empleado por cédula.
 */
export function useEmpleadoDetalle(cedula: string | null) {
  return useQuery<any>({
    queryKey: [QK, "detalle", cedula],
    queryFn: () => apiGet(`/v1/empleados/${encodeURIComponent(cedula!)}`),
    enabled: !!cedula,
  });
}

export function useCreateEmpleado() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: EmpleadoInput) => apiPost("/v1/empleados", data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useUpdateEmpleado() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ cedula, data }: { cedula: string; data: Partial<Omit<EmpleadoInput, "CEDULA">> }) =>
      apiPut(`/v1/empleados/${encodeURIComponent(cedula)}`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}

export function useDeleteEmpleado() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (cedula: string) => apiDelete(`/v1/empleados/${encodeURIComponent(cedula)}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: [QK] }),
  });
}
