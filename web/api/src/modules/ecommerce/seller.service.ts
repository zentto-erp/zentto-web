/**
 * seller.service.ts — Marketplace de vendedores Zentto Store.
 *
 * Onboarding → aplicación → aprobación admin → dashboard vendedor
 *   ↳ vendedor propone productos (draft/pending_review)
 *   ↳ admin aprueba/rechaza productos
 *   ↳ al final se generan payouts periódicos (futuro)
 */

import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

function scope() {
  const s = getActiveScope();
  return { companyId: s?.companyId ?? 1 };
}

// ─── Apply ─────────────────────────────────────────────

export async function applySeller(args: {
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
  const { output } = await callSpOut(
    "usp_Store_Seller_Apply",
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
      SellerId: sql.BigInt,
      StoreSlugOut: sql.NVarChar(80),
    }
  );
  if ((output.Resultado as number) !== 1) {
    return { ok: false, error: (output.Mensaje as string) || "apply_failed" };
  }
  return {
    ok: true,
    sellerId: Number(output.SellerId),
    storeSlug: output.StoreSlugOut as string | null,
    message: output.Mensaje as string,
  };
}

// ─── Dashboard ─────────────────────────────────────────

export async function getSellerDashboard(customerId: number) {
  const rows = await callSp<any>("usp_Store_Seller_Dashboard", {
    CompanyId: scope().companyId,
    CustomerId: customerId,
  });
  return rows[0] ?? null;
}

// ─── Products — seller ─────────────────────────────────

export async function submitSellerProduct(args: {
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
    "usp_Store_Seller_Product_Submit",
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

export async function listSellerProducts(args: {
  customerId: number;
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Seller_Products_List",
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

export async function adminListSellers(args: {
  status?: string | null;
  page?: number;
  limit?: number;
}) {
  const page = Math.max(args.page ?? 1, 1);
  const limit = Math.min(Math.max(args.limit ?? 20, 1), 100);
  const { rows, output } = await callSpOut<any>(
    "usp_Store_Seller_Admin_List",
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

export async function adminSetSellerStatus(args: {
  sellerId: number;
  status: "approved" | "rejected" | "suspended" | "pending";
  actor: string;
  reason?: string | null;
}) {
  const { output } = await callSpOut(
    "usp_Store_Seller_Admin_SetStatus",
    {
      CompanyId: scope().companyId,
      SellerId: args.sellerId,
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
    "usp_Store_Seller_Admin_Products_List",
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
    "usp_Store_Seller_Admin_Product_Review",
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
