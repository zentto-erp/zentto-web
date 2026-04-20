import type { NextFunction, Request, Response } from "express";
import type { TenantScope } from "../types";

/**
 * Middleware que rechaza con 403 cuando no hay `companyId` en el scope.
 * Debe ir DESPUÉS de `createTenantMiddleware`.
 */
export function requireCompany(req: Request, res: Response, next: NextFunction) {
  const scope = (req as Request & { scope?: TenantScope }).scope;
  if (!scope || !scope.companyId || scope.companyId <= 0) {
    return res.status(403).json({ error: "company_required" });
  }
  return next();
}
