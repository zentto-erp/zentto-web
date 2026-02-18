// hooks/useArticulos.ts
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Articulo,
  CreateArticuloDTO,
  UpdateArticuloDTO,
  ArticuloFilter,
  ArticuloFilterOptions,
} from "@/lib/types";
import { apiGet, apiPost, apiPut, apiDelete } from "@/lib/api";

const QUERY_KEY = "articulos";
const API_BASE = "/api/v1/inventario";

// ============ Mapeo de fila del backend al tipo Articulo ============

/** Proyecta una fila del backend (CachedArticulo) al tipo Articulo del frontend */
function mapRowToArticulo(row: Record<string, any>): Articulo {
  return {
    codigo: (row.CODIGO ?? row.codigo ?? "").trim(),
    referencia: (row.Referencia ?? row.referencia ?? "").trim(),
    descripcion: (row.DESCRIPCION ?? row.descripcion ?? "").trim(),
    descripcionCompleta: (row.DescripcionCompleta ?? row.descripcionCompleta ?? "").trim(),
    categoria: (row.Categoria ?? row.categoria ?? "").trim(),
    tipo: (row.Tipo ?? row.tipo ?? "").trim(),
    marca: (row.Marca ?? row.marca ?? "").trim(),
    clase: (row.Clase ?? row.clase ?? "").trim(),
    linea: (row.Linea ?? row.linea ?? "").trim(),
    unidad: (row.Unidad ?? row.unidad ?? "").trim(),
    precioVenta: parseFloat(row.PRECIO_VENTA ?? row.precioVenta) || 0,
    precioCompra: parseFloat(row.PRECIO_COMPRA ?? row.precioCompra) || 0,
    porcentaje: parseFloat(row.PORCENTAJE ?? row.porcentaje) || 0,
    precioVenta1: parseFloat(row.PRECIO_VENTA1 ?? row.precioVenta1) || 0,
    precioVenta2: parseFloat(row.PRECIO_VENTA2 ?? row.precioVenta2) || 0,
    precioVenta3: parseFloat(row.PRECIO_VENTA3 ?? row.precioVenta3) || 0,
    alicuota: parseFloat(row.Alicuota ?? row.alicuota) || 0,
    stock: parseFloat(row.EXISTENCIA ?? row.stock) || 0,
    minimo: parseInt(row.MINIMO ?? row.minimo) || 0,
    maximo: parseInt(row.MAXIMO ?? row.maximo) || 0,
    plu: parseInt(row.PLU ?? row.plu) || 0,
    barra: (row.Barra ?? row.barra ?? "").trim(),
    nParte: (row.N_PARTE ?? row.nParte ?? "").trim(),
    ubicacion: (row.UBICACION ?? row.ubicacion ?? "").trim(),
    ubicaFisica: (row.UbicaFisica ?? row.ubicaFisica ?? "").trim(),
    garantia: (row.Garantia ?? row.garantia ?? "").trim(),
    fecha: row.FECHA ?? row.fecha ?? null,
    fechaVence: row.FechaVence ?? row.fechaVence ?? null,
    servicio: Boolean(row.Servicio ?? row.servicio),
    costoPromedio: parseFloat(row.COSTO_PROMEDIO ?? row.costoPromedio) || 0,
    estado: row.Eliminado ? "Inactivo" : "Activo",
  };
}

// ============ QUERIES ============

/**
 * Lista artículos con filtros server-side (caché backend).
 * Compatible con MUI DataGrid server-side mode.
 */
export function useArticulosList(filter?: ArticuloFilter) {
  return useQuery({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      if (filter?.sortBy) params.append("sortBy", filter.sortBy);
      if (filter?.sortOrder) params.append("sortOrder", filter.sortOrder);
      if (filter?.categoria) params.append("categoria", filter.categoria);
      if (filter?.marca) params.append("marca", filter.marca);
      if (filter?.linea) params.append("linea", filter.linea);
      if (filter?.tipo) params.append("tipo", filter.tipo);
      if (filter?.clase) params.append("clase", filter.clase);
      if (filter?.unidad) params.append("unidad", filter.unidad);
      if (filter?.ubicacion) params.append("ubicacion", filter.ubicacion);
      if (filter?.estado) params.append("estado", filter.estado);
      if (filter?.precioMin !== undefined) params.append("precioMin", filter.precioMin.toString());
      if (filter?.precioMax !== undefined) params.append("precioMax", filter.precioMax.toString());
      if (filter?.stockMin !== undefined) params.append("stockMin", filter.stockMin.toString());
      if (filter?.stockMax !== undefined) params.append("stockMax", filter.stockMax.toString());
      if (filter?.servicio !== undefined) params.append("servicio", filter.servicio.toString());
      if (filter?.wildcard) params.append("wildcard", filter.wildcard);
      const raw: any = await apiGet(`${API_BASE}?${params.toString()}`);
      // El backend retorna { page, limit, total, rows, fromCache }
      const rows = (raw.rows ?? raw.data ?? raw.items ?? []).map(mapRowToArticulo);
      return {
        data: rows,
        total: raw.total ?? rows.length,
        page: raw.page ?? 1,
        limit: raw.limit ?? 50,
        fromCache: raw.fromCache ?? false,
      };
    },
    // Mantener datos anteriores mientras se cargan nuevos (evitar parpadeo)
    placeholderData: (prev) => prev,
  });
}

/**
 * Obtiene opciones únicas para los combos de filtro (lineas, categorias, etc.)
 * Se carga una sola vez y se mantiene en cache de TanStack Query.
 */
export function useArticuloFilterOptions() {
  return useQuery<ArticuloFilterOptions>({
    queryKey: [QUERY_KEY, "filters"],
    queryFn: () => apiGet(`${API_BASE}/filters`),
    staleTime: 5 * 60 * 1000, // 5 minutos
  });
}

export function useArticuloById(codigoArticulo: string) {
  return useQuery<Articulo>({
    queryKey: [QUERY_KEY, codigoArticulo],
    queryFn: async () => {
      const raw = await apiGet(`${API_BASE}/${codigoArticulo}`);
      return mapRowToArticulo(raw as any);
    },
    enabled: !!codigoArticulo,
  });
}

// ============ MUTATIONS ============

export function useCreateArticulo() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateArticuloDTO) => apiPost(API_BASE, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useUpdateArticulo(codigoArticulo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateArticuloDTO) => apiPut(`${API_BASE}/${codigoArticulo}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}

export function useDeleteArticulo() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (codigoArticulo: string) => apiDelete(`${API_BASE}/${codigoArticulo}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
    },
  });
}
