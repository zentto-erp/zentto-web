/**
 * webhook-endpoints.routes.ts — REST endpoints para gestionar webhooks del tenant.
 *
 * POST   /v1/webhooks          — Registrar endpoint
 * GET    /v1/webhooks          — Listar endpoints del tenant
 * GET    /v1/webhooks/:id      — Detalle de un endpoint
 * PATCH  /v1/webhooks/:id      — Actualizar endpoint
 * DELETE /v1/webhooks/:id      — Eliminar endpoint
 * GET    /v1/webhooks/:id/deliveries — Entregas de un endpoint
 */

import { Router } from "express";
import {
  createWebhookEndpoint,
  listWebhookEndpoints,
  getWebhookEndpoint,
  updateWebhookEndpoint,
  deleteWebhookEndpoint,
  listWebhookDeliveries,
  WEBHOOK_EVENT_TYPES,
} from "./webhook-endpoints.service.js";

export const webhookEndpointsRouter = Router();

/**
 * GET /v1/webhooks/event-types
 * Retorna la lista de event types soportados.
 */
webhookEndpointsRouter.get("/event-types", (_req, res) => {
  res.json({ eventTypes: WEBHOOK_EVENT_TYPES });
});

/**
 * POST /v1/webhooks
 * Body: { url, secret, events, description? }
 */
webhookEndpointsRouter.post("/", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const { url, secret, events, description } = req.body;

    if (!url || !secret || !events || !Array.isArray(events) || events.length === 0) {
      return res.status(400).json({
        error: "Campos requeridos: url, secret, events (array no vacío)",
      });
    }

    const result = await createWebhookEndpoint(companyId, {
      url,
      secret,
      events,
      description,
    });

    if (!result.ok) {
      return res.status(400).json({ error: result.mensaje });
    }

    res.status(201).json({
      webhookEndpointId: result.webhookEndpointId,
      message: result.mensaje,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/webhooks
 */
webhookEndpointsRouter.get("/", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const endpoints = await listWebhookEndpoints(companyId);
    res.json({ data: endpoints });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/webhooks/:id
 */
webhookEndpointsRouter.get("/:id", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const endpointId = Number(req.params.id);
    if (!endpointId) return res.status(400).json({ error: "id inválido" });

    const endpoint = await getWebhookEndpoint(companyId, endpointId);
    if (!endpoint) return res.status(404).json({ error: "Webhook no encontrado" });

    // No exponer el secret completo en GET
    const masked = endpoint.Secret
      ? endpoint.Secret.substring(0, 6) + "..." + endpoint.Secret.slice(-4)
      : "";

    res.json({
      ...endpoint,
      Secret: masked,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PATCH /v1/webhooks/:id
 * Body: { url?, secret?, events?, description?, isActive? }
 */
webhookEndpointsRouter.patch("/:id", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const endpointId = Number(req.params.id);
    if (!endpointId) return res.status(400).json({ error: "id inválido" });

    const result = await updateWebhookEndpoint(companyId, endpointId, req.body);

    if (!result.ok) {
      return res.status(404).json({ error: result.mensaje });
    }

    res.json({ message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * DELETE /v1/webhooks/:id
 */
webhookEndpointsRouter.delete("/:id", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const endpointId = Number(req.params.id);
    if (!endpointId) return res.status(400).json({ error: "id inválido" });

    const result = await deleteWebhookEndpoint(companyId, endpointId);

    if (!result.ok) {
      return res.status(404).json({ error: result.mensaje });
    }

    res.json({ message: result.mensaje });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/webhooks/:id/deliveries
 * Query: ?page=1&pageSize=50
 */
webhookEndpointsRouter.get("/:id/deliveries", async (req, res) => {
  try {
    const scope = (req as any).scope as { companyId: number } | undefined;
    const companyId = scope?.companyId ?? Number(req.query.companyId) ?? 0;
    if (!companyId) return res.status(400).json({ error: "companyId requerido" });

    const endpointId = Number(req.params.id);
    if (!endpointId) return res.status(400).json({ error: "id inválido" });

    const page = Number(req.query.page) || 1;
    const pageSize = Math.min(Number(req.query.pageSize) || 50, 200);

    const result = await listWebhookDeliveries(companyId, endpointId, page, pageSize);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
