/**
 * CRM Contact Service — SPs crm.Contact (ADR-CRM-001).
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

export interface ListContactsParams {
  crmCompanyId?: number;
  search?: string;
  isActive?: boolean;
  page?: number;
  limit?: number;
}

export async function listContacts(params: ListContactsParams = {}) {
  const { companyId } = scope();
  const page  = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_crm_Contact_List",
    {
      CompanyId:    companyId,
      CrmCompanyId: params.crmCompanyId ?? null,
      Search:       params.search ?? null,
      IsActive:     params.isActive ?? null,
      Page:         page,
      Limit:        limit,
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

export async function getContact(contactId: number) {
  const { companyId } = scope();
  const rows = await callSp("usp_crm_Contact_Detail", {
    CompanyId: companyId,
    ContactId: contactId,
  });
  return rows[0] || null;
}

export async function upsertContact(data: {
  contactId?: number | null;
  crmCompanyId?: number | null;
  firstName: string;
  lastName?: string | null;
  email?: string | null;
  phone?: string | null;
  mobile?: string | null;
  title?: string | null;
  department?: string | null;
  linkedIn?: string | null;
  notes?: string | null;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Contact_Upsert",
    {
      CompanyId:    companyId,
      ContactId:    data.contactId ?? null,
      CrmCompanyId: data.crmCompanyId ?? null,
      FirstName:    data.firstName,
      LastName:     data.lastName ?? null,
      Email:        data.email ?? null,
      Phone:        data.phone ?? null,
      Mobile:       data.mobile ?? null,
      Title:        data.title ?? null,
      Department:   data.department ?? null,
      LinkedIn:     data.linkedIn ?? null,
      Notes:        data.notes ?? null,
      IsActive:     data.isActive ?? true,
      UserId:       data.userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function deleteContact(contactId: number, userId: number): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Contact_Delete",
    {
      CompanyId: companyId,
      ContactId: contactId,
      UserId:    userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function searchContacts(term: string, limit = 20) {
  const { companyId } = scope();
  return callSp("usp_crm_Contact_Search", {
    CompanyId: companyId,
    Term: term,
    Limit: limit,
  });
}

export async function promoteContactToCustomer(
  contactId: number,
  customerCode: string | null,
  userId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Contact_PromoteToCustomer",
    {
      CompanyId:    companyId,
      ContactId:    contactId,
      CustomerCode: customerCode,
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
