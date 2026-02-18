"use client";

import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@datqbox/shared-api";

export interface ClienteListItem {
  codigo: string;
  nombre: string;
  rif: string;
  email?: string;
  telefono?: string;
  direccion?: string;
  saldo?: number;
  estado?: string;
}

export interface ClienteFilter {
  search?: string;
  page?: number;
  limit?: number;
  estado?: string;
}

export function useClientesList(filter?: ClienteFilter) {
  return useQuery({
    queryKey: ["clientes", "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      if (filter?.estado) params.append("estado", filter.estado);

      const query = params.toString();
      return apiGet(`/api/v1/clientes${query ? "?" + query : ""}`);
    },
  });
}
