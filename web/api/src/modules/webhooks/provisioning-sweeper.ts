/**
 * provisioning-sweeper.ts — Worker que procesa jobs pendientes de
 * sys.ProvisioningJob (BD del tenant, Cloudflare DNS, welcome email).
 *
 * Se ejecuta en intervalos (cron interno) en cada instancia de la API.
 * Cada job tiene MaxAttempts (default 5) — pasado eso queda como 'dead'
 * y requiere intervención manual del operador.
 */
import { callSp } from "../../db/query.js";
import { provisionTenantDatabase } from "../../db/provision-tenant-db.js";
import { createSubdomainDns } from "../../lib/cloudflare.client.js";
import { sendWelcomeEmail } from "../tenants/tenant.service.js";
import { obs } from "../integrations/observability.js";

interface PendingJob {
  JobId: number;
  CompanyId: number;
  CompanyCode: string;
  Step: string;
  Attempts: number;
  MaxAttempts: number;
  PayloadJson: any;
  LastError: string;
}

let running = false;

export async function runProvisioningSweeper(): Promise<{ processed: number; ok: number; failed: number }> {
  if (running) return { processed: 0, ok: 0, failed: 0 };
  running = true;
  let processed = 0, ok = 0, failed = 0;
  try {
    const jobs = await callSp<PendingJob>("usp_sys_provisioning_job_pending", { MaxRows: 20 });
    for (const job of jobs) {
      processed++;
      try {
        await processJob(job);
        await callSp("usp_sys_provisioning_job_complete", { JobId: job.JobId, Status: "done", Error: "" });
        ok++;
        obs.audit("provisioning.job.done", { module: "sweeper", jobId: job.JobId, step: job.Step, companyId: job.CompanyId });
      } catch (err: any) {
        failed++;
        const status = job.Attempts + 1 >= job.MaxAttempts ? "dead" : "pending";
        await callSp("usp_sys_provisioning_job_complete", {
          JobId: job.JobId,
          Status: status,
          Error: String(err?.message ?? err).slice(0, 1000),
        });
        obs.error(`provisioning.job.failed: step=${job.Step} err=${err?.message}`, {
          module: "sweeper", jobId: job.JobId, companyId: job.CompanyId, status,
        });
      }
    }
  } finally {
    running = false;
  }
  return { processed, ok, failed };
}

async function processJob(job: PendingJob): Promise<void> {
  const payload = typeof job.PayloadJson === "string" ? JSON.parse(job.PayloadJson) : job.PayloadJson;
  switch (job.Step) {
    case "provision_database": {
      const r = await provisionTenantDatabase(job.CompanyId, job.CompanyCode);
      if (!r.ok) throw new Error(r.error || "provision_database_failed");
      return;
    }
    case "cloudflare_dns": {
      const subdomain = String(payload.subdomain || "");
      if (!subdomain) throw new Error("subdomain_missing_in_payload");
      const r = await createSubdomainDns(subdomain);
      if (!r.ok) throw new Error(r.error || "cloudflare_dns_failed");
      return;
    }
    case "welcome_email": {
      const ownerEmail = String(payload.ownerEmail || "");
      const tenantUrl = String(payload.tenantUrl || "");
      const magicLinkUrl = payload.magicLinkUrl ? String(payload.magicLinkUrl) : undefined;
      if (!ownerEmail) throw new Error("ownerEmail_missing_in_payload");
      await sendWelcomeEmail(
        ownerEmail,
        String(payload.legalName || job.CompanyCode),
        String(payload.tempPassword || ""),
        job.CompanyId,
        tenantUrl,
        "ADMIN",
        magicLinkUrl
      );
      return;
    }
    default:
      throw new Error(`unknown_step: ${job.Step}`);
  }
}

/**
 * Inicia el cron interno del sweeper (cada 60s). Llamar desde app.ts una vez
 * al boot.
 */
export function startProvisioningSweeperCron(): void {
  if (process.env.PROVISIONING_SWEEPER_ENABLED === "false") {
    console.log("[sweeper] deshabilitado por env PROVISIONING_SWEEPER_ENABLED=false");
    return;
  }
  const intervalMs = Number(process.env.PROVISIONING_SWEEPER_INTERVAL_MS || 60_000);
  console.log(`[sweeper] iniciando cron de provisioning cada ${intervalMs}ms`);
  setInterval(() => {
    runProvisioningSweeper().catch((err) =>
      console.error("[sweeper] error en runProvisioningSweeper:", err)
    );
  }, intervalMs);
}
