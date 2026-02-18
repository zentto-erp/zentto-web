import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

export type ListCotizacionesParams = { search?: string; codigo?: string; page?: string; limit?: string };
export type ListCotizacionesResult = { page: number; limit: number; total: number; rows: any[]; executionMode?: "sp" | "ts_fallback" };

export async function listCotizaciones(params: ListCotizacionesParams): Promise<ListCotizacionesResult> {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("Search", sql.NVarChar(100), params.search ?? null);
    req.input("Codigo", sql.NVarChar(10), params.codigo ?? null);
    req.input("Page", sql.Int, page);
    req.input("Limit", sql.Int, limit);
    req.output("TotalCount", sql.Int);
    const result = await req.execute("usp_Cotizacion_List");
    const total = (req.parameters.TotalCount?.value as number) ?? 0;
    const rows = (result.recordset ?? []) as any[];
    return { page, limit, total, rows, executionMode: "sp" };
  } catch {
    // Fallback
  }

  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("CODIGO = @codigo");
    sqlParams.codigo = params.codigo;
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Cotizacion ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const totalResult = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Cotizacion ${clause}`, sqlParams);
  return { page, limit, total: Number(totalResult[0]?.total ?? 0), rows, executionMode: "ts_fallback" };
}

export async function getCotizacion(numFact: string): Promise<{ row: any; executionMode?: "sp" | "ts_fallback" } | { row: null; executionMode?: "sp" | "ts_fallback" }> {
  try {
    const pool = await getPool();
    const req = pool.request();
    req.input("NumFact", sql.NVarChar(20), numFact);
    const result = await req.execute("usp_Cotizacion_GetByNumFact");
    const rows = (result.recordset ?? []) as any[];
    return { row: rows[0] ?? null, executionMode: "sp" };
  } catch {
    // Fallback
  }
  const rows = await query<any>("SELECT TOP 1 * FROM Cotizacion WHERE NUM_FACT = @numFact", { numFact });
  return { row: rows[0] ?? null, executionMode: "ts_fallback" };
}

export async function getCotizacionDetalle(numFact: string) {
  return query<any>("SELECT * FROM Detalle_Cotizacion WHERE NUM_FACT = @numFact ORDER BY ID", { numFact });
}

export async function createCotizacion(body: Record<string, unknown>) {
  return createRow("dbo", "Cotizacion", body);
}

export async function updateCotizacion(numFact: string, body: Record<string, unknown>) {
  return updateRow("dbo", "Cotizacion", encodeKeyObject({ NUM_FACT: numFact }), body);
}

export async function deleteCotizacion(numFact: string) {
  return deleteRow("dbo", "Cotizacion", encodeKeyObject({ NUM_FACT: numFact }));
}

export async function createCotizacionTx(payload: { cotizacion: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({
    headerTable: "[dbo].[Cotizacion]",
    detailTable: "[dbo].[Detalle_Cotizacion]",
    header: payload.cotizacion ?? {},
    details: payload.detalle ?? [],
    linkFields: ["NUM_FACT", "SERIALTIPO"]
  });
}
