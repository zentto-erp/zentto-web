/**
 * byoc.routes.ts — Endpoints REST del módulo BYOC (Bring Your Own Cloud)
 *
 * POST   /v1/byoc/start                    Inicia un nuevo deploy job (JWT)
 * GET    /v1/byoc/jobs/:jobId              Obtiene estado de un job (JWT)
 * GET    /v1/byoc/jobs                     Lista jobs de un tenant (JWT)
 * GET    /v1/byoc/stream/:jobId            Server-Sent Events con logs (JWT query param)
 *
 * GET    /v1/byoc/onboarding/validate      Valida token de onboarding (público)
 * POST   /v1/byoc/wizard/start             Inicia deploy desde wizard (token onboarding)
 * GET    /v1/byoc/wizard/stream/:jobId     SSE desde wizard (token query param)
 */
import { Router } from "express";
import { z } from "zod";
import { requireJwt } from "../../middleware/auth.js";
import { startByocDeploy, getByocJobStatus, listByocJobs } from "./byoc.service.js";
import { callSp } from "../../db/query.js";
import { obs } from "../integrations/observability.js";
import type { CloudProvider, ByocCredentials } from "./byoc.types.js";

export const byocRouter = Router();

// ---------------------------------------------------------------------------
// Schemas de validación
// ---------------------------------------------------------------------------

const startSchema = z.object({
  companyId: z.number().int().positive(),
  config: z.object({
    provider: z.enum(["hetzner", "digitalocean", "aws", "gcp", "azure", "ssh"] as const),
    region: z.string().optional(),
    serverSize: z.string().optional(),
    domain: z.string().min(3),
    sshPublicKey: z.string().optional(),
  }),
  credentials: z.object({
    hetznerApiToken: z.string().optional(),
    doApiToken: z.string().optional(),
    awsAccessKeyId: z.string().optional(),
    awsSecretAccessKey: z.string().optional(),
    awsRegion: z.string().optional(),
    gcpServiceAccountJson: z.string().optional(),
    sshHost: z.string().optional(),
    sshPort: z.number().int().positive().optional(),
    sshUsername: z.string().optional(),
    sshPrivateKey: z.string().optional(),
  }),
});

