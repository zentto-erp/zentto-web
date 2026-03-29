import { callSp, callSpOut, sql } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listMovInvent(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const search = params.search ? `%${params.search}%` : null;
  const tipo = params.tipo || null;

  const { rows, output } = await callSpOut<any>(
    "usp_Movinvent_List",
    {
      Search: search,
      Tipo: tipo,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { page, limit, total: Number(output.TotalCount ?? 0), rows };
}

export async function getMovInvent(id: string) {
  const rows = await callSp<any>(
    "usp_Inv_Movement_GetById",
    { Id: Number(id) }
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

  const periodo = params.periodo || null;
  const codigo = params.codigo || null;

  const { rows, output } = await callSpOut<any>(
    "usp_Inv_Movement_ListPeriodSummary",
    {
      Periodo: periodo,
      Codigo: codigo,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { page, limit, total: Number(output.TotalCount ?? 0), rows };
}
