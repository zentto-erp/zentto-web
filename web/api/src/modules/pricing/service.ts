import { callSp } from "../../db/query.js";

export interface PricingPlan {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  TransactionFeePercent: number;
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  IsActive: boolean;
  CompanyId: number;
  CreatedAt: string;
}

export async function listPricingPlans(verticalType?: string): Promise<PricingPlan[]> {
  const rows = await callSp("usp_cfg_pricing_plan_list", {
    p_vertical_type: verticalType || null,
  }) as PricingPlan[];
  return rows;
}

export async function getPricingPlan(slug: string): Promise<PricingPlan | null> {
  const rows = await callSp("usp_cfg_pricing_plan_get", {
    p_slug: slug,
  }) as PricingPlan[];
  return rows[0] ?? null;
}
