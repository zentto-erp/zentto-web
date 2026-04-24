import { callSp, callSpOut } from "../../db/query.js";

export interface BrandConfig {
  BrandConfigId: number;
  CompanyId: number;
  LogoUrl: string;
  FaviconUrl: string;
  PrimaryColor: string;
  SecondaryColor: string;
  AccentColor: string;
  AppName: string;
  SupportEmail: string;
  SupportPhone: string;
  CustomDomain: string;
  CustomCss: string;
  FooterText: string;
  LoginBgUrl: string;
  IsActive: boolean;
  CreatedAt: string;
  UpdatedAt: string;
}

export interface BrandConfigInput {
  logoUrl?: string;
  faviconUrl?: string;
  primaryColor?: string;
  secondaryColor?: string;
  accentColor?: string;
  appName?: string;
  supportEmail?: string;
  supportPhone?: string;
  customDomain?: string;
  customCss?: string;
  footerText?: string;
  loginBgUrl?: string;
  isActive?: boolean;
}

// Simple in-memory cache (per-process). TTL 60s.
const cache = new Map<number, { data: BrandConfig | null; ts: number }>();
const CACHE_TTL = 60_000;

export async function getBrandConfig(companyId: number): Promise<BrandConfig | null> {
  const cached = cache.get(companyId);
  if (cached && Date.now() - cached.ts < CACHE_TTL) return cached.data;

  // Keys en PascalCase: callSp usa toSnakeParam() que antepone `p_`
  // automaticamente (CompanyId -> p_company_id). Pasar `p_company_id`
  // produce `p_p_company_id` y el SP falla con "function does not exist".
  const rows = await callSp("usp_cfg_brand_config_get", {
    CompanyId: companyId,
  }) as BrandConfig[];

  const row = rows[0] ?? null;
  cache.set(companyId, { data: row, ts: Date.now() });
  return row;
}

export async function upsertBrandConfig(
  companyId: number,
  input: BrandConfigInput,
): Promise<{ ok: boolean; mensaje: string }> {
  // Keys en PascalCase — ver nota en getBrandConfig.
  const rows = await callSp("usp_cfg_brand_config_upsert", {
    CompanyId: companyId,
    LogoUrl: input.logoUrl ?? "",
    FaviconUrl: input.faviconUrl ?? "",
    PrimaryColor: input.primaryColor ?? "#FFB547",
    SecondaryColor: input.secondaryColor ?? "#232f3e",
    AccentColor: input.accentColor ?? "#FFB547",
    AppName: input.appName ?? "",
    SupportEmail: input.supportEmail ?? "",
    SupportPhone: input.supportPhone ?? "",
    CustomDomain: input.customDomain ?? "",
    CustomCss: input.customCss ?? "",
    FooterText: input.footerText ?? "",
    LoginBgUrl: input.loginBgUrl ?? "",
    IsActive: input.isActive ?? true,
  }) as Array<{ ok: boolean; mensaje: string }>;

  // Invalidate cache for this company
  cache.delete(companyId);

  const result = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(result.ok), mensaje: String(result.mensaje) };
}
