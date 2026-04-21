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

import { callSp, callSpOut, callSpOutWithPii, sql } from "../../db/query.js";
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
  // PII: PayoutDetails se cifra con pgcrypto dentro del SP (usa GUC
  // zentto.master_key seteada por callSpOutWithPii).
  const { output } = await callSpOutWithPii(
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
  // Nota: snake_case intencional en el nombre del SP.
  // PostgreSQL auto-lowercase identificadores sin comillas: para que el caller
  // matchee con la función real (definida en migración 00150 con snake_case
  // tipo `get_dashboard`, `track_click`, etc.), pasamos el nombre ya en
  // snake_case. En SQL Server los SPs equivalentes viven en `sqlweb/` con
  // nombres también en snake_case.
  const rows = await callSp<any>("usp_Store_Affiliate_Get_Dashboard", {
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
    "usp_Store_Affiliate_Track_Click",
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
    "usp_Store_Affiliate_Attribute_Order",
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
    "usp_Store_Affiliate_Commissions_List",
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
  const rows = await callSp<any>("usp_Store_Affiliate_Commission_Rates_List", {});
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
  // PII: admin list incluye "payoutDetails" descifrado — usamos la variante
  // con GUC zentto.master_key seteada para que store.pii_decrypt_safe() tenga
  // acceso a la key dentro del SP.
  const { rows, output } = await callSpOutWithPii<any>(
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
    "usp_Store_Affiliate_Admin_Set_Status",
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
    "usp_Store_Affiliate_Admin_Commissions_List",
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
  const rows = await callSp<any>("usp_Store_Affiliate_Payout_Generate", {
    CompanyId: scope().companyId,
    From: args.periodStart ?? null,
    To: args.periodEnd ?? null,
  });
  const r = rows[0] ?? {};
  return {
    ok: Boolean(r.ok),
    message: String(r.mensaje ?? ""),
    payoutsCreated: Number(r.payoutsCreated ?? 0),
    totalAmount: Number(r.totalAmount ?? 0),
  };
}

// ─── Admin — bulk status de comisiones (Ola 4) ─────────

/**
 * Bulk-approve / bulk-mark-paid de comisiones (liquidación mensual).
 * Acepta estados: approved, paid, reversed.
 */
export async function adminBulkSetCommissionStatus(args: {
  ids: number[];
  status: "approved" | "paid" | "reversed";
  actor: string;
}) {
  if (!Array.isArray(args.ids) || args.ids.length === 0) {
    return { ok: false, message: "Sin comisiones seleccionadas", updated: 0 };
  }
  const ids = args.ids.filter((n) => Number.isInteger(n) && n > 0);
  if (ids.length === 0) {
    return { ok: false, message: "IDs inválidos", updated: 0 };
  }

  const { output } = await callSpOut(
    "usp_Store_Affiliate_Admin_Commissions_Bulk_Status",
    {
      CompanyId: scope().companyId,
      // En PG la función espera bigint[] nativo; el driver node-pg acepta
      // array JS y lo convierte al tipo adecuado. En SQL Server (fallback)
      // se pasaría CSV — pero el deploy actual es PostgreSQL, y pasar CSV
      // aquí revienta ("operator does not exist: bigint = bigint[]").
      Ids: ids,
      Status: args.status,
      Actor: args.actor,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      Updated: sql.Int,
    }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
    updated: Number(output.Updated ?? 0),
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
