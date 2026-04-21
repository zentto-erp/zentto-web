import { Router } from "express";
import { callSp } from "../../db/query.js";
import { resolveTenantBySubdomain } from "../tenants/tenant.service.js";

export const statusRouter = Router();

const startedAt = Date.now();

interface ServiceStatus {
  name: string;
  status: "operational" | "degraded" | "down";
  latencyMs?: number;
  detail?: string;
}

interface TenantDimension {
  subdomain: string;
  found: boolean;
  companyId?: number;
  companyCode?: string;
  tenantStatus?: string;
  plan?: string;
  isActive?: boolean;
}

/**
 * GET /v1/status -- Pagina publica de status
 *
 * Retorna health de cada componente: db, redis, api, uptime, version.
 * No requiere autenticacion.
 *
 * Query params:
 *   - tenant: subdominio del tenant (ej. ?tenant=acme). Si se pasa, agrega
 *     la dimension `tenant` al response con el estado de ese tenant
 *     (TenantStatus, Plan, IsActive). Si el tenant no existe o esta
 *     inactivo, el overall global se marca como 'degraded'.
 *
 * Referencia: gap G-08 del audit del Lote 1 multinicho
 * (docs/lanzamiento/AUDIT_INTEGRACION.md). Esta es la iteracion v1 — el
 * dashboard operativo en apps/panel y los tags de observability por-tenant
 * quedan para lote posterior (Fase 2).
 */
statusRouter.get("/", async (req, res) => {
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

  // -- Tenant dimension (opcional, via ?tenant=<subdomain>) ----
  let tenantDim: TenantDimension | undefined;
  const tenantParam =
    typeof req.query.tenant === "string" ? req.query.tenant.trim().toLowerCase() : "";
  if (tenantParam) {
    try {
      const tenant = await resolveTenantBySubdomain(tenantParam);
      if (!tenant) {
        tenantDim = { subdomain: tenantParam, found: false };
        if (overall === "operational") overall = "degraded";
      } else {
        tenantDim = {
          subdomain: tenantParam,
          found: true,
          companyId: tenant.CompanyId,
          companyCode: tenant.CompanyCode,
          tenantStatus: tenant.TenantStatus,
          plan: tenant.Plan,
          isActive: tenant.IsActive,
        };
        const tenantDegraded =
          !tenant.IsActive ||
          tenant.TenantStatus === "suspended" ||
          tenant.TenantStatus === "pending";
        if (tenantDegraded && overall === "operational") overall = "degraded";
      }
    } catch (err) {
      tenantDim = {
        subdomain: tenantParam,
        found: false,
      };
      services.push({
        name: "tenant_resolver",
        status: "degraded",
        detail: err instanceof Error ? err.message : "tenant_lookup_failed",
      });
      if (overall === "operational") overall = "degraded";
    }
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
    tenant: tenantDim,
  });
});
