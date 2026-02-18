import { env } from "../config/env.js";

/**
 * Singleton de conexión Redis.
 * Se reutiliza la misma instancia en toda la vida del proceso.
 */
let _instance: any = null;
let _checked = false;

export async function getRedis(): Promise<any | null> {
  // Si ya verificamos, devolver la instancia (puede ser null)
  if (_checked) return _instance;
  _checked = true;

  if (!env.redisUrl) return null;
  try {
    const module = await import("ioredis");
    const RedisCtor = module.default as unknown as new (url: string) => unknown;
    _instance = new RedisCtor(env.redisUrl);
    return _instance;
  } catch {
    return null;
  }
}
