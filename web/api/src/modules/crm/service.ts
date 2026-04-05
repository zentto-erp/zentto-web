/**
 * CRM Service — Stored Procedures
 *
 * Pipelines, Leads, Activities, Dashboard
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";
import { obs } from "../integrations/observability.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

interface SpResult {
  success: boolean;
  message: string;
  [key: string]: unknown;
}

function parseSpResult(output: Record<string, unknown>, extra?: string[]): SpResult {
  const r: SpResult = {
    success: Number(output.Resultado ?? output.ok ?? 0) === 1,
    message: String(output.Mensaje ?? output.mensaje ?? "OK"),
  };
  if (extra) {
    for (const k of extra) r[k] = output[k] ?? null;
  }
  return r;
}

// ── Pipelines ────────────────────────────────────────────────────────────────

export async function listPipelines() {
  const { companyId } = scope();
  return callSp("usp_CRM_Pipeline_List", { CompanyId: companyId });
}

export async function upsertPipeline(data: {
  pipelineId?: number | null;
  pipelineCode: string;
  pipelineName: string;
  isDefault?: boolean;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Pipeline_Upsert",
    {
      CompanyId: companyId,
      PipelineId: data.pipelineId ?? null,
      PipelineCode: data.pipelineCode,
      PipelineName: data.pipelineName,
      IsDefault: data.isDefault ?? false,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function getStages(pipelineId: number) {
  const s = scope();
  return callSp("usp_CRM_Pipeline_GetStages", { CompanyId: s.companyId, PipelineId: pipelineId });
}

// ── Stages ───────────────────────────────────────────────────────────────────

export async function upsertStage(
  pipelineId: number,
  data: {
    stageId?: number | null;
    stageCode: string;
    stageName: string;
    stageOrder: number;
    probability?: number;
    daysExpected?: number;
    color?: string | null;
    isClosed?: boolean;
    isWon?: boolean;
    isActive?: boolean;
    userId: number;
  },
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Stage_Upsert",
    {
      CompanyId: s.companyId,
      PipelineId: pipelineId,
      StageId: data.stageId ?? null,
      StageCode: data.stageCode,
      StageName: data.stageName,
      StageOrder: data.stageOrder,
      Probability: data.probability ?? 0,
      DaysExpected: data.daysExpected ?? 0,
      Color: data.color ?? null,
      IsClosed: data.isClosed ?? false,
      IsWon: data.isWon ?? false,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Leads ────────────────────────────────────────────────────────────────────

export interface ListLeadsParams {
  pipelineId?: number;
  stageId?: number;
  status?: string;
  assignedToUserId?: number;
  source?: string;
  priority?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export async function listLeads(params: ListLeadsParams = {}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_CRM_Lead_List",
    {
      CompanyId: companyId,
      PipelineId: params.pipelineId ?? null,
      StageId: params.stageId ?? null,
      Status: params.status ?? null,
      AssignedToUserId: params.assignedToUserId ?? null,
      Source: params.source ?? null,
      Priority: params.priority ?? null,
      Search: params.search ?? null,
      Page: page,
      Limit: limit,
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

export async function getLead(leadId: number) {
  const s = scope();
  const rows = await callSp("usp_CRM_Lead_Get", { CompanyId: s.companyId, LeadId: leadId });
  return rows[0] || null;
}

export async function createLead(data: {
  pipelineId: number;
  stageId: number;
  contactName: string;
  companyName?: string | null;
  email?: string | null;
  phone?: string | null;
  source: string;
  assignedToUserId?: number | null;
  estimatedValue?: number;
  currencyCode?: string;
  expectedCloseDate?: string | null;
  notes?: string | null;
  tags?: string | null;
  priority?: string;
  userId: number;
}): Promise<SpResult> {
  const { companyId, branchId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Lead_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      PipelineId: data.pipelineId,
      StageId: data.stageId,
      ContactName: data.contactName,
      CompanyName: data.companyName ?? null,
      Email: data.email ?? null,
      Phone: data.phone ?? null,
      Source: data.source,
      AssignedToUserId: data.assignedToUserId ?? null,
      EstimatedValue: data.estimatedValue ?? 0,
      CurrencyCode: data.currencyCode ?? "USD",
      ExpectedCloseDate: data.expectedCloseDate ?? null,
      Notes: data.notes ?? null,
      Tags: data.tags ?? null,
      Priority: data.priority ?? "MEDIUM",
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      LeadId: sql.Int,
      LeadCode: sql.NVarChar(30),
    },
  );
  const result = parseSpResult(output, ["LeadId", "LeadCode"]);
  if (result.success) {
    try { obs?.event("crm.lead.created", { leadId: result.LeadId, pipeline: data.pipelineId }); } catch {}
  }
  return result;
}

export async function updateLead(
  leadId: number,
  data: {
    stageId?: number | null;
    contactName?: string | null;
    companyName?: string | null;
    email?: string | null;
    phone?: string | null;
    assignedToUserId?: number | null;
    estimatedValue?: number | null;
    expectedCloseDate?: string | null;
    notes?: string | null;
    tags?: string | null;
    priority?: string | null;
    userId: number;
  },
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Lead_Update",
    {
      CompanyId: s.companyId,
      LeadId: leadId,
      StageId: data.stageId,
      ContactName: data.contactName,
      CompanyName: data.companyName,
      Email: data.email,
      Phone: data.phone,
      AssignedToUserId: data.assignedToUserId,
      EstimatedValue: data.estimatedValue,
      ExpectedCloseDate: data.expectedCloseDate,
      Notes: data.notes,
      Tags: data.tags,
      Priority: data.priority,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function changeLeadStage(
  leadId: number,
  data: { newStageId: number; notes?: string | null; userId: number },
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Lead_ChangeStage",
    {
      CompanyId: s.companyId,
      LeadId: leadId,
      NewStageId: data.newStageId,
      Notes: data.notes ?? null,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  const resultStage = parseSpResult(output);
  if (resultStage.success) {
    try { obs?.event("crm.lead.stage_changed", { leadId, newStageId: data.newStageId }); } catch {}
  }
  return resultStage;
}

export async function closeLead(
  leadId: number,
  data: {
    isWon: boolean;
    lostReason?: string | null;
    customerId?: number | null;
    userId: number;
  },
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Lead_Close",
    {
      CompanyId: s.companyId,
      LeadId: leadId,
      IsWon: data.isWon,
      LostReason: data.lostReason ?? null,
      CustomerId: data.customerId ?? null,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  const resultClose = parseSpResult(output);
  if (resultClose.success) {
    try { obs?.event(data.isWon ? "crm.lead.won" : "crm.lead.lost", { leadId, isWon: data.isWon }); } catch {}
  }
  return resultClose;
}

// ── Activities ───────────────────────────────────────────────────────────────

export interface ListActivitiesParams {
  leadId?: number;
  customerId?: number;
  isCompleted?: boolean;
  dueBefore?: string;
  page?: number;
  limit?: number;
}

export async function listActivities(params: ListActivitiesParams = {}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_CRM_Activity_List",
    {
      CompanyId: companyId,
      LeadId: params.leadId ?? null,
      CustomerId: params.customerId ?? null,
      IsCompleted: params.isCompleted ?? null,
      DueBefore: params.dueBefore ?? null,
      Page: page,
      Limit: limit,
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

export async function createActivity(data: {
  leadId?: number | null;
  customerId?: number | null;
  activityType: string;
  subject: string;
  description?: string | null;
  dueDate?: string | null;
  assignedToUserId: number;
  priority?: string;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Activity_Create",
    {
      CompanyId: companyId,
      LeadId: data.leadId ?? null,
      CustomerId: data.customerId ?? null,
      ActivityType: data.activityType,
      Subject: data.subject,
      Description: data.description ?? null,
      DueDate: data.dueDate ?? null,
      AssignedToUserId: data.assignedToUserId,
      Priority: data.priority ?? "MEDIUM",
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      ActivityId: sql.Int,
    },
  );
  const resultAct = parseSpResult(output, ["ActivityId"]);
  if (resultAct.success) {
    try { obs?.event("crm.activity.created", { activityId: resultAct.ActivityId, type: data.activityType }); } catch {}
  }
  return resultAct;
}

export async function completeActivity(
  activityId: number,
  userId: number,
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Activity_Complete",
    { CompanyId: s.companyId, ActivityId: activityId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  const resultComplete = parseSpResult(output);
  if (resultComplete.success) {
    try { obs?.event("crm.activity.completed", { activityId }); } catch {}
  }
  return resultComplete;
}

export async function updateActivity(
  activityId: number,
  data: {
    subject?: string | null;
    description?: string | null;
    dueDate?: string | null;
    priority?: string | null;
    userId: number;
  },
): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Activity_Update",
    {
      CompanyId: s.companyId,
      ActivityId: activityId,
      Subject: data.subject,
      Description: data.description,
      DueDate: data.dueDate,
      Priority: data.priority,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Dashboard ────────────────────────────────────────────────────────────────

export async function getDashboard(pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Dashboard", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
}
