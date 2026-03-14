import { callSp, callSpOut, callSpTx, sql } from "../../db/query.js";
import { getPool } from "../../db/mssql.js";

type QueryParams = { search?: string; codigo?: string; page?: string; limit?: string };

type Context = { companyId: number; branchId: number };

type CreateTxPayload = { abono: Record<string, unknown>; detalle: Record<string, unknown>[] };

type ServiceOptions = { currencyCode?: string };

/* ---------- pure helpers (kept as-is) ---------- */

function pickString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function pickNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseAmount(body: Record<string, unknown>): number {
  const amount =
    pickNumber(body.monto) ??
    pickNumber(body.MONTO) ??
    pickNumber(body.importe) ??
    pickNumber(body.IMPORTE) ??
    pickNumber(body.total) ??
    pickNumber(body.TOTAL) ??
    pickNumber(body.abono) ??
    pickNumber(body.ABONO) ??
    0;

  if (amount <= 0) throw new Error("monto_invalido");
  return amount;
}

function parseApplyDate(body: Record<string, unknown>): Date {
  const raw = body.fecha ?? body.FECHA ?? body.applyDate ?? body.ApplyDate;
  if (!raw) return new Date();
  const date = new Date(String(raw));
  if (Number.isNaN(date.getTime())) throw new Error("fecha_invalida");
  return date;
}

function parseReference(body: Record<string, unknown>): string {
  return (
    pickString(body.referencia) ??
    pickString(body.REFERENCIA) ??
    pickString(body.concepto) ??
    pickString(body.Concepto) ??
    pickString(body.PaymentReference) ??
    pickString(body.OBS) ??
    `ABONO-${Date.now()}`
  );
}

function normalizeDocType(body: Record<string, unknown>): string | null {
  return (
    pickString(body.tipoDoc) ??
    pickString(body.TIPO_DOC) ??
    pickString(body.tipo) ??
    pickString(body.TIPO)
  );
}

function toId(value: string): number {
  const id = Number(value);
  if (!Number.isFinite(id) || id <= 0) throw new Error("id_invalido");
  return id;
}

/* ---------- context resolution via SP ---------- */

