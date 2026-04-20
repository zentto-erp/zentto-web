/**
 * affiliate.routes.ts — Endpoints REST del programa de afiliados.
 *
 * Públicos (sin auth):
 *   GET    /store/affiliate/commission-rates    → tasas por categoría
 *   POST   /store/affiliate/track-click         → track click anónimo
 *   GET    /store/affiliate/link/:code          → redirige a / con cookie zentto_ref 30d
 *
 * Autenticados (cliente):
 *   POST   /store/affiliate/register            → aplicar al programa
 *   GET    /store/affiliate/dashboard           → stats + referral link
 *   GET    /store/affiliate/commissions         → lista paginada de comisiones
 *
 * Admin (requireJwt + isAdmin):
 *   GET    /store/admin/affiliates
 *   POST   /store/admin/affiliates/:id/status   { status }
 *   GET    /store/admin/affiliates/commissions
 *   POST   /store/admin/affiliates/payouts/generate
 */

import { Router } from "express";
import { z } from "zod";
import { requireJwt, type AuthenticatedRequest } from "../../middleware/auth.js";
import { verifyCustomerToken } from "./service.js";
import {
  registerAffiliate,
  getAffiliateDashboard,
  trackAffiliateClick,
  listMyCommissions,
  listCommissionRates,
  adminListAffiliates,
  adminSetAffiliateStatus,
  adminListCommissions,
  adminGeneratePayouts,
  adminBulkSetCommissionStatus,
} from "./affiliate.service.js";

export const affiliateRouter = Router();

// ─── Público ───────────────────────────────────────────

