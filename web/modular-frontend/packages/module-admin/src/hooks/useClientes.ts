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

function mapRowToCliente(row: Record<string, any>): ClienteListItem {
  return {
    codigo: String(row.CODIGO ?? row.codigo ?? ""),
    nombre: String(row.NOMBRE ?? row.nombre ?? ""),
    rif: String(row.RIF ?? row.rif ?? ""),
    email: row.EMAIL ?? row.email,
    telefono: row.TELEFONO ?? row.telefono,
    direccion: row.DIRECCION ?? row.direccion,
    saldo: Number(row.SALDO_TOT ?? row.SALDO ?? row.saldo ?? 0),
    estado: String(row.ESTADO ?? row.estado ?? "Activo"),
  };
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
      const raw = await apiGet(`/api/v1/clientes${query ? "?" + query : ""}`);
      const rows = (raw?.rows ?? raw?.items ?? raw?.data ?? []) as Record<string, any>[];
      const items = rows.map(mapRowToCliente);
      const total = Number(raw?.total ?? items.length);
      const page = Number(raw?.page ?? filter?.page ?? 1);
      const pageSize = Number(raw?.limit ?? filter?.limit ?? 50);
      const totalPages = Math.max(1, Math.ceil(total / Math.max(1, pageSize)));

      return {
        items,
        data: items,
        total,
        page,
        pageSize,
        totalPages,
      };
    },
  });
}
