// CSRF defense in depth — Origin/Referer validation for state-changing requests
//
// Sprint 3 #1 del plan de seguridad auth.
//
// Defensa en profundidad por encima de SameSite=Lax. SameSite=Lax bloquea
// CSRF cross-site clásico, pero NO bloquea ataques inter-tenant entre
// subdominios del mismo registrable domain (`*.zentto.net`). Todos los
// tenants comparten cookie con `domain=.zentto.net`, así que un tenant
// hostil podría montar requests a la API con la cookie de la víctima.
//
// Esta validación rechaza POST/PUT/PATCH/DELETE cuyo `Origin` (o `Referer`
// como fallback) no esté en la allowlist. Permite server-to-server con
// Authorization: Bearer (no hay riesgo de CSRF en clientes que no usan
// cookies del browser).
import type { Request, Response, NextFunction } from "express";
import { obs } from "../modules/integrations/observability.js";

const STATE_CHANGING_METHODS = new Set(["POST", "PUT", "PATCH", "DELETE"]);

export interface CsrfOriginOptions {
  /** Set de origins explícitamente permitidos (mismo conjunto que CORS). */
  allowlist: Set<string>;
  /** Si true, permite cualquier subdominio de zentto.net (tenants dinámicos). */
  allowZenttoSubdomain: boolean;
}

function extractOrigin(req: Request): string {
  const origin = (req.headers.origin as string | undefined) || "";
  if (origin) return origin;
  const referer = (req.headers.referer as string | undefined) || "";
  if (!referer) return "";
  try {
    return new URL(referer).origin;
  } catch {
    return "";
  }
}

export function createCsrfOriginMiddleware(opts: CsrfOriginOptions) {
  const subdomainRegex = /^https:\/\/[a-z0-9-]+\.zentto\.net$/;
  return function csrfOrigin(req: Request, res: Response, next: NextFunction) {
    if (!STATE_CHANGING_METHODS.has(req.method)) return next();

    // Server-to-server / scripts con Bearer: no hay riesgo de CSRF (cookies
    // no se envían automáticamente con headers Authorization).
    const authHeader = req.headers.authorization ?? "";
    if (authHeader.startsWith("Bearer ")) return next();

    const candidate = extractOrigin(req);

    if (!candidate) {
      try {
        obs.audit("auth.csrf.missing_origin", {
          method: req.method,
          path: req.path,
          ip: req.ip,
          ua: req.headers["user-agent"],
        });
      } catch {
        /* no romper la request si obs falla */
      }
      return res.status(403).json({
        error: "csrf_missing_origin",
        message: "Origin header required for state-changing requests",
      });
    }

    if (opts.allowlist.has(candidate)) return next();
    if (opts.allowZenttoSubdomain && subdomainRegex.test(candidate)) return next();

    try {
      obs.audit("auth.csrf.invalid_origin", {
        method: req.method,
        path: req.path,
        origin: candidate,
        ip: req.ip,
        ua: req.headers["user-agent"],
      });
    } catch {
      /* no romper la request si obs falla */
    }
    return res.status(403).json({
      error: "csrf_invalid_origin",
      message: `Origin ${candidate} not allowed for state-changing requests`,
    });
  };
}
