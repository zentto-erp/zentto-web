import type { NextFunction, Request, Response } from "express";
import { jwtVerify, type JWTPayload } from "jose";
import type { CompanyAccess, TenantScope } from "../types";
import { createJwksResolver, type JwksResolver } from "./jwks";

export interface TenantMiddlewareOptions {
  /** URL del JWKS del microservicio zentto-auth (https://auth.zentto.net/.well-known/jwks.json). */
  jwksUrl: string;
  /** Issuer esperado del JWT. */
  issuer?: string;
  /** Audience esperada del JWT. */
  audience?: string;
  /**
   * Fallback temporal a JWT firmado con HS256 (legacy). Debe eliminarse
   * cuando todos los tokens vengan del microservicio con JWKS RS256.
   */
  allowLegacyHs256?: { secret: string };
  /**
   * Paths que el middleware debe saltar (ej. `/health`, `/ws`).
   */
  publicPaths?: string[];
}

interface VerticalJwtPayload extends JWTPayload {
  sub: string;
  companyId?: number;
  branchId?: number | null;
  companyCode?: string;
  countryCode?: string;
  timeZone?: string;
  isAdmin?: boolean;
  roles?: string[];
  companyAccesses?: CompanyAccess[];
}

export interface TenantAuthenticatedRequest extends Request {
  user: VerticalJwtPayload;
  scope: TenantScope;
}

function parseCookies(header: string | undefined): Record<string, string> {
  if (!header) return {};
  return header.split(";").reduce((acc, part) => {
    const [rawKey, ...rawVal] = part.trim().split("=");
    if (rawKey && rawVal.length > 0) {
      acc[rawKey] = rawVal.join("=");
    }
    return acc;
  }, {} as Record<string, string>);
}

function extractToken(req: Request): string | undefined {
  const cookies = parseCookies(req.headers.cookie);
  const cookieToken =
    cookies["__Secure-zentto_token"] ||
    cookies["zentto_token"] ||
    cookies["zentto_access"];

  const header = req.headers.authorization;
  const bearer = header?.startsWith("Bearer ") ? header.slice(7) : undefined;

  return cookieToken ?? bearer;
}

async function verifyLegacyHs256(
  token: string,
  secret: string,
): Promise<VerticalJwtPayload> {
  const encoder = new TextEncoder();
  const { payload } = await jwtVerify(token, encoder.encode(secret));
  return payload as VerticalJwtPayload;
}

export function createTenantMiddleware(opts: TenantMiddlewareOptions) {
  const jwks: JwksResolver = createJwksResolver(opts.jwksUrl);
  const publicPaths = new Set(opts.publicPaths ?? ["/health", "/ws"]);

  return async function tenantMiddleware(
    req: Request,
    res: Response,
    next: NextFunction,
  ) {
    if (publicPaths.has(req.path)) return next();

    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: "missing_token" });
    }

    let payload: VerticalJwtPayload;
    try {
      const verifyOpts: Record<string, string> = {};
      if (opts.issuer) verifyOpts.issuer = opts.issuer;
      if (opts.audience) verifyOpts.audience = opts.audience;
      const { payload: verified } = await jwtVerify(
        token,
        jwks as never,
        verifyOpts,
      );
      payload = verified as VerticalJwtPayload;
    } catch (primaryErr) {
      if (opts.allowLegacyHs256) {
        try {
          payload = await verifyLegacyHs256(
            token,
            opts.allowLegacyHs256.secret,
          );
        } catch {
          return res.status(401).json({ error: "invalid_token" });
        }
      } else {
        return res.status(401).json({ error: "invalid_token" });
      }
    }

    const accesses = Array.isArray(payload.companyAccesses)
      ? payload.companyAccesses
      : [];

    const headerCompanyId = req.headers["x-company-id"];
    const headerBranchId = req.headers["x-branch-id"];

    let companyId: number | null = null;
    let branchId: number | null = null;

    if (headerCompanyId != null) {
      const parsed = parseInt(String(headerCompanyId), 10);
      if (!Number.isFinite(parsed) || parsed <= 0) {
        return res.status(400).json({ error: "invalid_company_id" });
      }
      const hasAccess =
        accesses.length === 0 ||
        accesses.some((a) => a.companyId === parsed);
      if (!hasAccess) {
        return res.status(403).json({ error: "company_access_denied" });
      }
      companyId = parsed;
      if (headerBranchId != null) {
        const parsedBranch = parseInt(String(headerBranchId), 10);
        branchId = Number.isFinite(parsedBranch) ? parsedBranch : null;
      }
    } else {
      // Sin header → usar default del token
      const fallback =
        accesses.find((a) => a.isDefault) ?? accesses[0] ?? null;
      if (fallback) {
        companyId = fallback.companyId;
        branchId = fallback.branchId ?? null;
      } else if (payload.companyId) {
        companyId = payload.companyId;
        branchId = payload.branchId ?? null;
      }
    }

    const activeAccess = accesses.find(
      (a) =>
        a.companyId === companyId &&
        (a.branchId ?? null) === (branchId ?? null),
    );

    const scope: TenantScope = {
      userId: String(payload.sub),
      companyId: companyId ?? 0,
      branchId,
      companyCode: activeAccess?.companyCode ?? payload.companyCode ?? null,
      countryCode: activeAccess?.countryCode ?? payload.countryCode ?? null,
      timeZone: activeAccess?.timeZone ?? payload.timeZone ?? null,
      isAdmin: payload.isAdmin === true,
      roles: Array.isArray(payload.roles) ? payload.roles : [],
    };

    (req as TenantAuthenticatedRequest).user = payload;
    (req as TenantAuthenticatedRequest).scope = scope;

    return next();
  };
}
