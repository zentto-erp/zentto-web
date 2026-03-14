import { query } from "../../db/query.js";
import { execute } from "../../db/query.js";

async function getDefaultContext() {
  const companyRows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );

  const companyId = Number(companyRows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");

  const branchRows = await query<{ BranchId: number }>(
    `SELECT TOP 1 BranchId
       FROM cfg.Branch
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
      ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId`,
    { companyId }
  );

  const branchId = Number(branchRows[0]?.BranchId ?? 0);
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");

  return { companyId, branchId };
}

async function listReceivable(params: { search?: string; codigo?: string; page?: string; limit?: string; currencyCode?: string }) {
  const { companyId, branchId } = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["d.CompanyId = @companyId", "d.BranchId = @branchId"];
  const sqlParams: Record<string, unknown> = { companyId, branchId };

  if (params.search) {
    where.push("(d.DocumentNumber LIKE @search OR d.Notes LIKE @search OR c.CustomerName LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("c.CustomerCode = @codigo");
    sqlParams.codigo = params.codigo;
  }
  if (params.currencyCode) {
    where.push("d.CurrencyCode = @currencyCode");
    sqlParams.currencyCode = params.currencyCode;
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT
        d.ReceivableDocumentId AS id,
        c.CustomerCode AS codigo,
        c.CustomerName AS nombre,
        d.DocumentType AS tipo,
        d.DocumentNumber AS documento,
        d.IssueDate AS fecha,
        d.DueDate AS fechaVence,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.CurrencyCode AS moneda,
        d.Notes AS observacion
       FROM ar.ReceivableDocument d
       INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
       ${clause}
      ORDER BY d.IssueDate DESC, d.ReceivableDocumentId DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM ar.ReceivableDocument d
       INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
       ${clause}`,
    sqlParams
  );

  return { page, limit, total: Number(totalRows[0]?.total ?? 0), rows, executionMode: "canonical" as const };
}

async function getReceivable(id: string) {
  const rows = await query<any>(
    `SELECT
        d.ReceivableDocumentId AS id,
        c.CustomerCode AS codigo,
        c.CustomerName AS nombre,
        d.DocumentType AS tipo,
        d.DocumentNumber AS documento,
        d.IssueDate AS fecha,
        d.DueDate AS fechaVence,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.CurrencyCode AS moneda,
        d.Notes AS observacion
       FROM ar.ReceivableDocument d
       INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
      WHERE d.ReceivableDocumentId = @id`,
    { id: Number(id) }
  );

  return rows[0] ?? null;
}

async function createReceivable(body: Record<string, unknown>, currencyCode?: string) {
  const { companyId, branchId } = await getDefaultContext();

  const codigo = String(body.codigo ?? body.CODIGO ?? "").trim();
  if (!codigo) throw new Error("codigo_cliente_requerido");

  const customerRows = await query<{ CustomerId: number }>(
    `SELECT TOP 1 CustomerId
       FROM [master].Customer
      WHERE CompanyId = @companyId
        AND CustomerCode = @codigo
        AND IsDeleted = 0`,
    { companyId, codigo }
  );
  const customerId = Number(customerRows[0]?.CustomerId ?? 0);
  if (!Number.isFinite(customerId) || customerId <= 0) throw new Error("cliente_no_encontrado");

  const total = Number(body.total ?? body.TOTAL ?? 0) || 0;
  const pendiente = Number(body.pendiente ?? body.PEND ?? total) || 0;
  const issueDate = body.fecha ?? body.FECHA ?? new Date();
  const dueDate = body.fechaVence ?? body.FECHAVENCE ?? issueDate;

  await execute(
    `INSERT INTO ar.ReceivableDocument
      (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate,
       CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, Notes, CreatedAt, UpdatedAt)
     VALUES
      (@companyId, @branchId, @customerId, @documentType, @documentNumber, @issueDate, @dueDate,
       @currencyCode, @totalAmount, @pendingAmount,
       CASE WHEN @pendingAmount <= 0 THEN 1 ELSE 0 END,
       CASE WHEN @pendingAmount <= 0 THEN 'PAID' WHEN @pendingAmount < @totalAmount THEN 'PARTIAL' ELSE 'PENDING' END,
       @notes, SYSUTCDATETIME(), SYSUTCDATETIME())`,
    {
      companyId,
      branchId,
      customerId,
      documentType: body.tipo ?? body.TIPO ?? "FACT",
      documentNumber: body.documento ?? body.DOCUMENTO,
      issueDate,
      dueDate,
      currencyCode: currencyCode ?? body.moneda ?? body.MONEDA ?? "USD",
      totalAmount: total,
      pendingAmount: pendiente,
      notes: body.observacion ?? body.OBS
    }
  );

  return { ok: true, executionMode: "canonical" as const };
}

async function updateReceivable(id: string, body: Record<string, unknown>) {
  const pending = body.pendiente ?? body.PEND;
  const total = body.total ?? body.TOTAL;

  await execute(
    `UPDATE ar.ReceivableDocument
        SET DocumentType = COALESCE(@documentType, DocumentType),
            DocumentNumber = COALESCE(@documentNumber, DocumentNumber),
            IssueDate = COALESCE(@issueDate, IssueDate),
            DueDate = COALESCE(@dueDate, DueDate),
            TotalAmount = COALESCE(@totalAmount, TotalAmount),
            PendingAmount = COALESCE(@pendingAmount, PendingAmount),
            Status = COALESCE(@status, Status),
            CurrencyCode = COALESCE(@currencyCode, CurrencyCode),
            Notes = COALESCE(@notes, Notes),
            UpdatedAt = SYSUTCDATETIME()
      WHERE ReceivableDocumentId = @id`,
    {
      id: Number(id),
      documentType: body.tipo ?? body.TIPO,
      documentNumber: body.documento ?? body.DOCUMENTO,
      issueDate: body.fecha ?? body.FECHA,
      dueDate: body.fechaVence ?? body.FECHAVENCE,
      totalAmount: total,
      pendingAmount: pending,
      status: body.estado ?? body.ESTADO,
      currencyCode: body.moneda ?? body.MONEDA,
      notes: body.observacion ?? body.OBS
    }
  );

  return { ok: true, executionMode: "canonical" as const };
}

async function deleteReceivable(id: string) {
  await execute(
    `UPDATE ar.ReceivableDocument
        SET PendingAmount = 0,
            PaidFlag = 1,
            Status = 'VOIDED',
            UpdatedAt = SYSUTCDATETIME()
      WHERE ReceivableDocumentId = @id`,
    { id: Number(id) }
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
