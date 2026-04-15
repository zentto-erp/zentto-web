// Barrel de @zentto/platform-client. Un submódulo por servicio de plataforma.
// Uso: `import { notify } from "@zentto/platform-client"` o import directo
// del subpath `@zentto/platform-client/notify`.

export * as notify from "./notify/index.js";
export * as auth from "./auth/index.js";
export * as cache from "./cache/index.js";
export * as landing from "./landing/index.js";
export * as events from "./events/index.js";
export * as webhooks from "./webhooks/index.js";

// Tipos de error compartidos (útiles para `instanceof` en callers).
export * from "./internal/errors.js";
