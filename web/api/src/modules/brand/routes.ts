import { Router } from "express";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import { getBrandConfig, upsertBrandConfig } from "./service.js";

export const brandRouter = Router();

/**
 * GET /v1/brand/config
 * Público (dentro del scope JWT) — devuelve la config de marca del tenant.
 * Cache de 60s en el service.
 */
brandRouter.get("/config", async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const companyId = authReq.scope?.companyId ?? 1;
    const config = await getBrandConfig(companyId);

    if (!config) {
      // Devolver defaults — no es error
      return res.json({
        CompanyId: companyId,
        LogoUrl: "",
        FaviconUrl: "",
        PrimaryColor: "#FFB547",
        SecondaryColor: "#232f3e",
        AccentColor: "#FFB547",
        AppName: "",
        SupportEmail: "",
        SupportPhone: "",
        CustomDomain: "",
        CustomCss: "",
        FooterText: "",
        LoginBgUrl: "",
        IsActive: true,
      });
    }

    res.json(config);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /v1/brand/config
 * Admin — upsert de la config de marca del tenant.
 */
brandRouter.put("/config", async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const companyId = authReq.scope?.companyId ?? 1;
    const result = await upsertBrandConfig(companyId, req.body);
    res.json({ success: result.ok, message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
