export interface PricingPlanDTO {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: string;
  ProductCode: string;
  Description: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  BillingCycleDefault: "monthly" | "annual" | "both";
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  ModuleCodes: string[];
  Limits: Record<string, number>;
  IsAddon: boolean;
  IsTrialOnly: boolean;
  TrialDays: number;
  SortOrder: number;
  PaddlePriceIdMonthly: string;
  PaddlePriceIdAnnual: string;
  PaddleSyncStatus: "draft" | "syncing" | "synced" | "error" | "skip";
  IsActive: boolean;
}

export interface CatalogProduct {
  ProductCode: string;
  VerticalType: string;
  IsAddon: boolean;
  Plans: PricingPlanDTO[];
}
