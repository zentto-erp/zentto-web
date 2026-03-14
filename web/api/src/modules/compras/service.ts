import {
  listDocumentosCompra,
  getDocumentoCompra,
  getDetalleDocumentoCompra,
  emitirDocumentoCompraTx,
  anularDocumentoCompraTx,
  TipoOperacionCompra
} from "../documentos-compra/service.js";

const TIPO: TipoOperacionCompra = "COMPRA";

export type GetComprasParams = {
  numCompra?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getCompras(params: GetComprasParams) {
  return listDocumentosCompra({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    fechaDesde: params.from,
    fechaHasta: params.to,
    search: params.numCompra
  });
}

export async function getCompra(numCompra: string) {
  return getDocumentoCompra(TIPO, numCompra);
}

export async function getDetalleCompra(numCompra: string) {
  return getDetalleDocumentoCompra(TIPO, numCompra);
}

export async function emitirCompraTx(payload: {
  compra: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoCompraTx({
    tipoOperacion: TIPO,
    documento: payload.compra,
    detalle: payload.detalle,
    options: payload.options
  });
}

export async function anularCompraTx(payload: {
  numCompra: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoCompraTx({
    tipoOperacion: TIPO,
    numFact: payload.numCompra,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
