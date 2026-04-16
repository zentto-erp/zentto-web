/**
 * Pool manager dinámico para PostgreSQL — multi-tenant
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

/** Cache: dbName → Pool */
const pools = new Map<string, Pool>();

/**
 * Obtiene (o crea) el pool de un tenant específico.
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
    ssl: (config.ssl ?? env.pg.ssl) ? { rejectUnauthorized: false } : false, // nosemgrep: javascript.lang.security.audit.sqli.node-bypass-tls-verification
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
 * Pool de la BD master — para login, health, tenant resolve.
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

/** Cerrar pool de un tenant específico */
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

/** Estadísticas de pools activos */
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
