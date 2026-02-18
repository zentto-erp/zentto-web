"use client";

import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@datqbox/shared-api";

const QK = "empleados";

export interface EmpleadoFilter {
  search?: string;
  grupo?: string;
  status?: string;
  nomina?: string;
  page?: number;
  limit?: number;
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
