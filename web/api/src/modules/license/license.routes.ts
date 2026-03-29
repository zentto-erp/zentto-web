/**
 * license.routes.ts — Endpoints REST del módulo de licencias
 *
 * GET    /v1/license/validate              Valida licencia por code+key (público, BYOC)
 * POST   /v1/license                       Crear licencia (X-Master-Key)
 * DELETE /v1/license/:licenseId            Revocar licencia (X-Master-Key)
 * PATCH  /v1/license/:licenseId/renew      Renovar licencia (X-Master-Key)
 * GET    /v1/license/company/:companyId    Obtener licencia activa (X-Master-Key)
 */
import { Router } from "express";
import { z } from "zod";
import { requireMasterKey } from "../../middleware/master-key.js";
import {
  validateLicense,
  createLicense,
  revokeLicense,
  renewLicense,
  getLicenseByCompany,
} from "./license.service.js";
import { obs } from "../integrations/observability.js";

const licenseRouter = Router();

// ── Rate limiter en memoria (sin Redis) ───────────────────────────────────────
// Map<companyCode, { count, resetAt }>
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_MAX = 20;
const RATE_LIMIT_WINDOW_MS = 60_000;

function checkRateLimit(code: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(code);

  if (!entry || now >= entry.resetAt) {
    rateLimitMap.set(code, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }

  if (entry.count >= RATE_LIMIT_MAX) {
    return false;
  }

  entry.count += 1;
  return true;
}

// Limpiar entradas expiradas cada 5 minutos para evitar memory leak
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitMap.entries()) {
    if (now >= entry.resetAt) {
      rateLimitMap.delete(key);
    }
  }
}, 5 * 60_000);

// ── Schemas de validación ─────────────────────────────────────────────────────

const createLicenseSchema = z.object({
  companyId:   z.number().int().positive(),
  licenseType: z.enum(['SUBSCRIPTION', 'LIFETIME', 'CORPORATE', 'INTERNAL', 'TRIAL']),
  plan:        z.enum(['FREE', 'STARTER', 'PRO', 'ENTERPRISE']),
  expiresAt:   z.string().datetime().nullable().optional(),
  paddleSubId: z.string().max(200).nullable().optional(),
  contractRef: z.string().max(200).nullable().optional(),
  maxUsers:    z.number().int().positive().nullable().optional(),
  notes:       z.string().max(1000).nullable().optional(),
});

const revokeSchema = z.object({
  reason: z.string().min(1).max(500),
});

const renewSchema = z.object({
  newExpiresAt: z.string().datetime().nullable().optional(),
});

// ── GET /validate — público ───────────────────────────────────────────────────

licenseRouter.get("/validate", async (req, res) => {
  const code = String(req.query.code ?? '').trim();
  const key  = String(req.query.key  ?? '').trim();

  if (!code || !key) {
    res.json({ ok: false, reason: 'missing_params' });
    return;
  }

  // Rate limit por companyCode
  if (!checkRateLimit(code)) {
    res.json({ ok: false, reason: 'rate_limit_exceeded' });
    return;
  }

  const result = await validateLicense(code, key).catch((err: unknown) => {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.route.validate.failed: ${msg}`, { module: 'license', code });
    return { ok: false as const, reason: 'internal_error' };
  });

  res.json(result);
});

// ── POST / — crear licencia ───────────────────────────────────────────────────

licenseRouter.post("/", requireMasterKey, async (req, res) => {
  const parsed = createLicenseSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  const { companyId, licenseType, plan, expiresAt, paddleSubId, contractRef, maxUsers, notes } =
    parsed.data;

  try {
    const result = await createLicense({
      companyId,
      licenseType,
      plan,
      expiresAt:   expiresAt ? new Date(expiresAt) : null,
      paddleSubId: paddleSubId ?? null,
      contractRef: contractRef ?? null,
      maxUsers:    maxUsers ?? null,
      notes:       notes ?? null,
    });

    res.status(201).json({ ok: true, ...result });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.route.create.failed: ${msg}`, { module: 'license', companyId });
    res.status(500).json({ error: msg });
  }
});

// ── DELETE /:licenseId — revocar ──────────────────────────────────────────────

licenseRouter.delete("/:licenseId", requireMasterKey, async (req, res) => {
  const licenseId = Number(req.params.licenseId);
  if (!licenseId || isNaN(licenseId)) {
    res.status(400).json({ error: 'invalid_license_id' });
    return;
  }

  const parsed = revokeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  try {
    await revokeLicense(licenseId, parsed.data.reason);
    res.json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.route.revoke.failed: ${msg}`, { module: 'license', licenseId });
    res.status(500).json({ error: msg });
  }
});

// ── PATCH /:licenseId/renew — renovar ────────────────────────────────────────

licenseRouter.patch("/:licenseId/renew", requireMasterKey, async (req, res) => {
  const licenseId = Number(req.params.licenseId);
  if (!licenseId || isNaN(licenseId)) {
    res.status(400).json({ error: 'invalid_license_id' });
    return;
  }

  const parsed = renewSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  const newExpiresAt = parsed.data.newExpiresAt ? new Date(parsed.data.newExpiresAt) : null;

  try {
    await renewLicense(licenseId, newExpiresAt);
    res.json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.route.renew.failed: ${msg}`, { module: 'license', licenseId });
    res.status(500).json({ error: msg });
  }
});

// ── GET /company/:companyId — obtener licencia activa ─────────────────────────

licenseRouter.get("/company/:companyId", requireMasterKey, async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: 'invalid_company_id' });
    return;
  }

  try {
    const license = await getLicenseByCompany(companyId);
    if (!license) {
      res.status(404).json({ error: 'license_not_found' });
      return;
    }
    res.json({ ok: true, data: license });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`license.route.get_by_company.failed: ${msg}`, { module: 'license', companyId });
    res.status(500).json({ error: msg });
  }
});

export default licenseRouter;
