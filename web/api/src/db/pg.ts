/**
 * Conexión PostgreSQL — delega al pool manager dinámico (retrocompatible)
 */
import { Pool, type PoolClient } from "pg";
import { getMasterPool } from "./pg-pool-manager.js";

/**
 * Devuelve el pool de la BD master configurada en .env (PG_DATABASE).
 * Alias retrocompatible — internamente usa pg-pool-manager.
 */
export function getPgPool(): Pool {
  return getMasterPool();
}

export { Pool };
export type { PoolClient };
