import { getPool } from "../../db/mssql.js";
import { callSp, callSpOut, callSpTx, sql } from "../../db/query.js";

type QueryParams = { search?: string; codigo?: string; page?: string; limit?: string };

type Context = { companyId: number; branchId: number };

type CreateTxPayload = { pago: Record<string, unknown>; detalle: Record<string, unknown>[] };

type ServiceOptions = { currencyCode?: string };

/* ------------------------------------------------------------------ */
/*  Utilidades de parsing (se mantienen intactas)                     */
/* ------------------------------------------------------------------ */

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
    pickNumber(body.pago) ??
    pickNumber(body.PAGO) ??
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
    `PAGO-${Date.now()}`
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

/* ------------------------------------------------------------------ */
/*  Contexto por defecto via SP                                       */
/* ------------------------------------------------------------------ */

async function getDefaultContext(): Promise<Context> {
  const rows = await callSp<{ CompanyId: number; BranchId: number }>(
    "usp_Cfg_ResolveContext"
  );

  const row = rows[0];
  if (!row) throw new Error("context_not_found");

  const companyId = Number(row.CompanyId ?? 0);
  const branchId = Number(row.BranchId ?? 0);

  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");

  return { companyId, branchId };
}

/* ------------------------------------------------------------------ */
/*  Listado paginado                                                  */
/* ------------------------------------------------------------------ */

export async function listPagos(params: QueryParams, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);

  const { rows, output } = await callSpOut<any>(
    "usp_AP_Application_ListByContext",
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

/* ------------------------------------------------------------------ */
/*  Detalle de un pago                                                */
/* ------------------------------------------------------------------ */

export async function getPago(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);
  const context = await getDefaultContext();

  const rows = await callSp<any>("usp_AP_Application_GetByContext", {
    ApplicationId: appId,
    CompanyId: context.companyId,
    BranchId: context.branchId,
    CurrencyCode: options.currencyCode ?? null,
  });

  return rows[0] ?? null;
}

export async function getPagoDetalle(id: string, options: ServiceOptions = {}) {
  const head = await getPago(id, options);
  return head ? [head] : [];
}

/* ------------------------------------------------------------------ */
/*  Crear pago (simple)                                               */
/* ------------------------------------------------------------------ */

export async function createPago(body: Record<string, unknown>, options: ServiceOptions = {}) {
  const context = await getDefaultContext();

  // Resolver id directo si viene
  const directId =
    pickNumber(body.PayableDocumentId) ??
    pickNumber(body.payableDocumentId) ??
    pickNumber(body.DocumentoId) ??
    pickNumber(body.documentoId) ??
    pickNumber(body.idDocumento) ??
    pickNumber(body.IdDocumento);

  let payableDocumentId: number;

  if (directId && directId > 0) {
    payableDocumentId = directId;
  } else {
    // Resolver via SP
    const documentNumber =
      pickString(body.documento) ??
      pickString(body.DOCUMENTO) ??
      pickString(body.Num_fact) ??
      pickString(body.numDoc) ??
      pickString(body.NumDoc);

    if (!documentNumber) throw new Error("documento_requerido");

    const supplierCode = pickString(body.codigo) ?? pickString(body.CODIGO) ?? pickString(body.Codigo);
    const documentType = normalizeDocType(body);

    const resolved = await callSp<{ PayableDocumentId: number; PendingAmount: number; TotalAmount: number; SupplierId: number; CurrencyCode: string }>(
      "usp_AP_Application_Resolve",
      {
        CompanyId: context.companyId,
        BranchId: context.branchId,
        DocumentNumber: documentNumber,
        SupplierCode: supplierCode,
        DocumentType: documentType,
      }
    );

    if (!resolved[0]) throw new Error("documento_no_encontrado");

    // Validar moneda
    if (options.currencyCode && String(resolved[0].CurrencyCode).toUpperCase() !== options.currencyCode.toUpperCase()) {
      throw new Error("moneda_no_permitida");
    }

    payableDocumentId = Number(resolved[0].PayableDocumentId);
  }

  if (!Number.isFinite(payableDocumentId) || payableDocumentId <= 0) throw new Error("documento_no_encontrado");

  const amount = parseAmount(body);
  const applyDate = parseApplyDate(body);
  const paymentReference = parseReference(body);

  const result = await callSp<{ ok: number; ApplicationId: number; NewPending: number; Message: string }>(
    "usp_AP_Application_Apply",
    {
      PayableDocumentId: payableDocumentId,
      Amount: amount,
      PaymentReference: paymentReference,
      ApplyDate: applyDate,
    }
  );

  const row = result[0];
  if (!row || !row.ok) {
    throw new Error(row?.Message ?? "no_fue_posible_crear_pago");
  }

  return {
    ok: true,
    id: Number(row.ApplicationId),
    documentoId: payableDocumentId,
    montoAplicado: amount,
    executionMode: "canonical" as const,
  };
}

