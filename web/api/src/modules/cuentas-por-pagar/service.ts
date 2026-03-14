import { execute, query } from "../../db/query.js";

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

export async function listCuentasPorPagar(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const { companyId, branchId } = await getDefaultContext();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["d.CompanyId = @companyId", "d.BranchId = @branchId"];
  const sqlParams: Record<string, unknown> = { companyId, branchId };

  if (params.search) {
    where.push("(d.DocumentNumber LIKE @search OR d.Notes LIKE @search OR s.SupplierName LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }
  if (params.codigo) {
    where.push("s.SupplierCode = @codigo");
    sqlParams.codigo = params.codigo;
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT
        d.PayableDocumentId AS id,
        s.SupplierCode AS codigo,
        s.SupplierName AS nombre,
        d.DocumentType AS tipo,
        d.DocumentNumber AS documento,
        d.IssueDate AS fecha,
        d.DueDate AS fechaVence,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.CurrencyCode AS moneda,
        d.Notes AS observacion
       FROM ap.PayableDocument d
       INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
       ${clause}
      ORDER BY d.IssueDate DESC, d.PayableDocumentId DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const total = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM ap.PayableDocument d
       INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
       ${clause}`,
    sqlParams
  );

  return { page, limit, total: Number(total[0]?.total ?? 0), rows, executionMode: "canonical" as const };
}

export async function getCuentaPorPagar(id: string) {
  const rows = await query<any>(
    `SELECT
        d.PayableDocumentId AS id,
        s.SupplierCode AS codigo,
        s.SupplierName AS nombre,
        d.DocumentType AS tipo,
        d.DocumentNumber AS documento,
        d.IssueDate AS fecha,
        d.DueDate AS fechaVence,
        d.TotalAmount AS total,
        d.PendingAmount AS pendiente,
        d.Status AS estado,
        d.CurrencyCode AS moneda,
        d.Notes AS observacion
       FROM ap.PayableDocument d
       INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
      WHERE d.PayableDocumentId = @id`,
    { id: Number(id) }
  );

  return rows[0] ?? null;
}

export async function createCuentaPorPagar(body: Record<string, unknown>) {
  const { companyId, branchId } = await getDefaultContext();

  const codigo = String(body.codigo ?? body.CODIGO ?? "").trim();
  if (!codigo) throw new Error("codigo_proveedor_requerido");

  const supplierRows = await query<{ SupplierId: number }>(
    `SELECT TOP 1 SupplierId
       FROM [master].Supplier
      WHERE CompanyId = @companyId
        AND SupplierCode = @codigo
        AND IsDeleted = 0`,
    { companyId, codigo }
  );
  const supplierId = Number(supplierRows[0]?.SupplierId ?? 0);
  if (!Number.isFinite(supplierId) || supplierId <= 0) throw new Error("proveedor_no_encontrado");

  const total = Number(body.total ?? body.TOTAL ?? 0) || 0;
  const pendiente = Number(body.pendiente ?? body.PEND ?? total) || 0;
  const issueDate = body.fecha ?? body.FECHA ?? new Date();
  const dueDate = body.fechaVence ?? body.FECHAVENCE ?? issueDate;

  await execute(
    `INSERT INTO ap.PayableDocument
      (CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber, IssueDate, DueDate,
       CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, Notes, CreatedAt, UpdatedAt)
     VALUES
      (@companyId, @branchId, @supplierId, @documentType, @documentNumber, @issueDate, @dueDate,
       @currencyCode, @totalAmount, @pendingAmount,
       CASE WHEN @pendingAmount <= 0 THEN 1 ELSE 0 END,
       CASE WHEN @pendingAmount <= 0 THEN 'PAID' WHEN @pendingAmount < @totalAmount THEN 'PARTIAL' ELSE 'PENDING' END,
       @notes, SYSUTCDATETIME(), SYSUTCDATETIME())`,
    {
      companyId,
      branchId,
      supplierId,
      documentType: body.tipo ?? body.TIPO ?? "COMPRA",
      documentNumber: body.documento ?? body.DOCUMENTO,
      issueDate,
      dueDate,
      currencyCode: body.moneda ?? body.MONEDA ?? "USD",
      totalAmount: total,
      pendingAmount: pendiente,
      notes: body.observacion ?? body.OBS
    }
  );

  return { ok: true, executionMode: "canonical" as const };
}

export async function updateCuentaPorPagar(id: string, body: Record<string, unknown>) {
  await execute(
    `UPDATE ap.PayableDocument
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
      WHERE PayableDocumentId = @id`,
    {
      id: Number(id),
      documentType: body.tipo ?? body.TIPO,
      documentNumber: body.documento ?? body.DOCUMENTO,
      issueDate: body.fecha ?? body.FECHA,
      dueDate: body.fechaVence ?? body.FECHAVENCE,
      totalAmount: body.total ?? body.TOTAL,
      pendingAmount: body.pendiente ?? body.PEND,
      status: body.estado ?? body.ESTADO,
      currencyCode: body.moneda ?? body.MONEDA,
      notes: body.observacion ?? body.OBS
    }
  );

  return { ok: true, executionMode: "canonical" as const };
}

export async function deleteCuentaPorPagar(id: string) {
  await execute(
    `UPDATE ap.PayableDocument
        SET PendingAmount = 0,
            PaidFlag = 1,
            Status = 'VOIDED',
            UpdatedAt = SYSUTCDATETIME()
      WHERE PayableDocumentId = @id`,
    { id: Number(id) }
  );

  return { ok: true, executionMode: "canonical" as const };
}
