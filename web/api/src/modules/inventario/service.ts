import { query } from "../../db/query.js";
import { createRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";

export type ListInventarioParams = {
  search?: string;
  categoria?: string;
  marca?: string;
  linea?: string;
  tipo?: string;
  clase?: string;
  page?: string;
  limit?: string;
};

export type ListInventarioResult = {
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

export async function listInventario(params: ListInventarioParams): Promise<ListInventarioResult> {
  const companyId = await getDefaultCompanyId();
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;

  const where: string[] = ["CompanyId = @companyId", "ISNULL(IsDeleted, 0) = 0"];
  const sqlParams: Record<string, unknown> = { companyId };

  if (params.search) {
    where.push("(ProductCode LIKE @search OR ProductName LIKE @search OR CategoryCode LIKE @search)");
    sqlParams.search = `%${params.search}%`;
  }

  if (params.categoria) {
    where.push("CategoryCode = @categoria");
    sqlParams.categoria = params.categoria;
  }

  if (params.tipo) {
    if (params.tipo.toUpperCase() === "SERVICIO") {
      where.push("IsService = 1");
    }
    if (params.tipo.toUpperCase() === "PRODUCTO") {
      where.push("IsService = 0");
    }
  }

  const clause = `WHERE ${where.join(" AND ")}`;

  const rows = await query<any>(
    `SELECT *
       FROM [master].Product
       ${clause}
      ORDER BY ProductCode
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    sqlParams
  );

  const totalResult = await query<{ total: number }>(
    `SELECT COUNT(1) AS total FROM [master].Product ${clause}`,
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

export async function getInventario(codigo: string): Promise<{ row: any; executionMode: "canonical" } | { row: null }> {
  const companyId = await getDefaultCompanyId();

  const rows = await query<any>(
    `SELECT TOP 1 *
       FROM [master].Product
      WHERE CompanyId = @companyId
        AND ProductCode = @codigo
        AND ISNULL(IsDeleted, 0) = 0`,
    { companyId, codigo }
  );

  return rows[0] ? { row: rows[0], executionMode: "canonical" } : { row: null };
}

export async function createInventario(body: Record<string, unknown>): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const payload = {
    CompanyId: companyId,
    ProductCode: body.ProductCode ?? body.CODIGO,
    ProductName: body.ProductName ?? body.DESCRIPCION,
    CategoryCode: body.CategoryCode ?? body.Categoria,
    UnitCode: body.UnitCode ?? body.Unidad,
    SalesPrice: body.SalesPrice ?? body.PRECIO_VENTA ?? 0,
    CostPrice: body.CostPrice ?? body.PRECIO_COMPRA ?? 0,
    DefaultTaxCode: body.DefaultTaxCode,
    DefaultTaxRate: body.DefaultTaxRate ?? 0,
    StockQty: body.StockQty ?? body.EXISTENCIA ?? 0,
    IsService: body.IsService ?? (String(body.Tipo ?? "").toUpperCase() === "SERVICIO" ? 1 : 0),
    IsActive: body.IsActive ?? 1,
    IsDeleted: 0,
    CreatedAt: new Date(),
    UpdatedAt: new Date(),
    CreatedByUserId: body.CreatedByUserId ?? null,
    UpdatedByUserId: body.UpdatedByUserId ?? null
  };

  await createRow("master", "Product", payload);
  return { ok: true, executionMode: "canonical" };
}

export async function updateInventario(codigo: string, body: Record<string, unknown>): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const key = encodeKeyObject({ CompanyId: companyId, ProductCode: codigo });
  const payload = {
    ProductName: body.ProductName ?? body.DESCRIPCION,
    CategoryCode: body.CategoryCode ?? body.Categoria,
    UnitCode: body.UnitCode ?? body.Unidad,
    SalesPrice: body.SalesPrice ?? body.PRECIO_VENTA,
    CostPrice: body.CostPrice ?? body.PRECIO_COMPRA,
    DefaultTaxCode: body.DefaultTaxCode,
    DefaultTaxRate: body.DefaultTaxRate,
    StockQty: body.StockQty ?? body.EXISTENCIA,
    IsService: body.IsService,
    IsActive: body.IsActive,
    UpdatedAt: new Date(),
    UpdatedByUserId: body.UpdatedByUserId ?? null
  };

  await updateRow("master", "Product", key, payload);
  return { ok: true, executionMode: "canonical" };
}

export async function deleteInventario(codigo: string): Promise<{ ok: boolean; executionMode: "canonical" }> {
  const companyId = await getDefaultCompanyId();

  const key = encodeKeyObject({ CompanyId: companyId, ProductCode: codigo });
  const payload = {
    IsDeleted: 1,
    DeletedAt: new Date(),
    IsActive: 0,
    UpdatedAt: new Date()
  };

  await updateRow("master", "Product", key, payload);
  return { ok: true, executionMode: "canonical" };
}
