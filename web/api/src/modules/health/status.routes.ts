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
  /** Metricas operativas adicionales (solo si ?detailed=true y resolvio OK). */
  health?: TenantHealthSnapshot;
}

interface TenantHealthSnapshot {
  subscriptionStatus: string | null;
  subscriptionSource: string | null;
  trialEndsAt: string | null;
  currentPeriodEnd: string | null;
  monthlyRecurringRevenue: number;
  activeUserCount: number;
  lastUserActivityAt: string | null;
  leadsLast24h: number;
  leadsConverted: number;
  tenantDbProvisioned: boolean;
  tenantDbName: string | null;
  snapshotAt: string;
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
 *   - detailed: si ?detailed=true y tenant resuelve, agrega `tenant.health`
 *     con metricas operativas (suscripcion, usuarios, leads, BD por-tenant)
 *     via usp_Sys_HealthCheck_Tenant. Usado por dashboard ops (Lote 4.A).
 *
 * Referencia: gap G-08 del audit del Lote 1 multinicho
 * (docs/lanzamiento/AUDIT_INTEGRACION.md). v1 (Lote 2.E) agrego dimension
 * tenant; v2 (Lote 4.A, este) agrega detalle operativo.
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
  const detailed = req.query.detailed === "true" || req.query.detailed === "1";
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

        // Enriquecer con snapshot operativo si el caller lo pidio (v2).
        if (detailed) {
          try {
            const healthRows = await callSp<{
              SubscriptionStatus: string | null;
              SubscriptionSource: string | null;
              TrialEndsAt: Date | null;
              CurrentPeriodEnd: Date | null;
              MonthlyRecurringRevenue: number | string | null;
              ActiveUserCount: number;
              LastUserActivityAt: Date | null;
              LeadsLast24h: number;
              LeadsConverted: number;
              TenantDbProvisioned: boolean | null;
              TenantDbName: string | null;
              SnapshotAt: Date;
            }>("usp_Sys_HealthCheck_Tenant", { Subdomain: tenantParam });
            const h = healthRows[0];
            if (h) {
              tenantDim.health = {
                subscriptionStatus: h.SubscriptionStatus,
                subscriptionSource: h.SubscriptionSource,
                trialEndsAt: h.TrialEndsAt ? new Date(h.TrialEndsAt).toISOString() : null,
                currentPeriodEnd: h.CurrentPeriodEnd ? new Date(h.CurrentPeriodEnd).toISOString() : null,
                monthlyRecurringRevenue: Number(h.MonthlyRecurringRevenue ?? 0),
                activeUserCount: Number(h.ActiveUserCount ?? 0),
                lastUserActivityAt: h.LastUserActivityAt ? new Date(h.LastUserActivityAt).toISOString() : null,
                leadsLast24h: Number(h.LeadsLast24h ?? 0),
                leadsConverted: Number(h.LeadsConverted ?? 0),
                tenantDbProvisioned: Boolean(h.TenantDbProvisioned),
                tenantDbName: h.TenantDbName,
                snapshotAt: new Date(h.SnapshotAt).toISOString(),
              };
              // Suscripcion vencida/cancelada baja overall.
              if (
                h.SubscriptionStatus === "cancelled" ||
                h.SubscriptionStatus === "expired" ||
                h.SubscriptionStatus === "past_due"
              ) {
                if (overall === "operational") overall = "degraded";
              }
            }
          } catch (hErr) {
            // Detailed query fallo: no rompemos el endpoint base — solo
            // marcamos el servicio como degradado para el caller sepa.
            services.push({
              name: "tenant_health_detail",
              status: "degraded",
              detail: hErr instanceof Error ? hErr.message : "health_detail_failed",
            });
            if (overall === "operational") overall = "degraded";
          }
        }
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
