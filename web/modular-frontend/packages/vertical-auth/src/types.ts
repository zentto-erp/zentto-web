/**
 * Shared multi-tenant auth types for Zentto vertical apps.
 *
 * Las apps verticales (hotel, medical, education, tickets) son standalone —
 * cada una con su propio Next.js + Express API. Este paquete centraliza el
 * contrato de sesión y scope para que todas usen los mismos headers y claims.
 */

export interface CompanyAccess {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number | null;
  branchCode: string | null;
  branchName: string | null;
  countryCode: string;
  timeZone: string;
  isDefault: boolean;
}

export interface ActiveCompany {
  companyId: number;
  branchId: number | null;
  companyCode?: string;
  branchCode?: string;
  countryCode?: string;
  timeZone?: string;
}

export interface TenantScope {
  userId: string;
  companyId: number;
  branchId: number | null;
  companyCode: string | null;
  countryCode: string | null;
  timeZone: string | null;
  isAdmin: boolean;
  roles: string[];
}

export interface VerticalSessionUser {
  id: string;
  name?: string | null;
  email?: string | null;
  role?: string;
}

export interface VerticalSession {
  user: VerticalSessionUser;
  companyAccesses: CompanyAccess[];
  activeCompany: ActiveCompany | null;
  accessToken?: string;
}
