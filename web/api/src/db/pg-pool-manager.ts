/**
 * Pool manager dinÃ¡mico para PostgreSQL â€” multi-tenant
 *
 * Reemplaza el singleton de pg.ts con un cache de pools por base de datos.
 * getMasterPool() devuelve el pool de la BD configurada en .env (PG_DATABASE).
 */
import { Pool } from "pg";
import { env } from "../config/env.js";

export interface TenantDbConfig {
  dbName: string;
  host?: string | null;
  port?: number | null;
  user?: string | null;
  password?: string | null;
  poolMin?: number;
  poolMax?: number;
  ssl?: boolean;
  isDemo?: boolean;
}

/** Cache: dbName â†’ Pool */
const pools = new Map<string, Pool>();

/**
 * Obtiene (o crea) el pool de un tenant especÃ­fico.
 */
export function getTenantPool(config: TenantDbConfig): Pool {
  const key = config.dbName;
  const existing = pools.get(key);
  if (existing) return existing;

  const pool = new Pool({
    host: config.host || env.pg.host,
    port: config.port || env.pg.port,
    database: config.dbName,
    user: config.user || env.pg.user,
    password: config.password || env.pg.password,
    min: config.poolMin ?? 0,
    max: config.poolMax ?? 5,
    // Security: rejectUnauthorized=false is intentional for internal Docker network
    // connections (172.18.0.x) where certs are self-signed.
    ssl: (config.ssl ?? env.pg.ssl) ? { rejectUnauthorized: false } : false, // nosemgrep: bypass-tls-verification
    idleTimeoutMillis: 60_000,
    connectionTimeoutMillis: 10_000,
  });

  pool.on("error", (err) => {
    console.error(`[PG Pool:${key}] Error:`, err.message);
  });

  pools.set(key, pool);
  return pool;
}

/**
 * Pool de la BD master â€” para login, health, tenant resolve.
 * Usa la config PG existente del .env (PG_DATABASE).
 */
export function getMasterPool(): Pool {
  const dbName = env.pg.database;
  return getTenantPool({
    dbName,
    host: env.pg.host,
    port: env.pg.port,
    user: env.pg.user,
    password: env.pg.password,
    poolMin: env.pg.poolMin,
    poolMax: env.pg.poolMax,
    ssl: env.pg.ssl,
  });
}

/** Cerrar pool de un tenant especÃ­fico */
export async function closeTenantPool(dbName: string): Promise<void> {
  const pool = pools.get(dbName);
  if (pool) {
    await pool.end();
    pools.delete(dbName);
  }
}

/** Cerrar todos los pools (shutdown) */
export async function closeAllPools(): Promise<void> {
  const promises: Promise<void>[] = [];
  pools.forEach((pool) => {
    promises.push(pool.end().catch(() => {}));
  });
  await Promise.all(promises);
  pools.clear();
}

/** EstadÃ­sticas de pools activos */
export function getPoolStats(): {
  dbName: string;
  total: number;
  idle: number;
  waiting: number;
}[] {
  return Array.from(pools.entries()).map(([dbName, pool]) => ({
    dbName,
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount,
  }));
}

/**
 * ALERT-4: monitor periÃ³dico de pool.waitingCount. Solo loguea si alguno de
 * los pools tiene requests en cola (ruido bajo en operaciÃ³n normal; alerta
 * visible en pico de carga).
 *
 * Idempotente: llamadas mÃºltiples reemplazan el timer previo.
 */
let poolStatsTimer: NodeJS.Timeout | null = null;
export function startPoolStatsMonitor(intervalSec: number): void {
  if (poolStatsTimer) {
    clearInterval(poolStatsTimer);
    poolStatsTimer = null;
  }
  if (!intervalSec || intervalSec <= 0) return;

  const intervalMs = intervalSec * 1000;
  const maxPool = env.pg.poolMax;
  console.log(
    `[pg-pool] monitor activo â€” intervalo ${intervalSec}s, pool.max=${maxPool}`
  );
  poolStatsTimer = setInterval(() => {
    const stats = getPoolStats();
    const waiting = stats.filter((s) => s.waiting > 0);
    if (waiting.length === 0) return;
    for (const s of waiting) {
      console.warn(
        `[pg-pool] db=${s.dbName} total=${s.total}/${maxPool} idle=${s.idle} waiting=${s.waiting}`
      );
    }
  }, intervalMs);
  // No mantener el event loop vivo por el monitor
  poolStatsTimer.unref?.();
}

export function stopPoolStatsMonitor(): void {
  if (poolStatsTimer) {
    clearInterval(poolStatsTimer);
    poolStatsTimer = null;
  }
}
