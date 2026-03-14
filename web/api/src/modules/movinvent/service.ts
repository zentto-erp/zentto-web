import { query } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

const MOVEMENT_TABLE = "master.InventoryMovement";
const SUMMARY_TABLE  = "master.InventoryPeriodSummary";

export async function listMovInvent(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = ["IsDeleted = 0"];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) {
    where.push("(ProductCode LIKE @search OR ProductName LIKE @search OR DocumentRef LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.tipo) { where.push("MovementType = @tipo"); sqlParams.tipo = params.tipo; }
  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<any>(
    `SELECT MovementId, ProductCode AS Codigo, ProductName AS Product, DocumentRef AS Documento,
            MovementType AS Tipo, MovementDate AS Fecha, Quantity, UnitCost, TotalCost, Notes
     FROM ${MOVEMENT_TABLE} ${clause}
     ORDER BY MovementDate DESC, MovementId DESC
     OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM ${MOVEMENT_TABLE} ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}

export async function getMovInvent(id: string) {
  const rows = await query<any>(
    `SELECT MovementId, ProductCode AS Codigo, ProductName AS Product, DocumentRef AS Documento,
            MovementType AS Tipo, MovementDate AS Fecha, Quantity, UnitCost, TotalCost, Notes
     FROM ${MOVEMENT_TABLE} WHERE MovementId = @id AND IsDeleted = 0`,
    { id: Number(id) }
  );
  return rows[0] ?? null;
}

export async function createMovInvent(body: Record<string, unknown>) {
  return createRow("master", "InventoryMovement", body);
}

export async function updateMovInvent(id: string, body: Record<string, unknown>) {
  return updateRow("master", "InventoryMovement", encodeKeyObject({ MovementId: Number(id) }), body);
}

export async function deleteMovInvent(id: string) {
  return deleteRow("master", "InventoryMovement", encodeKeyObject({ MovementId: Number(id) }));
}

export async function listMovInventMes(params: { periodo?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.periodo) { where.push("Period = @periodo"); sqlParams.periodo = params.periodo; }
  if (params.codigo)  { where.push("ProductCode = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(
    `SELECT SummaryId, Period AS Periodo, ProductCode AS Codigo,
            OpeningQty, InboundQty, OutboundQty, ClosingQty, SummaryDate AS fecha, IsClosed
     FROM ${SUMMARY_TABLE} ${clause}
     ORDER BY Period DESC, ProductCode
     OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM ${SUMMARY_TABLE} ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
