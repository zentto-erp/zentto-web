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

export interface AplicarCobroInput {
  requestId: string;
  codCliente: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: DocumentoAplicar[];
  formasPago: FormaPago[];
}

export interface AplicarCobroResult {
  success: boolean;
  numRecibo?: string;
  message: string;
}

export interface ListDocumentosCxCInput {
  codCliente?: string;
  tipoDoc?: string;
  estado?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  page?: number;
  limit?: number;
}

function buildReceiptNumber(prefix: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  return `${prefix}-${stamp}`;
}

function normalizeCxCEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (value === "PENDIENTE") return "PENDING";
  if (value === "PARCIAL") return "PARTIAL";
  if (value === "PAGADO") return "PAID";
  if (value === "ANULADO") return "VOIDED";
  if (["PENDING", "PARTIAL", "PAID", "VOIDED"].includes(value)) return value;
  return null;
}

export async function aplicarCobro(input: AplicarCobroInput): Promise<AplicarCobroResult> {
  const rows = await callSp<{
    NumRecibo: string;
    Resultado: number;
    Mensaje: string;
  }>(
    "usp_cxc_aplicar_cobro",
    {
      RequestId: input.requestId,
      CodCliente: input.codCliente,
      Fecha: input.fecha,
      MontoTotal: input.montoTotal,
      CodUsuario: input.codUsuario || "API",
      Observaciones: input.observaciones || "",
      DocumentosXml: arrayToXml(input.documentos ?? []),
      FormasPagoXml: input.formasPago?.length ? arrayToXml(input.formasPago) : null,
    }
  );

  const result = rows[0];
  const resultado = Number(result?.Resultado ?? -99);
  const mensaje = String(result?.Mensaje ?? "Error desconocido");
  const numRecibo = String(result?.NumRecibo ?? "");

  if (resultado > 0) {
    return { success: true, numRecibo, message: mensaje };
  }
  return { success: false, message: mensaje };
}

export const aplicarCobroTx = aplicarCobro;

export async function listDocumentos(input: ListDocumentosCxCInput) {
  const page = Math.max(1, Number(input.page ?? 1) || 1);
  const limit = Math.min(500, Math.max(1, Number(input.limit ?? 50) || 50));
  const offset = (page - 1) * limit;
  const estado = normalizeCxCEstado(input.estado);

  const { rows, output } = await callSpOut<any>(
    "usp_AR_Receivable_List",
    {
      CodCliente: input.codCliente || null,
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

export async function getDocumentosPendientes(codCliente: string) {
  return callSp<any>("usp_AR_Receivable_GetPending", { CodCliente: codCliente });
}

export async function getSaldoCliente(codCliente: string) {
  const rows = await callSp<any>("usp_AR_Balance_GetByCustomer", { CodCliente: codCliente });
  return rows[0] || null;
}
