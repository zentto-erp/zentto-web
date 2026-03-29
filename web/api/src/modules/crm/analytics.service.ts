/**
 * CRM Analytics Service — Stored Procedures
 *
 * KPIs, Forecast, Funnel, Win/Loss, Velocity, Activity Report
 */
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

// ── KPIs ─────────────────────────────────────────────────────────────────────

export async function getKPIs(pipelineId?: number) {
  const { companyId } = scope();
  const rows = await callSp("usp_CRM_Analytics_KPIs", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
  return rows[0] ?? null;
}

// ── Forecast ─────────────────────────────────────────────────────────────────

export async function getForecast(pipelineId?: number, months?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_Forecast", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    Months: months ?? 6,
  });
}

// ── Funnel ───────────────────────────────────────────────────────────────────

export async function getFunnel(pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_Funnel", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
}

// ── Win/Loss by Period ───────────────────────────────────────────────────────

export async function getWinLossByPeriod(
  pipelineId?: number,
  dateFrom?: string,
  dateTo?: string,
) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_WinLoss_ByPeriod", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    DateFrom: dateFrom ?? null,
    DateTo: dateTo ?? null,
  });
}

// ── Win/Loss by Source ───────────────────────────────────────────────────────

export async function getWinLossBySource(
  pipelineId?: number,
  dateFrom?: string,
  dateTo?: string,
) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_WinLoss_BySource", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    DateFrom: dateFrom ?? null,
    DateTo: dateTo ?? null,
  });
}

// ── Velocity ─────────────────────────────────────────────────────────────────

export async function getVelocity(pipelineId?: number) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_Velocity", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
  });
}

// ── Activity Report ──────────────────────────────────────────────────────────

export async function getActivityReport(
  pipelineId?: number,
  dateFrom?: string,
  dateTo?: string,
) {
  const { companyId } = scope();
  return callSp("usp_CRM_Analytics_ActivityReport", {
    CompanyId: companyId,
    PipelineId: pipelineId ?? null,
    DateFrom: dateFrom ?? null,
    DateTo: dateTo ?? null,
  });
}
