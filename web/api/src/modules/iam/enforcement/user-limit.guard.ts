/**
 * Middleware guard: validates maxUsers license limit before user creation.
 * Apply to POST /v1/usuarios and similar user-creation endpoints.
 */
import type { Request, Response, NextFunction } from "express";
import { checkUserLimit } from "../../license/license-enforcement.service.js";

export function requireUserLimit() {
  return async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await checkUserLimit();
      if (!result.allowed) {
        return res.status(403).json({
          error: "user_limit_exceeded",
          message: `Límite de usuarios alcanzado (plan ${result.plan}: ${result.current}/${result.max})`,
          current: result.current,
          max: result.max,
          plan: result.plan,
        });
      }
      next();
    } catch (err) {
      // Fail-open: if license check fails, allow the operation
      console.warn("[iam:user-limit] License check failed, allowing operation:", err);
      next();
    }
  };
}
