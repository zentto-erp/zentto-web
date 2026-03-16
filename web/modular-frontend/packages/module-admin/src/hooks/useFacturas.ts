"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiPost } from "@zentto/shared-api";

const QUERY_KEY = "facturas";
const API_BASE = "/api/v1/documentos-venta";
const TIPO_OPERACION = "FACT";

type LegacyFacturaListRow = {
  NUM_FACT?: string;
  CODIGO?: string;
  NOMBRE?: string;
  FECHA?: string;
  TOTAL?: number;
  PAGO?: string;
  ANULADA?: number;
};

type FacturaListItem = {
  numeroFactura: string;
  codigoCliente: string;
  nombreCliente: string;
  fecha: string;
  totalFactura: number;
  estado: string;
};

type FacturasListResponse = {
  data: FacturaListItem[];
  total: number;
  page: number;
  limit: number;
};

type FacturasFilter = {
  search?: string;
  page?: number;
  limit?: number;
  cliente?: string;
  estado?: string;
};

type FacturaDetalleInput = {
  cantidad?: number;
  precioUnitario?: number;
  precio?: number;
  descuento?: number;
  alicuota?: number;
  CANTIDAD?: number;
  PRECIO?: number;
  DESCUENTO?: number;
  ALICUOTA?: number;
  codigoArticulo?: string;
  articulo?: string;
  COD_SERV?: string;
  CODIGO?: string;
};

type FacturaPayloadInput = Record<string, unknown> & {
  detalles?: FacturaDetalleInput[];
  formasPago?: unknown[];
  totalFactura?: number;
  pago?: string;
  tipoPago?: string;
  numeroFactura?: string;
  NUM_FACT?: string;
  codigoCliente?: string;
  cliente?: string;
  CODIGO?: string;
  nombreCliente?: string;
  NOMBRE?: string;
  fecha?: string;
  referencia?: string | null;
  observaciones?: string | null;
  codUsuario?: string;
  options?: Record<string, unknown>;
};

type FacturaByIdResponse = {
  numeroFactura: string;
  codigoCliente: string;
  nombreCliente: string;
  fecha: string;
  referencia: string;
  observaciones: string;
  totalFactura: number;
  estado: string;
};

function normalizeFacturaRow(row: LegacyFacturaListRow): FacturaListItem {
  const anulado = Number(row.ANULADA ?? 0) !== 0;
  return {
    numeroFactura: String(row.NUM_FACT ?? ""),
    codigoCliente: String(row.CODIGO ?? ""),
    nombreCliente: String(row.NOMBRE ?? ""),
    fecha: row.FECHA ? String(row.FECHA).slice(0, 10) : "",
    totalFactura: Number(row.TOTAL ?? 0),
    estado: anulado ? "Anulada" : String(row.PAGO ?? "Emitida")
  };
}

function buildEmitirFacturaPayload(data: FacturaPayloadInput, numeroFactura?: string) {
  const detalles = Array.isArray(data.detalles) ? data.detalles : [];
  const total =
    Number(data.totalFactura ?? 0) ||
    detalles.reduce(
      (acc: number, d: FacturaDetalleInput) =>
        acc + Number(d.cantidad ?? 0) * Number(d.precioUnitario ?? d.precio ?? 0) - Number(d.descuento ?? 0),
      0
    );
  const pago = String(data.pago ?? data.tipoPago ?? "CONTADO").toUpperCase();

  return {
    tipoOperacion: TIPO_OPERACION,
    documento: {
      NUM_FACT: String(numeroFactura ?? data.numeroFactura ?? data.NUM_FACT ?? "").trim() || undefined,
      CODIGO: data.codigoCliente ?? data.cliente ?? data.CODIGO,
      NOMBRE: data.nombreCliente ?? data.NOMBRE,
      FECHA: data.fecha,
      REFERENCIA: data.referencia ?? null,
      OBSERVACIONES: data.observaciones ?? null,
      PAGO: pago,
      TOTAL: total,
      COD_USUARIO: data.codUsuario ?? "SUP"
    },
    detalle: detalles.map((d: FacturaDetalleInput) => ({
      COD_SERV: d.codigoArticulo ?? d.articulo ?? d.COD_SERV ?? d.CODIGO,
      CANTIDAD: Number(d.cantidad ?? d.CANTIDAD ?? 0),
      PRECIO: Number(d.precioUnitario ?? d.precio ?? d.PRECIO ?? 0),
      DESCUENTO: Number(d.descuento ?? d.DESCUENTO ?? 0),
      ALICUOTA: Number(d.alicuota ?? d.ALICUOTA ?? 16)
    })),
    formasPago: Array.isArray(data.formasPago) ? data.formasPago : [],
    options: data.options ?? {
      actualizarInventario: true,
      generarCxC: pago === "CREDITO",
      actualizarSaldosCliente: true
    }
  };
}

