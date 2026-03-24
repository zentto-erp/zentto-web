/**
 * backup.service.ts — Servicio de respaldo de bases de datos de tenants
 *
 * Flujo por backup:
 * 1. Registra en sys."TenantBackup" con Status=RUNNING
 * 2. Ejecuta pg_dump -Fc → archivo local en BACKUP_DIR
 * 3. Sube el archivo a Hetzner Object Storage (S3-compatible)
 * 4. Marca DONE con StorageKey + StorageStatus en BD
 * 5. Elimina el archivo local si la subida fue exitosa
 *
 * Variables de entorno requeridas para Object Storage:
 *   HETZNER_S3_ENDPOINT   — https://nbg1.your-objectstorage.com
 *   HETZNER_S3_BUCKET     — zentto-backups
 *   HETZNER_S3_ACCESS_KEY — Access Key ID de Hetzner
 *   HETZNER_S3_SECRET_KEY — Secret Access Key de Hetzner
 *   HETZNER_S3_REGION     — nbg1 (o fsn1, hel1)
 *
 * Si las variables S3 no están configuradas, el backup queda solo en local.
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { S3Client, PutObjectCommand, HeadBucketCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { callSp } from "../../db/query.js";
import { obs } from "../integrations/observability.js";

const BACKUP_DIR = process.env.BACKUP_DIR || "/backups/zentto";

// ── Cliente S3 (Hetzner Object Storage) ─────────────────────────────────────

function getS3Client(): S3Client | null {
  const endpoint   = process.env.HETZNER_S3_ENDPOINT;
  const accessKey  = process.env.HETZNER_S3_ACCESS_KEY;
  const secretKey  = process.env.HETZNER_S3_SECRET_KEY;
  const region     = process.env.HETZNER_S3_REGION || "nbg1";

  if (!endpoint || !accessKey || !secretKey) return null;

  return new S3Client({
    endpoint,
    region,
    credentials: { accessKeyId: accessKey, secretAccessKey: secretKey },
    forcePathStyle: true,  // requerido para Hetzner Object Storage
  });
}

async function uploadToStorage(
  localFilePath: string,
  storageKey: string
): Promise<{ ok: boolean; message: string }> {
  const s3     = getS3Client();
  const bucket = process.env.HETZNER_S3_BUCKET || "zentto-backups";

  if (!s3) {
    return { ok: false, message: "s3_not_configured" };
  }

  const fileStream  = fs.createReadStream(localFilePath);
  const fileStats   = fs.statSync(localFilePath);

  try {
    await s3.send(new PutObjectCommand({
      Bucket:        bucket,
      Key:           storageKey,
      Body:          fileStream,
      ContentLength: fileStats.size,
      ContentType:   "application/octet-stream",
      Metadata: {
        "zentto-backup": "true",
        "uploaded-at":   new Date().toISOString(),
      },
    }));
    return { ok: true, message: `uploaded: s3://${bucket}/${storageKey}` };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "s3_upload_failed";
    return { ok: false, message: msg };
  }
}

// ── Tipos internos ─────────────────────────────────────────────────────────────

interface BackupCreateRow {
  BackupId: number;
}

// ── createTenantBackup ────────────────────────────────────────────────────────

/**
 * Ejecuta un backup completo de la BD de un tenant.
 * 1. pg_dump -Fc  →  archivo local
 * 2. Upload Hetzner Object Storage
 * 3. Elimina archivo local si el upload fue OK
 * 4. Registra resultado en sys."TenantBackup"
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

  // 2. Directorio local temporal
  const tenantBackupDir = path.join(BACKUP_DIR, companyCode.toLowerCase());
  fs.mkdirSync(tenantBackupDir, { recursive: true });

  const timestamp  = new Date().toISOString().replace(/[:.]/g, "-");
  const fileName   = `${dbName}_${timestamp}.dump`;
  const filePath   = path.join(tenantBackupDir, fileName);
  const storageKey = `${companyCode.toLowerCase()}/${fileName}`;

  const pgHost     = process.env.PG_HOST     || "localhost";
  const pgPort     = process.env.PG_PORT     || "5432";
  const pgUser     = process.env.PG_USER     || "postgres";
  const pgPassword = process.env.PG_PASSWORD || "";

  try {
    obs.audit("backup.start", { module: "backup", companyId, dbName, backupId });

    // 3. pg_dump → archivo local
    execSync(
      `PGPASSWORD="${pgPassword}" pg_dump -h ${pgHost} -p ${pgPort} -U ${pgUser} -Fc -f "${filePath}" "${dbName}"`,
      { timeout: 30 * 60 * 1000, stdio: ["pipe", "pipe", "pipe"] }
    );

    const stats         = fs.statSync(filePath);
    const fileSizeBytes = stats.size;

    obs.log("info", `[backup] pg_dump completado: ${fileName} (${(fileSizeBytes / 1048576).toFixed(1)} MB)`, {
      module: "backup", companyId, backupId,
    });

    // 4. Subir a Hetzner Object Storage
    let storageStatus = "LOCAL_ONLY";
    let uploadedKey: string | null = null;

    if (getS3Client()) {
      obs.log("info", `[backup] Subiendo a Object Storage: ${storageKey}`, { module: "backup", companyId });
      const uploadResult = await uploadToStorage(filePath, storageKey);

      if (uploadResult.ok) {
        storageStatus = "UPLOADED";
        uploadedKey   = storageKey;
        obs.audit("backup.storage.upload", { module: "backup", companyId, backupId, storageKey });

        // Eliminar archivo local tras upload exitoso para ahorrar espacio en disco
        try {
          fs.unlinkSync(filePath);
          obs.log("info", `[backup] Archivo local eliminado tras upload: ${filePath}`, { module: "backup" });
        } catch {
          // No crítico — el archivo en Storage ya es la fuente de verdad
        }
      } else {
        storageStatus = "UPLOAD_FAILED";
        obs.error(`backup.storage.upload.failed: ${uploadResult.message}`, { module: "backup", companyId, backupId });
        // El archivo local se conserva como fallback
      }
    }

    // 5. Marcar como DONE
    await callSp("usp_Sys_Backup_Complete", {
      BackupId:       backupId,
      FilePath:       storageStatus === "UPLOADED" ? null : filePath,
      FileName:       fileName,
      FileSizeBytes:  fileSizeBytes,
      StorageKey:     uploadedKey,
      StorageStatus:  storageStatus,
    });

    obs.audit("backup.complete", { module: "backup", companyId, dbName, backupId, fileSizeBytes, storageStatus });
    return { ok: true, backupId, message: `backup_created: ${fileName} [${storageStatus}]` };

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "pg_dump_failed";
    obs.error(`backup.failed: ${msg}`, { module: "backup", companyId, dbName, backupId });

    // Limpiar archivo parcial si existe
    try { if (fs.existsSync(filePath)) fs.unlinkSync(filePath); } catch { /* ignorar */ }

    await callSp("usp_Sys_Backup_Fail", {
      BackupId:     backupId,
      ErrorMessage: msg.substring(0, 500),
    });
    return { ok: false, backupId, message: msg };
  }
}

