import type { Request } from "express";
import { env } from "../../config/env.js";
import { getRequestScope } from "../../context/request-context.js";

export type ActiveScope = {
  companyId: number;
  branchId: number;
  countryCode?: string;
  timeZone?: string;
  companyCode?: string;
  companyName?: string;
  branchCode?: string;
  branchName?: string;
};

export function getActiveScope(): ActiveScope | null {
  const scope = getRequestScope();
  if (!scope) return null;

  const companyId = Number(scope.companyId);
  const branchId = Number(scope.branchId);
  if (!Number.isFinite(companyId) || companyId <= 0) return null;
  if (!Number.isFinite(branchId) || branchId <= 0) return null;

  return {
    companyId,
    branchId,
    countryCode: scope.countryCode,
    companyCode: scope.companyCode,
    companyName: scope.companyName,
    branchCode: scope.branchCode,
    branchName: scope.branchName,
    timeZone: scope.timeZone,
  };
}

/**
 * Resuelve el CompanyId del tenant para endpoints **públicos** (sin JWT).
 *
 * Orden:
 *   1. Request scope (JWT activo).
 *   2. Subdomain middleware (req._tenantCompanyId).
 *   3. Header `X-Tenant-Id`.
 *   4. Cookie `tenant_id`.
 *   5. Env fallback `STORE_DEFAULT_COMPANY_ID` (solo si declarada explícitamente).
 *
 * Null si no se puede resolver. Callers responden 400 `tenant_required`.
 * Ver `docs/deploy/env-vars-ola2.md`.
 */
export function resolveTenantFromRequest(req: Request): number | null {
  const active = getActiveScope();
  if (active?.companyId) return active.companyId;

  const fromSubdomain = (req as any)._tenantCompanyId;
  if (typeof fromSubdomain === "number" && Number.isFinite(fromSubdomain) && fromSubdomain > 0) {
    return fromSubdomain;
  }

  const rawHeader = req.headers["x-tenant-id"];
  const headerValue = Array.isArray(rawHeader) ? rawHeader[0] : rawHeader;
  if (headerValue) {
    const n = Number(String(headerValue).trim());
    if (Number.isFinite(n) && n > 0) return n;
  }

  const cookieValue = (req as any).cookies?.tenant_id;
  if (cookieValue) {
    const n = Number(String(cookieValue).trim());
    if (Number.isFinite(n) && n > 0) return n;
  }

  if (typeof env.storeDefaultCompanyId === "number" && env.storeDefaultCompanyId > 0) {
    return env.storeDefaultCompanyId;
  }

  return null;
}
