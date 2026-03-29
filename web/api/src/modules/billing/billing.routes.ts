/**
 * billing.routes.ts — Rutas de facturación SaaS (Paddle)
 *
 * Montado en /v1/billing
 */

import { Router } from "express";
import express from "express";
import { z } from "zod";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import { verifyPaddleWebhookSignature } from "./paddle.client.js";
import {
  getPlans,
  createCheckout,
  handleWebhookEvent,
  getSubscription,
  getPortalUrl,
  cancelSubscription,
} from "./billing.service.js";
import type { WebhookEvent } from "./billing.types.js";

export const billingRouter = Router();

// ── GET /plans — Planes disponibles (público dentro de /v1, requiere JWT) ────

billingRouter.get("/plans", (_req, res) => {
  res.json({ ok: true, data: getPlans() });
});

// ── GET /config — Token público de Paddle para el frontend ───────────────────

billingRouter.get("/config", (_req, res) => {
  const clientToken = process.env.PADDLE_CLIENT_TOKEN;
  if (!clientToken) {
    res.status(500).json({ error: "paddle_not_configured" });
    return;
  }
  res.json({
    ok: true,
    data: {
      clientToken,
      environment: "production",
      domain: "app.zentto.net",
    },
  });
});

// ── POST /checkout — Crear sesión de checkout ────────────────────────────────

const checkoutSchema = z.object({
  priceId: z.string().min(1, "priceId es requerido"),
  customerEmail: z.string().email("Email no válido"),
});

billingRouter.post("/checkout", async (req, res) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.companyId) {
    res.status(401).json({ error: "not_authenticated" });
    return;
  }

  const parsed = checkoutSchema.safeParse(req.body);
  if (!parsed.success) {
    res
      .status(400)
      .json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  try {
    const result = await createCheckout(
      user.companyId,
      parsed.data.priceId,
      parsed.data.customerEmail
    );
    res.json({ ok: true, data: result });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "error_interno";
    res.status(400).json({ error: msg });
  }
});

// ── POST /webhook — Webhook de Paddle (firma verificada, sin JWT) ────────────
// NOTA: Este endpoint necesita raw body. Se monta por separado en app.ts
//       ANTES de express.json(). Aquí definimos la lógica como export.

export const billingWebhookHandler = Router();

billingWebhookHandler.post(
  "/",
  express.raw({ type: "*/*" }),
  async (req, res) => {
    const signature = req.headers["paddle-signature"] as string | undefined;
    if (!signature) {
      res.status(400).json({ error: "firma_paddle_faltante" });
      return;
    }

    const rawBody = req.body as Buffer;

    if (!verifyPaddleWebhookSignature(rawBody, signature)) {
      res.status(401).json({ error: "firma_invalida" });
      return;
    }

    let event: WebhookEvent;
    try {
      event = JSON.parse(rawBody.toString("utf8")) as WebhookEvent;
    } catch {
      res.status(400).json({ error: "json_invalido" });
      return;
    }

    try {
      const result = await handleWebhookEvent(event);
      res.json({ ok: true, ...result });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "error_interno";
      console.error("[billing webhook] Error procesando evento:", msg);
      res.status(500).json({ error: msg });
    }
  }
);

// ── GET /subscription — Suscripción activa de la empresa autenticada ─────────

billingRouter.get("/subscription", async (req, res) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.companyId) {
    res.status(401).json({ error: "not_authenticated" });
    return;
  }

  try {
    const subscription = await getSubscription(user.companyId);
    res.json({ ok: true, data: subscription });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "error_interno";
    res.status(500).json({ error: msg });
  }
});

// ── POST /portal — URL del portal de cliente Paddle ──────────────────────────

const portalSchema = z.object({
  customerId: z.string().min(1, "customerId es requerido"),
});

billingRouter.post("/portal", async (req, res) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.companyId) {
    res.status(401).json({ error: "not_authenticated" });
    return;
  }

  const parsed = portalSchema.safeParse(req.body);
  if (!parsed.success) {
    res
      .status(400)
      .json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  try {
    const url = await getPortalUrl(parsed.data.customerId);
    res.json({ ok: true, data: { portalUrl: url } });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "error_interno";
    res.status(400).json({ error: msg });
  }
});

// ── POST /cancel — Cancelar suscripción ──────────────────────────────────────

const cancelSchema = z.object({
  subscriptionId: z.string().min(1, "subscriptionId es requerido"),
});

billingRouter.post("/cancel", async (req, res) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.companyId) {
    res.status(401).json({ error: "not_authenticated" });
    return;
  }

  const parsed = cancelSchema.safeParse(req.body);
  if (!parsed.success) {
    res
      .status(400)
      .json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  try {
    const result = await cancelSubscription(parsed.data.subscriptionId);
    res.json({ ok: true, data: result });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "error_interno";
    res.status(400).json({ error: msg });
  }
});
