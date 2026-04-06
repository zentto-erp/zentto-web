/**
 * dispatcher.ts — Webhook event dispatcher.
 *
 * Uso desde cualquier módulo:
 *   import { emitWebhookEvent } from "../webhooks/dispatcher.js";
 *   await emitWebhookEvent(companyId, "order.created", { orderId: 123, total: 500 });
 *
 * Flujo:
 *  1. Busca endpoints activos suscritos al event type
 *  2. Crea un delivery record por cada uno
 *  3. Intenta POST con payload + firma HMAC-SHA256
 *  4. Marca success/failed según response
 *  5. Si falla, agenda retry con backoff exponencial
 */

import crypto from "node:crypto";
import { callSp } from "../db/query.js";

// ── Constantes ───────────────────────────────────────────────────────────────

/** Intervalos de retry en milisegundos: 1min, 5min, 30min, 2h, 6h */
const RETRY_DELAYS_MS = [
  1 * 60 * 1000,       // 1 minuto
  5 * 60 * 1000,       // 5 minutos
  30 * 60 * 1000,      // 30 minutos
  2 * 60 * 60 * 1000,  // 2 horas
  6 * 60 * 60 * 1000,  // 6 horas (último intento)
];

const DELIVERY_TIMEOUT_MS = 10_000; // 10 segundos timeout por request

// ── Interfaces internas ──────────────────────────────────────────────────────

interface ActiveEndpoint {
  WebhookEndpointId: number;
  Url: string;
  Secret: string;
}

interface PendingDelivery {
  WebhookDeliveryId: number;
  WebhookEndpointId: number;
  Url: string;
  Secret: string;
  EventType: string;
  Payload: object;
  Attempts: number;
  MaxAttempts: number;
}

// ── HMAC Signing ─────────────────────────────────────────────────────────────

/**
 * Genera firma HMAC-SHA256 del payload.
 * El cliente verifica comparando con el header X-Zentto-Signature.
 */
function signPayload(payload: string, secret: string): string {
  return crypto
    .createHmac("sha256", secret)
    .update(payload, "utf8")
    .digest("hex");
}

// ── HTTP delivery ────────────────────────────────────────────────────────────

interface DeliveryResult {
  success: boolean;
  statusCode: number | null;
  body: string | null;
}

async function deliverPayload(
  url: string,
  secret: string,
  eventType: string,
  payload: object,
  deliveryId: number
): Promise<DeliveryResult> {
  const bodyStr = JSON.stringify(payload);
  const signature = signPayload(bodyStr, secret);
  const timestamp = Math.floor(Date.now() / 1000).toString();

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), DELIVERY_TIMEOUT_MS);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Zentto-Event": eventType,
        "X-Zentto-Signature": `sha256=${signature}`,
        "X-Zentto-Timestamp": timestamp,
        "X-Zentto-Delivery": String(deliveryId),
        "User-Agent": "Zentto-Webhooks/1.0",
      },
      body: bodyStr,
      signal: controller.signal,
    });

    clearTimeout(timer);

    const respBody = await response.text().catch(() => "");
    return {
      success: response.status >= 200 && response.status < 300,
      statusCode: response.status,
      body: respBody.substring(0, 4000),
    };
  } catch (err: any) {
    return {
      success: false,
      statusCode: null,
      body: err.message?.substring(0, 4000) ?? "Error de red",
    };
  }
}

// ── Calcular next retry ──────────────────────────────────────────────────────

function getNextRetryAt(attempts: number): Date | null {
  if (attempts >= RETRY_DELAYS_MS.length) return null; // max alcanzado
  const delayMs = RETRY_DELAYS_MS[attempts] ?? RETRY_DELAYS_MS[RETRY_DELAYS_MS.length - 1];
  return new Date(Date.now() + delayMs);
}

// ── Emit event (punto de entrada principal) ──────────────────────────────────

/**
 * Emite un evento de webhook para un tenant.
 *
 * Es fire-and-forget: no bloquea al caller. Los errores se loguean pero
 * no propagan, para no afectar la operación principal del negocio.
 *
 * @param companyId  Tenant que origina el evento
 * @param eventType  Tipo de evento (ej. "order.created")
 * @param payload    Datos del evento (se serializa como JSON)
 */
