/**
 * Cache in-memory para endpoints publicos del storefront.
 *
 * Diseno minimalista:
 * - Map<string, {value, expires, etag}> con TTL.
 * - Generacion de ETag via hash debil del JSON.
 * - Helper `cached()` que envuelve un handler Express.
 * - Invalidacion por prefix (`invalidatePrefix("products:")`).
 *
 * Razon: zentto-cache es para layouts/templates (dual-write Redis+PG con
 * versionado), no para cachear respuestas HTTP de catalogo. Para storefront
 * publico, in-memory + ETag es suficiente y se monta sin infra extra. Si el
 * trafico justifica Redis dedicado, este wrapper se reemplaza por uno que
 * lea/escriba Redis sin tocar los handlers.
 */
import type { Request, Response, NextFunction, RequestHandler } from "express";
import { createHash } from "crypto";

interface Entry {
  value: unknown;
  expires: number;
  etag: string;
}

const store = new Map<string, Entry>();
const DEFAULT_TTL_MS = 60_000;

function makeEtag(value: unknown): string {
  const json = typeof value === "string" ? value : JSON.stringify(value);
  return `"${createHash("sha1").update(json).digest("base64").slice(0, 16)}"`;
}

export function cacheGet<T = unknown>(key: string): { value: T; etag: string } | null {
  const entry = store.get(key);
  if (!entry) return null;
  if (entry.expires < Date.now()) {
    store.delete(key);
    return null;
  }
  return { value: entry.value as T, etag: entry.etag };
}

export function cacheSet(key: string, value: unknown, ttlMs = DEFAULT_TTL_MS): string {
  const etag = makeEtag(value);
  store.set(key, { value, expires: Date.now() + ttlMs, etag });
  return etag;
}

export function invalidatePrefix(prefix: string): number {
  let count = 0;
  for (const k of store.keys()) {
    if (k.startsWith(prefix)) {
      store.delete(k);
      count++;
    }
  }
  return count;
}

export function cacheStats() {
  let active = 0;
  const now = Date.now();
  for (const e of store.values()) {
    if (e.expires > now) active++;
  }
  return { total: store.size, active, expired: store.size - active };
}

/**
 * Middleware factory: envuelve un handler async con cache + ETag.
 *
 * Uso:
 *   router.get("/products", cached("products", 60_000, async (req) => listProducts(...)));
 */
export function cached<TQuery = Record<string, unknown>>(
  prefix: string,
  ttlMs: number,
  handler: (req: Request) => Promise<unknown>,
  keyOf: (req: Request) => string = (req) => `${prefix}:${req.originalUrl}`,
): RequestHandler {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const key = keyOf(req);
      const hit = cacheGet(key);
      const ifNoneMatch = req.headers["if-none-match"];

      if (hit) {
        res.setHeader("X-Cache", "HIT");
        res.setHeader("ETag", hit.etag);
        res.setHeader("Cache-Control", `public, max-age=${Math.floor(ttlMs / 1000)}, stale-while-revalidate=300`);
        if (ifNoneMatch && ifNoneMatch === hit.etag) {
          return res.status(304).end();
        }
        return res.json(hit.value);
      }

      const value = await handler(req);
      const etag = cacheSet(key, value, ttlMs);
      res.setHeader("X-Cache", "MISS");
      res.setHeader("ETag", etag);
      res.setHeader("Cache-Control", `public, max-age=${Math.floor(ttlMs / 1000)}, stale-while-revalidate=300`);
      if (ifNoneMatch && ifNoneMatch === etag) {
        return res.status(304).end();
      }
      res.json(value);
    } catch (err: any) {
      if (err && typeof err.status === "number") {
        return res.status(err.status).json({ error: err.message || "error" });
      }
      console.error(`[storefront-cache] ${prefix} error:`, err);
      res.status(500).json({ error: "server_error", message: err?.message || String(err) });
    }
  };
}
