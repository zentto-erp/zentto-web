// hooks/useProveedores.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiDelete, apiGet, apiPost, apiPut } from "@datqbox/shared-api";
import { Proveedor, CreateProveedorDTO, UpdateProveedorDTO, ProveedorFilter, PaginatedResponse } from "@datqbox/shared-api/types";

type RawRow = Record<string, unknown>;

function mapRowToProveedor(row: RawRow): Proveedor {
  return {
    codigo: String(row.CODIGO ?? row.codigo ?? ""),
    nombre: String(row.NOMBRE ?? row.nombre ?? ""),
    rif: String(row.RIF ?? row.rif ?? ""),
    direccion: String(row.DIRECCION ?? row.direccion ?? ""),
    telefono: String(row.TELEFONO ?? row.telefono ?? ""),
    email: String(row.EMAIL ?? row.email ?? ""),
    estado: String(row.ESTADO ?? row.estado ?? "Activo") as Proveedor["estado"],
    saldo: Number(row.SALDO_TOT ?? row.SALDO ?? row.saldo ?? 0),
    fechaCreacion: new Date(),
  };
}

export function useProveedoresList(filter?: ProveedorFilter) {
  return useQuery({
    queryKey: ["proveedores", filter],
    queryFn: async (): Promise<PaginatedResponse<Proveedor>> => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      if (filter?.estado) params.append("estado", filter.estado);
      
      const query = params.toString();
      const raw = await apiGet(`/api/v1/proveedores${query ? "?" + query : ""}`);
      const rows = (raw?.rows ?? raw?.items ?? raw?.data ?? []) as RawRow[];
      const items = rows.map(mapRowToProveedor);
      const total = Number(raw?.total ?? items.length);
      const page = Number(raw?.page ?? filter?.page ?? 1);
      const pageSize = Number(raw?.limit ?? filter?.limit ?? 10);
      const totalPages = Math.max(1, Math.ceil(total / Math.max(1, pageSize)));

      return {
        items,
        data: items,
        total,
        page,
        pageSize,
        totalPages,
      };
    }
  });
}

export function useProveedorById(codigo: string) {
  return useQuery({
    queryKey: ["proveedores", codigo],
    queryFn: (): Promise<Proveedor> => apiGet(`/api/v1/proveedores/${codigo}`),
    enabled: !!codigo
  });
}

export function useCreateProveedor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateProveedorDTO): Promise<Proveedor> =>
      apiPost("/api/v1/proveedores", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
    }
  });
}

export function useUpdateProveedor(codigo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateProveedorDTO): Promise<Proveedor> =>
      apiPut(`/api/v1/proveedores/${codigo}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
      queryClient.invalidateQueries({ queryKey: ["proveedores", codigo] });
    }
  });
}

export function useDeleteProveedor() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (codigo: string): Promise<void> => {
      await apiDelete(`/api/v1/proveedores/${codigo}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
    }
  });
}