/* ------------------------------------------------------------------ */
/*  Actualizar pago                                                   */
/* ------------------------------------------------------------------ */

export async function updatePago(id: string, body: Record<string, unknown>, options: ServiceOptions = {}) {
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

  const result = await callSp<{ ok: number; Message: string }>(
    "usp_AP_Application_Update",
    {
      ApplicationId: appId,
      Amount: amount,
      ApplyDate: applyDate ? new Date(String(applyDate)) : null,
      PaymentReference: paymentReference,
      CurrencyCode: options.currencyCode ?? null,
    }
  );

  const row = result[0];
  if (!row || !row.ok) {
    const msg = row?.Message ?? "not_found";
    throw new Error(msg);
  }

  return { ok: true, executionMode: "canonical" as const };
}

/* ------------------------------------------------------------------ */
/*  Eliminar (reversar) pago                                          */
/* ------------------------------------------------------------------ */

export async function deletePago(id: string, options: ServiceOptions = {}) {
  const appId = toId(id);

  // Si se requiere validar moneda, primero verificamos el pago
  if (options.currencyCode) {
    const context = await getDefaultContext();
    const existing = await callSp<any>("usp_AP_Application_GetByContext", {
      ApplicationId: appId,
      CompanyId: context.companyId,
      BranchId: context.branchId,
      CurrencyCode: options.currencyCode,
    });
    if (!existing[0]) throw new Error("not_found");
  }

  const result = await callSp<{ ok: number; NewPending: number; Message: string }>(
    "usp_AP_Application_Reverse",
    { ApplicationId: appId }
  );

  const row = result[0];
  if (!row || !row.ok) {
    throw new Error(row?.Message ?? "not_found");
  }

  return { ok: true, executionMode: "canonical" as const };
}

/* ------------------------------------------------------------------ */
/*  Crear pagos en batch (transaccional)                              */
/* ------------------------------------------------------------------ */

export async function createPagoTx(payload: CreateTxPayload, options: ServiceOptions = {}) {
  const context = await getDefaultContext();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const base = payload.pago ?? {};
    const details = Array.isArray(payload.detalle) ? payload.detalle : [];
    const entries = details.length > 0 ? details : [base];

    const created: Array<{ ok: boolean; id: number; documentoId: number; montoAplicado: number; executionMode: "canonical" }> = [];

    for (const entry of entries) {
      const merged = { ...base, ...(entry ?? {}) };

      // Resolver documento via SP en la transaccion
      const directId =
        pickNumber(merged.PayableDocumentId) ??
        pickNumber(merged.payableDocumentId) ??
        pickNumber(merged.DocumentoId) ??
        pickNumber(merged.documentoId) ??
        pickNumber(merged.idDocumento) ??
        pickNumber(merged.IdDocumento);

      let payableDocumentId: number;

      if (directId && directId > 0) {
        payableDocumentId = directId;
      } else {
        const documentNumber =
          pickString(merged.documento) ??
          pickString(merged.DOCUMENTO) ??
          pickString(merged.Num_fact) ??
          pickString(merged.numDoc) ??
          pickString(merged.NumDoc);

        if (!documentNumber) throw new Error("documento_requerido");

        const supplierCode = pickString(merged.codigo) ?? pickString(merged.CODIGO) ?? pickString(merged.Codigo);
        const documentType = normalizeDocType(merged);

        const resolved = await callSpTx<{ PayableDocumentId: number; CurrencyCode: string }>(
          tx,
          "usp_AP_Application_Resolve",
          {
            CompanyId: context.companyId,
            BranchId: context.branchId,
            DocumentNumber: documentNumber,
            SupplierCode: supplierCode,
            DocumentType: documentType,
          }
        );

        if (!resolved[0]) throw new Error("documento_no_encontrado");

        if (options.currencyCode && String(resolved[0].CurrencyCode).toUpperCase() !== options.currencyCode.toUpperCase()) {
          throw new Error("moneda_no_permitida");
        }

        payableDocumentId = Number(resolved[0].PayableDocumentId);
      }

      const amount = parseAmount(merged);
      const applyDate = parseApplyDate(merged);
      const paymentReference = parseReference(merged);

      const result = await callSpTx<{ ok: number; ApplicationId: number; NewPending: number; Message: string }>(
        tx,
        "usp_AP_Application_Apply",
        {
          PayableDocumentId: payableDocumentId,
          Amount: amount,
          PaymentReference: paymentReference,
          ApplyDate: applyDate,
        }
      );

      const row = result[0];
      if (!row || !row.ok) {
        throw new Error(row?.Message ?? "no_fue_posible_crear_pago");
      }

      created.push({
        ok: true,
        id: Number(row.ApplicationId),
        documentoId: payableDocumentId,
        montoAplicado: amount,
        executionMode: "canonical" as const,
      });
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
