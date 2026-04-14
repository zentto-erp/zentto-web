import { callSp } from "../../db/query.js";
import type { PricingPlanDTO, CatalogProduct } from "./types.js";

type PlanRow = Omit<PricingPlanDTO, "MonthlyPrice" | "AnnualPrice"> & {
  MonthlyPrice: string | number;
  AnnualPrice: string | number;
};

function normalizePlan(row: PlanRow): PricingPlanDTO {
  return {
    ...row,
    MonthlyPrice: Number(row.MonthlyPrice ?? 0),
    AnnualPrice: Number(row.AnnualPrice ?? 0),
    Features: Array.isArray(row.Features) ? row.Features : [],
    ModuleCodes: Array.isArray(row.ModuleCodes) ? row.ModuleCodes : [],
    Limits: typeof row.Limits === "object" && row.Limits !== null ? row.Limits : {},
  };
}

export async function listPlans(opts: {
  vertical?: string | null;
  product?: string | null;
  includeTrial?: boolean;
} = {}): Promise<PricingPlanDTO[]> {
  const rows = await callSp<PlanRow>("usp_cfg_catalog_list", {
    VerticalType: opts.vertical ?? null,
    ProductCode: opts.product ?? null,
    IncludeTrial: opts.includeTrial ?? true,
  });
  return rows.map(normalizePlan);
}

export async function getPlanBySlug(slug: string): Promise<PricingPlanDTO | null> {
  const rows = await callSp<PlanRow>("usp_cfg_plan_get_by_slug", { Slug: slug });
  if (!rows.length) return null;
  return normalizePlan(rows[0]);
}

export async function getPlanByPaddlePriceId(priceId: string) {
  const rows = await callSp<{
    PricingPlanId: number;
    Slug: string;
    ProductCode: string;
    VerticalType: string;
    IsAddon: boolean;
    BillingCycle: string;
    ModuleCodes: string[];
    Limits: Record<string, number>;
    MonthlyPrice: string | number;
    AnnualPrice: string | number;
  }>("usp_cfg_plan_get_by_paddle_price_id", { PaddlePriceId: priceId });
  if (!rows.length) return null;
  const r = rows[0];
  return {
    ...r,
    MonthlyPrice: Number(r.MonthlyPrice ?? 0),
    AnnualPrice: Number(r.AnnualPrice ?? 0),
    ModuleCodes: Array.isArray(r.ModuleCodes) ? r.ModuleCodes : [],
    Limits: typeof r.Limits === "object" && r.Limits !== null ? r.Limits : {},
  };
}

export async function listProducts(vertical?: string): Promise<CatalogProduct[]> {
  const plans = await listPlans({ vertical: vertical ?? null, includeTrial: true });
  const map = new Map<string, CatalogProduct>();
  for (const p of plans) {
    const existing = map.get(p.ProductCode);
    if (existing) {
      existing.Plans.push(p);
    } else {
      map.set(p.ProductCode, {
        ProductCode: p.ProductCode,
        VerticalType: p.VerticalType,
        IsAddon: p.IsAddon,
        Plans: [p],
      });
    }
  }
  return Array.from(map.values());
}

export async function checkSubdomain(slug: string): Promise<{ available: boolean; mensaje: string }> {
  const normalized = (slug || "").trim().toLowerCase();
  const rows = await callSp<{ available: boolean; mensaje: string }>(
    "usp_cfg_subdomain_check",
    { Slug: normalized }
  );
  return rows[0] ?? { available: false, mensaje: "Error" };
}
