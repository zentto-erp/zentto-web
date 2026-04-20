import type { Request } from "express";
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
 * Orden de resolución:
 *   1. Request scope (si venía un JWT válido, ya hay scope).
 *   2. Middleware de subdomain (req._tenantCompanyId) — p.ej. acme.zentto.net.
 *   3. Header `X-Tenant-Id` (entero positivo).
 *   4. Cookie `tenant_id`.
 *
 * Devuelve `null` si no puede resolverlo. Los callers deben responder 400
 * `{ error: "tenant_required" }` en ese caso; NUNCA hacer fallback a 1.
 *
 * Ver `docs/integration/ecommerce-2026-04-review.md` — bloqueador multi-tenant.
 */
export function resolveTenantFromRequest(req: Request): number | null {
  // 1. Scope activo (si el request trae JWT)
  const active = getActiveScope();
  if (active?.companyId) return active.companyId;

  // 2. Subdomain middleware
  const fromSubdomain = (req as any)._tenantCompanyId;
  if (typeof fromSubdomain === "number" && Number.isFinite(fromSubdomain) && fromSubdomain > 0) {
    return fromSubdomain;
  }

  // 3. Header X-Tenant-Id
  const rawHeader = req.headers["x-tenant-id"];
  const headerValue = Array.isArray(rawHeader) ? rawHeader[0] : rawHeader;
  if (headerValue) {
    const n = Number(String(headerValue).trim());
    if (Number.isFinite(n) && n > 0) return n;
  }

  // 4. Cookie tenant_id
  const cookieValue = (req as any).cookies?.tenant_id;
  if (cookieValue) {
    const n = Number(String(cookieValue).trim());
    if (Number.isFinite(n) && n > 0) return n;
  }

  return null;
}
