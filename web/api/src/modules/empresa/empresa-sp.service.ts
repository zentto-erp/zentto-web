/**
 * Empresa Service - Stored Procedures
 * Usa SPs: usp_Empresa_Get, usp_Empresa_Update
 * Tabla con un solo registro
 */
import { callSp, callSpOut, sql } from "../../db/query.js";

export interface EmpresaRow {
  Empresa?: string;
  RIF?: string;
  Nit?: string;
  Telefono?: string;
  Direccion?: string;
  [key: string]: unknown;
}

export interface SpResult {
  success: boolean;
  message: string;
}

function rowToXml(row: Record<string, unknown>): string {
  const attrs = Object.entries(row)
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
  return `<row ${attrs}/>`;
}

export async function getEmpresaSP(): Promise<EmpresaRow | null> {
  const rows = await callSp<EmpresaRow>("usp_Empresa_Get");
  return rows[0] || null;
}

export async function updateEmpresaSP(row: Partial<EmpresaRow>): Promise<SpResult> {
  const { output } = await callSpOut<never>(
    "usp_Empresa_Update",
    { RowXml: rowToXml(row) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    success: Number(output.Resultado) === 1,
    message: String(output.Mensaje ?? "OK"),
  };
}
