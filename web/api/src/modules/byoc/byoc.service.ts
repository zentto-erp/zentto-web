/**
 * byoc.service.ts — Módulo BYOC (Bring Your Own Cloud)
 * Orquesta el provisioning de servidores cloud y la instalación de Zentto en ellos.
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { callSp } from "../../db/query.js";
import { obs } from "../integrations/observability.js";
import { sendWelcomeEmail } from "../tenants/tenant.service.js";
import { provisionHetzner } from "./providers/hetzner.provider.js";
import { provisionDigitalOcean } from "./providers/digitalocean.provider.js";
import { validateSshDirect } from "./providers/ssh.provider.js";
import type { StartByocInput, ByocDeployJob, CloudProvider } from "./byoc.types.js";

// ---------------------------------------------------------------------------
// Helpers de BD
// ---------------------------------------------------------------------------

async function updateJobStatus(
  jobId: number,
  status: ByocDeployJob["status"],
  extra?: {
    serverIp?: string;
    tenantUrl?: string;
    logLine?: string;
    errorMessage?: string;
  }
): Promise<void> {
  await callSp("usp_Sys_ByocJob_UpdateStatus", {
    JobId: jobId,
    Status: status,
    ServerIp: extra?.serverIp ?? null,
    TenantUrl: extra?.tenantUrl ?? null,
    LogLine: extra?.logLine ?? null,
    ErrorMessage: extra?.errorMessage ?? null,
  });
}

async function appendJobLog(jobId: number, line: string): Promise<void> {
  const timestamp = new Date().toISOString();
  const entry = `[${timestamp}] ${line}\n`;
  await callSp("usp_Sys_ByocJob_AppendLog", {
    JobId: jobId,
    LogLine: entry,
  }).catch(() => {
    // No fallar el deploy por un error de logging
    console.warn(`[byoc] Advertencia: no se pudo escribir log en BD para jobId=${jobId}`);
  });
}

// ---------------------------------------------------------------------------
// API pública
// ---------------------------------------------------------------------------

export async function startByocDeploy(
  input: StartByocInput
): Promise<{ jobId: number }> {
  const rows = await callSp<{ JobId: number }>("usp_Sys_ByocJob_Create", {
    CompanyId: input.companyId,
    Provider: input.config.provider,
    Domain: input.config.domain,
    Region: input.config.region ?? null,
    ServerSize: input.config.serverSize ?? null,
  });

  const jobId = Number(rows[0]?.JobId ?? 0);
  if (!jobId) {
    throw new Error("[byoc] No se pudo crear el job en BD");
  }

  obs.audit("byoc.job.created", {
    module: "byoc",
    entity: "ByocDeployJob",
    entityId: jobId,
    companyId: input.companyId,
    provider: input.config.provider,
  });

  // Lanzar deploy en background — no bloquea la respuesta HTTP
  setImmediate(() => {
    runDeployJob(jobId, input).catch((err) => {
      console.error(`[byoc] runDeployJob (jobId=${jobId}) error no capturado:`, err?.message);
    });
  });

  return { jobId };
}

export async function getByocJobStatus(
  jobId: number
): Promise<ByocDeployJob | null> {
  const rows = await callSp<{
    JobId: number;
    CompanyId: number;
    Provider: CloudProvider;
    Status: ByocDeployJob["status"];
    ServerIp?: string;
    TenantUrl?: string;
    LogOutput?: string;
    ErrorMessage?: string;
    StartedAt?: string;
    CompletedAt?: string;
  }>("usp_Sys_ByocJob_Get", { JobId: jobId });

  const row = rows[0];
  if (!row) return null;

  return {
    jobId: Number(row.JobId),
    companyId: Number(row.CompanyId),
    provider: row.Provider,
    status: row.Status,
    serverIp: row.ServerIp ?? undefined,
    tenantUrl: row.TenantUrl ?? undefined,
    logOutput: row.LogOutput ?? undefined,
    errorMessage: row.ErrorMessage ?? undefined,
    startedAt: row.StartedAt ? new Date(row.StartedAt) : undefined,
    completedAt: row.CompletedAt ? new Date(row.CompletedAt) : undefined,
  };
}

export async function listByocJobs(
  companyId: number
): Promise<ByocDeployJob[]> {
  const rows = await callSp<{
    JobId: number;
    CompanyId: number;
    Provider: CloudProvider;
    Status: ByocDeployJob["status"];
    ServerIp?: string;
    TenantUrl?: string;
    LogOutput?: string;
    ErrorMessage?: string;
    StartedAt?: string;
    CompletedAt?: string;
  }>("usp_Sys_ByocJob_List", { CompanyId: companyId });

  return rows.map((row) => ({
    jobId: Number(row.JobId),
    companyId: Number(row.CompanyId),
    provider: row.Provider,
    status: row.Status,
    serverIp: row.ServerIp ?? undefined,
    tenantUrl: row.TenantUrl ?? undefined,
    logOutput: row.LogOutput ?? undefined,
    errorMessage: row.ErrorMessage ?? undefined,
    startedAt: row.StartedAt ? new Date(row.StartedAt) : undefined,
    completedAt: row.CompletedAt ? new Date(row.CompletedAt) : undefined,
  }));
}

// ---------------------------------------------------------------------------
// Orquestador interno
// ---------------------------------------------------------------------------

async function runDeployJob(
  jobId: number,
  input: StartByocInput
): Promise<void> {
  const { config, credentials, companyId } = input;
  const { provider } = config;

  // ── 1. PROVISIONING ──────────────────────────────────────────────────────
  try {
    await updateJobStatus(jobId, "PROVISIONING");
    obs.audit("byoc.job.provisioning", { module: "byoc", entityId: jobId, companyId, provider });
    await appendJobLog(jobId, `Iniciando provisioning en ${provider}...`);
  } catch (err: any) {
    obs.error(`byoc.job.status_update_failed: ${err.message}`, { module: "byoc", jobId });
  }

  let serverIp: string;
  const serverName = `zentto-byoc-${companyId}-${Date.now()}`;

  try {
    serverIp = await provisionServer(provider, serverName, config, credentials);
    await appendJobLog(jobId, `Servidor provisionado: ${serverIp}`);
  } catch (err: any) {
    const msg = err instanceof Error ? err.message : String(err);
    obs.error(`byoc.job.provision_failed: ${msg}`, { module: "byoc", jobId, companyId, provider });
    await appendJobLog(jobId, `ERROR en provisioning: ${msg}`);
    await updateJobStatus(jobId, "FAILED", { errorMessage: msg });
    return;
  }

  // ── 2. INSTALLING ─────────────────────────────────────────────────────────
  try {
    await updateJobStatus(jobId, "INSTALLING", { serverIp });
    obs.audit("byoc.job.installing", { module: "byoc", entityId: jobId, companyId, serverIp });
    await appendJobLog(jobId, `Iniciando instalación de Zentto en ${serverIp}...`);
  } catch (err: any) {
    obs.error(`byoc.job.status_update_failed: ${err.message}`, { module: "byoc", jobId });
  }

  // Obtener clave SSH: del provider si es cloud, o del cliente si es ssh directo
  const sshUser = credentials.sshUsername || "root";
  const sshPort = credentials.sshPort || 22;

  // Para providers cloud, usar la clave pública del cliente o generar acceso directo
  // Para ssh directo, usar la clave privada del cliente
  const privateKey = credentials.sshPrivateKey;

  try {
    await runInstallScript(jobId, serverIp, sshUser, sshPort, privateKey ?? null, config.domain, companyId);
    await appendJobLog(jobId, "Instalación completada exitosamente.");
  } catch (err: any) {
    const msg = err instanceof Error ? err.message : String(err);
    obs.error(`byoc.job.install_failed: ${msg}`, { module: "byoc", jobId, companyId, serverIp });
    await appendJobLog(jobId, `ERROR en instalación: ${msg}`);
    await updateJobStatus(jobId, "FAILED", { serverIp, errorMessage: msg });
    return;
  }

  // ── 3. DONE ───────────────────────────────────────────────────────────────
  const tenantUrl = `https://${config.domain}`;

  try {
    await updateJobStatus(jobId, "DONE", { serverIp, tenantUrl });
    obs.audit("byoc.job.done", {
      module: "byoc",
      entity: "ByocDeployJob",
      entityId: jobId,
      companyId,
      serverIp,
      tenantUrl,
    });
    await appendJobLog(jobId, `Deploy completado. URL del tenant: ${tenantUrl}`);
  } catch (err: any) {
    obs.error(`byoc.job.status_update_failed: ${err.message}`, { module: "byoc", jobId });
  }

  // Enviar email de bienvenida con la URL del tenant
  try {
    const companyRows = await callSp<{ OwnerEmail: string; LegalName: string }>(
      "usp_Cfg_Tenant_GetInfo",
      { CompanyId: companyId }
    );
    const company = companyRows[0];
    if (company?.OwnerEmail) {
      await sendWelcomeEmail(
        company.OwnerEmail,
        company.LegalName,
        "(ver credenciales de instalación)",
        companyId,
        tenantUrl
      );
      obs.audit("byoc.job.welcome_email_sent", {
        module: "byoc",
        entityId: jobId,
        companyId,
        ownerEmail: company.OwnerEmail,
      });
    }
  } catch (err: any) {
    obs.error(`byoc.job.welcome_email_failed: ${err.message}`, { module: "byoc", jobId, companyId });
    console.error("[byoc] Error enviando welcome email:", err.message);
  }
}

// ---------------------------------------------------------------------------
// Dispatch por provider
// ---------------------------------------------------------------------------

async function provisionServer(
  provider: CloudProvider,
  serverName: string,
  config: StartByocInput["config"],
  credentials: StartByocInput["credentials"]
): Promise<string> {
  switch (provider) {
    case "hetzner": {
      if (!credentials.hetznerApiToken) {
        throw new Error("[byoc] hetznerApiToken requerido para provider=hetzner");
      }
      const { serverIp } = await provisionHetzner(
        credentials.hetznerApiToken,
        serverName,
        config.serverSize || "cx22",
        config.region || "nbg1"
      );
      return serverIp;
    }

    case "digitalocean": {
      if (!credentials.doApiToken) {
        throw new Error("[byoc] doApiToken requerido para provider=digitalocean");
      }
      const { serverIp } = await provisionDigitalOcean(
        credentials.doApiToken,
        serverName,
        config.serverSize || "s-2vcpu-4gb",
        config.region || "nyc3"
      );
      return serverIp;
    }

    case "ssh": {
      if (!credentials.sshHost || !credentials.sshUsername || !credentials.sshPrivateKey) {
        throw new Error("[byoc] sshHost, sshUsername y sshPrivateKey requeridos para provider=ssh");
      }
      const { serverIp } = await validateSshDirect(
        credentials.sshHost,
        credentials.sshPort || 22,
        credentials.sshUsername,
        credentials.sshPrivateKey
      );
      return serverIp;
    }

    case "aws":
    case "gcp":
    case "azure":
      throw new Error(`[byoc] Provider '${provider}' no implementado aún (MVP)`);

    default: {
      const _exhaustive: never = provider;
      throw new Error(`[byoc] Provider desconocido: ${_exhaustive}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Instalación SSH
// ---------------------------------------------------------------------------

async function runInstallScript(
  jobId: number,
  serverIp: string,
  sshUser: string,
  sshPort: number,
  privateKey: string | null,
  domain: string,
  companyId: number
): Promise<void> {
  // Directorio del script de instalación (bundleado con la imagen Docker)
  const installScript =
    process.env.BYOC_INSTALL_SCRIPT ||
    path.join(process.cwd(), "scripts", "zentto-install.sh");

  if (!fs.existsSync(installScript)) {
    throw new Error(`[byoc] Script de instalación no encontrado: ${installScript}`);
  }

  let keyFile: string | null = null;

  try {
    // Si hay clave privada, escribirla en archivo temporal
    if (privateKey) {
      const tmpDir = os.tmpdir();
      keyFile = path.join(tmpDir, `byoc_deploy_key_${jobId}_${Date.now()}.pem`);
      fs.writeFileSync(keyFile, privateKey, { mode: 0o600 });
    }

    const keyArg = keyFile ? `-i "${keyFile}"` : "";
    const envVars = [
      `ZENTTO_DOMAIN=${domain}`,
      `ZENTTO_COMPANY_ID=${companyId}`,
      `ZENTTO_API_URL=${process.env.API_BASE_URL || "https://api.zentto.net"}`,
    ].join(" ");

    await appendJobLog(jobId, `Ejecutando script de instalación en ${sshUser}@${serverIp}:${sshPort}...`);

    execSync(
      `ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${keyArg} -p ${sshPort} ${sshUser}@${serverIp} 'export ${envVars} && bash -s' < "${installScript}"`,
      {
        timeout: 15 * 60 * 1000, // 15 min máximo para instalación
        encoding: "utf8",
        stdio: ["pipe", "pipe", "pipe"],
      }
    );

    await appendJobLog(jobId, "Script de instalación ejecutado correctamente.");
  } finally {
    // Limpiar clave temporal siempre
    if (keyFile) {
      try {
        fs.unlinkSync(keyFile);
      } catch {
        // ignorar
      }
    }
  }
}
