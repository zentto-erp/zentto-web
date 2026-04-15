/**
 * retry.ts — Helper de reintentos con backoff exponencial.
 * Usado para llamadas a servicios externos (Notify, Cloudflare, etc.) que
 * pueden fallar transitorio y deben recuperarse sin intervención manual.
 */

export interface RetryOptions {
  attempts?: number;        // intentos totales (default 3)
  baseDelayMs?: number;     // backoff inicial (default 500)
  maxDelayMs?: number;      // tope del backoff (default 8000)
  /** Si retorna true, no se reintenta (error permanente, ej. 4xx). */
  isPermanent?: (err: unknown) => boolean;
  /** Callback por cada fallo (audit). */
  onAttemptFailed?: (err: unknown, attempt: number) => void;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  opts: RetryOptions = {}
): Promise<T> {
  const attempts = opts.attempts ?? 3;
  const base = opts.baseDelayMs ?? 500;
  const max = opts.maxDelayMs ?? 8000;
  let lastErr: unknown;

  for (let i = 1; i <= attempts; i++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      opts.onAttemptFailed?.(err, i);
      if (i === attempts) break;
      if (opts.isPermanent?.(err)) break;
      const delay = Math.min(max, base * Math.pow(2, i - 1)) + Math.floor(Math.random() * 200);
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  throw lastErr;
}

/** Detecta errores HTTP 4xx (no reintentar). */
export function isHttp4xx(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  return /\b4\d\d\b/.test(msg);
}
