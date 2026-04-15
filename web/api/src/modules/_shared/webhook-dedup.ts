/**
 * webhook-dedup.ts — Idempotencia de webhooks externos (Paddle, GitHub, etc.)
 * usando sys.WebhookEvent. Evita doble provisionamiento si el provider
 * reenvía el mismo evento por timeout/retry.
 */
import crypto from "node:crypto";
import { callSp } from "../../db/query.js";

export interface WebhookDedupResult {
  isNew: boolean;
  previousStatus?: string;
}

/**
 * Intenta registrar un evento como "processing". Devuelve isNew=true si era
 * nuevo (caller debe procesar), false si ya se había recibido (skip).
 */
export async function dedupWebhookEvent(opts: {
  eventId: string;
  eventType: string;
  source?: string;
  payloadHash?: string;
}): Promise<WebhookDedupResult> {
  if (!opts.eventId) {
    // Sin event_id no podemos deduplicar — tratar como nuevo (best-effort)
    return { isNew: true };
  }
  const rows = await callSp<{ was_new: boolean; previous_status: string | null }>(
    "usp_sys_webhook_event_dedup",
    {
      EventId: opts.eventId,
      EventType: opts.eventType,
      Source: opts.source ?? "paddle",
      PayloadHash: opts.payloadHash ?? "",
    }
  );
  const r = rows[0];
  return { isNew: Boolean(r?.was_new), previousStatus: r?.previous_status ?? undefined };
}

export async function completeWebhookEvent(opts: {
  eventId: string;
  status: "done" | "error" | "skipped";
  companyId?: number;
  errorMessage?: string;
}): Promise<void> {
  if (!opts.eventId) return;
  await callSp("usp_sys_webhook_event_complete", {
    EventId: opts.eventId,
    Status: opts.status,
    CompanyId: opts.companyId ?? null,
    ErrorMessage: opts.errorMessage ?? "",
  }).catch(() => {});
}

export function hashPayload(raw: string | Buffer): string {
  return crypto.createHash("sha256").update(raw).digest("hex");
}
