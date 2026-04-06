import { Router } from "express";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import {
  applyPartner,
  getPartnerByEmail,
  listPartnerReferrals,
  getPartnerDashboard,
} from "./service.js";

export const partnersRouter = Router();

/**
 * POST /v1/partners/apply
 * Publico — solicitar ser partner.
 */
partnersRouter.post("/apply", async (req, res) => {
  try {
    const { companyName, contactName, email, phone } = req.body;
    if (!companyName || !contactName || !email) {
      return res.status(400).json({ error: "companyName, contactName y email son requeridos" });
    }
    const result = await applyPartner({ companyName, contactName, email, phone });
    res.json({ success: result.ok, message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/partners/me
 * Autenticado — mi perfil de partner (por email del JWT).
 */
partnersRouter.get("/me", async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const email = authReq.user?.email;
    if (!email) {
      return res.status(401).json({ error: "No se pudo obtener el email del token" });
    }
    const partner = await getPartnerByEmail(email);
    if (!partner) {
      return res.status(404).json({ error: "No eres partner registrado" });
    }
    res.json(partner);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/partners/referrals
 * Autenticado — listar mis referidos.
 */
partnersRouter.get("/referrals", async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const email = authReq.user?.email;
    if (!email) {
      return res.status(401).json({ error: "No se pudo obtener el email del token" });
    }
    const partner = await getPartnerByEmail(email);
    if (!partner) {
      return res.status(404).json({ error: "No eres partner registrado" });
    }
    const referrals = await listPartnerReferrals(partner.PartnerId);
    res.json(referrals);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/partners/dashboard
 * Autenticado — KPIs del partner.
 */
partnersRouter.get("/dashboard", async (req, res) => {
  try {
    const authReq = req as AuthenticatedRequest;
    const email = authReq.user?.email;
    if (!email) {
      return res.status(401).json({ error: "No se pudo obtener el email del token" });
    }
    const partner = await getPartnerByEmail(email);
    if (!partner) {
      return res.status(404).json({ error: "No eres partner registrado" });
    }
    const dashboard = await getPartnerDashboard(partner.PartnerId);
    res.json(dashboard);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
