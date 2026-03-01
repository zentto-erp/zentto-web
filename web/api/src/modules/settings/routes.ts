import { Router } from "express";
import {
  getAllSettings,
  getModuleSettings,
  getModuleSettingsWithMeta,
  saveModuleSettings,
  listSettingModules,
} from "./service.js";

export const settingsRouter = Router();

/**
 * GET /v1/settings
 * Returns ALL settings grouped by module.
 * Query: ?companyId=1
 */
settingsRouter.get("/", async (req, res) => {
  try {
    const companyId = Number(req.query.companyId) || 1;
    const data = await getAllSettings(companyId);
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/settings/modules
 * List distinct module names with settings.
 */
settingsRouter.get("/modules", async (req, res) => {
  try {
    const companyId = Number(req.query.companyId) || 1;
    const modules = await listSettingModules(companyId);
    res.json(modules);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/settings/:module
 * Returns settings for a single module.
 * Query: ?companyId=1&meta=true (meta returns full metadata)
 */
settingsRouter.get("/:module", async (req, res) => {
  try {
    const companyId = Number(req.query.companyId) || 1;
    const moduleName = req.params.module;
    const wantMeta = req.query.meta === "true";

    if (wantMeta) {
      const data = await getModuleSettingsWithMeta(companyId, moduleName);
      return res.json(data);
    }

    const data = await getModuleSettings(companyId, moduleName);
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /v1/settings/:module
 * Bulk-save settings for a module.
 * Body: { key1: value1, key2: value2, ... }
 */
settingsRouter.put("/:module", async (req, res) => {
  try {
    const companyId = Number(req.query.companyId) || 1;
    const moduleName = req.params.module;
    const userId = (req as any).userId ?? null;
    const result = await saveModuleSettings(companyId, moduleName, req.body, userId);
    res.json({ success: true, ...result });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
