import {
  listDocumentosVenta,
  getDocumentoVenta,
  getDetalleDocumentoVenta,
  emitirDocumentoVentaTx,
  anularDocumentoVentaTx,
  TipoOperacionVenta
} from "../documentos-venta/service.js";

const TIPO: TipoOperacionVenta = "PEDIDO";

export type GetPedidosParams = {
  numPedido?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getPedidos(params: GetPedidosParams) {
  return listDocumentosVenta({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    from: params.from,
    to: params.to,
    search: params.numPedido
  });
}

export async function getPedido(numPedido: string) {
  return getDocumentoVenta(TIPO, numPedido);
}

export async function getDetallePedido(numPedido: string) {
  return getDetalleDocumentoVenta(TIPO, numPedido);
}

export async function emitirPedidoTx(payload: {
  pedido: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoVentaTx({
    tipoOperacion: TIPO,
    documento: payload.pedido,
    detalle: payload.detalle,
    formasPago: payload.formasPago,
    options: payload.options
  });
}

export async function anularPedidoTx(payload: {
  numPedido: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoVentaTx({
    tipoOperacion: TIPO,
    numFact: payload.numPedido,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
