import type { Request, Response, NextFunction } from "express";
import { verifyJwt, type JwtPayload, type CompanyAccessClaim } from "../auth/jwt.js";
import { runWithRequestContext, type RequestScope } from "../context/request-context.js";
import { env } from "../config/env.js";
import { obs } from "../modules/integrations/observability.js";

const PUBLIC_PATHS = new Set([
  "/auth/login",
  "/auth/login-options",
  "/auth/register",
  "/auth/verify-email",
  "/auth/resend-verification",
  "/auth/forgot-password",
  "/auth/reset-password/confirm",
]);

export interface AuthenticatedRequest extends Request {
  user?: JwtPayload;
  scope?: RequestScope;
}

function parseIntHeader(value: string | string[] | undefined): number | null {
  const first = Array.isArray(value) ? value[0] : value;
  if (!first) return null;
  const parsed = Number(first);
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  return Math.trunc(parsed);
}

/**
 * Lookup exacto de una cookie por nombre. Evita matches accidentales por
 * substring (importante: `zentto_token` es prefijo de `__Secure-zentto_token`).
 */
function getCookieValue(cookieHeader: string | undefined, name: string): string | undefined {
  if (!cookieHeader) return undefined;
  const parts = cookieHeader.split(";");
  for (const part of parts) {
    const trimmed = part.trim();
    const eq = trimmed.indexOf("=");
    if (eq < 0) continue;
    if (trimmed.slice(0, eq) === name) {
      return decodeURIComponent(trimmed.slice(eq + 1));
    }
  }
  return undefined;
}

function toScope(access: CompanyAccessClaim): RequestScope {
  return {
    companyId: Number(access.companyId),
    branchId: Number(access.branchId),
    companyCode: access.companyCode,
    companyName: access.companyName,
    branchCode: access.branchCode,
    branchName: access.branchName,
    countryCode: access.countryCode,
    timeZone: access.timeZone,
  };
}

function resolveScope(payload: JwtPayload, req: Request): RequestScope | null {
  const accesses = (payload.companyAccesses ?? []).map((row) => toScope(row));
  const requestedCompanyId = parseIntHeader(req.headers["x-company-id"] as string | string[] | undefined);
  const requestedBranchId = parseIntHeader(req.headers["x-branch-id"] as string | string[] | undefined);

  // V1 backward compat: tokens viejos con companyId embebido — remover tras migración
  const defaultScopeFromToken = (
    payload.companyId && payload.branchId
      ? {
          companyId: Number(payload.companyId),
          branchId: Number(payload.branchId),
          companyCode: payload.companyCode,
          companyName: payload.companyName,
          branchCode: payload.branchCode,
          branchName: payload.branchName,
          countryCode: payload.countryCode,
          timeZone: payload.timeZone,
        }
      : null
  );

  const defaultScope =
    defaultScopeFromToken ??
    accesses.find((row, idx) => {
      const raw = payload.companyAccesses?.[idx];
      return raw?.isDefault === true;
    }) ??
    accesses[0] ??
    null;

  if (!requestedCompanyId && !requestedBranchId) {
    return defaultScope;
  }

  if (accesses.length === 0) {
    if (!defaultScope) return null;
    if (
      (requestedCompanyId && requestedCompanyId !== defaultScope.companyId) ||
      (requestedBranchId && requestedBranchId !== defaultScope.branchId)
    ) {
      return null;
    }
    return defaultScope;
  }

  let match: RequestScope | undefined;
  if (requestedCompanyId && requestedBranchId) {
    match = accesses.find(
      (row) => row.companyId === requestedCompanyId && row.branchId === requestedBranchId
    );
  } else if (requestedCompanyId) {
    const byCompany = accesses.filter((row) => row.companyId === requestedCompanyId);
    match = byCompany[0];
  } else if (requestedBranchId) {
    match = accesses.find((row) => row.branchId === requestedBranchId);
  }

  return match ?? null;
}

