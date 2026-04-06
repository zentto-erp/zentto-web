import { Router } from "express";
import { callSp } from "../../db/query.js";

export const statusRouter = Router();

const startedAt = Date.now();

interface ServiceStatus {
  name: string;
  status: "operational" | "degraded" | "down";
  latencyMs?: number;
  detail?: string;
}

/**
 * GET /v1/status -- Pagina publica de status
 *
 * Retorna health de cada componente: db, redis, api, uptime, version.
 * No requiere autenticacion.
 */
statusRouter.get("/", async (_req, res) => {
  const services: ServiceStatus[] = [];
  let overall: "operational" | "degraded" | "down" = "operational";

  // -- API ----
  services.push({
    name: "api",
    status: "operational",
    detail: "API respondiendo",
  });

  // -- Database ----
  const dbStart = Date.now();
  try {
    const rows = await callSp<{ ok: number; serverTime: Date; dbName: string }>(
      "usp_Sys_HealthCheck",
    );
    const latency = Date.now() - dbStart;
    services.push({
      name: "database",
      status: latency > 2000 ? "degraded" : "operational",
      latencyMs: latency,
      detail: rows[0]?.dbName || "connected",
    });
    if (latency > 2000) overall = "degraded";
  } catch (err) {
    services.push({
      name: "database",
      status: "down",
      latencyMs: Date.now() - dbStart,
      detail: err instanceof Error ? err.message : "connection_failed",
    });
    overall = "down";
  }

  // -- Redis ----
  try {
    const redisUrl = process.env.REDIS_URL;
    if (redisUrl) {
      const ioredis = await import("ioredis");
      const RedisClient = ioredis.default ?? ioredis;
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const client = new (RedisClient as any)(redisUrl, { connectTimeout: 3000, lazyConnect: true });
      const redisStart = Date.now();
      await client.ping();
      const latency = Date.now() - redisStart;
      await client.quit();
      services.push({
        name: "redis",
        status: latency > 1000 ? "degraded" : "operational",
        latencyMs: latency,
        detail: "connected",
      });
      if (latency > 1000 && overall === "operational") overall = "degraded";
    } else {
      services.push({
        name: "redis",
        status: "operational",
        detail: "not_configured (optional)",
      });
    }
  } catch {
    services.push({
      name: "redis",
      status: "degraded",
      detail: "unavailable",
    });
    if (overall === "operational") overall = "degraded";
  }

  // -- Uptime & version ----
  const uptimeMs = Date.now() - startedAt;
  const uptimeHours = Math.floor(uptimeMs / 3_600_000);
  const uptimeMinutes = Math.floor((uptimeMs % 3_600_000) / 60_000);

  res.json({
    ok: overall !== "down",
    overall,
    version: process.env.npm_package_version || process.env.APP_VERSION || "1.0.0",
    uptime: `${uptimeHours}h ${uptimeMinutes}m`,
    uptimeMs,
    timestamp: new Date().toISOString(),
    services,
  });
});
