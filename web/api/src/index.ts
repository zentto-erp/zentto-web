import "dotenv/config";
import { createServer } from "node:http";
import cron from "node-cron";
import { createApp } from "./app.js";
import { warmUp } from "./modules/inventario/inventario-cache.js";
import { getTasasBCV, triggerSyncTasas } from "./modules/config/service.js";
import { attachFiscalRelayWs } from "./modules/pos/fiscal-relay.js";
import { startNotificationConsumer, stopNotificationConsumer } from "./modules/integrations/kafka-notification-consumer.js";
import { startWebhookDispatcher, stopWebhookDispatcher } from "./modules/webhooks/dispatcher.js";

const port = Number(process.env.PORT || 4000);
const app = await createApp();

const httpServer = createServer(app);
attachFiscalRelayWs(httpServer);

httpServer.listen(port, async () => {
  console.log(`[api] listening on :${port}`);

  // ALERT-4: activar monitor de pool.waitingCount (opt-in por env var).
  try {
    const { env } = await import("./config/env.js");
    const { startPoolStatsMonitor } = await import("./db/pg-pool-manager.js");
    console.log(
      `[api] pg pool config — max=${env.pg.poolMax} min=${env.pg.poolMin} ssl=${env.pg.ssl}`
    );
    startPoolStatsMonitor(env.pg.poolStatsIntervalSec);
  } catch (err: any) {
    console.warn("[api] no se pudo iniciar pool stats monitor:", err?.message ?? err);
  }

  // Pre-calentar caché de inventario (~64k artículos) en background
  warmUp()
    .then((n) => console.log(`[api] Cache inventario listo: ${n} artículos`))
    .catch((err) => console.error("[api] Error precalentando cache inventario:", err));

  // Initialize and check fallback rates at boot.
  getTasasBCV()
    .then(r => console.log(`[api] Tasas activas: 1 USD = ${r.USD} / 1 EUR = ${r.EUR} [${r.fechaInformativa}]`))
    .catch(console.error);

  // Setup cron to sync BCV rates every Monday-Friday around 1:00 PM (13:00)
  cron.schedule("0 13 * * 1-5", () => {
    console.log("[cron] Realizando sincronización de Tasas BCV...");
    triggerSyncTasas()
      .then(res => console.log("[cron] BCV Sync exitoso:", res))
      .catch(err => console.error("[cron] Fallo en sync:", err));
  }, {
    timezone: "America/Caracas"
  });

  // Kafka notification consumer — best-effort, no bloquea
  startNotificationConsumer().catch(err =>
    console.warn('[kafka-consumer] Failed to start:', err.message || err)
  );

  // Webhook dispatcher — enruta eventos Kafka a los webhooks de cada tenant.
  // Activado por WEBHOOK_DISPATCHER_ENABLED=true.
  startWebhookDispatcher().catch(err =>
    console.warn('[webhook-dispatcher] Failed to start:', err.message || err)
  );

  // Alertas automáticas del sistema — cada hora (minuto 15)
  cron.schedule("15 * * * *", async () => {
    try {
      const { processSystemAlerts } = await import("./modules/sistema/alertas-automaticas.service.js");
      const result = await processSystemAlerts();
      if (result.generated > 0) {
        console.log(`[cron] Alertas generadas: ${result.generated} (${result.checks.join(", ")})`);
      }
    } catch (err) {
      console.error("[cron] Error en alertas automáticas:", err);
    }
  });
});

// Graceful shutdown
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, async () => {
    console.log(`[api] ${signal} received — shutting down`);
    await stopNotificationConsumer();
    const { obs } = await import("./modules/integrations/observability.js");
    await obs.disconnect();
    httpServer.close(() => process.exit(0));
  });
}
