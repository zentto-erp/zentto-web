/**
 * affiliate.service.ts — Programa de afiliados Zentto Store.
 *
 * Cubre:
 *   - Registro de afiliados (customer_id → pending)
 *   - Dashboard (clicks, conversiones, comisiones por estado, serie mensual)
 *   - Tracking de clicks con referral_code
 *   - Atribución de órdenes (se llama desde checkout)
 *   - Listado paginado de comisiones (cliente + admin)
 *   - Rates públicas (para la landing pública `/afiliados`)
 *   - Admin: listar afiliados, aprobar/suspender, generar payouts
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1 };
}

// ─── Tipos ─────────────────────────────────────────────

export interface CommissionRate {
  category: string;
  rate: number;
  isDefault?: boolean;
}

export interface AffiliateDashboard {
  affiliateId: number;
  referralCode: string;
  status: string;
  legalName: string | null;
  clicksTotal: number;
  conversions: number;
  pendingAmount: number;
  approvedAmount: number;
  paidAmount: number;
  totalEarned: number;
  currencyCode: string;
  monthly: Array<{ mon: string; amount: number }>;
}

// ─── Registro ──────────────────────────────────────────

export async function registerAffiliate(args: {
  customerId: number;
  legalName: string;
  taxId?: string | null;
  contactEmail?: string | null;
  payoutMethod?: string | null;
  payoutDetails?: Record<string, unknown> | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Affiliate_Register",
    {
      CompanyId: scope().companyId,
      CustomerId: args.customerId,
      LegalName: args.legalName,
      TaxId: args.taxId ?? null,
      ContactEmail: args.contactEmail ?? null,
      PayoutMethod: args.payoutMethod ?? null,
      PayoutDetails: args.payoutDetails ? JSON.stringify(args.payoutDetails) : null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      ReferralCode: sql.NVarChar(20),
      AffiliateId: sql.BigInt,
    }
  );
  const resultado = output.Resultado as number;
  if (resultado !== 1) return { ok: false, error: (output.Mensaje as string) || "register_failed" };
  return {
    ok: true,
    affiliateId: Number(output.AffiliateId),
    referralCode: output.ReferralCode as string,
    message: output.Mensaje as string,
  };
}

// ─── Dashboard ─────────────────────────────────────────

export async function getAffiliateDashboard(customerId: number): Promise<AffiliateDashboard | null> {
  const rows = await callSp<any>("usp_Store_Affiliate_GetDashboard", {
    CompanyId: scope().companyId,
    CustomerId: customerId,
  });
  const r = rows[0];
  if (!r) return null;

  let monthly: Array<{ mon: string; amount: number }> = [];
  try {
    const raw = (r as any).monthlyJson ?? (r as any).monthly_json ?? "[]";
    const parsed = typeof raw === "string" ? JSON.parse(raw) : raw;
    if (Array.isArray(parsed)) {
      monthly = parsed.map((p: any) => ({
        mon: String(p.mon ?? p.month ?? ""),
        amount: Number(p.amount ?? 0),
      }));
    }
  } catch { /* ignore */ }

  return {
    affiliateId: Number(r.affiliateId),
    referralCode: String(r.referralCode),
    status: String(r.status ?? "pending"),
    legalName: r.legalName ?? null,
    clicksTotal: Number(r.clicksTotal ?? 0),
    conversions: Number(r.conversions ?? 0),
    pendingAmount: Number(r.pendingAmount ?? 0),
    approvedAmount: Number(r.approvedAmount ?? 0),
    paidAmount: Number(r.paidAmount ?? 0),
    totalEarned: Number(r.totalEarned ?? 0),
    currencyCode: String(r.currencyCode ?? "USD"),
    monthly,
  };
}

// ─── Track click ───────────────────────────────────────

