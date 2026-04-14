/**
 * catalog/admin.service.ts — CRUD de planes + sync con Paddle desde backoffice.
 */
import { callSp } from "../../db/query.js";
import { paddleApi } from "../billing/paddle.client.js";

export interface PlanUpsertInput {
  slug: string;
  name: string;
  verticalType: string;
  productCode: string;
  description: string;
  monthlyPrice: number;
  annualPrice: number;
  billingCycleDefault?: "monthly" | "annual" | "both";
  maxUsers: number;
  maxTransactions: number;
  features: string[];
  moduleCodes: string[];
  limits: Record<string, number | boolean>;
  isAddon: boolean;
  isTrialOnly: boolean;
  trialDays: number;
  sortOrder: number;
  isActive: boolean;
}

export async function upsertPlan(input: PlanUpsertInput) {
  const rows = await callSp<{
    ok: boolean;
    mensaje: string;
    PricingPlanId: number;
    RequiresPaddleSync: boolean;
  }>("usp_cfg_plan_upsert", {
    Slug: input.slug,
    Name: input.name,
    VerticalType: input.verticalType,
    ProductCode: input.productCode,
    Description: input.description,
    MonthlyPrice: input.monthlyPrice,
    AnnualPrice: input.annualPrice,
    BillingCycleDefault: input.billingCycleDefault ?? "monthly",
    MaxUsers: input.maxUsers,
    MaxTransactions: input.maxTransactions,
    Features: JSON.stringify(input.features),
    ModuleCodes: JSON.stringify(input.moduleCodes),
    Limits: JSON.stringify(input.limits),
    IsAddon: input.isAddon,
    IsTrialOnly: input.isTrialOnly,
    TrialDays: input.trialDays,
    SortOrder: input.sortOrder,
    IsActive: input.isActive,
  });
  return rows[0];
}

export async function listPendingSync() {
  return await callSp<{
    PricingPlanId: number;
    Slug: string;
    Name: string;
    ProductCode: string;
    MonthlyPrice: string | number;
    AnnualPrice: string | number;
    PaddleProductId: string;
    PaddlePriceIdMonthly: string;
    PaddlePriceIdAnnual: string;
    PaddleSyncStatus: string;
  }>("usp_cfg_plan_list_pending_sync");
}

/**
 * Sincroniza un plan específico con Paddle:
 *   1. Si no tiene Product → crea Product
 *   2. Si no tiene Price mensual → crea Price
 *   3. Si no tiene Price anual y AnnualPrice > 0 → crea Price
 *   4. Si precio cambió → archiva el viejo y crea nuevo (Paddle no permite update)
 */
export async function syncPlanToPaddle(planId: number): Promise<{ ok: boolean; mensaje: string; details?: any }> {
  const pending = await listPendingSync();
  const plan = pending.find((p) => p.PricingPlanId === planId);
  if (!plan) {
    return { ok: false, mensaje: "plan_not_in_pending_sync" };
  }

  try {
    await callSp("usp_cfg_plan_set_paddle_ids", {
      PlanId: planId,
      PaddleProductId: plan.PaddleProductId || null,
      PaddlePriceMonthly: plan.PaddlePriceIdMonthly || null,
      PaddlePriceAnnual: plan.PaddlePriceIdAnnual || null,
      SyncStatus: "syncing",
      SyncError: "",
    });

    let productId = plan.PaddleProductId;
    if (!productId) {
      const product = await paddleApi.post<{ id: string }>("/products", {
        name: plan.Name,
        description: plan.ProductCode,
        type: "standard",
        tax_category: "saas",
        custom_data: { slug: plan.Slug, product_code: plan.ProductCode },
      });
      productId = product.id;
    }

    // Monthly price
    const monthlyPrice = Number(plan.MonthlyPrice);
    let priceMonthlyId = plan.PaddlePriceIdMonthly;
    if (monthlyPrice > 0 && !priceMonthlyId) {
      const priceM = await paddleApi.post<{ id: string }>("/prices", {
        product_id: productId,
        name: `${plan.Name} (mensual)`,
        description: `${plan.Name} mensual`,
        unit_price: { amount: Math.round(monthlyPrice * 100).toString(), currency_code: "USD" },
        billing_cycle: { interval: "month", frequency: 1 },
        custom_data: { slug: plan.Slug, cycle: "monthly" },
      });
      priceMonthlyId = priceM.id;
    }

    // Annual price (opcional)
    const annualPrice = Number(plan.AnnualPrice);
    let priceAnnualId = plan.PaddlePriceIdAnnual;
    if (annualPrice > 0 && !priceAnnualId) {
      const priceA = await paddleApi.post<{ id: string }>("/prices", {
        product_id: productId,
        name: `${plan.Name} (anual)`,
        description: `${plan.Name} anual`,
        unit_price: { amount: Math.round(annualPrice * 100).toString(), currency_code: "USD" },
        billing_cycle: { interval: "year", frequency: 1 },
        custom_data: { slug: plan.Slug, cycle: "annual" },
      });
      priceAnnualId = priceA.id;
    }

    await callSp("usp_cfg_plan_set_paddle_ids", {
      PlanId: planId,
      PaddleProductId: productId,
      PaddlePriceMonthly: priceMonthlyId,
      PaddlePriceAnnual: priceAnnualId,
      SyncStatus: "synced",
      SyncError: "",
    });

    return { ok: true, mensaje: "synced", details: { productId, priceMonthlyId, priceAnnualId } };
  } catch (err: any) {
    await callSp("usp_cfg_plan_set_paddle_ids", {
      PlanId: planId,
      PaddleProductId: null,
      PaddlePriceMonthly: null,
      PaddlePriceAnnual: null,
      SyncStatus: "error",
      SyncError: err.message ?? String(err),
    });
    return { ok: false, mensaje: err.message ?? "sync_failed" };
  }
}

export async function syncAllPendingToPaddle(): Promise<{ total: number; ok: number; failed: number; errors: string[] }> {
  const pending = await listPendingSync();
  let okCount = 0;
  let failedCount = 0;
  const errors: string[] = [];
  for (const p of pending) {
    const result = await syncPlanToPaddle(p.PricingPlanId);
    if (result.ok) okCount++;
    else {
      failedCount++;
      errors.push(`${p.Slug}: ${result.mensaje}`);
    }
  }
  return { total: pending.length, ok: okCount, failed: failedCount, errors };
}
