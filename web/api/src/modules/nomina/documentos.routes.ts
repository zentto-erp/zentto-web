/**
 * Rutas de Plantillas de Documentos de Nómina
 */
import { Router } from "express";
import { z } from "zod";
import { requireJwt } from "../../middleware/auth.js";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import * as documentosService from "./documentos.service.js";

const router = Router();

// ─── Esquemas de validación ───────────────────────────────────────────────────

const saveTemplateSchema = z.object({
  templateCode: z.string().min(1).max(50),
  templateName: z.string().min(1).max(150),
  templateType: z.string().min(1).max(50),
  countryCode: z.string().min(1).max(10),
  payrollCode: z.string().max(50).optional(),
  contentMD: z.string().min(1),
  isDefault: z.boolean().optional(),
});

const renderSchema = z.object({
  payrollRunId: z.number().int().positive().optional(),
  batchId: z.number().int().positive().optional(),
  employeeCode: z.string().optional(),
}).refine(d => d.payrollRunId || (d.batchId && d.employeeCode), {
  message: 'Se requiere payrollRunId o (batchId + employeeCode)'
});

// ─── Rutas ────────────────────────────────────────────────────────────────────

// GET /v1/nomina/documentos/templates
router.get("/templates", requireJwt, async (req: AuthenticatedRequest, res) => {
  try {
    const companyId = Number(req.user?.companyId);
    const rows = await documentosService.listDocumentTemplates(
      companyId,
      req.query.countryCode as string | undefined,
      req.query.templateType as string | undefined
    );
    const data = rows.map((r: any) => ({
      templateId: r.TemplateId,
      templateCode: r.TemplateCode,
      templateName: r.TemplateName,
      templateType: r.TemplateType,
      countryCode: r.CountryCode,
      payrollCode: r.PayrollCode ?? null,
      isDefault: !!r.IsDefault,
      isSystem: !!r.IsSystem,
      isActive: !!r.IsActive,
      updatedAt: r.UpdatedAt,
    }));
    res.json({ data });
  } catch (err: any) {
    res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/nomina/documentos/templates/vars/batch/:batchId/:employeeCode
// IMPORTANTE: registrada antes de /templates/:code para evitar que :code capture "vars"
router.get("/templates/vars/batch/:batchId/:employeeCode", requireJwt, async (req: AuthenticatedRequest, res) => {
  const batchId = parseInt(req.params.batchId);
  const { employeeCode } = req.params;
  if (isNaN(batchId) || batchId <= 0) {
    return res.status(400).json({ error: "batchId_invalido" });
  }

  try {
    const companyId = Number(req.user?.companyId);
    const vars = await documentosService.getTemplateVariablesFromBatch(companyId, batchId, employeeCode);
    res.json({ vars });
  } catch (err: any) {
    res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/nomina/documentos/templates/:code
router.get("/templates/:code", requireJwt, async (req: AuthenticatedRequest, res) => {
  try {
    const companyId = Number(req.user?.companyId);
    const r = await documentosService.getDocumentTemplate(companyId, req.params.code);
    res.json({
      templateId: r.TemplateId,
      templateCode: r.TemplateCode,
      templateName: r.TemplateName,
      templateType: r.TemplateType,
      countryCode: r.CountryCode,
      payrollCode: r.PayrollCode ?? null,
      contentMD: r.ContentMD,
      isDefault: !!r.IsDefault,
      isSystem: !!r.IsSystem,
      isActive: !!r.IsActive,
      createdAt: r.CreatedAt,
      updatedAt: r.UpdatedAt,
    });
  } catch (err: any) {
    const status = err.statusCode === 404 ? 404 : 500;
    res.status(status).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/nomina/documentos/templates
router.post("/templates", requireJwt, async (req: AuthenticatedRequest, res) => {
  const parsed = saveTemplateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const companyId = Number(req.user?.companyId);
    const result = await documentosService.saveDocumentTemplate(companyId, parsed.data);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/nomina/documentos/templates/:code
router.delete("/templates/:code", requireJwt, async (req: AuthenticatedRequest, res) => {
  try {
    const companyId = Number(req.user?.companyId);
    const result = await documentosService.deleteDocumentTemplate(companyId, req.params.code);
    res.status(result.success ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/nomina/documentos/templates/:code/render
router.post("/templates/:code/render", requireJwt, async (req: AuthenticatedRequest, res) => {
  const parsed = renderSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  try {
    const companyId = Number(req.user?.companyId);
    const result = await documentosService.renderTemplate(
      companyId,
      req.params.code,
      { payrollRunId: parsed.data.payrollRunId, batchId: parsed.data.batchId, employeeCode: parsed.data.employeeCode }
    );
    res.json(result);
  } catch (err: any) {
    const status = err.statusCode === 404 ? 404 : 500;
    res.status(status).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/nomina/documentos/templates/:code/vars/:runId
router.get("/templates/:code/vars/:runId", requireJwt, async (req: AuthenticatedRequest, res) => {
  const runId = parseInt(req.params.runId, 10);
  if (isNaN(runId) || runId <= 0) {
    return res.status(400).json({ error: "runId_invalido" });
  }

  try {
    const companyId = Number(req.user?.companyId);
    const vars = await documentosService.getTemplateVariables(companyId, runId);
    res.json({ vars });
  } catch (err: any) {
    res.status(500).json({ error: String(err.message ?? err) });
  }
});

export default router;
