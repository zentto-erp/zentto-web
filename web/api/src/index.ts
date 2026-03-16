import "dotenv/config";
import cron from "node-cron";
import { createApp } from "./app.js";
import { warmUp } from "./modules/inventario/inventario-cache.js";
import { getTasasBCV, triggerSyncTasas } from "./modules/config/service.js";

const port = Number(process.env.PORT || 4000);
const app = await createApp();

app.listen(port, () => {
  console.log(`[api] listening on :${port}`);

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
});