export async function requireJwt(req: Request, res: Response, next: NextFunction) {
  if (req.method === "OPTIONS") {
    return next();
  }

  if (PUBLIC_PATHS.has(req.path)) {
    return next();
  }

  // Extraer JWT — prioridad:
  //   1. Cookie __Secure-zentto_token (HttpOnly + Secure prefix, escritura nueva)
  //   2. Cookie zentto_token (HttpOnly, seteada por este API en /auth/login — legacy en transición)
  //   3. Cookie zentto_access (HttpOnly, seteada por zentto-auth microservice — legacy)
  //   4. Authorization: Bearer header (legacy — será deprecado)
  const cookieHeader = req.headers.cookie;
  let token: string | undefined =
    getCookieValue(cookieHeader, "__Secure-zentto_token") ??
    getCookieValue(cookieHeader, "zentto_token") ??
    getCookieValue(cookieHeader, "zentto_access");

  // Fallback: Bearer header (legacy — para transición)
  if (!token) {
    const auth = req.headers.authorization ?? "";
    const [scheme, bearerToken] = auth.split(" ");
    if (scheme === "Bearer" && bearerToken) {
      token = bearerToken;
    }
  }

  if (!token) {
    return res.status(401).json({ error: "missing_token" });
  }

  try {
    const payload = verifyJwt(token!);
    const scope = resolveScope(payload, req);

    // /auth/profile puede funcionar sin scope (JWT de zentto-auth sin companyAccesses)
    const isProfileEndpoint = req.path === "/auth/profile" || req.path === "/auth/companies";
    if (!scope?.companyId || !scope?.branchId) {
      if (!isProfileEndpoint) {
        return res.status(403).json({ error: "invalid_scope", message: "No hay empresa/sucursal activa para este usuario" });
      }
    }

    // Profile/companies endpoints: funcionar sin scope (JWT de zentto-auth sin companies)
    if (!scope) {
      (req as AuthenticatedRequest).user = payload;
      (req as AuthenticatedRequest).scope = undefined;
      return next();
    }

    // ── Resolver BD del tenant (solo PostgreSQL) ──
    let tenantPool;
    if ((env.dbType ?? "postgres") === "postgres") {
      try {
        const { resolveTenantDb } = await import("../db/tenant-resolver.js");
        const { getTenantPool, getMasterPool } = await import("../db/pg-pool-manager.js");

        const subdomainCompanyId = (req as any)._tenantCompanyId as number | undefined;
        if (subdomainCompanyId) {
          const accesses = (payload.companyAccesses ?? []);
          const hasAccess = accesses.some((a) => Number(a.companyId) === subdomainCompanyId);
          if (!hasAccess) {
            // Sprint 0 #5 — auditar intento de cross-tenant. Es señal fuerte
            // de token robado o de un usuario malicioso probando subdominios.
            try {
              obs.audit("auth.tenant_mismatch", {
                userId: payload.sub,
                tenantCompanyId: subdomainCompanyId,
                allowedCompanies: accesses.map((a) => Number(a.companyId)),
                ip: req.ip,
                ua: req.headers["user-agent"],
                path: req.path,
              });
            } catch {
              /* obs no debe romper la auth */
            }
            return res.status(403).json({ error: "tenant_mismatch", message: "Tu cuenta no tiene acceso a este tenant" });
          }
          const tenantAccess = accesses.find((a) => Number(a.companyId) === subdomainCompanyId);
          if (tenantAccess) {
            const tenantScope = toScope(tenantAccess);
            scope.companyId = tenantScope.companyId;
            scope.branchId = tenantScope.branchId;
            scope.companyCode = tenantScope.companyCode;
            scope.companyName = tenantScope.companyName;
            scope.branchCode = tenantScope.branchCode;
            scope.branchName = tenantScope.branchName;
            scope.countryCode = tenantScope.countryCode;
            scope.timeZone = tenantScope.timeZone;
          }
        }

        const dbMode = req.headers["x-db-mode"] as string | undefined;
        const isTenantSubdomain = !!(req as any)._isTenantSubdomain;

        if (dbMode === "demo" && !isTenantSubdomain) {
          tenantPool = getMasterPool();
          scope.dbName = process.env.PG_DATABASE || "zentto_prod";
          scope.isDemo = true;
        } else {
          const tenantDb = await resolveTenantDb(scope.companyId, isTenantSubdomain);
          tenantPool = getTenantPool(tenantDb);
          scope.dbName = tenantDb.dbName;
          scope.isDemo = tenantDb.isDemo ?? false;
        }
      } catch (err) {
        const isTenantSubdomain = !!(req as any)._isTenantSubdomain;
        if (isTenantSubdomain) {
          console.error("[auth] Tenant resolver failed for subdomain:", (err as Error).message);
          return res.status(503).json({ error: "tenant_unavailable", message: "Base de datos del tenant no disponible" });
        }
        console.warn("[auth] Tenant resolver not available, using default pool:", (err as Error).message);
      }
    }

    const scopedUser: JwtPayload = {
      ...payload,
      companyId: scope.companyId,
      branchId: scope.branchId,
      companyCode: scope.companyCode,
      companyName: scope.companyName,
      branchCode: scope.branchCode,
      branchName: scope.branchName,
      countryCode: scope.countryCode,
      timeZone: scope.timeZone,
    };

    (req as AuthenticatedRequest).user = scopedUser;
    (req as AuthenticatedRequest).scope = scope;

    return runWithRequestContext({ user: scopedUser, scope, tenantPool }, () => next());
  } catch (err) {
    // Sprint 0 #5 — auditar fallos de validación de token (firma inválida,
    // expirado, claims malformados). Útil para detectar ataques de forgery.
    try {
      obs.audit("auth.token_invalid", {
        reason: (err as Error)?.message,
        ip: req.ip,
        ua: req.headers["user-agent"],
        path: req.path,
      });
    } catch {
      /* obs no debe romper la auth */
    }
    return res.status(401).json({ error: "invalid_token" });
  }
}

export const requireAuth = requireJwt;

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.isAdmin) {
    return res.status(403).json({ error: "forbidden", message: "Requiere permisos de administrador" });
  }
  return next();
}

export function requireModule(modulo: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as AuthenticatedRequest).user;
    if (!user) {
      return res.status(401).json({ error: "not_authenticated" });
    }
    if (user.isAdmin) return next();
    if (user.modulos && user.modulos.includes(modulo)) {
      return next();
    }
    return res.status(403).json({
      error: "forbidden",
      message: `No tienes acceso al módulo: ${modulo}`,
    });
  };
}

export function requireCreate(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canCreate) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para crear registros" });
}

export function requireUpdate(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canUpdate) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para actualizar registros" });
}

export function requireDelete(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canDelete) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para eliminar registros" });
}
