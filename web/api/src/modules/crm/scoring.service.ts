/**
 * CRM Scoring / Detail / Timeline Service — Stored Procedures
 *
 * Lead Scoring, Lead Detail, Lead Timeline, Lead History
 */
import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

// ── Lead Score Calculate ─────────────────────────────────────────────────────

export async function calculateLeadScore(leadId: number, userId?: number) {
  const { output } = await callSpOut(
    "usp_CRM_LeadScore_Calculate",
    { LeadId: leadId, UserId: userId ?? null },
    { ok: sql.Int, mensaje: sql.NVarChar(500), Score: sql.Int },
  );
  return {
    success: Number(output.ok ?? 0) === 1,
    message: String(output.mensaje ?? "OK"),
    score: Number(output.Score ?? 0),
  };
}

// ── Bulk Calculate Scores ────────────────────────────────────────────────────

export async function bulkCalculateScores() {
  const { companyId } = scope();
  const { output } = await callSpOut(
    "usp_CRM_LeadScore_BulkCalculate",
    { CompanyId: companyId },
    { ok: sql.Int, mensaje: sql.NVarChar(500) },
  );
  return {
    success: Number(output.ok ?? 0) === 1,
    message: String(output.mensaje ?? "OK"),
  };
}

// ── Get Lead Score ───────────────────────────────────────────────────────────

export async function getLeadScore(leadId: number) {
  const rows = await callSp("usp_CRM_LeadScore_Get", { LeadId: leadId });
  return rows[0] ?? null;
}

// ── Get Lead Detail ──────────────────────────────────────────────────────────

export async function getLeadDetail(leadId: number) {
  const rows = await callSp("usp_CRM_Lead_GetDetail", { LeadId: leadId });
  return rows[0] ?? null;
}

// ── Get Lead Timeline ────────────────────────────────────────────────────────

export async function getLeadTimeline(pipelineId?: number, status?: string) {
  const { companyId } = scope();
  return callSp("usp_CRM_Lead_Timeline", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    Status: status ?? null,
  });
}

// ── Get Lead History ─────────────────────────────────────────────────────────

export async function getLeadHistory(leadId: number) {
  return callSp("usp_CRM_Lead_GetHistory", { LeadId: leadId });
}
