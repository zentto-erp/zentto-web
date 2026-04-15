/**
 * HTTP helper compartido entre submódulos.
 *
 * - Retries con backoff exponencial ante errores de red o 5xx.
 * - Sin retry en 4xx (es error del caller).
 * - Timeout por request.
 * - onError hook para observability.
 * - No lanza: siempre retorna Result<T> (ok/error). Los callers deciden si
 *   propagar o no.
 */

export interface HttpConfig {
  baseUrl: string;
  timeoutMs: number;
  retries: number;
  onError: (err: Error, ctx: { path: string; attempt: number }) => void;
}

export interface HttpResult<T = unknown> {
  ok: boolean;
  status?: number;
  data?: T;
  error?: string;
}

export interface RequestOptions {
  method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  path: string;
  body?: object;
  headers?: Record<string, string>;
  query?: Record<string, string | number | undefined | null>;
  /** Enviar cookies (para endpoints que usan cookie httpOnly). */
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
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...opts.headers,
  };
  let lastErr: Error | undefined;

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
        return { ok: true, status: res.status, data: json as T };
      }
      // 4xx: sin retry — es error del caller / auth / validación.
      if (res.status >= 400 && res.status < 500) {
        return {
          ok: false,
          status: res.status,
          error: (json.error as string) ?? (json.message as string) ?? `HTTP ${res.status}`,
        };
      }
      lastErr = new Error(`HTTP ${res.status}`);
    } catch (err) {
      lastErr = err as Error;
    }
    if (attempt < cfg.retries) {
      cfg.onError(lastErr, { path: opts.path, attempt });
      await new Promise((r) => setTimeout(r, 250 * Math.pow(2, attempt)));
    }
  }
  const err = lastErr ?? new Error("unknown error");
  cfg.onError(err, { path: opts.path, attempt: cfg.retries });
  return { ok: false, error: err.message };
}

export function defaultHttpConfig(overrides: Partial<HttpConfig> & { baseUrl: string }): HttpConfig {
  return {
    baseUrl: overrides.baseUrl,
    timeoutMs: overrides.timeoutMs ?? 10_000,
    retries: Math.max(0, overrides.retries ?? 1),
    onError: overrides.onError ?? (() => {}),
  };
}
