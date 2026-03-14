import { callSp, callSpOut, sql } from "../../db/query.js";

export async function listCuentasPorPagar(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<any>(
    "usp_AP_Payable_ListFull",
    {
      Search: params.search || null,
      Codigo: params.codigo || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { page, limit, total: Number(output.TotalCount ?? 0), rows, executionMode: "canonical" as const };
}

export async function getCuentaPorPagar(id: string) {
  const rows = await callSp<any>("usp_AP_Payable_GetById", { Id: Number(id) });
  return rows[0] ?? null;
}

export async function createCuentaPorPagar(body: Record<string, unknown>) {
  const codigo = String(body.codigo ?? body.CODIGO ?? "").trim();
  if (!codigo) throw new Error("codigo_proveedor_requerido");

  const total = Number(body.total ?? body.TOTAL ?? 0) || 0;
  const pendiente = Number(body.pendiente ?? body.PEND ?? total) || 0;

  await callSpOut(
    "usp_AP_Payable_Create",
    {
      Codigo: codigo,
      DocumentType: body.tipo ?? body.TIPO ?? "COMPRA",
      DocumentNumber: body.documento ?? body.DOCUMENTO ?? null,
      IssueDate: body.fecha ?? body.FECHA ?? null,
      DueDate: body.fechaVence ?? body.FECHAVENCE ?? null,
      CurrencyCode: body.moneda ?? body.MONEDA ?? "USD",
      TotalAmount: total,
      PendingAmount: pendiente,
      Notes: body.observacion ?? body.OBS ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "canonical" as const };
}

export async function updateCuentaPorPagar(id: string, body: Record<string, unknown>) {
  await callSpOut(
    "usp_AP_Payable_Update",
    {
      Id: Number(id),
      DocumentType: body.tipo ?? body.TIPO ?? null,
      DocumentNumber: body.documento ?? body.DOCUMENTO ?? null,
      IssueDate: body.fecha ?? body.FECHA ?? null,
      DueDate: body.fechaVence ?? body.FECHAVENCE ?? null,
      TotalAmount: body.total ?? body.TOTAL ?? null,
      PendingAmount: body.pendiente ?? body.PEND ?? null,
      Status: body.estado ?? body.ESTADO ?? null,
      CurrencyCode: body.moneda ?? body.MONEDA ?? null,
      Notes: body.observacion ?? body.OBS ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "canonical" as const };
}

export async function deleteCuentaPorPagar(id: string) {
  await callSpOut(
    "usp_AP_Payable_Void",
    { Id: Number(id) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "canonical" as const };
}