affiliateRouter.get("/affiliate/commission-rates", async (_req, res) => {
  try {
    const rows = await listCommissionRates();
    res.json({ rows });
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const trackClickSchema = z.object({
  referralCode: z.string().min(3).max(20),
  sessionId: z.string().max(100).optional(),
  referer: z.string().max(500).optional(),
});

affiliateRouter.post("/affiliate/track-click", async (req, res) => {
  try {
    const parsed = trackClickSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });

    const ip = (req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0]?.trim()
      || req.socket.remoteAddress
      || null;
    const userAgent = (req.headers["user-agent"] as string | undefined) || null;

    const result = await trackAffiliateClick({
      referralCode: parsed.data.referralCode,
      sessionId: parsed.data.sessionId ?? null,
      ip,
      userAgent,
      referer: parsed.data.referer ?? null,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

/**
 * Redirect con cookie de atribución de 30 días.
 * GET /store/affiliate/link/:referralCode
 *   → 302 → FRONTEND_URL con cookie `zentto_ref=<code>` + track-click async.
 */
affiliateRouter.get("/affiliate/link/:referralCode", async (req, res) => {
  const code = String(req.params.referralCode || "").slice(0, 20);
  const target = process.env.PUBLIC_FRONTEND_URL || "https://app.zentto.net";

  try {
    const ip = (req.headers["x-forwarded-for"] as string | undefined)?.split(",")[0]?.trim()
      || req.socket.remoteAddress
      || null;
    const userAgent = (req.headers["user-agent"] as string | undefined) || null;
    const referer = (req.headers.referer as string | undefined) || null;
    // Leer cookie zentto_sid manualmente (la API no usa cookie-parser)
    const cookieHeader = req.headers.cookie ?? "";
    let sessionId: string | null = null;
    for (const part of cookieHeader.split(";")) {
      const t = part.trim();
      if (t.startsWith("zentto_sid=")) { sessionId = decodeURIComponent(t.slice("zentto_sid=".length)); break; }
    }

    // Track async (no bloquea redirect)
    trackAffiliateClick({ referralCode: code, sessionId, ip, userAgent, referer })
      .catch(() => { /* ignore */ });

    // Cookie httpOnly=false (frontend debe leerla para mandarla en checkout)
    const thirtyDays = 30 * 24 * 60 * 60 * 1000;
    res.cookie("zentto_ref", code, {
      maxAge: thirtyDays,
      sameSite: "lax",
      path: "/",
      secure: process.env.NODE_ENV === "production",
    });
    res.redirect(302, target);
  } catch {
    res.redirect(302, target);
  }
});

// ─── Authenticated cliente ─────────────────────────────

const registerSchema = z.object({
  legalName: z.string().min(2).max(200),
  taxId: z.string().max(40).optional(),
  contactEmail: z.string().email().max(200).optional(),
  payoutMethod: z.string().max(30).optional(),
  payoutDetails: z.record(z.unknown()).optional(),
});

affiliateRouter.post("/affiliate/register", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });

    const result = await registerAffiliate({
      customerId,
      legalName: parsed.data.legalName,
      taxId: parsed.data.taxId,
      contactEmail: parsed.data.contactEmail ?? (user as any).email,
      payoutMethod: parsed.data.payoutMethod,
      payoutDetails: parsed.data.payoutDetails as Record<string, unknown> | undefined,
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

affiliateRouter.get("/affiliate/dashboard", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const data = await getAffiliateDashboard(customerId);
    if (!data) return res.status(404).json({ error: "not_an_affiliate" });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

affiliateRouter.get("/affiliate/commissions", async (req, res) => {
  try {
    const user = await verifyCustomerToken(req.headers.authorization);
    if (!user) return res.status(401).json({ error: "not_authenticated" });
    const customerId = Number(user.sub);
    if (!Number.isFinite(customerId)) return res.status(400).json({ error: "invalid_customer" });

    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;

    const data = await listMyCommissions({ customerId, status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Admin ─────────────────────────────────────────────

affiliateRouter.get("/admin/affiliates", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });

    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await adminListAffiliates({ status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const adminSetStatusSchema = z.object({
  status: z.enum(["active", "suspended", "pending", "rejected"]),
});

affiliateRouter.post("/admin/affiliates/:id/status", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });

    const parsed = adminSetStatusSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });

    const affiliateId = Number(req.params.id);
    if (!Number.isFinite(affiliateId)) return res.status(400).json({ error: "invalid_id" });

    const result = await adminSetAffiliateStatus({
      affiliateId,
      status: parsed.data.status,
      actor: user.name || String(user.sub),
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// Shorthand: /approve y /suspend
affiliateRouter.post("/admin/affiliates/:id/approve", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const affiliateId = Number(req.params.id);
    const result = await adminSetAffiliateStatus({
      affiliateId,
      status: "active",
      actor: user.name || String(user.sub),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

affiliateRouter.post("/admin/affiliates/:id/suspend", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const affiliateId = Number(req.params.id);
    const result = await adminSetAffiliateStatus({
      affiliateId,
      status: "suspended",
      actor: user.name || String(user.sub),
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

affiliateRouter.get("/admin/affiliates/commissions", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const status = (req.query.status as string | undefined) || undefined;
    const page = req.query.page ? Number(req.query.page) : 1;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await adminListCommissions({ status, page, limit });
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

const generatePayoutsSchema = z.object({
  periodStart: z.string().optional(),
  periodEnd: z.string().optional(),
});

affiliateRouter.post("/admin/affiliates/payouts/generate", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const parsed = generatePayoutsSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_body" });
    const result = await adminGeneratePayouts({
      periodStart: parsed.data.periodStart ?? null,
      periodEnd: parsed.data.periodEnd ?? null,
    });
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});

// ─── Bulk status comisiones (Ola 4: liquidación mensual) ──
const bulkCommissionsSchema = z.object({
  ids: z.array(z.number().int().positive()).min(1).max(500),
  status: z.enum(["approved", "paid", "reversed"]),
});

affiliateRouter.post("/admin/affiliates/commissions/bulk-status", requireJwt, async (req, res) => {
  try {
    const user = (req as AuthenticatedRequest).user;
    if (!user?.isAdmin) return res.status(403).json({ error: "forbidden" });
    const parsed = bulkCommissionsSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", details: parsed.error.flatten() });
    const result = await adminBulkSetCommissionStatus({
      ids: parsed.data.ids,
      status: parsed.data.status,
      actor: user.name || String(user.sub),
    });
    if (!result.ok) return res.status(400).json(result);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: "server_error", message: err.message });
  }
});
