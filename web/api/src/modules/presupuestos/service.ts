import {
  listDocumentosVenta,
  getDocumentoVenta,
  getDetalleDocumentoVenta,
  emitirDocumentoVentaTx,
  anularDocumentoVentaTx,
  TipoOperacionVenta
} from "../documentos-venta/service.js";

const TIPO: TipoOperacionVenta = "PRESUP";

export type GetPresupuestosParams = {
  numPresup?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getPresupuestos(params: GetPresupuestosParams) {
  return listDocumentosVenta({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    from: params.from,
    to: params.to,
    search: params.numPresup
  });
}

export async function getPresupuesto(numPresup: string) {
  return getDocumentoVenta(TIPO, numPresup);
}

export async function getDetallePresupuesto(numPresup: string) {
  return getDetalleDocumentoVenta(TIPO, numPresup);
}

export async function emitirPresupuestoTx(payload: {
  presupuesto: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoVentaTx({
    tipoOperacion: TIPO,
    documento: payload.presupuesto,
    detalle: payload.detalle,
    formasPago: payload.formasPago,
    options: payload.options
  });
}

export async function anularPresupuestoTx(payload: {
  numPresup: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoVentaTx({
    tipoOperacion: TIPO,
    numFact: payload.numPresup,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
