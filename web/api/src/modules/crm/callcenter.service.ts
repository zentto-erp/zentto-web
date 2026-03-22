/**
 * Call Center Service — Stored Procedures
 *
 * Colas, Agentes, Llamadas, Scripts, Campanas, Dashboard
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

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

// ═══════════════════════════════════════════════════════════════════════════════
//  COLAS (CallQueue)
// ═══════════════════════════════════════════════════════════════════════════════

export async function listQueues() {
  const { companyId } = scope();
  return callSp("usp_CRM_CallQueue_List", { CompanyId: companyId });
}

export async function upsertQueue(data: {
  queueId?: number | null;
  queueCode: string;
  queueName: string;
  queueType?: string;
  description?: string | null;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_CallQueue_Upsert",
    {
      CompanyId: companyId,
      QueueId: data.queueId ?? null,
      QueueCode: data.queueCode,
      QueueName: data.queueName,
      QueueType: data.queueType ?? "GENERAL",
      Description: data.description ?? null,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AGENTES (Agent)
// ═══════════════════════════════════════════════════════════════════════════════

export async function listAgents(params: {
  queueId?: number | null;
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_CRM_Agent_List",
    {
      CompanyId: companyId,
      QueueId: params.queueId ?? null,
      Status: params.status ?? null,
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

export async function upsertAgent(data: {
  agentId?: number | null;
  userIdAgent: number;
  queueId?: number | null;
  agentCode: string;
  agentName: string;
  extension?: string | null;
  maxConcurrentCalls?: number;
  isActive?: boolean;
  adminUserId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Agent_Upsert",
    {
      CompanyId: companyId,
      AgentId: data.agentId ?? null,
      UserId_Agent: data.userIdAgent,
      QueueId: data.queueId ?? null,
      AgentCode: data.agentCode,
      AgentName: data.agentName,
      Extension: data.extension ?? null,
      MaxConcurrentCalls: data.maxConcurrentCalls ?? 1,
      IsActive: data.isActive ?? true,
      AdminUserId: data.adminUserId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function updateAgentStatus(
  agentId: number,
  status: string,
): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_CRM_Agent_UpdateStatus",
    { AgentId: agentId, Status: status },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LLAMADAS (CallLog)
// ═══════════════════════════════════════════════════════════════════════════════

export interface ListCallsParams {
  agentId?: number | null;
  queueId?: number | null;
  direction?: string | null;
  result?: string | null;
  customerCode?: string | null;
  fechaDesde: string;
  fechaHasta: string;
  page?: number;
  limit?: number;
}

export async function listCalls(params: ListCallsParams) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_CRM_CallLog_List",
    {
      CompanyId: companyId,
      AgentId: params.agentId ?? null,
      QueueId: params.queueId ?? null,
      Direction: params.direction ?? null,
      Result: params.result ?? null,
      CustomerCode: params.customerCode ?? null,
      FechaDesde: params.fechaDesde,
      FechaHasta: params.fechaHasta,
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

export async function getCall(callLogId: number) {
  const rows = await callSp("usp_CRM_CallLog_Get", { CallLogId: callLogId });
  return rows[0] || null;
}

export async function createCall(data: {
  agentId?: number | null;
  queueId?: number | null;
  callDirection: string;
  callerNumber: string;
  calledNumber: string;
  customerCode?: string | null;
  customerId?: number | null;
  leadId?: number | null;
  contactName?: string | null;
  callStartTime: string;
  callEndTime?: string | null;
  durationSeconds?: number | null;
  waitSeconds?: number | null;
  result: string;
  disposition?: string | null;
  notes?: string | null;
  recordingUrl?: string | null;
  callbackScheduled?: string | null;
  relatedDocumentType?: string | null;
  relatedDocumentNumber?: string | null;
  tags?: string | null;
  satisfactionScore?: number | null;
  userId: number;
}): Promise<SpResult> {
  const { companyId, branchId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_CallLog_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      AgentId: data.agentId ?? null,
      QueueId: data.queueId ?? null,
      CallDirection: data.callDirection,
      CallerNumber: data.callerNumber,
      CalledNumber: data.calledNumber,
      CustomerCode: data.customerCode ?? null,
      CustomerId: data.customerId ?? null,
      LeadId: data.leadId ?? null,
      ContactName: data.contactName ?? null,
      CallStartTime: data.callStartTime,
      CallEndTime: data.callEndTime ?? null,
      DurationSeconds: data.durationSeconds ?? null,
      WaitSeconds: data.waitSeconds ?? null,
      Result: data.result,
      Disposition: data.disposition ?? null,
      Notes: data.notes ?? null,
      RecordingUrl: data.recordingUrl ?? null,
      CallbackScheduled: data.callbackScheduled ?? null,
      RelatedDocumentType: data.relatedDocumentType ?? null,
      RelatedDocumentNumber: data.relatedDocumentNumber ?? null,
      Tags: data.tags ?? null,
      SatisfactionScore: data.satisfactionScore ?? null,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      CallLogId: sql.BigInt,
    },
  );
  return parseSpResult(output, ["CallLogId"]);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCRIPTS (CallScript)
// ═══════════════════════════════════════════════════════════════════════════════

export async function listScripts(queueType?: string | null) {
  const { companyId } = scope();
  return callSp("usp_CRM_CallScript_List", {
    CompanyId: companyId,
    QueueType: queueType ?? null,
  });
}

export async function upsertScript(data: {
  scriptId?: number | null;
  scriptCode: string;
  scriptName: string;
  queueType: string;
  content: string;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_CallScript_Upsert",
    {
      CompanyId: companyId,
      ScriptId: data.scriptId ?? null,
      ScriptCode: data.scriptCode,
      ScriptName: data.scriptName,
      QueueType: data.queueType,
      Content: data.content,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CAMPANAS (Campaign)
// ═══════════════════════════════════════════════════════════════════════════════

export async function listCampaigns(params: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const { companyId } = scope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  const { rows, output } = await callSpOut(
    "usp_CRM_Campaign_List",
    {
      CompanyId: companyId,
      Status: params.status ?? null,
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

export async function getCampaign(campaignId: number) {
  const rows = await callSp("usp_CRM_Campaign_Get", { CampaignId: campaignId });
  return rows[0] || null;
}

export async function createCampaign(data: {
  campaignCode: string;
  campaignName: string;
  campaignType: string;
  queueId?: number | null;
  scriptId?: number | null;
  startDate: string;
  endDate?: string | null;
  assignedToUserId?: number | null;
  notes?: string | null;
  contactsJson?: string | null;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Campaign_Create",
    {
      CompanyId: companyId,
      CampaignCode: data.campaignCode,
      CampaignName: data.campaignName,
      CampaignType: data.campaignType,
      QueueId: data.queueId ?? null,
      ScriptId: data.scriptId ?? null,
      StartDate: data.startDate,
      EndDate: data.endDate ?? null,
      AssignedToUserId: data.assignedToUserId ?? null,
      Notes: data.notes ?? null,
      ContactsJson: data.contactsJson ?? null,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      CampaignId: sql.BigInt,
    },
  );
  return parseSpResult(output, ["CampaignId"]);
}

export async function updateCampaignStatus(
  campaignId: number,
  status: string,
  userId: number,
): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_CRM_Campaign_UpdateStatus",
    { CampaignId: campaignId, Status: status, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function getNextContact(campaignId: number, agentId: number) {
  const rows = await callSp("usp_CRM_Campaign_GetNextContact", {
    CampaignId: campaignId,
    AgentId: agentId,
  });
  return rows[0] || null;
}

export async function logAttempt(data: {
  campaignContactId: number;
  result: string;
  callbackDate?: string | null;
  notes?: string | null;
  userId: number;
}): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_CRM_Campaign_LogAttempt",
    {
      CampaignContactId: data.campaignContactId,
      Result: data.result,
      CallbackDate: data.callbackDate ?? null,
      Notes: data.notes ?? null,
      UserId: data.userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

export async function getDashboard(fechaDesde: string, fechaHasta: string) {
  const { companyId } = scope();
  const rows = await callSp("usp_CRM_CallCenter_Dashboard", {
    CompanyId: companyId,
    FechaDesde: fechaDesde,
    FechaHasta: fechaHasta,
  });
  return rows[0] || null;
}
