/**
 * backoffice.routes.ts — Backoffice Zentto para gestión de clientes/tenants
 *
 * Todos los endpoints requieren X-Master-Key.
 *
 * GET    /v1/backoffice/tenants                         Lista tenants con licencia
 * GET    /v1/backoffice/tenants/:companyId              Detalle de un tenant
 * GET    /v1/backoffice/revenue                         Métricas de revenue
 * POST   /v1/backoffice/tenants/:companyId/apply-plan   Aplica módulos del plan
 */
import { Router } from "express";
import { z } from "zod";
import { requireMasterKey } from "../../middleware/master-key.js";
import { callSp } from "../../db/query.js";
import { applyPlanModules, getLicenseByCompany } from "../license/license.service.js";
import { obs } from "../integrations/observability.js";

const backofficeRouter = Router();

// Todos los endpoints de backoffice requieren master key
backofficeRouter.use(requireMasterKey);

// ── Schemas ───────────────────────────────────────────────────────────────────

const tenantListQuerySchema = z.object({
  page:     z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  status:   z.string().optional(),
  plan:     z.string().optional(),
  search:   z.string().optional(),
});

const applyPlanSchema = z.object({
  plan: z.enum(['FREE', 'STARTER', 'PRO', 'ENTERPRISE']),
});

// ── Tipos internos ────────────────────────────────────────────────────────────

interface TenantListRow {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  Plan: string;
  LicenseType: string | null;
  LicenseStatus: string | null;
  ExpiresAt: string | null;
  CreatedAt: string;
  UserCount: number;
  LastLogin: string | null;
  TotalCount: number;
}

interface TenantDetailRow {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  TradeName: string | null;
  OwnerEmail: string | null;
  FiscalCountryCode: string;
  BaseCurrency: string;
  Plan: string;
  LicenseType: string | null;
  LicenseStatus: string | null;
  LicenseKey: string | null;
  ExpiresAt: string | null;
  PaddleSubId: string | null;
  ContractRef: string | null;
  MaxUsers: number | null;
  CreatedAt: string;
  UpdatedAt: string | null;
  UserCount: number;
  LastLogin: string | null;
  TenantSubdomain: string | null;
  TenantStatus: string | null;
}

interface RevenueRow {
  Plan: string;
  LicenseType: string;
  TenantCount: number;
  EstimatedMRR: number;
}

// ── GET /tenants ──────────────────────────────────────────────────────────────

backofficeRouter.get("/tenants", async (req, res) => {
  const parsed = tenantListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  const { page, pageSize, status, plan, search } = parsed.data;

  try {
    const rows = await callSp<TenantListRow>(
      "usp_Sys_Backoffice_TenantList",
      {
        Page:     page,
        PageSize: pageSize,
        Status:   status ?? null,
        Plan:     plan ?? null,
        Search:   search ?? null,
      }
    );

    const total = rows[0]?.TotalCount ?? 0;
    res.json({
      ok: true,
      data: rows.map(({ TotalCount: _tc, ...rest }) => rest),
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.tenants.list.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── GET /tenants/:companyId ───────────────────────────────────────────────────

backofficeRouter.get("/tenants/:companyId", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: 'invalid_company_id' });
    return;
  }

  try {
    const rows = await callSp<TenantDetailRow>(
      "usp_Sys_Backoffice_TenantDetail",
      { CompanyId: companyId }
    );

    const tenant = rows[0];
    if (!tenant) {
      res.status(404).json({ error: 'tenant_not_found' });
      return;
    }

    res.json({ ok: true, data: tenant });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.tenants.detail.failed: ${msg}`, { module: 'backoffice', companyId });
    res.status(500).json({ error: msg });
  }
});

// ── GET /revenue ──────────────────────────────────────────────────────────────

backofficeRouter.get("/revenue", async (_req, res) => {
  try {
    const rows = await callSp<RevenueRow>(
      "usp_Sys_Backoffice_RevenueMetrics",
      {}
    );

    // Calcular totales agregados
    const totalMRR = rows.reduce((sum, r) => sum + (r.EstimatedMRR ?? 0), 0);
    const totalTenants = rows.reduce((sum, r) => sum + (r.TenantCount ?? 0), 0);

    res.json({
      ok: true,
      data: rows,
      summary: { totalMRR, totalTenants },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.revenue.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── POST /tenants/:companyId/apply-plan ───────────────────────────────────────

backofficeRouter.post("/tenants/:companyId/apply-plan", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: 'invalid_company_id' });
    return;
  }

  const parsed = applyPlanSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  try {
    const result = await applyPlanModules(companyId, parsed.data.plan);
    res.json({ ok: true, modulesApplied: result.modulesApplied });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.apply_plan.failed: ${msg}`, { module: 'backoffice', companyId });
    res.status(500).json({ error: msg });
  }
});

export default backofficeRouter;
