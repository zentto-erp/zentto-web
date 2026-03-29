/**
 * Purchases Analytics Service — Stored Procedures
 *
 * KPIs, ByMonth, BySupplier, AgingAP, PaymentSchedule
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

export async function getKPIs(from?: string, to?: string) {
  const { companyId } = scope();
  const rows = await callSp("usp_Purchases_Analytics_KPIs", {
    CompanyId: companyId,
    From: from ?? null,
    To: to ?? null,
  });
  return rows[0] ?? null;
}

// ── By Month ─────────────────────────────────────────────────────────────────

export async function getByMonth(months?: number) {
  const { companyId } = scope();
  return callSp("usp_Purchases_Analytics_ByMonth", {
    CompanyId: companyId,
    Months: months ?? 12,
  });
}

// ── By Supplier ──────────────────────────────────────────────────────────────

export async function getBySupplier(
  top?: number,
  from?: string,
  to?: string,
) {
  const { companyId } = scope();
  return callSp("usp_Purchases_Analytics_BySupplier", {
    CompanyId: companyId,
    Top: top ?? 10,
    From: from ?? null,
    To: to ?? null,
  });
}

// ── Aging AP ─────────────────────────────────────────────────────────────────

export async function getAgingAP() {
  const { companyId } = scope();
  return callSp("usp_Purchases_Analytics_AgingAP", {
    CompanyId: companyId,
  });
}

// ── Payment Schedule ─────────────────────────────────────────────────────────

export async function getPaymentSchedule(months?: number) {
  const { companyId } = scope();
  return callSp("usp_Purchases_Analytics_PaymentSchedule", {
    CompanyId: companyId,
    Months: months ?? 3,
  });
}