async function getDefaultContext(): Promise<Context> {
  const rows = await callSp<{ CompanyId: number; BranchId: number; UserId: number | null }>(
    "usp_Cfg_ResolveContext"
  );

  const row = rows[0];
  if (!row) throw new Error("context_not_found");

  const companyId = Number(row.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");

  const branchId = Number(row.BranchId ?? 0);
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");

  return { companyId, branchId };
}

/* ---------- document resolution via SP (transactional) ---------- */

async function resolveReceivableDocumentId(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>
): Promise<number> {
  const directId =
    pickNumber(body.ReceivableDocumentId) ??
    pickNumber(body.receivableDocumentId) ??
    pickNumber(body.DocumentoId) ??
    pickNumber(body.documentoId) ??
    pickNumber(body.idDocumento) ??
    pickNumber(body.IdDocumento);

  if (directId && directId > 0) return directId;

  const documentNumber =
    pickString(body.documento) ??
    pickString(body.DOCUMENTO) ??
    pickString(body.Num_fact) ??
    pickString(body.numDoc) ??
    pickString(body.NumDoc);

  if (!documentNumber) throw new Error("documento_requerido");

  const customerCode = pickString(body.codigo) ?? pickString(body.CODIGO) ?? pickString(body.Codigo);
  const documentType = normalizeDocType(body);

  const rows = await callSpTx<{
    ReceivableDocumentId: number;
    PendingAmount: number;
    TotalAmount: number;
    CustomerId: number;
    CurrencyCode: string;
  }>(tx, "usp_AR_Application_Resolve", {
    CompanyId: context.companyId,
    BranchId: context.branchId,
    DocumentNumber: documentNumber,
    CustomerCode: customerCode,
    DocumentType: documentType,
  });

  const resolved = Number(rows[0]?.ReceivableDocumentId ?? 0);
  if (!Number.isFinite(resolved) || resolved <= 0) throw new Error("documento_no_encontrado");
  return resolved;
}

/* ---------- create single abono inside a transaction ---------- */

async function createAbonoInTx(
  tx: sql.Transaction,
  context: Context,
  body: Record<string, unknown>,
  options: ServiceOptions
) {
  const receivableDocumentId = await resolveReceivableDocumentId(tx, context, body);
  const requestedAmount = parseAmount(body);
  const applyDate = parseApplyDate(body);
  const paymentReference = parseReference(body);

  // usp_AR_Application_Apply handles locking, validation, insert, doc update and balance refresh
  const rows = await callSpTx<{
    ok: number;
    ApplicationId: number | null;
    NewPending: number | null;
    Message: string;
  }>(tx, "usp_AR_Application_Apply", {
    ReceivableDocumentId: receivableDocumentId,
    Amount: requestedAmount,
    PaymentReference: paymentReference,
    ApplyDate: applyDate,
  });

  const result = rows[0];
  if (!result || result.ok !== 1) {
    throw new Error(result?.Message ?? "no_fue_posible_crear_abono");
  }

  return {
    ok: true,
    id: Number(result.ApplicationId),
    documentoId: receivableDocumentId,
    montoAplicado: requestedAmount,
    executionMode: "canonical" as const,
  };
}

/* ---------- public exports ---------- */

export async function listAbonos(params: QueryParams, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  const { rows, output } = await callSpOut<any>(
    "usp_AR_Application_ListByContext",
    {
      CompanyId: context.companyId,
      BranchId: context.branchId,
      Search: params.search ?? null,
      Codigo: params.codigo ?? null,
      CurrencyCode: options.currencyCode ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    page,
    limit,
    total: Number(output.TotalCount ?? 0),
    rows,
    executionMode: "canonical" as const,
  };
}

export async function getAbono(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const context = await getDefaultContext();

  const rows = await callSp<any>("usp_AR_Application_GetByContext", {
    ApplicationId: appId,
    CompanyId: context.companyId,
    BranchId: context.branchId,
    CurrencyCode: options.currencyCode ?? null,
  });

  return rows[0] ?? null;
}

export async function getAbonoDetalle(id: string, options: ServiceOptions = {}) {
  const head = await getAbono(id, options);
  return head ? [head] : [];
}

export async function createAbono(body: Record<string, unknown>, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const created = await createAbonoInTx(tx, context, body, options);
    await tx.commit();
    return created;
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}

export async function updateAbono(id: string, body: Record<string, unknown>, options: ServiceOptions = {}) {
  const appId = toId(id);

  const hasAmountUpdate =
    body.monto !== undefined ||
    body.MONTO !== undefined ||
    body.importe !== undefined ||
    body.IMPORTE !== undefined ||
    body.total !== undefined ||
    body.TOTAL !== undefined;

  const amount = hasAmountUpdate ? parseAmount(body) : null;
  const applyDate = body.fecha ?? body.FECHA ?? body.applyDate ?? body.ApplyDate ?? null;
  const paymentReference = parseReference(body);

  const rows = await callSp<{ ok: number; Message: string }>("usp_AR_Application_Update", {
    ApplicationId: appId,
    Amount: amount,
    ApplyDate: applyDate ? new Date(String(applyDate)) : null,
    PaymentReference: paymentReference,
    CurrencyCode: options.currencyCode ?? null,
  });

  const result = rows[0];
  if (!result || result.ok !== 1) {
    const msg = result?.Message ?? "update_failed";
    if (msg.includes("no encontrada")) throw new Error("not_found");
    if (msg.includes("moneda")) throw new Error("not_found");
    throw new Error(msg);
  }

  return { ok: true, executionMode: "canonical" as const };
}

export async function deleteAbono(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);

  // usp_AR_Application_Reverse is fully transactional (locking, delete, doc update, balance)
  const rows = await callSp<{ ok: number; NewPending: number | null; Message: string }>(
    "usp_AR_Application_Reverse",
    { ApplicationId: appId }
  );

  const result = rows[0];
  if (!result || result.ok !== 1) {
    const msg = result?.Message ?? "delete_failed";
    if (msg.includes("no encontrada")) throw new Error("not_found");
    throw new Error(msg);
  }

  return { ok: true, executionMode: "canonical" as const };
}

export async function createAbonoTx(payload: CreateTxPayload, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const base = payload.abono ?? {};
    const details = Array.isArray(payload.detalle) ? payload.detalle : [];
    const entries = details.length > 0 ? details : [base];

    const created: Array<{ ok: boolean; id: number; documentoId: number; montoAplicado: number; executionMode: "canonical" }> = [];

    for (const entry of entries) {
      const merged = { ...base, ...(entry ?? {}) };
      const row = await createAbonoInTx(tx, context, merged, options);
      created.push(row);
    }

    await tx.commit();

    return {
      ok: true,
      total: created.length,
      rows: created,
      executionMode: "canonical" as const,
    };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // ignore rollback error
    }
    throw error;
  }
}
