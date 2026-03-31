/**
 * CRM Automation Service — Rules, Stale-Lead Detection, Action Logs
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

// ── Automation Rules ─────────────────────────────────────────────────────────

export async function listRules() {
  const { companyId } = scope();
  return callSp("usp_CRM_Automation_List", { CompanyId: companyId });
}

export async function upsertRule(data: {
  ruleId?: number | null;
  ruleName: string;
  ruleType: string;
  triggerEvent?: string | null;
  conditionJson?: string | null;
  actionJson?: string | null;
  isActive?: boolean;
  userId: number;
}): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Automation_Upsert",
    {
      CompanyId: companyId,
      RuleId: data.ruleId ?? null,
      RuleName: data.ruleName,
      RuleType: data.ruleType,
      TriggerEvent: data.triggerEvent ?? null,
      ConditionJson: data.conditionJson ?? null,
      ActionJson: data.actionJson ?? null,
      IsActive: data.isActive ?? true,
      UserId: data.userId,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      RuleId: sql.Int,
    },
  );
  return parseSpResult(output, ["RuleId"]);
}

export async function deleteRule(ruleId: number, userId: number): Promise<SpResult> {
  const s = scope();
  const { output } = await callSpOut(
    "usp_CRM_Automation_Delete",
    { CompanyId: s.companyId, RuleId: ruleId, UserId: userId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

// ── Stale-Lead Detection ─────────────────────────────────────────────────────

export async function findStaleLeads(days?: number, pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Lead_FindStale", {
    CompanyId: companyId,
    StaleDays: days ?? 7,
    PipelineId: pipelineId ?? null,
  });
}

// ── Action Logs ──────────────────────────────────────────────────────────────

export async function logAction(
  ruleId: number | null,
  leadId: number,
  actionTaken: string,
  actionResult: string,
): Promise<SpResult> {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_Automation_LogAction",
    {
      CompanyId: companyId,
      RuleId: ruleId,
      LeadId: leadId,
      ActionTaken: actionTaken,
      ActionResult: actionResult,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) },
  );
  return parseSpResult(output);
}

export async function getAutomationLogs(
  ruleId?: number | null,
  leadId?: number | null,
  limit?: number,
) {
  const { companyId } = scope();
  return callSp("usp_CRM_Automation_GetLogs", {
    CompanyId: companyId,
    RuleId: ruleId ?? null,
    LeadId: leadId ?? null,
    Limit: limit ?? 50,
  });
}
