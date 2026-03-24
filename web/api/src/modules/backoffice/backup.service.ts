/**
 * backup.service.ts — Servicio de respaldo de bases de datos de tenants
 *
 * Ejecuta pg_dump en formato custom (-Fc) y registra el resultado en
 * sys."TenantBackup". Los errores son capturados y marcados en BD sin
 * propagar la excepción al caller del endpoint.
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { callSp } from "../../db/query.js";
import { obs } from "../integrations/observability.js";

const BACKUP_DIR = process.env.BACKUP_DIR || "/backups/zentto";

// ── Tipos internos ─────────────────────────────────────────────────────────────

interface BackupCreateRow {
  BackupId: number;
}

// ── createTenantBackup ────────────────────────────────────────────────────────

/**
 * Ejecuta un backup de la BD de un tenant usando pg_dump -Fc.
 * 1. Registra el backup en sys."TenantBackup" con Status=RUNNING.
 * 2. Crea el directorio de destino si no existe.
 * 3. Llama a pg_dump con timeout de 30 minutos.
 * 4. Actualiza el registro a DONE o FAILED según el resultado.
 */
export async function createTenantBackup(
  companyId: number,
  companyCode: string,
  dbName: string,
  requestedBy: string = "backoffice"
): Promise<{ ok: boolean; backupId?: number; message: string }> {
  // 1. Registrar backup en BD (Status=RUNNING)
  const rows = await callSp<BackupCreateRow>("usp_Sys_Backup_Create", {
    CompanyId: companyId,
    DbName:    dbName,
    CreatedBy: requestedBy,
  });
  const backupId = Number(rows[0]?.BackupId);
  if (!backupId) throw new Error("No se pudo crear registro de backup");

  // 2. Asegurar directorio de destino
  const tenantBackupDir = path.join(BACKUP_DIR, companyCode.toLowerCase());
  fs.mkdirSync(tenantBackupDir, { recursive: true });

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const fileName  = `${dbName}_${timestamp}.dump`;
  const filePath  = path.join(tenantBackupDir, fileName);

  // 3. Ejecutar pg_dump en formato custom (comprimido)
  const pgHost     = process.env.PG_HOST     || "localhost";
  const pgPort     = process.env.PG_PORT     || "5432";
  const pgUser     = process.env.PG_USER     || "postgres";
  const pgPassword = process.env.PG_PASSWORD || "";

  try {
    obs.audit("backup.start", { module: "backup", companyId, dbName, backupId });

    execSync(
      `PGPASSWORD="${pgPassword}" pg_dump -h ${pgHost} -p ${pgPort} -U ${pgUser} -Fc -f "${filePath}" "${dbName}"`,
      { timeout: 30 * 60 * 1000, stdio: ["pipe", "pipe", "pipe"] }
    );

    // 4. Obtener tamaño del archivo generado
    const stats         = fs.statSync(filePath);
    const fileSizeBytes = stats.size;

    // 5. Marcar como DONE
    await callSp("usp_Sys_Backup_Complete", {
      BackupId:      backupId,
      FilePath:      filePath,
      FileName:      fileName,
      FileSizeBytes: fileSizeBytes,
    });

    obs.audit("backup.complete", { module: "backup", companyId, dbName, backupId, fileSizeBytes });
    return { ok: true, backupId, message: `backup_created: ${fileName}` };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "pg_dump_failed";
    obs.error(`backup.failed: ${msg}`, { module: "backup", companyId, dbName, backupId });
    await callSp("usp_Sys_Backup_Fail", {
      BackupId:     backupId,
      ErrorMessage: msg.substring(0, 500),
    });
    return { ok: false, backupId, message: msg };
  }
}

// ── listTenantBackups ─────────────────────────────────────────────────────────

/**
 * Lista los backups de todos los tenants o de uno en particular.
 * Delega en usp_Sys_Backup_List.
 */
export async function listTenantBackups(companyId?: number) {
  return callSp("usp_Sys_Backup_List", { CompanyId: companyId ?? null });
}

// ── getLatestBackupsPerTenant ─────────────────────────────────────────────────

/**
 * Devuelve el último backup de cada tenant activo.
 * Usado por el widget de dashboard de backoffice.
 */
export async function getLatestBackupsPerTenant() {
  return callSp("usp_Sys_Backup_Latest_Per_Tenant", {});
}
