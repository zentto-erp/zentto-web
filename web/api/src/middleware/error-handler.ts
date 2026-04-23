/**
 * Global error handler — ALERT-3 (endpoints con error handling asimétrico).
 *
 * Antes existía un handler inline en `app.ts` que lograba evitar 502s pero no
 * tenía contrato formal. Este módulo:
 *
 *   1. Reconoce instancias de `ApiError` (ver `utils/api-error.ts`) y respeta
 *      su status/code/message/details.
 *   2. Normaliza errores arbitrarios a 500 con cuerpo genérico, SIN exponer
 *      stack trace en producción (en dev muestra las 5 primeras líneas para
 *      facilitar debugging).
 *   3. Loguea siempre el stack completo en servidor.
 *
 * Se monta DESPUÉS de todos los routers en `app.ts`. Routes nuevas deben
 * preferir `next(err)` o `throw new ApiError(...)` en lugar de
 * `res.status(500).json({ error: String(err) })`. Ver CLAUDE.md del repo.
 */
import type { ErrorRequestHandler } from "express";
import { ApiError } from "../utils/api-error.js";

export const globalErrorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  const isProd = process.env.NODE_ENV === "production";

  // Log completo en server, independiente del ambiente
  try {
    console.error(
      "[UNHANDLED]",
      err?.message ?? err,
      err?.stack?.split("\n").slice(0, 5).join("\n")
    );
  } catch {
    /* logging never blocks */
  }

  if (res.headersSent) return;

  if (err instanceof ApiError) {
    res.status(err.status).json({
      error: err.code,
      message: err.message,
      ...(err.details !== undefined ? { details: err.details } : {}),
    });
    return;
  }

  // Errores de parseo de JSON del body-parser
  if (err?.type === "entity.parse.failed") {
    res.status(400).json({ error: "invalid_json", message: "Body JSON inválido" });
    return;
  }

  // Errores de Zod — ya se manejan en cada route normalmente, pero por si escapan
  if (err?.name === "ZodError" && Array.isArray(err.issues)) {
    res.status(400).json({ error: "invalid_payload", issues: err.issues });
    return;
  }

  // Fallback: 500 genérico, sin leak de stack en prod
  res.status(500).json({
    error: "internal_server_error",
    message: isProd ? "Error interno del servidor" : err?.message || "Error interno",
    ...(isProd ? {} : { stack: err?.stack?.split("\n").slice(0, 5) }),
  });
};
