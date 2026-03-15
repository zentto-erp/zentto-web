import { callSp, callSpOut, sql } from "../../db/query.js";
import { arrayToXml } from "../../utils/xml.js";

export interface DocumentoAplicar {
  tipoDoc: string;
  numDoc: string;
  montoAplicar: number;
}

export interface FormaPago {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
}

export interface AplicarPagoInput {
  requestId: string;
  codProveedor: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: DocumentoAplicar[];
  formasPago: FormaPago[];
}

export interface AplicarPagoResult {
  success: boolean;
  numPago?: string;
  message: string;
}

export interface ListDocumentosCxPInput {
  codProveedor?: string;
  tipoDoc?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

function buildPaymentNumber(prefix: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  return `${prefix}-${stamp}`;
}

function normalizeCxPEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (value === "PENDIENTE") return "PENDING";
  if (value === "PARCIAL") return "PARTIAL";
  if (value === "PAGADO") return "PAID";
  if (value === "ANULADO") return "VOIDED";
  if (["PENDING", "PARTIAL", "PAID", "VOIDED"].includes(value)) return value;
  return null;
}

export async function aplicarPago(input: AplicarPagoInput): Promise<AplicarPagoResult> {
  const numPago = buildPaymentNumber("PAG");

  const { output } = await callSpOut(
    "usp_AP_Payable_ApplyPayment",
    {
      CodProveedor: input.codProveedor,
      Fecha: input.fecha ? new Date(input.fecha) : null,
      RequestId: input.requestId,
      NumPago: numPago,
      DocumentosXml: arrayToXml(input.documentos ?? []),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? -99);
  const mensaje = String(output.Mensaje ?? "Error desconocido");

  if (resultado > 0) {
    return { success: true, numPago, message: mensaje };
  }
  return { success: false, message: mensaje };
}

export const aplicarPagoTx = aplicarPago;

export async function listDocumentos(input: ListDocumentosCxPInput) {
  const page = Math.max(1, Number(input.page ?? 1) || 1);
  const limit = Math.min(500, Math.max(1, Number(input.limit ?? 50) || 50));
  const offset = (page - 1) * limit;
  const estado = normalizeCxPEstado(input.estado);

  const { rows, output } = await callSpOut<any>(
    "usp_AP_Payable_List",
    {
      CodProveedor: input.codProveedor || null,
      TipoDoc: input.tipoDoc || null,
      Estado: estado,
      FechaDesde: input.fechaDesde || null,
      FechaHasta: input.fechaHasta || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getDocumentosPendientes(codProveedor: string) {
  return callSp<any>("usp_AP_Payable_GetPending", { CodProveedor: codProveedor });
}

export async function getSaldoProveedor(codProveedor: string) {
  const rows = await callSp<any>("usp_AP_Balance_GetBySupplier", { CodProveedor: codProveedor });
  return rows[0] || null;
}
