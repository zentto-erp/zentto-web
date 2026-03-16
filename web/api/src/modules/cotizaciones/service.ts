import {
  listDocumentosVenta,
  getDocumentoVenta,
  getDetalleDocumentoVenta,
  emitirDocumentoVentaTx,
  anularDocumentoVentaTx,
  TipoOperacionVenta
} from "../documentos-venta/service.js";

const TIPO: TipoOperacionVenta = "COTIZ";

export type GetCotizacionesParams = {
  numCotiz?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getCotizaciones(params: GetCotizacionesParams) {
  return listDocumentosVenta({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    from: params.from,
    to: params.to,
    search: params.numCotiz
  });
}

export async function getCotizacion(numCotiz: string) {
  return getDocumentoVenta(TIPO, numCotiz);
}

export async function getDetalleCotizacion(numCotiz: string) {
  return getDetalleDocumentoVenta(TIPO, numCotiz);
}

export async function emitirCotizacionTx(payload: {
  cotizacion: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoVentaTx({
    tipoOperacion: TIPO,
    documento: payload.cotizacion,
    detalle: payload.detalle,
    formasPago: payload.formasPago,
    options: payload.options
  });
}

export async function anularCotizacionTx(payload: {
  numCotiz: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoVentaTx({
    tipoOperacion: TIPO,
    numFact: payload.numCotiz,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
