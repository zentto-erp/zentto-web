// Barrel del platform-client. Cada submódulo expone su propia API; acá
// re-exportamos en namespaces para llamadas tipo `platform.notify.email.send(...)`.

export * as notify from "./notify/index.js";

// Placeholders — se llenan cuando se migren cache/auth/landing al mismo patrón.
// export * as cache from "./cache/index.js";
// export * as auth from "./auth/index.js";
// export * as landing from "./landing/index.js";
