/**
 * resource.service.ts — Gestión de recursos de tenants en Zentto
 *
 * Funciones:
 * - runResourceAudit()      — Audita uso de recursos via SP usp_Sys_Resource_Audit
 * - dropTenantDatabase()    — Elimina BD de tenant con verificación de seguridad
 * - getResourceSummary()    — Query directa a pg_database para tamaños sin SP
 */
import { Client } from "pg";
import { env } from "../../config/env.js";
import { callSp } from "../../db/query.js";
import { getMasterPool } from "../../db/pg-pool-manager.js";
import { obs } from "../integrations/observability.js";

// ── Tipos internos ─────────────────────────────────────────────────────────

interface ResourceAuditRow {
  TenantsAudited: number;
  TotalSizeMB: number;
}

interface CleanupConfirmedRow {
  QueueId: number;
  CompanyId: number;
  CompanyCode: string;
  Status: string;
}

interface ResourceSummaryRow {
  dbName: string;
  sizeMB: number;
}

// ── runResourceAudit ───────────────────────────────────────────────────────

/**
 * Ejecuta la auditoría de recursos de todos los tenants.
 * Actualiza la tabla sys.TenantDatabase con los tamaños de BD actuales.
 * Retorna el número de tenants auditados y el tamaño total en MB.
 */
export async function runResourceAudit(): Promise<{ tenantsAudited: number; totalSizeMB: number }> {
  try {
    const rows = await callSp<ResourceAuditRow>("usp_Sys_Resource_Audit", {});
    const row = rows[0];
    obs.audit('resource.audit.complete', {
      module: 'resource-service',
      tenantsAudited: row?.TenantsAudited ?? 0,
      totalSizeMB: row?.TotalSizeMB ?? 0,
    });
    return {
      tenantsAudited: row?.TenantsAudited ?? 0,
      totalSizeMB: row?.TotalSizeMB ?? 0,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`resource.audit.failed: ${msg}`, { module: 'resource-service' });
    throw new Error(msg);
  }
}

// ── dropTenantDatabase ─────────────────────────────────────────────────────

/**
 * Elimina la BD de un tenant.
 *
 * SEGURIDAD: Solo procede si el tenant tiene Status='CONFIRMED' en CleanupQueue.
 * Nunca elimina una BD arbitrariamente sin verificación previa.
 *
 * Flujo:
 * 1. Verificar en CleanupQueue que CompanyId tenga Status='CONFIRMED'
 * 2. DROP DATABASE IF EXISTS "zentto_tenant_{code}"
 * 3. El SP usp_Sys_Cleanup_Process ya marca el registro como DELETED
 */
export async function dropTenantDatabase(
  companyId: number,
  companyCode: string,
): Promise<{ ok: boolean; message: string }> {
  const dbName = `zentto_tenant_${companyCode.toLowerCase().replace(/[^a-z0-9]/g, "_")}`;

  // 1. Verificar que el tenant esté en CleanupQueue con Status='CONFIRMED'
  try {
    const masterPool = getMasterPool();
    const verifyResult = await masterPool.query<CleanupConfirmedRow>(
      `SELECT "QueueId", "CompanyId", "CompanyCode", "Status"
       FROM sys."CleanupQueue"
       WHERE "CompanyId" = $1
         AND "Status" = 'CONFIRMED'
       LIMIT 1`,
      [companyId],
    );

    if (verifyResult.rows.length === 0) {
      const msg = `tenant_not_in_confirmed_cleanup_queue: CompanyId=${companyId}`;
      obs.error(`resource.drop_db.blocked: ${msg}`, { module: 'resource-service', companyId, companyCode });
      return { ok: false, message: msg };
    }
  } catch (verifyErr: unknown) {
    const msg = verifyErr instanceof Error ? verifyErr.message : 'verify_failed';
    obs.error(`resource.drop_db.verify_failed: ${msg}`, { module: 'resource-service', companyId });
    return { ok: false, message: msg };
  }

  // 2. Conectar como admin a BD 'postgres' y ejecutar DROP DATABASE
  const adminClient = new Client({
    host: env.pg?.host || process.env.PG_HOST || "localhost",
    port: env.pg?.port || Number(process.env.PG_PORT) || 5432,
    user: env.pg?.user || process.env.PG_USER || "postgres",
    password: env.pg?.password || process.env.PG_PASSWORD || "",
    database: "postgres",
  });

  obs.audit('resource.drop_db.start', { module: 'resource-service', companyId, companyCode, dbName });

  try {
    await adminClient.connect();

    // Verificar que la BD existe antes de intentar eliminarla
    const exists = await adminClient.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [dbName],
    );

    if (exists.rows.length === 0) {
      obs.log('info', `[resource] BD ya no existe: ${dbName} — omitiendo DROP`, { companyId });
      await adminClient.end();
      return { ok: true, message: `database_not_found_skipped: ${dbName}` };
    }

    // Terminar conexiones activas antes de eliminar
    await adminClient.query(
      `SELECT pg_terminate_backend(pid)
       FROM pg_stat_activity
       WHERE datname = $1 AND pid <> pg_backend_pid()`,
      [dbName],
    );

    await adminClient.query(`DROP DATABASE IF EXISTS "${dbName}"`);
    await adminClient.end();

    obs.audit('resource.drop_db.complete', { module: 'resource-service', companyId, companyCode, dbName });
    return { ok: true, message: `database_dropped: ${dbName}` };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'drop_failed';
    obs.error(`resource.drop_db.error: ${msg}`, { module: 'resource-service', companyId, dbName });
    try { await adminClient.end(); } catch { /* ya cerrada */ }
    return { ok: false, message: msg };
  }
}

// ── getResourceSummary ─────────────────────────────────────────────────────

/**
 * Query directa a pg_database para obtener tamaños de BD de tenants.
 * Útil para el dashboard rápido sin pasar por el SP de auditoría.
 * Filtra solo BDs con prefijo 'zentto_tenant_'.
 */
export async function getResourceSummary(): Promise<ResourceSummaryRow[]> {
  const masterPool = getMasterPool();
  try {
    const result = await masterPool.query<{ datname: string; size_mb: string }>(
      `SELECT datname,
              pg_database_size(datname) / 1048576.0 AS size_mb
       FROM pg_database
       WHERE datname LIKE 'zentto_tenant_%'
         AND datistemplate = FALSE
       ORDER BY size_mb DESC`,
    );

    return result.rows.map(row => ({
      dbName: row.datname,
      sizeMB: parseFloat(row.size_mb) || 0,
    }));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'query_failed';
    obs.error(`resource.summary.failed: ${msg}`, { module: 'resource-service' });
    return [];
  }
}
