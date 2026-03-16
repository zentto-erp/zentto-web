import {
  listDocumentosVenta,
  getDocumentoVenta,
  getDetalleDocumentoVenta,
  emitirDocumentoVentaTx,
  anularDocumentoVentaTx,
  TipoOperacionVenta
} from "../documentos-venta/service.js";

export type GetNotasParams = {
  numNota?: string;
  tipo?: TipoOperacionVenta;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getNotas(params: GetNotasParams) {
  return listDocumentosVenta({
    tipoOperacion: params.tipo ?? "NOTACRED",
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    from: params.from,
    to: params.to,
    search: params.numNota
  });
}

export async function getNota(tipo: TipoOperacionVenta, numNota: string) {
  return getDocumentoVenta(tipo, numNota);
}

export async function getDetalleNota(tipo: TipoOperacionVenta, numNota: string) {
  return getDetalleDocumentoVenta(tipo, numNota);
}

export async function emitirNotaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  nota: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoVentaTx({
    tipoOperacion: payload.tipoOperacion,
    documento: payload.nota,
    detalle: payload.detalle,
    formasPago: payload.formasPago,
    options: payload.options
  });
}

export async function anularNotaTx(payload: {
  tipoOperacion: TipoOperacionVenta;
  numNota: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoVentaTx({
    tipoOperacion: payload.tipoOperacion,
    numFact: payload.numNota,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
