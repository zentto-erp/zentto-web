/**
 * CRM Deal Service — SPs crm.Deal (ADR-CRM-001).
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

export interface ListDealsParams {
  pipelineId?: number;
  stageId?: number;
  status?: string;
  ownerAgentId?: number;
  contactId?: number;
  crmCompanyId?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export async function listDeals(params: ListDealsParams = {}) {
  const { companyId } = scope();
  const page  = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_crm_Deal_List",
    {
      CompanyId:    companyId,
      PipelineId:   params.pipelineId ?? null,
      StageId:      params.stageId ?? null,
      Status:       params.status ?? null,
      OwnerAgentId: params.ownerAgentId ?? null,
      ContactId:    params.contactId ?? null,
      CrmCompanyId: params.crmCompanyId ?? null,
      Search:       params.search ?? null,
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

export async function getDeal(dealId: number) {
  const { companyId } = scope();
  const rows = await callSp("usp_crm_Deal_Detail", {
    CompanyId: companyId,
    DealId: dealId,
  });
  return rows[0] || null;
}

export async function upsertDeal(data: {
  dealId?: number | null;
  name: string;
  pipelineId?: number | null;
  stageId?: number | null;
  contactId?: number | null;
  crmCompanyId?: number | null;
  ownerAgentId?: number | null;
  value?: number;
  currency?: string;
  probability?: number | null;
  expectedClose?: string | null;
  priority?: string;
  source?: string | null;
  notes?: string | null;
  tags?: string | null;
  branchId?: number;
  userId: number;
}): Promise<SpResult> {
  const { companyId, branchId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Deal_Upsert",
    {
      CompanyId:      companyId,
      DealId:         data.dealId ?? null,
      Name:           data.name,
      PipelineId:     data.pipelineId ?? null,
      StageId:        data.stageId ?? null,
      ContactId:      data.contactId ?? null,
      CrmCompanyId:   data.crmCompanyId ?? null,
      OwnerAgentId:   data.ownerAgentId ?? null,
      Value:          data.value ?? 0,
      Currency:       data.currency ?? "USD",
      Probability:    data.probability ?? null,
      ExpectedClose:  data.expectedClose ?? null,
      Priority:       data.priority ?? "MEDIUM",
      Source:         data.source ?? null,
      Notes:          data.notes ?? null,
      Tags:           data.tags ?? null,
      BranchId:       data.branchId ?? branchId ?? 1,
      UserId:         data.userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function moveDealStage(
  dealId: number,
  newStageId: number,
  notes: string | null,
  userId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Deal_MoveStage",
    {
      CompanyId:  companyId,
      DealId:     dealId,
      NewStageId: newStageId,
      Notes:      notes,
      UserId:     userId,
    },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function closeDealWon(
  dealId: number,
  reason: string | null,
  userId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Deal_CloseWon",
    { CompanyId: companyId, DealId: dealId, Reason: reason, UserId: userId },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function closeDealLost(
  dealId: number,
  reason: string | null,
  userId: number,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Deal_CloseLost",
    { CompanyId: companyId, DealId: dealId, Reason: reason, UserId: userId },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function deleteDeal(dealId: number, userId: number): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Deal_Delete",
    { CompanyId: companyId, DealId: dealId, UserId: userId },
    {
      Resultado: sql.Bit,
      Mensaje:   sql.NVarChar(500),
      Id:        sql.BigInt,
    },
  );
  return parse(output);
}

export async function searchDeals(term: string, limit = 20) {
  const { companyId } = scope();
  return callSp("usp_crm_Deal_Search", {
    CompanyId: companyId,
    Term: term,
    Limit: limit,
  });
}

export async function getDealTimeline(dealId: number, limit = 100) {
  const { companyId } = scope();
  return callSp("usp_crm_Deal_Timeline", {
    CompanyId: companyId,
    DealId: dealId,
    Limit: limit,
  });
}

export async function convertLeadToDeal(
  leadId: number,
  data: {
    dealName?: string | null;
    pipelineId?: number | null;
    stageId?: number | null;
    crmCompanyId?: number | null;
    userId: number;
  },
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_crm_Lead_Convert",
    {
      CompanyId:    companyId,
      LeadId:       leadId,
      DealName:     data.dealName ?? null,
      PipelineId:   data.pipelineId ?? null,
      StageId:      data.stageId ?? null,
      CrmCompanyId: data.crmCompanyId ?? null,
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
