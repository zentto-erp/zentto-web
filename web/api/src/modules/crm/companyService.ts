/**
 * CRM Company Service — SPs crm.Company (ADR-CRM-001).
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

interface SpResult {
  success: boolean;
  message: string;
  id: number | null;
}

function parse(output: Record<string, unknown>): SpResult {
  const ok = Number(output.Resultado ?? output.ok ?? 0) === 1;
  return {
    success: ok,
    message: String(output.Mensaje ?? output.mensaje ?? (ok ? "OK" : "ERROR")),
    id: output.Id != null ? Number(output.Id) : output.id != null ? Number(output.id) : null,
  };
}

export interface ListCompaniesParams {
  search?: string;
  industry?: string;
  isActive?: boolean;
  page?: number;
  limit?: number;
}

export async function listCompanies(params: ListCompaniesParams = {}) {
  const { companyId } = scope();
  const page  = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_crm_Company_List",
    {
      CompanyId: companyId,
      Search:    params.search ?? null,
      Industry:  params.industry ?? null,
      IsActive:  params.isActive ?? null,
      Page:      page,
      Limit:     limit,
    },
    { TotalCount: sql.Int },
  );

  return {
    rows: rows || [],
    total: Number(output.TotalCount ?? (rows as any)?.[0]?.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getCompany(crmCompanyId: number) {
  const { companyId } = scope();
  const rows = await callSp("usp_crm_Company_Detail", {
    CompanyId: companyId,
    CrmCompanyId: crmCompanyId,
  });
  return rows[0] || null;
}

export async function upsertCompany(data: {
  crmCompanyId?: number | null;
  name: string;
  legalName?: string | null;
  taxId?: string | null;
  industry?: string | null;
  size?: string | null;
  website?: string | null;
  phone?: string | null;
  email?: string | null;
  billingAddress?: unknown;
  shippingAddress?: unknown;
  notes?: string | null;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Company_Upsert",
    {
      CompanyId:        companyId,
      CrmCompanyId:     data.crmCompanyId ?? null,
      Name:             data.name,
      LegalName:        data.legalName ?? null,
      TaxId:            data.taxId ?? null,
      Industry:         data.industry ?? null,
      Size:             data.size ?? null,
      Website:          data.website ?? null,
      Phone:            data.phone ?? null,
      Email:            data.email ?? null,
      BillingAddress:   data.billingAddress ? JSON.stringify(data.billingAddress) : null,
      ShippingAddress:  data.shippingAddress ? JSON.stringify(data.shippingAddress) : null,
      Notes:            data.notes ?? null,
      IsActive:         data.isActive ?? true,
      UserId:           data.userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function deleteCompany(crmCompanyId: number, userId: number): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Company_Delete",
    {
      CompanyId:    companyId,
      CrmCompanyId: crmCompanyId,
      UserId:       userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function searchCompanies(term: string, limit = 20) {
  const { companyId } = scope();
  return callSp("usp_crm_Company_Search", {
    CompanyId: companyId,
    Term: term,
    Limit: limit,
  });
}
