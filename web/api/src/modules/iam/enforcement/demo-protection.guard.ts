/**
 * Middleware guard: prevents deletion/deactivation of the DEMO company.
 * CompanyId <= 1 is reserved for the system default / demo company.
 */
import type { Request, Response, NextFunction } from "express";

const DEMO_COMPANY_MAX_ID = 1;

export function requireDemoProtection() {
  return (req: Request, res: Response, next: NextFunction) => {
    const companyId =
      Number(req.params.companyId) ||
      Number(req.params.id) ||
      Number((req as any).scope?.companyId) ||
      0;

    if (companyId > 0 && companyId <= DEMO_COMPANY_MAX_ID) {
      return res.status(403).json({
        error: "demo_protected",
        message: "La empresa demo no puede ser eliminada ni desactivada",
      });
    }
    next();
  };
}
