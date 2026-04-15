/**
 * HTTP helper compartido entre submódulos.
 *
 * Features:
 *   - Retries con backoff exponencial ante errores de red o 5xx.
 *   - Sin retry en 4xx (es error del caller).
 *   - Timeout por request.
 *   - Circuit breaker por (baseUrl): evita cascade cuando upstream cae.
 *   - Errores tipados (AuthError, RateLimitedError, ServiceError, etc.) en `errorInstance`.
 *   - Hook `beforeRetry` (ej. AuthClient lo usa para auto-refresh del JWT).
 *   - No lanza: siempre retorna Result<T> (ok/error).
 */
import { CircuitBreaker, type CircuitOptions } from "./circuit.js";
import { CircuitOpenError, NetworkError, mapHttpError, type PlatformError } from "./errors.js";

export interface HttpConfig {
  baseUrl: string;
  timeoutMs: number;
  retries: number;
  onError: (err: Error, ctx: { path: string; attempt: number }) => void;
  /** Opcional: permite al AuthClient interceptar 401 para refresh + retry. */
  beforeRetry?: (err: PlatformError, ctx: { path: string; attempt: number }) => Promise<{ retry: boolean; headers?: Record<string, string> }>;
  /** Circuit breaker compartido entre requests del mismo cliente. */
  breaker: CircuitBreaker;
}

export interface HttpResult<T = unknown> {
  ok: boolean;
  status?: number;
  data?: T;
  error?: string;
  errorInstance?: PlatformError;
}

export interface RequestOptions {
  method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  path: string;
  body?: object;
  headers?: Record<string, string>;
  query?: Record<string, string | number | undefined | null>;
  credentials?: "include" | "omit";
}

function buildUrl(baseUrl: string, path: string, query?: RequestOptions["query"]): string {
  const url = `${baseUrl.replace(/\/$/, "")}${path.startsWith("/") ? path : `/${path}`}`;
  if (!query) return url;
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries(query)) {
    if (v === undefined || v === null) continue;
    params.set(k, String(v));
  }
  const qs = params.toString();
  return qs ? `${url}?${qs}` : url;
}

export async function httpRequest<T = unknown>(
  cfg: HttpConfig,
  opts: RequestOptions,
): Promise<HttpResult<T>> {
  const url = buildUrl(cfg.baseUrl, opts.path, opts.query);
  const breakerKey = cfg.baseUrl;

  if (!cfg.breaker.allow(breakerKey)) {
    const err = new CircuitOpenError(`Circuit open for ${cfg.baseUrl}`, { path: opts.path, attempt: 0 });
    cfg.onError(err, { path: opts.path, attempt: 0 });
    return { ok: false, error: err.message, errorInstance: err };
  }

  let headers: Record<string, string> = { "Content-Type": "application/json", ...opts.headers };
  let lastErr: PlatformError | undefined;

  for (let attempt = 0; attempt <= cfg.retries; attempt++) {
    try {
      const res = await fetch(url, {
        method: opts.method,
        headers,
        body: opts.body ? JSON.stringify(opts.body) : undefined,
        credentials: opts.credentials,
        signal: AbortSignal.timeout(cfg.timeoutMs),
      });
      const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;

      if (res.ok) {
        cfg.breaker.recordSuccess(breakerKey);
        return { ok: true, status: res.status, data: json as T };
      }

      const err = mapHttpError(res.status, json, opts.path, attempt);
      lastErr = err;

      // 4xx: sin retry por default. Pero beforeRetry puede pedir retry
      // (ej. AuthClient refresca token y reintenta 401 una vez).
      if (res.status >= 400 && res.status < 500) {
        const shouldRetry = cfg.beforeRetry && attempt < cfg.retries
          ? await cfg.beforeRetry(err, { path: opts.path, attempt })
          : { retry: false };
        if (!shouldRetry.retry) {
          // 4xx → NO toca el breaker (es error del caller, no del servicio).
          return { ok: false, status: res.status, error: err.message, errorInstance: err };
        }
        if (shouldRetry.headers) headers = { ...headers, ...shouldRetry.headers };
        continue;
      }

      // 5xx → cuenta para el breaker
      cfg.breaker.recordFailure(breakerKey);
    } catch (netErr) {
      const err = new NetworkError((netErr as Error).message, { path: opts.path, attempt, cause: netErr });
      lastErr = err;
      cfg.breaker.recordFailure(breakerKey);
    }

    if (attempt < cfg.retries) {
      cfg.onError(lastErr!, { path: opts.path, attempt });
      await new Promise((r) => setTimeout(r, 250 * Math.pow(2, attempt)));
    }
  }

  const err = lastErr ?? new NetworkError("unknown error", { path: opts.path, attempt: cfg.retries });
  cfg.onError(err, { path: opts.path, attempt: cfg.retries });
  return { ok: false, error: err.message, errorInstance: err };
}

export interface HttpConfigInput {
  baseUrl: string;
  timeoutMs?: number;
  retries?: number;
  onError?: HttpConfig["onError"];
  circuit?: CircuitOptions;
  beforeRetry?: HttpConfig["beforeRetry"];
}

export function defaultHttpConfig(overrides: HttpConfigInput): HttpConfig {
  return {
    baseUrl: overrides.baseUrl,
    timeoutMs: overrides.timeoutMs ?? 10_000,
    retries: Math.max(0, overrides.retries ?? 1),
    onError: overrides.onError ?? (() => {}),
    beforeRetry: overrides.beforeRetry,
    breaker: new CircuitBreaker(overrides.circuit ?? {}),
  };
}
