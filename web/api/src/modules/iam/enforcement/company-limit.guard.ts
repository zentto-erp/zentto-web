/**
 * Middleware guard: validates maxCompanies license limit before company creation.
 * Also usable as a direct function call from tenant provisioning.
 */
import type { Request, Response, NextFunction } from "express";
import { checkCompanyLimit } from "../../license/license-enforcement.service.js";

/**
 * Express middleware version — apply to company/branch creation routes.
 */
export function requireCompanyLimit() {
  return async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await checkCompanyLimit();
      if (!result.allowed) {
        return res.status(403).json({
          error: "company_limit_exceeded",
          message: `Límite de empresas alcanzado (plan ${result.plan}: ${result.current}/${result.max})`,
          current: result.current,
          max: result.max,
          multiCompanyEnabled: result.multiCompanyEnabled,
          plan: result.plan,
        });
      }
      if (!result.multiCompanyEnabled && result.current >= 1) {
        return res.status(403).json({
          error: "multi_company_disabled",
          message: `El plan ${result.plan} no permite múltiples empresas. Actualice su plan.`,
          plan: result.plan,
        });
      }
      next();
    } catch (err) {
      console.warn("[iam:company-limit] License check failed, allowing operation:", err);
      next();
    }
  };
}

/**
 * Direct function call — for use inside provisionTenant() and similar.
 * Returns { allowed, reason } instead of sending HTTP response.
 */
export async function validateCompanyLimit(companyId?: number): Promise<{ allowed: boolean; reason?: string }> {
  try {
    const result = await checkCompanyLimit(companyId);
    if (!result.allowed) {
      return {
        allowed: false,
        reason: `Límite de empresas alcanzado (plan ${result.plan}: ${result.current}/${result.max})`,
      };
    }
    if (!result.multiCompanyEnabled && result.current >= 1) {
      return {
        allowed: false,
        reason: `El plan ${result.plan} no permite múltiples empresas`,
      };
    }
    return { allowed: true };
  } catch {
    return { allowed: true }; // Fail-open
  }
}
