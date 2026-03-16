import type { Request, Response, NextFunction } from "express";
import { getRedis } from "../db/redis.js";

type RateLimitOptions = {
  name: string;
  max: number;
  windowSec: number;
  keyGenerator?: (req: Request) => string;
  message?: string;
};

type CounterResult = {
  count: number;
  ttlSec: number;
};

const memoryCounters = new Map<string, { count: number; expiresAt: number }>();

function toPositiveInt(value: number, fallback: number) {
  if (!Number.isFinite(value) || value <= 0) return fallback;
  return Math.trunc(value);
}

function parseForwardedIp(value: string | string[] | undefined) {
  const raw = Array.isArray(value) ? value[0] : value;
  if (!raw) return null;
  const first = raw.split(",")[0]?.trim();
  return first || null;
}

export function getClientIp(req: Request) {
  const forwarded = parseForwardedIp(req.headers["x-forwarded-for"]);
  const realIp = parseForwardedIp(req.headers["x-real-ip"]);
  const socketIp = req.socket?.remoteAddress?.trim() || null;
  return forwarded || realIp || socketIp || "unknown";
}

async function incrementWithRedis(key: string, windowSec: number): Promise<CounterResult | null> {
  const redis = await getRedis();
  if (!redis) return null;

  const count = Number(await redis.incr(key));
  if (count === 1) {
    await redis.expire(key, windowSec);
  }
  let ttl = Number(await redis.ttl(key));
  if (!Number.isFinite(ttl) || ttl < 0) {
    ttl = windowSec;
  }
  return { count, ttlSec: ttl };
}

function incrementInMemory(key: string, windowSec: number): CounterResult {
  const now = Date.now();
  const existing = memoryCounters.get(key);

  if (!existing || existing.expiresAt <= now) {
    const fresh = {
      count: 1,
      expiresAt: now + windowSec * 1000,
    };
    memoryCounters.set(key, fresh);
    return { count: 1, ttlSec: windowSec };
  }

  existing.count += 1;
  memoryCounters.set(key, existing);
  const ttlSec = Math.max(1, Math.ceil((existing.expiresAt - now) / 1000));
  return { count: existing.count, ttlSec };
}

async function incrementCounter(key: string, windowSec: number): Promise<CounterResult> {
  const redisResult = await incrementWithRedis(key, windowSec);
  if (redisResult) return redisResult;
  return incrementInMemory(key, windowSec);
}

export function createRateLimiter(options: RateLimitOptions) {
  const max = toPositiveInt(options.max, 30);
  const windowSec = toPositiveInt(options.windowSec, 60);

  return async (req: Request, res: Response, next: NextFunction) => {
    if (req.method === "OPTIONS") return next();

    const keyBase = options.keyGenerator ? options.keyGenerator(req) : getClientIp(req);
    const key = `rl:${options.name}:${keyBase}`;
    const { count, ttlSec } = await incrementCounter(key, windowSec);

    const remaining = Math.max(0, max - count);
    res.setHeader("X-RateLimit-Limit", String(max));
    res.setHeader("X-RateLimit-Remaining", String(remaining));
    res.setHeader("X-RateLimit-Reset", String(ttlSec));

    if (count > max) {
      res.setHeader("Retry-After", String(ttlSec));
      return res.status(429).json({
        error: "rate_limit_exceeded",
        message: options.message ?? "Demasiadas solicitudes. Intente nuevamente en unos minutos.",
        retryAfterSeconds: ttlSec,
      });
    }

    return next();
  };
}
