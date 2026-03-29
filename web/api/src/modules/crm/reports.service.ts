/**
 * CRM Reports Service — Stored Procedures
 *
 * Sales by Period, Lead Aging, Conversion by Source, Top Performers
 */
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

// ── Sales by Period ─────────────────────────────────────────────────────────

export async function getSalesByPeriod(pipelineId?: number, groupBy?: string) {
  const { companyId } = scope();
  return callSp("usp_CRM_Report_SalesByPeriod", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    GroupBy: groupBy ?? "month",
  });
}

// ── Lead Aging ──────────────────────────────────────────────────────────────

export async function getLeadAging(pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Report_LeadAging", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
}

// ── Conversion by Source ────────────────────────────────────────────────────

export async function getConversionBySource(pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Report_ConversionBySource", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
}

// ── Top Performers ──────────────────────────────────────────────────────────

export async function getTopPerformers(pipelineId?: number, dateFrom?: string) {
  const { companyId } = scope();
  return callSp("usp_CRM_Report_TopPerformers", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    DateFrom: dateFrom ?? null,
  });
}