export async function emitWebhookEvent(
  companyId: number,
  eventType: string,
  payload: Record<string, unknown>
): Promise<void> {
  try {
    // 1. Buscar endpoints activos suscritos a este evento
    const endpoints = await callSp<ActiveEndpoint>(
      "usp_Platform_WebhookEndpoint_ListByEvent",
      { CompanyId: companyId, EventType: eventType }
    );

    if (!endpoints.length) return; // nadie suscrito

    // 2. Enriquecer payload con metadatos del evento
    const enrichedPayload = {
      event: eventType,
      timestamp: new Date().toISOString(),
      data: payload,
    };

    // 3. Procesar cada endpoint en paralelo (fire-and-forget)
    const deliveries = endpoints.map(async (ep) => {
      try {
        // Crear delivery record
        const deliveryRows = await callSp<{ WebhookDeliveryId: number }>(
          "usp_Platform_WebhookDelivery_Create",
          {
            WebhookEndpointId: ep.WebhookEndpointId,
            EventType: eventType,
            Payload: JSON.stringify(enrichedPayload),
          }
        );

        const deliveryId = deliveryRows[0]?.WebhookDeliveryId;
        if (!deliveryId) return;

        // Intentar entrega
        const result = await deliverPayload(
          ep.Url,
          ep.Secret,
          eventType,
          enrichedPayload,
          deliveryId
        );

        if (result.success) {
          // Marcar como success
          await callSp("usp_Platform_WebhookDelivery_UpdateStatus", {
            WebhookDeliveryId: deliveryId,
            Status: "success",
            ResponseCode: result.statusCode,
            ResponseBody: result.body,
            NextRetryAtUtc: null,
          });
        } else {
          // Marcar como pending con retry
          const nextRetry = getNextRetryAt(0); // primer intento acaba de fallar → attempt 1
          await callSp("usp_Platform_WebhookDelivery_UpdateStatus", {
            WebhookDeliveryId: deliveryId,
            Status: nextRetry ? "pending" : "failed",
            ResponseCode: result.statusCode,
            ResponseBody: result.body,
            NextRetryAtUtc: nextRetry?.toISOString() ?? null,
          });
        }
      } catch (innerErr: any) {
        console.error(
          `[webhooks] Error procesando delivery para endpoint ${ep.WebhookEndpointId}:`,
          innerErr.message
        );
      }
    });

    // No await global — fire-and-forget para no bloquear
    Promise.allSettled(deliveries).catch(() => {});
  } catch (err: any) {
    console.error(`[webhooks] Error emitiendo evento ${eventType}:`, err.message);
  }
}

// ── Retry processor (para job/cron) ──────────────────────────────────────────

/**
 * Procesa deliveries pendientes cuyo retry time ya pasó.
 * Debe llamarse periódicamente (ej. cada 30 segundos desde un job).
 */
export async function processWebhookRetries(): Promise<number> {
  let processed = 0;

  try {
    const pending = await callSp<PendingDelivery>(
      "usp_Platform_WebhookDelivery_ListPendingRetries",
      { Limit: 100 }
    );

    if (!pending.length) return 0;

    const tasks = pending.map(async (d) => {
      try {
        const payload = typeof d.Payload === "string" ? JSON.parse(d.Payload) : d.Payload;

        const result = await deliverPayload(
          d.Url,
          d.Secret,
          d.EventType,
          payload,
          d.WebhookDeliveryId
        );

        if (result.success) {
          await callSp("usp_Platform_WebhookDelivery_UpdateStatus", {
            WebhookDeliveryId: d.WebhookDeliveryId,
            Status: "success",
            ResponseCode: result.statusCode,
            ResponseBody: result.body,
            NextRetryAtUtc: null,
          });
        } else {
          const nextRetry = getNextRetryAt(d.Attempts); // Attempts ya refleja intento actual
          await callSp("usp_Platform_WebhookDelivery_UpdateStatus", {
            WebhookDeliveryId: d.WebhookDeliveryId,
            Status: nextRetry ? "pending" : "failed",
            ResponseCode: result.statusCode,
            ResponseBody: result.body,
            NextRetryAtUtc: nextRetry?.toISOString() ?? null,
          });
        }

        processed++;
      } catch (err: any) {
        console.error(
          `[webhooks] Error en retry delivery ${d.WebhookDeliveryId}:`,
          err.message
        );
      }
    });

    await Promise.allSettled(tasks);
  } catch (err: any) {
    console.error("[webhooks] Error en processWebhookRetries:", err.message);
  }

  return processed;
}
