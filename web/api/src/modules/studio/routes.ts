/**
 * studio/routes.ts — Studio Addons API
 *
 * GET    /v1/studio/addons                    Lista addons de la empresa
 * GET    /v1/studio/addons/:addonId           Obtener addon con config
 * POST   /v1/studio/addons                    Crear addon
 * PUT    /v1/studio/addons/:addonId           Actualizar addon
 * DELETE /v1/studio/addons/:addonId           Soft delete
 * GET    /v1/studio/addons/module/:moduleId   Addons visibles en un módulo
 */

import { Router } from "express";
import { z } from "zod";
import { callSp } from "../../db/query.js";
import { requireAdmin } from "../../middleware/auth.js";
import type { AuthenticatedRequest } from "../../middleware/auth.js";

export const studioRouter = Router();

// ── Schemas de validación ────────────────────────────────────────────────────

const listQuerySchema = z.object({
  moduleId: z.string().optional(),
  page:     z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(50),
});

const saveSchema = z.object({
  title:       z.string().min(1).max(200),
  description: z.string().max(500).nullable().optional(),
  icon:        z.string().max(10).nullable().optional(),
  modules:     z.array(z.string().min(1).max(50)).default([]),
  config:      z.record(z.unknown()),
});

// ── Tipos ────────────────────────────────────────────────────────────────────

interface AddonListRow {
  AddonId: string;
  Title: string;
  Description: string | null;
  Icon: string | null;
  Modules: string | null;
  CreatedBy: number;
  CreatedAt: string;
  UpdatedAt: string;
  TotalCount: number;
}

interface AddonDetailRow extends AddonListRow {
  Config: string;
}

interface SaveResult {
  ok: boolean;
  mensaje: string;
  AddonId: string;
}

interface DeleteResult {
  ok: boolean;
  mensaje: string;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function parseModules(modulesStr: string | null): string[] {
  if (!modulesStr) return [];
  return modulesStr.split(",").map((m) => m.trim()).filter(Boolean);
}

function formatAddon(row: AddonListRow) {
  const { TotalCount: _, Modules, ...rest } = row;
  return { ...rest, modules: parseModules(Modules) };
}

// ── GET /addons/module/:moduleId — Addons de un módulo específico ────────────
// IMPORTANTE: esta ruta va ANTES de /addons/:addonId para que no capture "module" como addonId

studioRouter.get("/addons/module/:moduleId", async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  const moduleId = req.params.moduleId;

  try {
    const rows = await callSp<AddonListRow>("usp_zsys_StudioAddon_List", {
      CompanyId: companyId,
      ModuleId:  moduleId,
      Page:      1,
      PageSize:  100,
    });

    res.json({
      data: rows.map(formatAddon),
      totalCount: rows[0]?.TotalCount ?? 0,
    });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ── GET /addons — Lista todos los addons de la empresa ───────────────────────

studioRouter.get("/addons", async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });

  const { moduleId, page, pageSize } = parsed.data;

  try {
    const rows = await callSp<AddonListRow>("usp_zsys_StudioAddon_List", {
      CompanyId: companyId,
      ModuleId:  moduleId ?? null,
      Page:      page,
      PageSize:  pageSize,
    });

    const total = rows[0]?.TotalCount ?? 0;
    res.json({
      data: rows.map(formatAddon),
      totalCount: total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ── GET /addons/:addonId — Obtener addon con config ──────────────────────────

studioRouter.get("/addons/:addonId", async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  try {
    const rows = await callSp<AddonDetailRow>("usp_zsys_StudioAddon_Get", {
      CompanyId: companyId,
      AddonId:   req.params.addonId,
    });

    const row = rows[0];
    if (!row) return res.status(404).json({ error: "addon_not_found" });

    let config: unknown = {};
    try { config = JSON.parse(row.Config); } catch { config = {}; }

    res.json({
      data: {
        ...formatAddon(row),
        config,
      },
    });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ── POST /addons — Crear addon (solo admin) ──────────────────────────────────

studioRouter.post("/addons", requireAdmin, async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  const userId = parseInt(String(authReq.user?.sub ?? "0"), 10) || 0;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  const parsed = saveSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });

  const { title, description, icon, modules, config } = parsed.data;
  const addonId = `addon-${Date.now()}`;

  try {
    const rows = await callSp<SaveResult>("usp_zsys_StudioAddon_Save", {
      CompanyId:  companyId,
      AddonId:    addonId,
      Title:      title,
      Description: description ?? null,
      Icon:       icon ?? null,
      Config:     JSON.stringify(config),
      CreatedBy:  userId,
      Modules:    modules.join(",") || null,
    });

    const result = rows[0];
    if (!result?.ok) return res.status(400).json({ ok: false, mensaje: result?.mensaje ?? "Error" });

    res.status(201).json({
      ok: true,
      mensaje: result.mensaje,
      data: {
        addonId,
        title,
        modules,
        createdAt: new Date().toISOString(),
      },
    });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ── PUT /addons/:addonId — Actualizar addon (solo admin) ─────────────────────

studioRouter.put("/addons/:addonId", requireAdmin, async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  const userId = parseInt(String(authReq.user?.sub ?? "0"), 10) || 0;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  const parsed = saveSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });

  const { title, description, icon, modules, config } = parsed.data;

  try {
    const rows = await callSp<SaveResult>("usp_zsys_StudioAddon_Save", {
      CompanyId:  companyId,
      AddonId:    req.params.addonId,
      Title:      title,
      Description: description ?? null,
      Icon:       icon ?? null,
      Config:     JSON.stringify(config),
      CreatedBy:  userId,
      Modules:    modules.join(",") || null,
    });

    const result = rows[0];
    if (!result?.ok) return res.status(400).json({ ok: false, mensaje: result?.mensaje ?? "Error" });

    res.json({ ok: true, mensaje: result.mensaje });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ── DELETE /addons/:addonId — Soft delete (solo admin) ───────────────────────

studioRouter.delete("/addons/:addonId", requireAdmin, async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  const companyId = authReq.scope?.companyId;
  if (!companyId) return res.status(403).json({ error: "no_scope" });

  try {
    const rows = await callSp<DeleteResult>("usp_zsys_StudioAddon_Delete", {
      CompanyId: companyId,
      AddonId:   req.params.addonId,
    });

    const result = rows[0];
    if (!result?.ok) return res.status(404).json({ ok: false, mensaje: result?.mensaje ?? "No encontrado" });

    res.json({ ok: true, mensaje: result.mensaje });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});