export async function trackAffiliateClick(args: {
  referralCode: string;
  sessionId?: string | null;
  ip?: string | null;
  userAgent?: string | null;
  referer?: string | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Affiliate_TrackClick",
    {
      ReferralCode: args.referralCode,
      SessionId: args.sessionId ?? null,
      Ip: args.ip ?? null,
      UserAgent: args.userAgent ?? null,
      Referer: args.referer ?? null,
    },
    { Resultado: sql.Int, ClickId: sql.BigInt }
  );
  return {
    ok: (output.Resultado as number) === 1,
    clickId: output.ClickId ? Number(output.ClickId) : null,
  };
}

// ─── Atribución de órdenes ─────────────────────────────

export async function attributeOrderCommission(args: {
  orderNumber: string;
  referralCode: string;
  sessionId?: string | null;
  orderAmount: number;
  currency?: string | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Affiliate_AttributeOrder",
    {
      CompanyId: scope().companyId,
      OrderNumber: args.orderNumber,
      ReferralCode: args.referralCode,
      SessionId: args.sessionId ?? null,
      OrderAmount: args.orderAmount,
      Currency: args.currency ?? "USD",
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      CommissionAmount: sql.Decimal(14, 2),
    }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
    commissionAmount: Number(output.CommissionAmount ?? 0),
  };
}

// ─── Commissions list (cliente) ────────────────────────

export async function listMyCommissions(args: {
  customerId: number;
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);

  const { rows, output } = await callSpOut<any>(
    "usp_Store_Affiliate_CommissionsList",
    {
      CompanyId: scope().companyId,
      CustomerId: args.customerId,
      Status: args.status ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );
  return { page, limit, total: (output.TotalCount as number) ?? 0, rows };
}

// ─── Commission rates (público) ────────────────────────

export async function listCommissionRates(): Promise<CommissionRate[]> {
  const rows = await callSp<any>("usp_Store_Affiliate_CommissionRatesList", {});
  return rows.map((r: any) => ({
    category: String(r.category),
    rate: Number(r.rate),
    isDefault: Boolean(r.isDefault),
  }));
}

// ─── Admin — listar afiliados ──────────────────────────

export async function adminListAffiliates(args: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Affiliate_Admin_List",
    {
      CompanyId: scope().companyId,
      Status: args.status ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );
  return { page, limit, total: (output.TotalCount as number) ?? 0, rows };
}

// ─── Admin — cambiar estado ────────────────────────────

export async function adminSetAffiliateStatus(args: {
  affiliateId: number;
  status: "active" | "suspended" | "pending" | "rejected";
  actor: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Affiliate_Admin_SetStatus",
    {
      CompanyId: scope().companyId,
      AffiliateId: args.affiliateId,
      Status: args.status,
      Actor: args.actor,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
  };
}

// ─── Admin — listar comisiones ─────────────────────────

export async function adminListCommissions(args: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Affiliate_Admin_CommissionsList",
    {
      CompanyId: scope().companyId,
      Status: args.status ?? null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );
  return { page, limit, total: (output.TotalCount as number) ?? 0, rows };
}

// ─── Admin — generar payouts ───────────────────────────

export async function adminGeneratePayouts(args: {
  periodStart?: string | null;
  periodEnd?: string | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Affiliate_PayoutGenerate",
    {
      CompanyId: scope().companyId,
      PeriodStart: args.periodStart ?? null,
      PeriodEnd: args.periodEnd ?? null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      PayoutsCreated: sql.Int,
      TotalAmount: sql.Decimal(14, 2),
    }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
    payoutsCreated: Number(output.PayoutsCreated ?? 0),
    totalAmount: Number(output.TotalAmount ?? 0),
  };
}

// ─── Utilidad compartida para checkout ─────────────────

/**
 * Llamado desde el flow de checkout cuando hay cookie `zentto_ref` activa.
 * No lanza — silencioso si falla (best-effort).
 */
export async function tryAttributeOrder(args: {
  orderNumber: string;
  referralCode: string;
  sessionId?: string | null;
  orderAmount: number;
  currency?: string | null;
}): Promise<void> {
  try {
    if (!args.referralCode || !args.orderNumber || !args.orderAmount) return;
    await attributeOrderCommission(args);
  } catch (err) {
    console.warn("[affiliate] tryAttributeOrder error:", err);
  }
}
