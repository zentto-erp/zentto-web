// hooks/useArticulos.ts
// Hook de TanStack Query para el módulo de artículos.
// Mapea la respuesta cruda del API (nombres SQL) al tipo Articulo del frontend.
"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Articulo, CreateArticuloDTO, UpdateArticuloDTO, ArticuloFilter, ArticuloFilterOptions, PaginatedResponse } from "@zentto/shared-api/types";
import { apiGet, apiPost, apiPut, apiDelete } from "@zentto/shared-api";

const QUERY_KEY = "articulos";
const API_BASE = "/api/v1/articulos";
type RawArticuloRow = Record<string, any>;

/**
 * Convierte una fila cruda del API (nombres SQL como CODIGO, DESCRIPCION, etc.)
 * al tipo Articulo que consume el frontend.
 * El campo DescripcionCompleta viene calculado del SP.
 */
function mapRowToArticulo(r: RawArticuloRow): Articulo {
  // Descripción compuesta: viene del SP como DescripcionCompleta
  // o se calcula aquí como fallback
  const descCompleta = r.DescripcionCompleta
    ?? [r.Categoria, r.Tipo, r.DESCRIPCION, r.Marca, r.Clase]
         .map((s) => String(s ?? "").trim())
         .filter(Boolean)
         .join(" ");

  return {
    codigo: r.CODIGO ?? r.codigo ?? "",
    descripcionCompleta: descCompleta,
    nombre: descCompleta,   // Alias para compatibilidad
    // Campos separados (para edición individual)
    descripcion: (r.DESCRIPCION ?? r.descripcion ?? "").trim(),
    categoria: (r.Categoria ?? r.categoria ?? "").trim(),
    tipo: (r.Tipo ?? r.tipo ?? "").trim(),
    marca: (r.Marca ?? r.marca ?? "").trim(),
    clase: (r.Clase ?? r.clase ?? "").trim(),
    linea: (r.Linea ?? r.linea ?? "").trim(),
    // Precios
    precio: r.PRECIO_VENTA ?? r.precio ?? 0,
    precioVenta: r.PRECIO_VENTA ?? r.precioVenta ?? 0,
    precioCompra: r.PRECIO_COMPRA ?? r.precioCompra ?? 0,
    // Inventario
    stock: r.EXISTENCIA ?? r.stock ?? 0,
    unidad: (r.Unidad ?? r.unidad ?? "").trim(),
    estado: r.Eliminado === true ? "Inactivo" : "Activo",
    // Campos adicionales
    referencia: (r.Referencia ?? "").trim(),
    alicuota: r.Alicuota ?? 0,
    plu: r.PLU ?? 0,
    barra: (r.Barra ?? "").trim(),
    nParte: (r.N_PARTE ?? "").trim(),
    ubicacion: (r.UBICACION ?? "").trim(),
    ubicaFisica: (r.UbicaFisica ?? "").trim(),
    garantia: (r.Garantia ?? "").trim(),
    fecha: r.FECHA ?? null,
    fechaVence: r.FechaVence ?? null,
    servicio: r.Servicio === true || r.Servicio === 1,
    precioVenta1: r.PRECIO_VENTA1 ?? 0,
    precioVenta2: r.PRECIO_VENTA2 ?? 0,
    precioVenta3: r.PRECIO_VENTA3 ?? 0,
    costoPromedio: r.COSTO_PROMEDIO ?? 0,
    minimo: r.MINIMO ?? 0,
    maximo: r.MAXIMO ?? 0,
    id: r.Id ?? r.id,
  };
}

// ============ QUERIES ============

export function useArticulosList(filter?: ArticuloFilter) {
  return useQuery<PaginatedResponse<Articulo>>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", filter.page.toString());
      if (filter?.limit) params.append("limit", filter.limit.toString());
      if (filter?.sortBy) params.append("sortBy", filter.sortBy);
      if (filter?.sortOrder) params.append("sortOrder", filter.sortOrder);
      if (filter?.linea) params.append("linea", filter.linea);
      if (filter?.categoria) params.append("categoria", filter.categoria);
      if (filter?.marca) params.append("marca", filter.marca);
      if (filter?.tipo) params.append("tipo", filter.tipo);
      if (filter?.clase) params.append("clase", filter.clase);
      if (filter?.unidad) params.append("unidad", filter.unidad);
      if (filter?.ubicacion) params.append("ubicacion", filter.ubicacion);
      if (filter?.estado) params.append("estado", filter.estado);
      if (filter?.precioMin != null) params.append("precioMin", filter.precioMin.toString());
      if (filter?.precioMax != null) params.append("precioMax", filter.precioMax.toString());
      if (filter?.stockMin != null) params.append("stockMin", filter.stockMin.toString());
      if (filter?.stockMax != null) params.append("stockMax", filter.stockMax.toString());
      if (filter?.servicio != null) params.append("servicio", filter.servicio.toString());
      if (filter?.wildcard) params.append("wildcard", filter.wildcard);
      const res = await apiGet(`${API_BASE}?${params.toString()}`);
      // El API devuelve { page, limit, total, rows: [...] }
      // El frontend espera PaginatedResponse con data/items
      const rawRows = (res.rows ?? res.data ?? res.items ?? []) as RawArticuloRow[];
      const mapped = rawRows.map(mapRowToArticulo);
      return {
        data: mapped,
        items: mapped,
        total: res.total ?? 0,
        page: res.page ?? 1,
        pageSize: res.limit ?? filter?.limit ?? 10,
        totalPages: Math.ceil((res.total ?? 0) / (res.limit ?? filter?.limit ?? 10)),
      };
    },
  });
}

export function useArticuloById(codigoArticulo: string) {
  return useQuery<Articulo>({
    queryKey: [QUERY_KEY, codigoArticulo],
    queryFn: async () => {
      const raw = await apiGet(`${API_BASE}/${codigoArticulo}`);
      return mapRowToArticulo(raw);
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
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, codigoArticulo] });
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

// ============ FILTROS ============

export function useArticuloFilterOptions() {
  return useQuery<ArticuloFilterOptions>({
    queryKey: [QUERY_KEY, "filterOptions"],
    queryFn: () => apiGet(`${API_BASE}/filters`),
    staleTime: 5 * 60 * 1000, // 5 minutos
  });
}
