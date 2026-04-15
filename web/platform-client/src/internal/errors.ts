/**
 * Jerarquía de errores tipados del SDK.
 *
 * El SDK NO lanza por default (mantiene shape best-effort `{ ok, error }`).
 * Estos errores se usan:
 *   a) En `result.errorInstance` para callers que quieran `instanceof`.
 *   b) Opcionalmente en modo `throwOnError: true` (futuro).
 *
 * La jerarquía permite reaccionar fino:
 *   if (err instanceof RateLimitedError) backoff();
 *   if (err instanceof AuthError) redirectToLogin();
 */

export class PlatformError extends Error {
  readonly status?: number;
  readonly path?: string;
  readonly attempt?: number;

  constructor(message: string, opts?: { status?: number; path?: string; attempt?: number; cause?: unknown }) {
    super(message);
    this.name = "PlatformError";
    this.status = opts?.status;
    this.path = opts?.path;
    this.attempt = opts?.attempt;
    if (opts?.cause !== undefined) (this as any).cause = opts.cause;
  }
}

/** 4xx 401/403 — token inválido/expirado, scope faltante. */
export class AuthError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "AuthError";
  }
}

/** 4xx 400/422 — body mal formado, campos faltantes. */
export class ValidationError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "ValidationError";
  }
}

/** 4xx 404 — recurso no existe. */
export class NotFoundError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "NotFoundError";
  }
}

/** 4xx 429 — rate limited upstream. */
export class RateLimitedError extends PlatformError {
  readonly retryAfterSec?: number;
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1] & { retryAfterSec?: number }) {
    super(message, opts);
    this.name = "RateLimitedError";
    this.retryAfterSec = opts?.retryAfterSec;
  }
}

/** 5xx — error del servicio upstream. Normalmente reintentable. */
export class ServiceError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "ServiceError";
  }
}

/** Errores de red (timeout, DNS, connection reset). Reintentables. */
export class NetworkError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "NetworkError";
  }
}

/** Circuit breaker abierto — upstream fallando demasiado. */
export class CircuitOpenError extends PlatformError {
  constructor(message: string, opts?: ConstructorParameters<typeof PlatformError>[1]) {
    super(message, opts);
    this.name = "CircuitOpenError";
  }
}

/** Mapea HTTP status + contexto a un error tipado. */
export function mapHttpError(status: number | undefined, body: Record<string, unknown>, path: string, attempt: number): PlatformError {
  const msg = (body.error as string) ?? (body.message as string) ?? (status ? `HTTP ${status}` : "unknown error");
  const opts = { status, path, attempt };
  if (status === 401 || status === 403) return new AuthError(msg, opts);
  if (status === 404) return new NotFoundError(msg, opts);
  if (status === 429) {
    const retryAfterSec = typeof body.retryAfter === "number" ? body.retryAfter : undefined;
    return new RateLimitedError(msg, { ...opts, retryAfterSec });
  }
  if (status && status >= 400 && status < 500) return new ValidationError(msg, opts);
  if (status && status >= 500) return new ServiceError(msg, opts);
  return new NetworkError(msg, opts);
}
