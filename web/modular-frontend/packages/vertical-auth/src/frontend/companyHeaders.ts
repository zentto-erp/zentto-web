import type { ActiveCompany } from "../types";

/**
 * Retorna los headers multi-tenant que toda request al backend vertical debe
 * enviar. El middleware `createTenantMiddleware` los lee en el otro extremo.
 */
export function companyHeaders(
  active: ActiveCompany | null | undefined,
): Record<string, string> {
  if (!active) return {};
  const headers: Record<string, string> = {
    "x-company-id": String(active.companyId),
  };
  if (active.branchId != null) {
    headers["x-branch-id"] = String(active.branchId);
  }
  if (active.timeZone) {
    headers["x-timezone"] = active.timeZone;
  }
  if (active.countryCode) {
    headers["x-country-code"] = active.countryCode;
  }
  return headers;
}
