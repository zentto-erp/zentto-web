/**
 * webhooks/index.ts — Barrel export del sistema de webhooks.
 *
 * Uso:
 *   import { emitWebhookEvent } from "./webhooks/index.js";
 *   await emitWebhookEvent(companyId, "order.created", { orderId: 123 });
 */

export { emitWebhookEvent, processWebhookRetries } from "./dispatcher.js";
