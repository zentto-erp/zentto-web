/**
 * merchant.service.ts — Marketplace de comerciantes externos (merchants) de Zentto Store.
 *
 * NOTA: en el dominio interno usamos "Merchant" para evitar colisión con
 * master.Seller (vendedor comercial del ERP). En la UI pública se muestra
 * "Vendedor" / ruta `/vender` por UX en español.
 *
 * Onboarding → aplicación → aprobación admin → dashboard merchant
 *   ↳ merchant propone productos (draft/pending_review)
 *   ↳ admin aprueba/rechaza productos
 *   ↳ al final se generan payouts periódicos (futuro)
 */

import { callSp, callSpOut, callSpWithPii, callSpOutWithPii, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1 };
}

// ─── Apply ─────────────────────────────────────────────

export async function applyMerchant(args: {
  customerId: number;
  legalName: string;
  taxId?: string | null;
  storeSlug?: string | null;
  description?: string | null;
  logoUrl?: string | null;
  contactEmail?: string | null;
  contactPhone?: string | null;
  payoutMethod?: string | null;
  payoutDetails?: Record<string, unknown> | null;
}) {
  // PII: PayoutDetails se cifra con pgcrypto dentro del SP (usa GUC
  // zentto.master_key seteada por callSpOutWithPii).
  const { output } = await callSpOutWithPii(
    "usp_Store_Merchant_Apply",
    {
      CompanyId: scope().companyId,
      CustomerId: args.customerId,
      LegalName: args.legalName,
      TaxId: args.taxId ?? null,
      StoreSlug: args.storeSlug ?? null,
      Description: args.description ?? null,
      LogoUrl: args.logoUrl ?? null,
      ContactEmail: args.contactEmail ?? null,
      ContactPhone: args.contactPhone ?? null,
      PayoutMethod: args.payoutMethod ?? null,
      PayoutDetails: args.payoutDetails ? JSON.stringify(args.payoutDetails) : null,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      MerchantId: sql.BigInt,
      StoreSlugOut: sql.NVarChar(80),
    }
  );
  if ((output.Resultado as number) !== 1) {
    return { ok: false, error: (output.Mensaje as string) || "apply_failed" };
  }
  return {
    ok: true,
    merchantId: Number(output.MerchantId),
    storeSlug: output.StoreSlugOut as string | null,
    message: output.Mensaje as string,
  };
}

// ─── Dashboard ─────────────────────────────────────────

export async function getMerchantDashboard(customerId: number) {
  const rows = await callSp<any>("usp_Store_Merchant_Dashboard", {
    CompanyId: scope().companyId,
    CustomerId: customerId,
  });
  return rows[0] ?? null;
}

// ─── Products — merchant ───────────────────────────────

export async function submitMerchantProduct(args: {
  customerId: number;
  productId?: number | null;
  code?: string | null;
  name: string;
  description?: string | null;
  price: number;
  stock: number;
  category?: string | null;
  imageUrl?: string | null;
  submit?: boolean;
}) {
  const { output } = await callSpOut(
    "usp_Store_Merchant_Product_Submit",
    {
      CompanyId: scope().companyId,
      CustomerId: args.customerId,
      ProductId: args.productId ?? null,
      Code: args.code ?? null,
      Name: args.name,
      Description: args.description ?? null,
      Price: args.price,
      Stock: args.stock,
      Category: args.category ?? null,
      ImageUrl: args.imageUrl ?? null,
      Submit: args.submit ? 1 : 0,
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500),
      OutProductId: sql.BigInt,
      OutStatus: sql.NVarChar(20),
    }
  );
  if ((output.Resultado as number) !== 1) {
    return { ok: false, error: (output.Mensaje as string) || "submit_failed" };
  }
  return {
    ok: true,
    productId: Number(output.OutProductId ?? 0),
    status: output.OutStatus as string,
    message: output.Mensaje as string,
  };
}

