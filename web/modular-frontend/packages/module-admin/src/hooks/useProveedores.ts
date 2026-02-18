// hooks/useProveedores.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@datqbox/shared-api";
import { Proveedor, CreateProveedorDTO, UpdateProveedorDTO, ProveedorFilter, PaginatedResponse } from "@datqbox/shared-api/types";

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
      return apiGet(`/api/v1/proveedores${query ? "?" + query : ""}`);
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
    mutationFn: async (data: UpdateProveedorDTO): Promise<Proveedor> => {
      const res = await fetch(`/api/v1/proveedores/${codigo}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
      });
      if (!res.ok) throw new Error(await res.text());
      return res.json();
    },
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
      const res = await fetch(`/api/v1/proveedores/${codigo}`, {
        method: "DELETE"
      });
      if (!res.ok) throw new Error(await res.text());
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["proveedores"] });
    }
  });
}

