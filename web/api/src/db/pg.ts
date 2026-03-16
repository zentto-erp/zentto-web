/**
 * Conexión PostgreSQL — pool singleton usando 'pg'
 */
import { Pool, type PoolClient } from "pg";
import { env } from "../config/env.js";

let pool: InstanceType<typeof Pool> | null = null;

export function getPgPool(): InstanceType<typeof Pool> {
  if (pool) return pool;

  pool = new Pool({
    host: env.pg.host,
    port: env.pg.port,
    database: env.pg.database,
    user: env.pg.user,
    password: env.pg.password,
    min: env.pg.poolMin,
    max: env.pg.poolMax,
    ssl: env.pg.ssl ? { rejectUnauthorized: false } : false,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  });

  pool.on("error", (err: Error) => {
    console.error("[PG] Pool error:", err.message);
  });

  return pool;
}

export { Pool };
export type { PoolClient };
