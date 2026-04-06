import { callSp } from "../../db/query.js";

export interface Partner {
  PartnerId: number;
  CompanyName: string;
  ContactName: string;
  Email: string;
  Phone: string;
  Status: string;
  CommissionPercent: number;
  TotalReferrals: number;
  TotalRevenue: number;
  ApiKey: string;
  CompanyId: number;
  CreatedAt: string;
}

export interface PartnerReferral {
  PartnerReferralId: number;
  PartnerId: number;
  ReferredCompanyId: number;
  Status: string;
  CommissionAmount: number;
  PaidAt: string | null;
  CreatedAt: string;
}

export interface PartnerDashboard {
  TotalReferrals: number;
  ConvertedReferrals: number;
  PendingReferrals: number;
  TotalCommission: number;
  PaidCommission: number;
  PendingCommission: number;
}

export async function applyPartner(input: {
  companyName: string;
  contactName: string;
  email: string;
  phone?: string;
}): Promise<{ ok: boolean; mensaje: string }> {
  const rows = await callSp("usp_cfg_partner_apply", {
    p_company_name: input.companyName,
    p_contact_name: input.contactName,
    p_email: input.email,
    p_phone: input.phone ?? "",
  }) as Array<{ ok: boolean; mensaje: string }>;
  const result = rows[0] ?? { ok: false, mensaje: "no_result" };
  return { ok: Boolean(result.ok), mensaje: String(result.mensaje) };
}

export async function getPartnerByEmail(email: string): Promise<Partner | null> {
  const rows = await callSp("usp_cfg_partner_get_by_email", {
    p_email: email,
  }) as Partner[];
  return rows[0] ?? null;
}

export async function listPartnerReferrals(partnerId: number): Promise<PartnerReferral[]> {
  const rows = await callSp("usp_cfg_partner_referrals_list", {
    p_partner_id: partnerId,
  }) as PartnerReferral[];
  return rows;
}

export async function getPartnerDashboard(partnerId: number): Promise<PartnerDashboard> {
  const rows = await callSp("usp_cfg_partner_dashboard", {
    p_partner_id: partnerId,
  }) as PartnerDashboard[];
  return rows[0] ?? {
    TotalReferrals: 0,
    ConvertedReferrals: 0,
    PendingReferrals: 0,
    TotalCommission: 0,
    PaidCommission: 0,
    PendingCommission: 0,
  };
}