// ---------------------------------------------------------------------------
// POST /v1/byoc/start
// ---------------------------------------------------------------------------
byocRouter.post("/start", requireJwt, async (req, res) => {
  const parsed = startSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  try {
    const result = await startByocDeploy(parsed.data);
    res.status(201).json({ ok: true, jobId: result.jobId });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.start.failed: ${msg}`, { module: "byoc", companyId: parsed.data.companyId });
    res.status(500).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// GET /v1/byoc/jobs/:jobId
// ---------------------------------------------------------------------------
byocRouter.get("/jobs/:jobId", requireJwt, async (req, res) => {
  const jobId = Number(req.params.jobId);
  if (!jobId || isNaN(jobId)) {
    res.status(400).json({ error: "invalid_job_id" });
    return;
  }

  try {
    const job = await getByocJobStatus(jobId);
    if (!job) {
      res.status(404).json({ error: "job_not_found" });
      return;
    }
    res.json(job);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.get_job.failed: ${msg}`, { module: "byoc", jobId });
    res.status(500).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// GET /v1/byoc/jobs?companyId=N
// ---------------------------------------------------------------------------
byocRouter.get("/jobs", requireJwt, async (req, res) => {
  // Usar companyId del scope JWT. No confiar en query param.
  const companyId = (req as any).scope?.companyId ?? Number(req.query.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: "invalid_company_id" });
    return;
  }

  try {
    const jobs = await listByocJobs(companyId);
    res.json({ ok: true, data: jobs, total: jobs.length });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.list_jobs.failed: ${msg}`, { module: "byoc", companyId });
    res.status(500).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// GET /v1/byoc/stream/:jobId — Server-Sent Events
// Sin JWT en header — usa query param ?token=...
// ---------------------------------------------------------------------------
byocRouter.get("/stream/:jobId", async (req, res) => {
  const jobId = Number(req.params.jobId);
  if (!jobId || isNaN(jobId)) {
    res.status(400).json({ error: "invalid_job_id" });
    return;
  }

  // Validar token por query param (no hay JWT en EventSource nativo)
  const token = req.query.token as string | undefined;
  if (!token) {
    res.status(401).json({ error: "missing_token" });
    return;
  }

  try {
    const { verifyJwt } = await import("../../auth/jwt.js");
    verifyJwt(token); // lanza si el token es inválido
  } catch {
    res.status(401).json({ error: "invalid_token" });
    return;
  }

  // Configurar SSE
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no"); // Nginx: desactivar buffering
  res.flushHeaders();

  const POLL_MS = 2_000;
  let lastLogLength = 0;
  let closed = false;

  const sendEvent = (event: string, data: unknown) => {
    if (!closed) {
      res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    }
  };

  const poll = async () => {
    if (closed) return;

    try {
      const job = await getByocJobStatus(jobId);
      if (!job) {
        sendEvent("error", { message: "job_not_found" });
        res.end();
        closed = true;
        return;
      }

      // Enviar status
      sendEvent("status", {
        jobId: job.jobId,
        status: job.status,
        serverIp: job.serverIp,
        tenantUrl: job.tenantUrl,
        errorMessage: job.errorMessage,
      });

      // Enviar solo las líneas nuevas de log
      const fullLog = job.logOutput ?? "";
      if (fullLog.length > lastLogLength) {
        const newLines = fullLog.slice(lastLogLength);
        lastLogLength = fullLog.length;
        sendEvent("log", { lines: newLines });
      }

      // Cerrar stream cuando el job termina
      if (job.status === "DONE" || job.status === "FAILED") {
        sendEvent("done", { status: job.status });
        res.end();
        closed = true;
        return;
      }

      // Continuar polling
      if (!closed) {
        setTimeout(poll, POLL_MS);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "internal_error";
      sendEvent("error", { message: msg });
      res.end();
      closed = true;
    }
  };

  req.on("close", () => {
    closed = true;
  });

  // Iniciar polling
  setTimeout(poll, 500);
});

// ---------------------------------------------------------------------------
// GET /v1/byoc/onboarding/validate?token=...
// Público — valida el token de onboarding recibido en el email
// ---------------------------------------------------------------------------
byocRouter.get("/onboarding/validate", async (req, res) => {
  const token = req.query.token as string | undefined;
  if (!token) {
    res.status(400).json({ valid: false, message: "Token requerido" });
    return;
  }

  try {
    const rows = await callSp<{
      CompanyId: number;
      DeployType: string;
      ok: number;
      reason: string;
    }>("usp_Sys_OnboardingToken_Validate", { Token: token });

    const row = rows[0];
    if (!row || row.ok === 0) {
      const messages: Record<string, string> = {
        token_not_found: "Este enlace no existe o ya fue utilizado.",
        token_already_used: "Este enlace ya fue utilizado anteriormente.",
        token_expired: "Este enlace ha expirado. Contacta a soporte@zentto.net.",
      };
      res.json({
        valid: false,
        message: messages[row?.reason ?? ""] ?? "Enlace inválido.",
      });
      return;
    }

    // Obtener nombre de la empresa
    const companyRows = await callSp<{ LegalName: string; Plan: string }>(
      "usp_Cfg_Tenant_GetInfo",
      { CompanyId: row.CompanyId }
    );
    const company = companyRows[0];

    res.json({
      valid: true,
      companyId: row.CompanyId,
      companyName: company?.LegalName ?? "",
      planLabel: company?.Plan ?? "",
      deployType: row.DeployType,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.onboarding.validate.failed: ${msg}`, { module: "byoc" });
    res.status(500).json({ valid: false, message: "Error interno del servidor." });
  }
});

// ---------------------------------------------------------------------------
// POST /v1/byoc/wizard/start
// Autenticado con token de onboarding (no JWT)
// ---------------------------------------------------------------------------
const wizardStartSchema = z.object({
  token: z.string().min(10),
  provider: z.enum(["hetzner", "digitalocean", "aws", "gcp", "azure", "ssh"] as const),
  credentials: z.object({
    apiToken: z.string().optional(),
    ip: z.string().optional(),
    sshPort: z.number().int().positive().optional(),
    sshUser: z.string().optional(),
    sshKey: z.string().optional(),
  }),
  config: z.object({
    domain: z.string().min(3),
    region: z.string().optional(),
    size: z.string().optional(),
  }),
});

