/**
 * webhook-retry.job.ts — Job periódico para reintentar deliveries fallidos.
 *
 * Programación:
 * - Primera ejecución: 30 segundos después del boot
 * - Siguientes: cada 30 segundos
 *
 * Procesa hasta 100 deliveries pendientes por ciclo.
 */

import { processWebhookRetries } from "../webhooks/index.js";

// ── Constantes ───────────────────────────────────────────────────────────────

const RUN_AFTER_BOOT_MS = 30_000;  // 30 segundos tras el boot
const INTERVAL_MS = 30_000;        // cada 30 segundos

// ── Job ──────────────────────────────────────────────────────────────────────

let intervalRef: ReturnType<typeof setInterval> | null = null;

async function run(): Promise<void> {
  try {
    const processed = await processWebhookRetries();
    if (processed > 0) {
      console.log(`[webhook-retry] Procesados ${processed} deliveries pendientes`);
    }
  } catch (err: any) {
    console.error("[webhook-retry] Error:", err.message);
  }
}

export function startWebhookRetryJob(): void {
  console.log(
    `[webhook-retry] Job programado: primera ejecución en ${RUN_AFTER_BOOT_MS / 1000}s, luego cada ${INTERVAL_MS / 1000}s`
  );

  setTimeout(() => {
    run();
    intervalRef = setInterval(run, INTERVAL_MS);
  }, RUN_AFTER_BOOT_MS);
}

export function stopWebhookRetryJob(): void {
  if (intervalRef) {
    clearInterval(intervalRef);
    intervalRef = null;
    console.log("[webhook-retry] Job detenido");
  }
}
