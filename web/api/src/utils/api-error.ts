/**
 * ApiError — clase estándar de errores HTTP para el core (ALERT-3).
 *
 * Usarla en lugar de `res.status(500).json({ error: String(err) })`, que expone
 * stack trace al cliente. Ejemplo de migración:
 *
 * ```ts
 * // ❌ antes
 * try { ... } catch (err) { res.status(500).json({ error: String(err) }); }
 *
 * // ✅ después
 * router.get("/x", async (_req, _res, next) => {
 *   try {
 *     ...
 *   } catch (err) {
 *     next(err); // global error handler formatea y loguea
 *   }
 * });
 *
 * // o lanzar explícito:
 * throw new ApiError(404, "not_found", "Cliente no existe");
 * ```
 *
 * El global handler en `middleware/error-handler.ts` reconoce instancias de
 * ApiError y respeta `status`/`code`/`message`/`details`. Otros errores caen
 * a 500 con cuerpo genérico (nunca leak de stack en producción).
 */
export class ApiError extends Error {
  public readonly status: number;
  public readonly code: string;
  public readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.details = details;
  }

  // Helpers comunes
  static badRequest(code: string, message: string, details?: unknown) {
    return new ApiError(400, code, message, details);
  }
  static unauthorized(code = "unauthorized", message = "No autenticado") {
    return new ApiError(401, code, message);
  }
  static forbidden(code = "forbidden", message = "Sin permisos") {
    return new ApiError(403, code, message);
  }
  static notFound(code = "not_found", message = "Recurso no existe") {
    return new ApiError(404, code, message);
  }
  static conflict(code: string, message: string, details?: unknown) {
    return new ApiError(409, code, message, details);
  }
  static internal(code = "internal_error", message = "Error interno", details?: unknown) {
    return new ApiError(500, code, message, details);
  }
}
