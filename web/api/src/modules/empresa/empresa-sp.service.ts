/**
 * Empresa Service - Stored Procedures
 * Usa SPs: usp_Empresa_Get, usp_Empresa_Update
 * Tabla con un solo registro
 */
import { getPool, sql } from "../../db/mssql.js";

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
  const pool = await getPool();
  const request = new sql.Request(pool);

  const result = await request.execute("usp_Empresa_Get");
  return result.recordset?.[0] || null;
}

export async function updateEmpresaSP(row: Partial<EmpresaRow>): Promise<SpResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("RowXml", sql.NVarChar(sql.MAX), rowToXml(row));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("usp_Empresa_Update");

  const resultado = request.parameters.Resultado?.value as number;
  return {
    success: resultado === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
