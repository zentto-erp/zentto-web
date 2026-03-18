import { Router } from "express";
import { z } from "zod";
import crypto from "node:crypto";
import { provisionTenant, getTenantInfo, sendWelcomeEmail, resolveTenantBySubdomain, resolveTenantByEmail } from "./tenant.service.js";

export const tenantsRouter = Router();

function requireMasterKey(
  req: import("express").Request,
  res: import("express").Response,
  next: import("express").NextFunction
): void {
  const key = req.headers["x-master-key"] as string | undefined;
  const expected = process.env.MASTER_API_KEY;
  if (
    !expected ||
    !key ||
    key.length !== expected.length ||
    !crypto.timingSafeEqual(Buffer.from(key), Buffer.from(expected))
  ) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }
  next();
}

const provisionSchema = z.object({
  companyCode:          z.string().min(3).max(20).regex(/^[A-Z0-9_-]+$/i, "Solo letras, números, guiones"),
  legalName:            z.string().min(3).max(200),
  ownerEmail:           z.string().email(),
  countryCode:          z.string().length(2),
  baseCurrency:         z.string().length(3),
  adminUserCode:        z.string().min(3).max(40).optional(),
  adminPassword:        z.string().min(8),
  plan:                 z.enum(["FREE", "STARTER", "PRO", "ENTERPRISE"]).default("STARTER"),
  paddleSubscriptionId: z.string().optional(),
});

// POST /api/tenants/provision
tenantsRouter.post("/provision", requireMasterKey, async (req, res) => {
  const parsed = provisionSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  const data = parsed.data;
  // adminUserCode default: email normalizado
  const adminUserCode = data.adminUserCode
    ?? data.ownerEmail.split("@")[0].toUpperCase().slice(0, 40);

  try {
    const result = await provisionTenant({ ...data, adminUserCode });

    if (!result.ok) {
      res.status(409).json({ error: result.mensaje });
      return;
    }

    // Enviar email de bienvenida (no bloquea la respuesta)
    sendWelcomeEmail(data.ownerEmail, data.legalName, data.adminPassword, result.companyId).catch(() => {});

    res.status(201).json({
      ok: true,
      companyId: result.companyId,
      userId: result.userId,
      mensaje: result.mensaje,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    res.status(500).json({ error: msg });
  }
});

// GET /api/tenants/resolve-by-email/:email — Publico (para billing success page)
tenantsRouter.get("/resolve-by-email/:email", async (req, res) => {
  const email = decodeURIComponent(req.params.email || "").toLowerCase().trim();
  if (!email || !email.includes("@")) {
    res.status(400).json({ error: "invalid_email" });
    return;
  }
  const tenant = await resolveTenantByEmail(email);
  if (!tenant) {
    res.status(404).json({ error: "tenant_not_found" });
    return;
  }
  // No exponer datos sensibles
  res.json({
    CompanyId: tenant.CompanyId,
    CompanyCode: tenant.CompanyCode,
    LegalName: tenant.LegalName,
    OwnerEmail: tenant.OwnerEmail,
    Plan: tenant.Plan,
    TenantStatus: tenant.TenantStatus,
    TenantSubdomain: tenant.TenantSubdomain,
  });
});

// GET /api/tenants/resolve/:subdomain — Publico (para routing multi-tenant)
tenantsRouter.get("/resolve/:subdomain", async (req, res) => {
  const subdomain = req.params.subdomain?.toLowerCase().trim();
  if (!subdomain || subdomain.length < 3) {
    res.status(400).json({ error: "invalid_subdomain" });
    return;
  }
  const tenant = await resolveTenantBySubdomain(subdomain);
  if (!tenant) {
    res.status(404).json({ error: "tenant_not_found" });
    return;
  }
  res.json(tenant);
});

// GET /api/tenants/:companyId
tenantsRouter.get("/:companyId", requireMasterKey, async (req, res) => {
  const id = Number(req.params.companyId);
  if (!id || isNaN(id)) {
    res.status(400).json({ error: "invalid_company_id" });
    return;
  }
  const info = await getTenantInfo(id);
  if (!info) {
    res.status(404).json({ error: "not_found" });
    return;
  }
  res.json(info);
});
