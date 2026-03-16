import { callSp } from "../../db/query.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export async function listRetenciones(params: { search?: string; tipo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const rows = await callSp<any>('usp_Tax_Retention_List', {
    Search: params.search || null,
    Tipo: params.tipo || null,
    Offset: offset,
    Limit: limit
  });

  const totalRows = await callSp<{ total: number }>('usp_Tax_Retention_Count', {
    Search: params.search || null,
    Tipo: params.tipo || null
  });

  return { page, limit, total: Number(totalRows[0]?.total ?? 0), rows };
}

export async function getRetencion(codigo: string) {
  const rows = await callSp<any>('usp_Tax_Retention_GetByCode', { Codigo: codigo });
  return rows[0] ?? null;
}

export async function createRetencion(body: Record<string, unknown>) {
  return createRow("master", "TaxRetention", body);
}

export async function updateRetencion(codigo: string, body: Record<string, unknown>) {
  return updateRow("master", "TaxRetention", encodeKeyObject({ RetentionCode: codigo }), body);
}

export async function deleteRetencion(codigo: string) {
  return deleteRow("master", "TaxRetention", encodeKeyObject({ RetentionCode: codigo }));
}
