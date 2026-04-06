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

  const rows = await callSp("usp_cfg_brand_config_get", {
    p_company_id: companyId,
  }) as BrandConfig[];

  const row = rows[0] ?? null;
  cache.set(companyId, { data: row, ts: Date.now() });
  return row;
}

export async function upsertBrandConfig(
  companyId: number,
  input: BrandConfigInput,
): Promise<{ ok: boolean; mensaje: string }> {
  const rows = await callSp("usp_cfg_brand_config_upsert", {
    p_company_id: companyId,
    p_logo_url: input.logoUrl ?? "",
    p_favicon_url: input.faviconUrl ?? "",
    p_primary_color: input.primaryColor ?? "#FFB547",
    p_secondary_color: input.secondaryColor ?? "#232f3e",
    p_accent_color: input.accentColor ?? "#FFB547",
    p_app_name: input.appName ?? "",
    p_support_email: input.supportEmail ?? "",
    p_support_phone: input.supportPhone ?? "",
    p_custom_domain: input.customDomain ?? "",
    p_custom_css: input.customCss ?? "",
    p_footer_text: input.footerText ?? "",
    p_login_bg_url: input.loginBgUrl ?? "",
    p_is_active: input.isActive ?? true,
  }) as Array<{ ok: boolean; mensaje: string }>;

  // Invalidate cache for this company
  cache.delete(companyId);

  const result = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(result.ok), mensaje: String(result.mensaje) };
}
