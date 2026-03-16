import {
  listDocumentosVenta,
  getDocumentoVenta,
  getDetalleDocumentoVenta,
  emitirDocumentoVentaTx,
  anularDocumentoVentaTx,
  TipoOperacionVenta
} from "../documentos-venta/service.js";

const TIPO: TipoOperacionVenta = "FACT";

export type GetFacturasParams = {
  numFact?: string;
  codUsuario?: string;
  from?: string;
  to?: string;
  page?: string;
  pageSize?: string;
};

export async function getFacturas(params: GetFacturasParams) {
  return listDocumentosVenta({
    tipoOperacion: TIPO,
    codigo: params.codUsuario, 
    page: params.page,
    limit: params.pageSize,
    from: params.from,
    to: params.to,
    search: params.numFact
  });
}

export async function getFactura(numFact: string) {
  return getDocumentoVenta(TIPO, numFact);
}

export async function getDetalleFactura(numFact: string) {
  return getDetalleDocumentoVenta(TIPO, numFact);
}

export async function emitirFacturaTx(payload: {
  factura: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: Record<string, unknown>;
}) {
  return emitirDocumentoVentaTx({
    tipoOperacion: TIPO,
    documento: payload.factura,
    detalle: payload.detalle,
    formasPago: payload.formasPago,
    options: payload.options
  });
}

export async function anularFacturaTx(payload: {
  numFact: string;
  codUsuario?: string;
  motivo?: string;
}) {
  return anularDocumentoVentaTx({
    tipoOperacion: TIPO,
    numFact: payload.numFact,
    codUsuario: payload.codUsuario,
    motivo: payload.motivo
  });
}
