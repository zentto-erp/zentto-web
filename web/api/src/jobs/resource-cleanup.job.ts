/**
 * resource-cleanup.job.ts — Job diario de auditoría y limpieza de recursos
 *
 * Ejecuta:
 * 1. usp_Sys_Resource_Audit()   — actualiza tamaños de BD por tenant
 * 2. usp_Sys_Cleanup_Scan()     — detecta nuevos candidatos para limpieza
 * 3. Notifica a tenants con DeleteAfter < NOW()+7 días via Zentto Notify
 *
 * Programación:
 * - Primera ejecución: 60 segundos después del boot
 * - Siguientes: cada 24 horas
 */
import { callSp } from "../db/query.js";
import { runResourceAudit } from "../modules/backoffice/resource.service.js";
import { obs } from "../modules/integrations/observability.js";

// ── Constantes ─────────────────────────────────────────────────────────────

const RUN_AFTER_BOOT_MS = 60_000;          // 60 segundos tras el boot
const INTERVAL_MS = 24 * 60 * 60 * 1000;  // 24 horas

// ── Tipos internos ─────────────────────────────────────────────────────────

interface CleanupScanRow {
  NewCandidates: number;
  TotalPending: number;
}

interface CleanupNearDeadlineRow {
  QueueId: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  OwnerEmail: string | null;
  DeleteAfter: string;
  DaysUntilDelete: number;
}

// ── Job principal ──────────────────────────────────────────────────────────

async function runJob(): Promise<void> {
  obs.log('info', '[resource-job] Iniciando audit de recursos...', { module: 'resource-job' });

  let tenantsAudited = 0;
  let totalSizeMB = 0;
  let newCandidates = 0;

  try {
    // 1. Auditar recursos — actualiza tamaños de BD en sys.TenantDatabase
    try {
      const auditResult = await runResourceAudit();
      tenantsAudited = auditResult.tenantsAudited;
      totalSizeMB = auditResult.totalSizeMB;
      obs.log('info', `[resource-job] Audit completo: ${tenantsAudited} tenants, ${totalSizeMB.toFixed(1)} MB total`, { module: 'resource-job' });
    } catch (auditErr: unknown) {
      const msg = auditErr instanceof Error ? auditErr.message : 'audit_error';
      obs.error(`[resource-job] Audit falló (continuando): ${msg}`, { module: 'resource-job' });
    }

    // 2. Scan de nuevos candidatos para limpieza
    try {
      const scanRows = await callSp<CleanupScanRow>("usp_Sys_Cleanup_Scan", {});
      const scanRow = scanRows[0];
      newCandidates = scanRow?.NewCandidates ?? 0;
      obs.log('info', `[resource-job] Scan completo: ${newCandidates} nuevos candidatos, ${scanRow?.TotalPending ?? 0} pendientes`, { module: 'resource-job' });
    } catch (scanErr: unknown) {
      const msg = scanErr instanceof Error ? scanErr.message : 'scan_error';
      obs.error(`[resource-job] Scan falló (continuando): ${msg}`, { module: 'resource-job' });
    }

    // 3. Notificar a tenants con DeleteAfter próximo (menos de 7 días)
    try {
      const nearDeadline = await callSp<CleanupNearDeadlineRow>(
        "usp_Sys_Cleanup_List",
        { Status: 'PENDING' }
      );

      const urgentTenants = nearDeadline.filter(r =>
        r.DaysUntilDelete !== null &&
        r.DaysUntilDelete >= 0 &&
        r.DaysUntilDelete <= 7
      );

      if (urgentTenants.length > 0) {
        obs.log('info', `[resource-job] ${urgentTenants.length} tenants con eliminación en ≤7 días — enviando notificaciones`, { module: 'resource-job' });

        const notifyUrl = process.env.ZENTTO_NOTIFY_URL;
        const notifyApiKey = process.env.ZENTTO_NOTIFY_API_KEY;

        if (notifyUrl && notifyApiKey) {
          // Enviar notificaciones en paralelo (máximo 5 concurrentes)
          const chunkSize = 5;
          for (let i = 0; i < urgentTenants.length; i += chunkSize) {
            const chunk = urgentTenants.slice(i, i + chunkSize);
            await Promise.allSettled(
              chunk.map(tenant => sendDeletionWarning(tenant, notifyUrl, notifyApiKey))
            );
          }
        } else {
          obs.log('warn', '[resource-job] ZENTTO_NOTIFY_URL o ZENTTO_NOTIFY_API_KEY no configurados — omitiendo notificaciones', { module: 'resource-job' });
        }
      }
    } catch (notifyErr: unknown) {
      const msg = notifyErr instanceof Error ? notifyErr.message : 'notify_error';
      obs.error(`[resource-job] Notificaciones fallaron (continuando): ${msg}`, { module: 'resource-job' });
    }

    // 4. Loguear resultado final
    obs.audit('resource.cleanup.job.run', {
      module: 'resource-job',
      tenantsAudited,
      totalSizeMB,
      newCandidates,
    });

    obs.log('info', '[resource-job] Job completado exitosamente', { module: 'resource-job', tenantsAudited, newCandidates });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'job_failed';
    obs.error(`resource.cleanup.job.failed: ${msg}`, { module: 'resource-job' });
  }
}

// ── Función auxiliar: enviar aviso de eliminación ──────────────────────────

async function sendDeletionWarning(
  tenant: CleanupNearDeadlineRow,
  notifyUrl: string,
  apiKey: string,
): Promise<void> {
  if (!tenant.OwnerEmail) return;

  try {
    const response = await fetch(`${notifyUrl}/api/v1/send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        channel: 'email',
        to: tenant.OwnerEmail,
        template: 'account_deletion_warning',
        variables: {
          companyName: tenant.LegalName,
          companyCode: tenant.CompanyCode,
          daysUntilDelete: tenant.DaysUntilDelete,
          deleteAfter: tenant.DeleteAfter,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    obs.log('info', `[resource-job] Notificación enviada a ${tenant.OwnerEmail} (${tenant.CompanyCode})`, { module: 'resource-job' });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'send_error';
    obs.error(`resource.cleanup.notify.failed: ${msg}`, { module: 'resource-job', companyCode: tenant.CompanyCode });
  }
}

// ── Inicio del job ─────────────────────────────────────────────────────────

/**
 * Registra el job de limpieza de recursos para ejecución periódica.
 * Primera ejecución: 60s después del boot.
 * Siguiente: cada 24 horas.
 */
export function startResourceCleanupJob(): void {
  obs.log('info', `[resource-job] Job registrado — primera ejecución en ${RUN_AFTER_BOOT_MS / 1000}s`, { module: 'resource-job' });

  setTimeout(async () => {
    await runJob();
    setInterval(runJob, INTERVAL_MS);
  }, RUN_AFTER_BOOT_MS);
}
