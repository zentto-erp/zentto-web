import "dotenv/config";
import { createApp } from "./app.js";
import { warmUp } from "./modules/inventario/inventario-cache.js";

const port = Number(process.env.PORT || 4000);
const app = await createApp();

app.listen(port, () => {
  console.log(`[api] listening on :${port}`);

  // Pre-calentar caché de inventario (~64k artículos) en background
  warmUp()
    .then((n) => console.log(`[api] Cache inventario listo: ${n} artículos`))
    .catch((err) => console.error("[api] Error precalentando cache inventario:", err));
});