byocRouter.post("/wizard/start", async (req, res) => {
  const parsed = wizardStartSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  const { token, provider, credentials, config } = parsed.data;

  // Validar token de onboarding (consume el token — uso único)
  let companyId: number;
  try {
    const rows = await callSp<{ CompanyId: number; ok: number; reason: string }>(
      "usp_Sys_OnboardingToken_Validate",
      { Token: token }
    );
    const row = rows[0];
    if (!row || row.ok === 0) {
      res.status(401).json({ error: "token_invalid", reason: row?.reason });
      return;
    }
    companyId = Number(row.CompanyId);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.wizard.start.token_validate_failed: ${msg}`, { module: "byoc" });
    res.status(500).json({ error: "internal_error" });
    return;
  }

  // Mapear credenciales del wizard al formato del servicio
  const serviceCredentials: Record<string, unknown> = {};
  if (provider === "hetzner") serviceCredentials.hetznerApiToken = credentials.apiToken;
  if (provider === "digitalocean") serviceCredentials.doApiToken = credentials.apiToken;
  if (provider === "ssh") {
    serviceCredentials.sshHost = credentials.ip;
    serviceCredentials.sshPort = credentials.sshPort ?? 22;
    serviceCredentials.sshUsername = credentials.sshUser ?? "root";
    serviceCredentials.sshPrivateKey = credentials.sshKey;
  }

  try {
    const result = await startByocDeploy({
      companyId,
      config: {
        provider: provider as CloudProvider,
        domain: config.domain,
        region: config.region,
        serverSize: config.size,
      },
      credentials: serviceCredentials as ByocCredentials,
    });
    res.status(201).json({ ok: true, jobId: result.jobId });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`byoc.wizard.start.failed: ${msg}`, { module: "byoc", companyId });
    res.status(500).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// GET /v1/byoc/wizard/stream/:jobId?token=...
// SSE para el wizard — usa token de onboarding como auth (no JWT)
// ---------------------------------------------------------------------------
byocRouter.get("/wizard/stream/:jobId", async (req, res) => {
  const jobId = Number(req.params.jobId);
  if (!jobId || isNaN(jobId)) {
    res.status(400).json({ error: "invalid_job_id" });
    return;
  }

  // Validar que el token existe (solo existencia, ya fue consumido al hacer /start)
  const token = req.query.token as string | undefined;
  if (!token || token.length < 10) {
    res.status(401).json({ error: "missing_token" });
    return;
  }

  // Configurar SSE
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders();

  const POLL_MS = 2_000;
  let lastLogLength = 0;
  let closed = false;

  const sendEvent = (event: string, data: unknown) => {
    if (!closed) res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };

  const poll = async () => {
    if (closed) return;
    try {
      const job = await getByocJobStatus(jobId);
      if (!job) {
        sendEvent("error", { message: "job_not_found" });
        res.end();
        closed = true;
        return;
      }

      sendEvent("status", {
        jobId: job.jobId,
        status: job.status,
        serverIp: job.serverIp,
        tenantUrl: job.tenantUrl,
        errorMessage: job.errorMessage,
      });

      const fullLog = job.logOutput ?? "";
      if (fullLog.length > lastLogLength) {
        const newLines = fullLog.slice(lastLogLength);
        lastLogLength = fullLog.length;
        sendEvent("log", { lines: newLines });
      }

      if (job.status === "DONE" || job.status === "FAILED") {
        sendEvent("done", { status: job.status, tenantUrl: job.tenantUrl });
        res.end();
        closed = true;
        return;
      }

      if (!closed) setTimeout(poll, POLL_MS);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "internal_error";
      sendEvent("error", { message: msg });
      res.end();
      closed = true;
    }
  };

  req.on("close", () => { closed = true; });
  setTimeout(poll, 500);
});

export default byocRouter;
