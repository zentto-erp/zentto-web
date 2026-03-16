import { emitirDocumentoVentaTx } from "../documentos-venta/service.js";

export interface CotizacionTxInput {
  cotizacion: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  codUsuario?: string;
}

export interface CotizacionTxResult {
  success: boolean;
  numFact?: string;
  detalleRows?: number;
  message?: string;
}

export async function emitirCotizacionTx(input: CotizacionTxInput): Promise<CotizacionTxResult> {
  const payload = {
    ...input.cotizacion,
    COD_USUARIO: input.codUsuario ?? input.cotizacion.COD_USUARIO ?? "API"
  };
  const result = await emitirDocumentoVentaTx({
    tipoOperacion: "COTIZ",
    documento: payload,
    detalle: input.detalle
  });

  return {
    success: result.ok === true,
    numFact: result.numFact,
    detalleRows: result.detalleRows,
  };
}
