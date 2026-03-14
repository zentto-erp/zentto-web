import {
  listDocumentosCompra,
  getDocumentoCompra,
  getDetalleDocumentoCompra,
  emitirDocumentoCompraTx,
  anularDocumentoCompraTx,
  TipoOperacionCompra
} from "../documentos-compra/service.js";

const TIPO: TipoOperacionCompra = "ORDEN";

export type GetOrdenesParams = {
  numOrden?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getOrdenes(params: GetOrdenesParams) {
  return listDocumentosCompra({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    fechaDesde: params.from,
    fechaHasta: params.to,
    search: params.numOrden
  });
}

export async function getOrden(numOrden: string) {
  return getDocumentoCompra(TIPO, numOrden);
}

export async function getDetalleOrden(numOrden: string) {
  return getDetalleDocumentoCompra(TIPO, numOrden);
}

export async function emitirOrdenTx(payload: {
  orden: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoCompraTx({
    tipoOperacion: TIPO,
    documento: payload.orden,
    detalle: payload.detalle,
    options: payload.options
  });
}

export async function anularOrdenTx(payload: {
  numOrden: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoCompraTx({
    tipoOperacion: TIPO,
    numFact: payload.numOrden,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