// ── listTenantBackups ─────────────────────────────────────────────────────────

export async function listTenantBackups(companyId?: number) {
  return callSp("usp_Sys_Backup_List", { CompanyId: companyId ?? null });
}

// ── getLatestBackupsPerTenant ─────────────────────────────────────────────────

export async function getLatestBackupsPerTenant() {
  return callSp("usp_Sys_Backup_Latest_Per_Tenant", {});
}

// ── restoreTenantBackup ───────────────────────────────────────────────────────

/**
 * Restaura la BD de un tenant desde un backup.
 *
 * Flujo:
 * 1. Obtener metadatos del backup (BackupId + CompanyId deben coincidir)
 * 2. Si el archivo está en Object Storage, descargarlo localmente
 * 3. Ejecutar pg_restore contra la BD del tenant
 * 4. Registrar resultado en obs.audit
 *
 * ATENCIÓN: La BD destino debe existir. No la elimina ni recrea.
 * Si se necesita restaurar sobre una BD vacía, crearla antes con
 * CREATE DATABASE "zentto_tenant_{code}".
 */
export async function restoreTenantBackup(
  companyId: number,
  backupId: number
): Promise<{ ok: boolean; message: string }> {
  interface BackupRow {
    BackupId: number;
    CompanyId: number;
    DbName: string;
    FilePath: string | null;
    FileName: string;
    StorageKey: string | null;
    StorageStatus: string | null;
    Status: string;
  }

  // 1. Obtener metadatos del backup
  const rows = await callSp<BackupRow>("usp_Sys_Backup_List", { CompanyId: companyId });
  const backup = rows.find((r: BackupRow) => Number(r.BackupId) === backupId);

  if (!backup) {
    obs.error(`restore.backup_not_found: backupId=${backupId} companyId=${companyId}`, { module: "backup" });
    return { ok: false, message: "backup_not_found" };
  }
  if (backup.Status !== "DONE") {
    return { ok: false, message: `backup_status_invalid: ${backup.Status}` };
  }

  obs.audit("restore.start", { module: "backup", companyId, backupId, dbName: backup.DbName });

  let localFilePath = backup.FilePath;
  let tempFile: string | null = null;

  try {
    // 2. Si está en Object Storage, descargar primero
    if (backup.StorageStatus === "UPLOADED" && backup.StorageKey) {
      const s3     = getS3Client();
      const bucket = process.env.HETZNER_S3_BUCKET || "zentto-backups";

      if (!s3) {
        return { ok: false, message: "restore_requires_s3_configured" };
      }

      const tmpDir  = `/tmp`;
      tempFile      = path.join(tmpDir, `restore_${backupId}_${Date.now()}.dump`);
      localFilePath = tempFile;

      obs.log("info", `[restore] Descargando desde Object Storage: ${backup.StorageKey}`, { module: "backup" });

      const response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: backup.StorageKey }));
      const fileStream = fs.createWriteStream(tempFile);
      await pipeline(response.Body as Readable, fileStream);
    }

    if (!localFilePath || !fs.existsSync(localFilePath)) {
      return { ok: false, message: "backup_file_not_accessible" };
    }

    // 3. pg_restore
    const pgHost     = process.env.PG_HOST     || "localhost";
    const pgPort     = process.env.PG_PORT     || "5432";
    const pgUser     = process.env.PG_USER     || "postgres";
    const pgPassword = process.env.PG_PASSWORD || "";

    obs.log("info", `[restore] Ejecutando pg_restore sobre ${backup.DbName}`, { module: "backup", companyId, backupId });

    execSync(
      `PGPASSWORD="${pgPassword}" pg_restore -h ${pgHost} -p ${pgPort} -U ${pgUser} -d "${backup.DbName}" --clean --if-exists -Fc "${localFilePath}"`,
      { timeout: 60 * 60 * 1000, stdio: ["pipe", "pipe", "pipe"] }
    );

    obs.audit("restore.complete", { module: "backup", companyId, backupId, dbName: backup.DbName });
    return { ok: true, message: `restored: ${backup.FileName} → ${backup.DbName}` };

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "pg_restore_failed";
    obs.error(`restore.failed: ${msg}`, { module: "backup", companyId, backupId });
    return { ok: false, message: msg };
  } finally {
    // Limpiar archivo temporal de descarga
    if (tempFile) {
      try { fs.unlinkSync(tempFile); } catch { /* ignorar */ }
    }
  }
}

// ── verifyStorageConnection ───────────────────────────────────────────────────

/**
 * Verifica que Hetzner Object Storage esté configurado y accesible.
 * Usado en el health check del dashboard de backoffice.
 */
export async function verifyStorageConnection(): Promise<{ ok: boolean; message: string }> {
  const s3     = getS3Client();
  const bucket = process.env.HETZNER_S3_BUCKET || "zentto-backups";

  if (!s3) {
    return { ok: false, message: "s3_not_configured" };
  }

  try {
    await s3.send(new HeadBucketCommand({ Bucket: bucket }));
    return { ok: true, message: `bucket_accessible: ${bucket}` };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "s3_check_failed";
    return { ok: false, message: msg };
  }
}
