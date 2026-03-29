/**
 * subdomain-tenant.ts — Resuelve el tenant a partir del subdomain del Origin/Referer
 *
 * Ejecuta ANTES de requireJwt. Inyecta req._tenantCompanyId para que
 * auth.ts use el pool correcto.
 *
 * Dominios conocidos (app.zentto.net, appdev.zentto.net, localhost) = bypass.
 * Subdomain no encontrado = 404 (NUNCA fallback a otra BD).
 */

import type { Request, Response, NextFunction } from "express";
import { getMasterPool } from "../db/pg-pool-manager.js";

// ── Cache en memoria: slug → CompanyId (TTL 5 min) ─────────────────────────
interface SlugCacheEntry {
  companyId: number;
  expiresAt: number;
}

const slugCache = new Map<string, SlugCacheEntry>();
const SLUG_TTL_MS = 5 * 60 * 1000;
const NOT_FOUND_SENTINEL = -1;

// ── Dominios que NO son tenants (bypass) ────────────────────────────────────
const KNOWN_DOMAINS = new Set([
  "zentto.net",
  "www.zentto.net",
  "app.zentto.net",
  "appdev.zentto.net",
  "dev.zentto.net",
  "app.dev.zentto.net",
  "api.zentto.net",
  "api.dev.zentto.net",
  "vault.zentto.net",
  "notify.zentto.net",
  "kibana.zentto.net",
  "kafka.zentto.net",
]);

// ── Extensiones de Request ──────────────────────────────────────────────────
declare global {
  namespace Express {
    interface Request {
      _tenantCompanyId?: number;
      _tenantSlug?: string;
      _isTenantSubdomain?: boolean;
    }
  }
}

/**
 * Extrae el hostname del header Origin o Referer.
 * Origin: "https://acme.zentto.net" → "acme.zentto.net"
 */
function extractHostname(req: Request): string | null {
  const origin = req.headers.origin;
  if (origin) {
    try {
      return new URL(origin).hostname;
    } catch { /* ignore */ }
  }

  const referer = req.headers.referer;
  if (referer) {
    try {
      return new URL(referer).hostname;
    } catch { /* ignore */ }
  }

  return null;
}

/**
 * Extrae el slug del subdomain: "acme.zentto.net" → "acme"
 * Retorna null si no es un subdomain de zentto.net o es un dominio conocido.
 */
function extractTenantSlug(hostname: string): string | null {
  if (!hostname.endsWith(".zentto.net")) return null;
  if (KNOWN_DOMAINS.has(hostname)) return null;
  if (hostname.startsWith("localhost")) return null;

  // "acme.zentto.net" → "acme"
  const slug = hostname.replace(".zentto.net", "");

  // Validar que es un slug simple (no sub-sub-dominios tipo "x.y.zentto.net")
  if (slug.includes(".")) return null;

  // Sanitizar
  if (!/^[a-z0-9][a-z0-9-]{0,29}$/.test(slug)) return null;

  return slug;
}

/**
 * Resuelve slug → CompanyId usando la BD master.
 * Usa callSp indirecto (query directa al master pool para no depender del context).
 */
async function resolveSlugToCompanyId(slug: string): Promise<number | null> {
  // Check cache
  const cached = slugCache.get(slug);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.companyId === NOT_FOUND_SENTINEL ? null : cached.companyId;
  }

  try {
    const masterPool = getMasterPool();
    const result = await masterPool.query(
      `SELECT * FROM usp_cfg_tenant_resolvesubdomain($1)`,
      [slug],
    );

    const row = result.rows[0];
    if (row && row.CompanyId && row.IsActive !== false) {
      const companyId = Number(row.CompanyId);
      slugCache.set(slug, { companyId, expiresAt: Date.now() + SLUG_TTL_MS });
      return companyId;
    }
  } catch (err) {
    console.warn("[subdomain-tenant] Error resolviendo slug:", slug, (err as Error).message);
  }

  // Cache negativo: evita queries repetidas para slugs inexistentes
  slugCache.set(slug, { companyId: NOT_FOUND_SENTINEL, expiresAt: Date.now() + SLUG_TTL_MS });
  return null;
}

/**
 * Middleware principal: extrae subdomain → resuelve tenant → inyecta en req.
 */
export async function subdomainTenantMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  // OPTIONS preflight: dejar pasar sin resolver
  if (req.method === "OPTIONS") {
    next();
    return;
  }

  // Health check y rutas internas: bypass
  if (req.path === "/health" || req.path === "/health/") {
    next();
    return;
  }

  const hostname = extractHostname(req);

  // Sin Origin/Referer (calls directos, postman, health checks): bypass
  if (!hostname) {
    next();
    return;
  }

  // Localhost: bypass (desarrollo local)
  if (hostname === "localhost" || hostname.startsWith("127.") || hostname.startsWith("192.168.")) {
    next();
    return;
  }

  // Dominio conocido (app.zentto.net, etc.): bypass, no es tenant
  if (KNOWN_DOMAINS.has(hostname)) {
    next();
    return;
  }

  // Extraer slug del subdomain
  const slug = extractTenantSlug(hostname);
  if (!slug) {
    // No es un subdomain de zentto.net válido: dejar pasar (podría ser otro dominio)
    next();
    return;
  }

  // ── Es un subdomain de tenant: resolver obligatoriamente ──
  const companyId = await resolveSlugToCompanyId(slug);

  if (!companyId) {
    // SEGURIDAD: Tenant no encontrado → 404.
    // NUNCA caer a otra base de datos.
    res.status(404).json({
      error: "tenant_not_found",
      message: `El subdominio '${slug}' no está registrado`,
    });
    return;
  }

  // Inyectar en el request para que auth.ts lo use
  req._tenantCompanyId = companyId;
  req._tenantSlug = slug;
  req._isTenantSubdomain = true;

  next();
}

/** Invalida el cache de un slug (después de provisioning o cambio) */
export function invalidateSlugCache(slug: string): void {
  slugCache.delete(slug);
}

/** Invalida todo el cache de slugs */
export function invalidateAllSlugCache(): void {
  slugCache.clear();
}
