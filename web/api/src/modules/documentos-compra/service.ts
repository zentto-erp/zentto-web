import { anularCompraTx, emitirCompraTx, getCompra, getDetalleCompra, getIndicadoresCompra, listCompras } from "../compras/service.js";
import { cerrarOrdenConCompraTx, createOrdenTx, getOrden, getOrdenDetalle, listOrdenes } from "../ordenes/service.js";

export type TipoOperacionCompra = "ORDEN" | "COMPRA";

export function normalizeTipoOperacionCompra(value?: string): TipoOperacionCompra {
  const raw = String(value || "COMPRA").trim().toUpperCase();
  const v = raw.replace(/[\s\-]/g, "_");
  const map: Record<string, TipoOperacionCompra> = {
    ORDEN: "ORDEN",
    ORDENES: "ORDEN",
    ORDEN_COMPRA: "ORDEN",
    ORDENES_COMPRA: "ORDEN",
    ORDC: "ORDEN",
    OC: "ORDEN",
    COMPRA: "COMPRA",
    COMPRAS: "COMPRA",
    FACT: "COMPRA",
    FACTURA: "COMPRA",
    NC: "COMPRA",
    ND: "COMPRA"
  };
  const normalized = map[v] ?? map[raw];
  if (!normalized) return "COMPRA"; // Default en lugar de error
  return normalized;
}

export async function listDocumentosCompra(input: {
  tipoOperacion: TipoOperacionCompra;
  search?: string;
  codigo?: string;
  proveedor?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: string;
  limit?: string;
}) {
  if (input.tipoOperacion === "ORDEN") {
    return listOrdenes({ search: input.search, codigo: input.codigo, page: input.page, limit: input.limit });
  }
  return listCompras({
    search: input.search,
    proveedor: input.proveedor ?? input.codigo,
    estado: input.estado,
    fechaDesde: input.fechaDesde,
    fechaHasta: input.fechaHasta,
    page: input.page,
    limit: input.limit
  });
}

export async function getDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  if (tipoOperacion === "ORDEN") return { row: await getOrden(numFact), executionMode: undefined };
  return getCompra(numFact);
}

export async function getDetalleDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  if (tipoOperacion === "ORDEN") return getOrdenDetalle(numFact);
  return getDetalleCompra(numFact);
}

export async function getIndicadoresDocumentoCompra(tipoOperacion: TipoOperacionCompra, numFact: string) {
  if (tipoOperacion === "ORDEN") return null;
  return getIndicadoresCompra(numFact);
}

export async function emitirDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
  documento: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  if (payload.tipoOperacion === "ORDEN") {
    return createOrdenTx({ orden: payload.documento, detalle: payload.detalle });
  }
  return emitirCompraTx({
    compra: payload.documento,
    detalle: payload.detalle,
    options: payload.options as any
  });
}

export async function anularDocumentoCompraTx(payload: {
  tipoOperacion: TipoOperacionCompra;
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  if (payload.tipoOperacion === "ORDEN") {
    throw new Error("anular_orden_no_implementado");
  }
  return anularCompraTx({ numFact: payload.numFact, codUsuario: payload.codUsuario, motivo: payload.motivo });
}

export async function cerrarOrdenConCompraDocumentoTx(payload: {
  numFactOrden: string;
  compra: Record<string, unknown>;
  detalle?: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxP?: boolean;
    actualizarSaldosProveedor?: boolean;
  };
}) {
  return cerrarOrdenConCompraTx(payload);
}