export function useFacturasList(filter?: FacturasFilter) {
  return useQuery<FacturasListResponse>({
    queryKey: [QUERY_KEY, "list", filter],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.append("tipoOperacion", TIPO_OPERACION);
      if (filter?.search) params.append("search", filter.search);
      if (filter?.page) params.append("page", String(filter.page));
      if (filter?.limit) params.append("limit", String(filter.limit));
      if (filter?.cliente) params.append("codigo", filter.cliente);
      if (filter?.estado) params.append("estado", filter.estado);

      const resp = await apiGet(`${API_BASE}?${params.toString()}`);
      const rows = Array.isArray(resp?.rows) ? (resp.rows as LegacyFacturaListRow[]) : [];

      return {
        data: rows.map(normalizeFacturaRow),
        total: Number(resp?.total ?? rows.length),
        page: Number(resp?.page ?? filter?.page ?? 1),
        limit: Number(resp?.limit ?? filter?.limit ?? 50)
      };
    }
  });
}

export function useFacturaById(numeroFactura: string) {
  return useQuery<FacturaByIdResponse>({
    queryKey: [QUERY_KEY, numeroFactura],
    queryFn: async () => {
      const row = await apiGet(`${API_BASE}/${TIPO_OPERACION}/${encodeURIComponent(numeroFactura)}`);
      return {
        numeroFactura: row?.NUM_FACT ?? numeroFactura,
        codigoCliente: row?.CODIGO ?? "",
        nombreCliente: row?.NOMBRE ?? "",
        fecha: row?.FECHA ? String(row.FECHA).slice(0, 10) : "",
        referencia: row?.REFERENCIA ?? "",
        observaciones: row?.OBSERVACIONES ?? "",
        totalFactura: Number(row?.TOTAL ?? 0),
        estado: Number(row?.ANULADA ?? 0) ? "Anulada" : String(row?.PAGO ?? "Emitida")
      };
    },
    enabled: !!numeroFactura
  });
}

export function useCreateFactura() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: FacturaPayloadInput) => apiPost(`${API_BASE}/emitir-tx`, buildEmitirFacturaPayload(data)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: ["clientes"] });
      queryClient.invalidateQueries({ queryKey: ["inventario"] });
      queryClient.invalidateQueries({ queryKey: ["p-cobrar"] });
    }
  });
}

export function useUpdateFactura(numeroFactura: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: FacturaPayloadInput) =>
      apiPost(`${API_BASE}/emitir-tx`, buildEmitirFacturaPayload(data, numeroFactura))
    ,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY, numeroFactura] });
    }
  });
}

export function useDeleteFactura() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (numeroFactura: string) =>
      apiPost(`${API_BASE}/anular-tx`, {
        tipoOperacion: TIPO_OPERACION,
        numFact: numeroFactura
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [QUERY_KEY] });
      queryClient.invalidateQueries({ queryKey: ["clientes"] });
      queryClient.invalidateQueries({ queryKey: ["inventario"] });
      queryClient.invalidateQueries({ queryKey: ["p-cobrar"] });
    }
  });
}
