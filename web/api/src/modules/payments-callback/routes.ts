/**
 * Callback handler — recibe del microservicio zentto-payments cuando una
 * suscripción/transacción cambia de estado.
 *
 * Ruta destino para cutover de Paddle:
 *   - Hoy:      Paddle webhook → /v1/billing/webhook (legacy paddleApi directo)
 *   - Cutover:  Paddle webhook → payments.zentto.net/v1/webhooks/paddle
 *               microservicio → POST /v1/payments/callback (este endpoint)
 *
 * Reusa la lógica existente en billing.service.handleWebhookEvent —
 * la transformación entre formato microservicio y formato Paddle es trivial.
 */
import { Router, type Request, type Response } from "express";
import { handleWebhookEvent } from "../billing/billing.service.js";

export const paymentsCallbackRouter = Router();

paymentsCallbackRouter.post("/callback", async (req: Request, res: Response) => {
  try {
    const { eventType, status, providerSubId, providerTxnId, customData, rawPayload, metadata } = req.body ?? {};
    if (!eventType || !status) return res.status(400).json({ error: "missing_fields" });

    // Reusar handleWebhookEvent del módulo billing — espera formato Paddle WebhookEvent.
    // Si el rawPayload viene del microservicio (subscription event), lo pasamos tal cual.
    // El handler del billing ya maneja: subscription.created/updated/canceled + transaction.completed
    if (eventType.startsWith("subscription.") || eventType.startsWith("transaction.")) {
      const payload = (rawPayload ?? {}) as { event_type?: string; data?: Record<string, unknown> };
      if (!payload.event_type) {
        // Construir payload si vino solo el shape del microservicio
        payload.event_type = eventType;
        payload.data = {
          id: providerSubId ?? providerTxnId,
          status: status === "paid" ? "active" : status,
          custom_data: { ...(customData ?? metadata ?? {}) },
        };
      }
      const result = await handleWebhookEvent(payload as never);
      return res.json({ received: true, ...result });
    }

    return res.json({ received: true, ignored: true, reason: "event_not_handled" });
  } catch (err: unknown) {
    console.error("[payments-callback] error:", err);
    return res.status(500).json({ error: "callback_processing_error" });
  }
});
