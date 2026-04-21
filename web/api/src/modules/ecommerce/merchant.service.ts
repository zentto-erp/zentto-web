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
