/**
 * TTL cache en memoria + wrapper `memoAsync` para memoizar resultados
 * positivos de funciones async.
 *
 * Uso típico:
 *   const cache = new TtlCache<MeResponse>({ ttlMs: 15_000 });
 *   const me = await memoAsync(cache, "me", () => client.me());
 *
 * Sólo cachea resultados "ok" (`{ ok: true }`). Los errores se propagan
 * sin guardarse — así los callers reintentan en la siguiente llamada.
 */

export interface TtlCacheOptions {
  /** TTL default por entrada. Default 15s. */
  ttlMs?: number;
  /** Límite de entradas; al exceder se evicta por FIFO. Default 200. */
  maxEntries?: number;
}

interface Entry<T> {
  value: T;
  expiresAt: number;
}

export class TtlCache<T> {
  private readonly ttlMs: number;
  private readonly maxEntries: number;
  private readonly data = new Map<string, Entry<T>>();

  constructor(opts: TtlCacheOptions = {}) {
    this.ttlMs = opts.ttlMs ?? 15_000;
    this.maxEntries = Math.max(1, opts.maxEntries ?? 200);
  }

  get(key: string): T | undefined {
    const e = this.data.get(key);
    if (!e) return undefined;
    if (e.expiresAt <= Date.now()) {
      this.data.delete(key);
      return undefined;
    }
    return e.value;
  }

  set(key: string, value: T, ttlMsOverride?: number): void {
    if (this.data.size >= this.maxEntries && !this.data.has(key)) {
      // FIFO evict
      const oldest = this.data.keys().next().value;
      if (oldest !== undefined) this.data.delete(oldest);
    }
    this.data.set(key, {
      value,
      expiresAt: Date.now() + (ttlMsOverride ?? this.ttlMs),
    });
  }

  delete(key: string): void {
    this.data.delete(key);
  }

  clear(): void {
    this.data.clear();
  }

  size(): number {
    return this.data.size;
  }
}

/**
 * Memoiza una función async por `key`. Si ya hay un resultado cacheado no
 * expirado, lo devuelve sin llamar a fn. Si múltiples callers piden la
 * misma key simultáneamente, se coalesce en una sola llamada (single-flight).
 *
 * Sólo guarda resultados donde `shouldCache(r)` sea true (default: r?.ok ===
 * true, para compatibilidad con el shape Result<T> del SDK).
 */
export function memoAsync<T>(
  cache: TtlCache<T>,
  key: string,
  fn: () => Promise<T>,
  opts?: { ttlMsOverride?: number; shouldCache?: (r: T) => boolean },
): Promise<T> {
  const cached = cache.get(key);
  if (cached !== undefined) return Promise.resolve(cached);

  const inflight = (cache as unknown as { _inflight?: Map<string, Promise<T>> })._inflight
    ?? (((cache as unknown as { _inflight: Map<string, Promise<T>> })._inflight = new Map()));
  const existing = inflight.get(key);
  if (existing) return existing;

  const p = (async () => {
    const shouldCache = opts?.shouldCache ?? ((r: T) => (r as unknown as { ok?: boolean })?.ok === true);
    try {
      const r = await fn();
      if (shouldCache(r)) cache.set(key, r, opts?.ttlMsOverride);
      return r;
    } finally {
      inflight.delete(key);
    }
  })();
  inflight.set(key, p);
  return p;
}
