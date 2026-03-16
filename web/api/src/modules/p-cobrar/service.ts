import { callSp, callSpOut, sql } from "../../db/query.js";

async function listReceivable(params: { search?: string; codigo?: string; page?: string; limit?: string; currencyCode?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const { rows, output } = await callSpOut<any>(
    "usp_AR_Receivable_ListFull",
    {
      Search: params.search || null,
      Codigo: params.codigo || null,
      CurrencyCode: params.currencyCode || null,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return { page, limit, total: Number(output.TotalCount ?? 0), rows, executionMode: "canonical" as const };
}

async function getReceivable(id: string) {
  const rows = await callSp<any>("usp_AR_Receivable_GetById", { Id: Number(id) });
  return rows[0] ?? null;
}

async function createReceivable(body: Record<string, unknown>, currencyCode?: string) {
  const codigo = String(body.codigo ?? body.CODIGO ?? "").trim();
  if (!codigo) throw new Error("codigo_cliente_requerido");

  const total = Number(body.total ?? body.TOTAL ?? 0) || 0;
  const pendiente = Number(body.pendiente ?? body.PEND ?? total) || 0;

  await callSpOut(
    "usp_AR_Receivable_Create",
    {
      Codigo: codigo,
      DocumentType: body.tipo ?? body.TIPO ?? "FACT",
      DocumentNumber: body.documento ?? body.DOCUMENTO ?? null,
      IssueDate: body.fecha ?? body.FECHA ?? null,
      DueDate: body.fechaVence ?? body.FECHAVENCE ?? null,
      CurrencyCode: currencyCode ?? body.moneda ?? body.MONEDA ?? "USD",
      TotalAmount: total,
      PendingAmount: pendiente,
      Notes: body.observacion ?? body.OBS ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "canonical" as const };
}

async function updateReceivable(id: string, body: Record<string, unknown>) {
  await callSpOut(
    "usp_AR_Receivable_Update",
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

async function deleteReceivable(id: string) {
  await callSpOut(
    "usp_AR_Receivable_Void",
    { Id: Number(id) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return { ok: true, executionMode: "canonical" as const };
}

export const pCobrarService = {
  list: (p: any) => listReceivable({ ...p, currencyCode: "USD" }),
  get: (id: string) => getReceivable(id),
  create: (b: Record<string, unknown>) => createReceivable(b, "USD"),
  update: (id: string, b: Record<string, unknown>) => updateReceivable(id, b),
  delete: (id: string) => deleteReceivable(id),

  listC: (p: any) => listReceivable({ ...p, currencyCode: "VES" }),
  getC: (id: string) => getReceivable(id),
  createC: (b: Record<string, unknown>) => createReceivable(b, "VES"),
  updateC: (id: string, b: Record<string, unknown>) => updateReceivable(id, b),
  deleteC: (id: string) => deleteReceivable(id)
};