export async function listMerchantProducts(args: {
  customerId: number;
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Merchant_Products_List",
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

// ─── Admin ─────────────────────────────────────────────

/**
 * Detalle admin de un merchant — incluye "payoutDetails" descifrado on-the-fly.
 * El SP usa store.pii_decrypt_safe() que requiere la GUC zentto.master_key,
 * que seteamos vía callSpWithPii.
 */
export async function adminGetMerchantDetail(merchantId: number) {
  const rows = await callSpWithPii<any>(
    "usp_Store_Merchant_Admin_Get_Detail",
    {
      CompanyId: scope().companyId,
      MerchantId: merchantId,
    }
  );
  return rows[0] ?? null;
}

export async function adminListMerchants(args: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Merchant_Admin_List",
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

export async function adminSetMerchantStatus(args: {
  merchantId: number;
  status: "approved" | "rejected" | "suspended" | "pending";
  actor: string;
  reason?: string | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Merchant_Admin_Set_Status",
    {
      CompanyId: scope().companyId,
      MerchantId: args.merchantId,
      Status: args.status,
      Actor: args.actor,
      Reason: args.reason ?? null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
  };
}

export async function adminListPendingProducts(args: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Merchant_Admin_Products_List",
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

export async function adminReviewProduct(args: {
  productId: number;
  status: "approved" | "rejected";
  notes?: string | null;
  actor: string;
}) {
  const { output } = await callSpOut(
    "usp_Store_Merchant_Admin_Product_Review",
    {
      CompanyId: scope().companyId,
      ProductId: args.productId,
      Status: args.status,
      Notes: args.notes ?? null,
      Actor: args.actor,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: (output.Resultado as number) === 1,
    message: output.Mensaje as string,
  };
}

// ─── Transactional wiring post-checkout ────────────────

/**
 * Rellena ar.SalesDocumentLine.MerchantId para cada línea cuya ProductCode
 * coincide con un store.MerchantProduct aprobado. Idempotente.
 */
export async function populateOrderMerchants(orderNumber: string): Promise<number> {
  try {
    const { output } = await callSpOut(
      "usp_Store_Order_Populate_Merchants",
      {
        CompanyId: scope().companyId,
        OrderNumber: orderNumber,
      },
      {
        Resultado: sql.Int,
        Mensaje: sql.NVarChar(500),
        LinesUpdated: sql.Int,
      }
    );
    return Number(output.LinesUpdated ?? 0);
  } catch (err) {
    console.warn("[merchant] populateOrderMerchants error:", err);
    return 0;
  }
}

/**
 * Genera store.MerchantCommission por cada línea con MerchantId set.
 * Aplica el fix afiliado+merchant: la commission del afiliado se descuenta
 * del CommissionAmount retenido por Zentto (AffiliateDeduction), nunca del
 * total bruto. Idempotente por (CompanyId, OrderNumber).
 */
export async function generateMerchantCommissions(args: {
  orderNumber: string;
  affiliateCommissionAmount?: number;
}): Promise<{
  ok: boolean;
  commissionsCreated: number;
  totalMerchantEarning: number;
  totalZenttoRevenue: number;
}> {
  try {
    const { output } = await callSpOut(
      "usp_Store_Merchant_Commission_Generate",
      {
        CompanyId: scope().companyId,
        OrderNumber: args.orderNumber,
        AffiliateCommissionAmount: Number(args.affiliateCommissionAmount ?? 0),
      },
      {
        Resultado: sql.Int,
        Mensaje: sql.NVarChar(500),
        CommissionsCreated: sql.Int,
        TotalMerchantEarning: sql.Decimal(14, 2),
        TotalZenttoRevenue: sql.Decimal(14, 2),
      }
    );
    return {
      ok: (output.Resultado as number) === 1,
      commissionsCreated: Number(output.CommissionsCreated ?? 0),
      totalMerchantEarning: Number(output.TotalMerchantEarning ?? 0),
      totalZenttoRevenue: Number(output.TotalZenttoRevenue ?? 0),
    };
  } catch (err) {
    console.warn("[merchant] generateMerchantCommissions error:", err);
    return { ok: false, commissionsCreated: 0, totalMerchantEarning: 0, totalZenttoRevenue: 0 };
  }
}

// ─── Admin — generar payouts merchants ─────────────────

/**
 * Análogo a adminGeneratePayouts de afiliados. Agrupa commissions approved
 * por (MerchantId, CurrencyCode) en el período dado y crea MerchantPayout.
 *
 * PostgreSQL: la función devuelve una TABLE (callSp lee la primera fila).
 * SQL Server: el SP devuelve OUTPUT params — usar callSpOut si DB_TYPE=sqlserver.
 * Sigue el mismo patrón que affiliate.service.ts:adminGeneratePayouts (#506).
 */
export async function adminGenerateMerchantPayouts(args: {
  periodStart?: string | null;
  periodEnd?: string | null;
}) {
  const rows = await callSp<any>("usp_Store_Merchant_Payout_Generate", {
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
