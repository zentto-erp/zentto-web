/**
 * tenant-resolver.ts — Resuelve CompanyId → config de BD del tenant
 *
 * Cache en memoria con TTL de 5 minutos. Consulta sys.TenantDatabase
 * en la BD master (demo). Si el CompanyId no tiene registro, retorna
 * la BD demo como fallback (retrocompatibilidad total).
 */

import { getMasterPool, type TenantDbConfig } from "./pg-pool-manager.js";

interface CacheEntry {
  config: TenantDbConfig;
  expiresAt: number;
}

const cache = new Map<number, CacheEntry>();
const TTL_MS = 5 * 60 * 1000; // 5 minutos

/**
 * Resuelve la config de BD para un CompanyId.
 *
 * @param companyId - ID de la empresa
 * @param strictMode - Si true (subdomains de tenant), NUNCA cae a BD demo.
 *                     Si false (dominios conocidos), fallback a BD demo si no hay tenant.
 */
export async function resolveTenantDb(
  companyId: number,
  strictMode: boolean = false,
): Promise<TenantDbConfig> {
  // Check cache
  const cached = cache.get(companyId);
  if (cached && cached.expiresAt > Date.now()) return cached.config;

  try {
    const masterPool = getMasterPool();
    const result = await masterPool.query(
      `SELECT * FROM usp_sys_tenantdb_resolve($1)`,
      [companyId],
    );

    if (result.rows.length > 0) {
      const row = result.rows[0];
      const config: TenantDbConfig = {
        dbName: row.DbName,
        host: row.DbHost || null,
        port: row.DbPort || null,
        user: row.DbUser || null,
        password: row.DbPassword || null,
        poolMin: row.PoolMin ?? 0,
        poolMax: row.PoolMax ?? 5,
        isDemo: row.IsDemo ?? true,
      };
      cache.set(companyId, { config, expiresAt: Date.now() + TTL_MS });
      return config;
    }
  } catch (err) {
    if (strictMode) {
      // SEGURIDAD: en modo estricto (subdomain de tenant), NO silenciar errores
      throw new Error(`Tenant DB not found for companyId ${companyId}: ${(err as Error).message}`);
    }
    // Si la tabla sys.TenantDatabase no existe aún (pre-migración),
    // fallback silencioso a master solo para dominios conocidos
  }

  // strictMode: NUNCA caer a BD demo
  if (strictMode) {
    throw new Error(`No tenant database registered for companyId ${companyId}`);
  }

  // Fallback: BD master (demo) — solo para dominios conocidos (app.zentto.net)
  const masterPool = getMasterPool();
  const fallback: TenantDbConfig = {
    dbName: (masterPool as any).options?.database || process.env.PG_DATABASE || "zentto_prod",
    isDemo: true,
  };
  cache.set(companyId, { config: fallback, expiresAt: Date.now() + TTL_MS });
  return fallback;
}

/** Invalida el cache para un CompanyId (después de provisioning) */
export function invalidateTenantCache(companyId: number): void {
  cache.delete(companyId);
}

/** Invalida todo el cache (deploy, etc.) */
export function invalidateAllTenantCache(): void {
  cache.clear();
}
