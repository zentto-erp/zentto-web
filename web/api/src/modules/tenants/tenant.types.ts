export interface TenantProvisionInput {
  companyCode: string;
  legalName: string;
  ownerEmail: string;
  countryCode: string;
  baseCurrency: string;
  adminUserCode: string;
  adminPassword: string;   // password en claro — service hace bcrypt
  plan: "FREE" | "STARTER" | "PRO" | "ENTERPRISE";
  paddleSubscriptionId?: string;
}

export interface TenantProvisionResult {
  ok: boolean;
  mensaje: string;
  companyId: number;
  userId: number;
}

export interface TenantInfo {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  OwnerEmail: string | null;
  Plan: string;
  TenantStatus: string;
  BaseCurrency: string;
  FiscalCountryCode: string;
  ProvisionedAt: string | null;
  PaddleSubscriptionId: string | null;
  IsActive: boolean;
  BranchCount: number;
  UserCount: number;
}
