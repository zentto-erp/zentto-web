import { query } from "../../db/query.js";
import { createRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export type ListClientesParams = {
  search?: string;
  estado?: string;
  vendedor?: string;
  page?: string;
  limit?: string;
};

export type ListClientesResult = {
  page: number;
  limit: number;
  total: number;
  rows: any[];
  executionMode: "canonical";
};

async function getDefaultCompanyId() {
  const rows = await query<{ CompanyId: number }>(
    `SELECT TOP 1 CompanyId
       FROM cfg.Company
      WHERE IsDeleted = 0
      ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId`
  );
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  return companyId;
}

export async function listClientes(params: ListClientesParams): Promise<ListClientesResult> {
  const companyId = await getDefaultCompanyId();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["CompanyId = @companyId", "ISNULL(IsDeleted, 0) = 0"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.search) {
    where.push("(CustomerCode LIKE @search OR CustomerName LIKE @search OR FiscalId LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }

  if (params.estado) {
    where.push("IsActive = @estado");
    sqlParams.estado = params.estado === "ACTIVO" ? 1 : 0;
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT *
       FROM [master].Customer
       ${clause}
      ORDER BY CustomerCode
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM [master].Customer ${clause}`,
    sqlParams
  );

  return {
    page,
    limit,
    total: Number(totalResult[0]?.total ?? 0),
    rows,
    executionMode: "canonical"
  };
}

export async function getCliente(codigo: string): Promise<{ row: any; executionMode: "canonical" } | { row: null }> {
  const companyId = await getDefaultCompanyId();

  const rows = await query<any>(
    `SELECT TOP 1 *
       FROM [master].Customer
      WHERE CompanyId = @companyId
        AND CustomerCode = @codigo
        AND ISNULL(IsDeleted, 0) = 0`,
    { companyId, codigo }
  );

  return rows[0] ? { row: rows[0], executionMode: "canonical" } : { row: null };
}

export async function createCliente(body: Record<string, unknown>): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const payload = {
    CompanyId: companyId,
    CustomerCode: body.CustomerCode ?? body.CODIGO,
    CustomerName: body.CustomerName ?? body.NOMBRE,
    FiscalId: body.FiscalId ?? body.RIF,
    Email: body.Email,
    Phone: body.Phone ?? body.TELEFONO,
    AddressLine: body.AddressLine ?? body.DIRECCION,
    CreditLimit: body.CreditLimit ?? body.LIMITE ?? 0,
    TotalBalance: body.TotalBalance ?? 0,
    IsActive: body.IsActive ?? 1,
    IsDeleted: 0,
    CreatedAt: new Date(),
    UpdatedAt: new Date(),
    CreatedByUserId: body.CreatedByUserId ?? null,
    UpdatedByUserId: body.UpdatedByUserId ?? null
  };

  await createRow("master", "Customer", payload);
  return { ok: true, executionMode: "canonical" };
}

export async function updateCliente(codigo: string, body: Record<string, unknown>): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const key = encodeKeyObject({ CompanyId: companyId, CustomerCode: codigo });
  const payload = {
    CustomerName: body.CustomerName ?? body.NOMBRE,
    FiscalId: body.FiscalId ?? body.RIF,
    Email: body.Email,
    Phone: body.Phone ?? body.TELEFONO,
    AddressLine: body.AddressLine ?? body.DIRECCION,
    CreditLimit: body.CreditLimit ?? body.LIMITE,
    TotalBalance: body.TotalBalance,
    IsActive: body.IsActive,
    UpdatedAt: new Date(),
    UpdatedByUserId: body.UpdatedByUserId ?? null
  };

  await updateRow("master", "Customer", key, payload);
  return { ok: true, executionMode: "canonical" };
}

export async function deleteCliente(codigo: string): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const key = encodeKeyObject({ CompanyId: companyId, CustomerCode: codigo });
  const payload = {
    IsDeleted: 1,
    DeletedAt: new Date(),
    IsActive: 0,
    UpdatedAt: new Date()
  };

  await updateRow("master", "Customer", key, payload);
  return { ok: true, executionMode: "canonical" };
}
