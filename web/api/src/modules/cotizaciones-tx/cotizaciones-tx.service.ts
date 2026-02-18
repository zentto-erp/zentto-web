/**
 * Cotizaciones Transaccional Service
 * Usa SP: sp_emitir_cotizacion_tx
 */
import { getPool, sql } from "../../db/mssql.js";

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

function recordToXmlAttrs(row: Record<string, unknown>): string {
  return Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => {
      const escaped = String(v)
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
      return `${k}="${escaped}"`;
    })
    .join(" ");
}

function cotizacionToXml(cotizacion: Record<string, unknown>): string {
  const attrs = recordToXmlAttrs(cotizacion);
  return `<cotizacion ${attrs}/>`;
}

function detalleToXml(detalle: Record<string, unknown>[]): string {
  const rows = detalle
    .map((row) => `<row ${recordToXmlAttrs(row)} />`)
    .join("");
  return `<detalles>${rows}</detalles>`;
}

export async function emitirCotizacionTx(input: CotizacionTxInput): Promise<CotizacionTxResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CotizacionXml", sql.NVarChar(sql.MAX), cotizacionToXml(input.cotizacion));
  request.input("DetalleXml", sql.NVarChar(sql.MAX), detalleToXml(input.detalle));
  request.input("CodUsuario", sql.NVarChar(60), input.codUsuario || "API");

  const result = await request.execute("sp_emitir_cotizacion_tx");
  const output = result.recordset?.[0];

  return {
    success: output?.ok === true,
    numFact: output?.numFact,
    detalleRows: output?.detalleRows,
  };
}
