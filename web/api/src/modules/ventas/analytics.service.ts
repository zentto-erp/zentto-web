/**
 * Sales Analytics Service — Stored Procedures
 *
 * KPIs, ByMonth, ByCustomer, AgingAR, CollectionForecast, ByProduct
 */
import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

// -- Helpers ------------------------------------------------------------------

function scope() {
  const s = getActiveScope();
  if (!s) throw new Error("No active scope");
  return s;
}

// -- KPIs ---------------------------------------------------------------------

export async function getKPIs(from?: string, to?: string) {
  const { companyId } = scope();
  const rows = await callSp("usp_Sales_Analytics_KPIs", {
    CompanyId: companyId,
    From: from ?? null,
    To: to ?? null,
  });
  return rows[0] ?? null;
}

// -- By Month -----------------------------------------------------------------

export async function getByMonth(months?: number) {
  const { companyId } = scope();
  return callSp("usp_Sales_Analytics_ByMonth", {
    CompanyId: companyId,
    Months: months ?? 12,
  });
}

// -- By Customer --------------------------------------------------------------

export async function getByCustomer(
  top?: number,
  from?: string,
  to?: string,
) {
  const { companyId } = scope();
  return callSp("usp_Sales_Analytics_ByCustomer", {
    CompanyId: companyId,
    Top: top ?? 10,
    From: from ?? null,
    To: to ?? null,
  });
}

// -- Aging AR -----------------------------------------------------------------

export async function getAgingAR() {
  const { companyId } = scope();
  return callSp("usp_Sales_Analytics_AgingAR", {
    CompanyId: companyId,
  });
}

// -- Collection Forecast ------------------------------------------------------

export async function getCollectionForecast(months?: number) {
  const { companyId } = scope();
  return callSp("usp_Sales_Analytics_CollectionForecast", {
    CompanyId: companyId,
    Months: months ?? 3,
  });
}

// -- By Product ---------------------------------------------------------------

export async function getByProduct(
  top?: number,
  from?: string,
  to?: string,
) {
  const { companyId } = scope();
  return callSp("usp_Sales_Analytics_ByProduct", {
    CompanyId: companyId,
    Top: top ?? 10,
    From: from ?? null,
    To: to ?? null,
  });
}
