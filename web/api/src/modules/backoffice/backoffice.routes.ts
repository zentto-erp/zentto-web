/**
 * backoffice.routes.ts — Backoffice Zentto para gestión de clientes/tenants
 *
 * Todos los endpoints requieren X-Master-Key.
 *
 * GET    /v1/backoffice/tenants                         Lista tenants con licencia
 * GET    /v1/backoffice/tenants/:companyId              Detalle de un tenant
 * GET    /v1/backoffice/revenue                         Métricas de revenue
 * POST   /v1/backoffice/tenants/:companyId/apply-plan   Aplica módulos del plan
 * GET    /v1/backoffice/resources                       Uso de recursos de todos los tenants
 * GET    /v1/backoffice/cleanup                         Cola de limpieza (tenants para eliminar)
 * POST   /v1/backoffice/cleanup/scan                    Ejecuta scan automático de candidatos
 * POST   /v1/backoffice/cleanup/:queueId/action         Acción sobre un item (CANCEL|NOTIFY|CONFIRM_DELETE)
 * GET    /v1/backoffice/dashboard                       Métricas generales del servidor
 * GET    /v1/backoffice/backups                         Último backup por tenant (todos)
 * GET    /v1/backoffice/tenants/:companyId/backups      Historial de backups de un tenant
 * POST   /v1/backoffice/tenants/:companyId/backup       Lanza backup manual (async 202)
 */
import { Router } from "express";
import { z } from "zod";
import { requireMasterKey } from "../../middleware/master-key.js";
import { callSp } from "../../db/query.js";
import { applyPlanModules, getLicenseByCompany } from "../license/license.service.js";
import { dropTenantDatabase } from "./resource.service.js";
import { createTenantBackup, listTenantBackups, getLatestBackupsPerTenant, restoreTenantBackup, verifyStorageConnection, getBackupProgress } from "./backup.service.js";
import { obs } from "../integrations/observability.js";

const backofficeRouter = Router();

// Todos los endpoints de backoffice requieren master key
backofficeRouter.use(requireMasterKey);

// ── Schemas ───────────────────────────────────────────────────────────────────

const tenantListQuerySchema = z.object({
  page:     z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  status:   z.string().optional(),
  plan:     z.string().optional(),
  search:   z.string().optional(),
});

const applyPlanSchema = z.object({
  plan: z.enum(['FREE', 'STARTER', 'PRO', 'ENTERPRISE']),
});

// ── Tipos internos ────────────────────────────────────────────────────────────

interface TenantListRow {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  Plan: string;
  LicenseType: string | null;
  LicenseStatus: string | null;
  ExpiresAt: string | null;
  CreatedAt: string;
  UserCount: number;
  LastLogin: string | null;
  TotalCount: number;
}

interface TenantDetailRow {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  TradeName: string | null;
  OwnerEmail: string | null;
  FiscalCountryCode: string;
  BaseCurrency: string;
  Plan: string;
  LicenseType: string | null;
  LicenseStatus: string | null;
  LicenseKey: string | null;
  ExpiresAt: string | null;
  PaddleSubId: string | null;
  ContractRef: string | null;
  MaxUsers: number | null;
  CreatedAt: string;
  UpdatedAt: string | null;
  UserCount: number;
  LastLogin: string | null;
  TenantSubdomain: string | null;
  TenantStatus: string | null;
}

interface RevenueRow {
  Plan: string;
  LicenseType: string;
  TenantCount: number;
  EstimatedMRR: number;
}

interface CleanupRow {
  QueueId: number;
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  Reason: string;
  FlaggedAt: string;
  DeleteAfter: string;
  Status: string;
  DbSizeMB: number | null;
  LastLoginAt: string | null;
  DaysUntilDelete: number | null;
}

interface CleanupScanRow {
  NewCandidates: number;
  TotalPending: number;
}

interface CleanupProcessRow {
  ok: boolean;
  mensaje?: string;
}

interface ResourceRow extends CleanupRow {
  // CleanupRow ya incluye los campos de recursos
}

interface DashboardTenantRow {
  TenantCount: number;
  TrialCount: number;
}

interface DashboardCleanupRow {
  CleanupPending: number;
}

interface DashboardResourceRow {
  TotalDbSizeMB: number;
}

// ── GET /tenants ──────────────────────────────────────────────────────────────

backofficeRouter.get("/tenants", async (req, res) => {
  const parsed = tenantListQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  const { page, pageSize, status, plan, search } = parsed.data;

  try {
    const rows = await callSp<TenantListRow>(
      "usp_Sys_Backoffice_TenantList",
      {
        Page:     page,
        PageSize: pageSize,
        Status:   status ?? null,
        Plan:     plan ?? null,
        Search:   search ?? null,
      }
    );

    const total = rows[0]?.TotalCount ?? 0;
    res.json({
      ok: true,
      data: rows.map(({ TotalCount: _tc, ...rest }) => rest),
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.tenants.list.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── GET /tenants/:companyId ───────────────────────────────────────────────────

backofficeRouter.get("/tenants/:companyId", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: 'invalid_company_id' });
    return;
  }

  try {
    const rows = await callSp<TenantDetailRow>(
      "usp_Sys_Backoffice_TenantDetail",
      { CompanyId: companyId }
    );

    const tenant = rows[0];
    if (!tenant) {
      res.status(404).json({ error: 'tenant_not_found' });
      return;
    }

    res.json({ ok: true, data: tenant });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.tenants.detail.failed: ${msg}`, { module: 'backoffice', companyId });
    res.status(500).json({ error: msg });
  }
});

// ── GET /revenue ──────────────────────────────────────────────────────────────

backofficeRouter.get("/revenue", async (_req, res) => {
  try {
    const rows = await callSp<RevenueRow>(
      "usp_Sys_Backoffice_RevenueMetrics",
      {}
    );

    // Calcular totales agregados
    const totalMRR = rows.reduce((sum, r) => sum + (r.EstimatedMRR ?? 0), 0);
    const totalTenants = rows.reduce((sum, r) => sum + (r.TenantCount ?? 0), 0);

    res.json({
      ok: true,
      data: rows,
      summary: { totalMRR, totalTenants },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.revenue.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── POST /tenants/:companyId/apply-plan ───────────────────────────────────────

backofficeRouter.post("/tenants/:companyId/apply-plan", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: 'invalid_company_id' });
    return;
  }

  const parsed = applyPlanSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  try {
    const result = await applyPlanModules(companyId, parsed.data.plan);
    res.json({ ok: true, modulesApplied: result.modulesApplied });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.apply_plan.failed: ${msg}`, { module: 'backoffice', companyId });
    res.status(500).json({ error: msg });
  }
});

// ── GET /resources ─────────────────────────────────────────────────────────

backofficeRouter.get("/resources", async (req, res) => {
  const status = typeof req.query.status === "string" ? req.query.status : null;
  try {
    const rows = await callSp<CleanupRow>(
      "usp_Sys_Cleanup_List",
      { Status: status }
    );

    // Agrupar por tenant para el resumen de recursos
    const byTenant = new Map<number, ResourceRow>();
    for (const row of rows) {
      if (!byTenant.has(row.CompanyId)) {
        byTenant.set(row.CompanyId, { ...row });
      }
    }

    res.json({ ok: true, data: Array.from(byTenant.values()) });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.resources.list.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── GET /cleanup ───────────────────────────────────────────────────────────

backofficeRouter.get("/cleanup", async (req, res) => {
  const status = typeof req.query.status === "string" ? req.query.status : null;
  try {
    const rows = await callSp<CleanupRow>(
      "usp_Sys_Cleanup_List",
      { Status: status }
    );
    res.json({ ok: true, data: rows });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.cleanup.list.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── POST /cleanup/scan ─────────────────────────────────────────────────────

backofficeRouter.post("/cleanup/scan", async (_req, res) => {
  try {
    const rows = await callSp<CleanupScanRow>(
      "usp_Sys_Cleanup_Scan",
      {}
    );
    const row = rows[0];
    obs.audit('backoffice.cleanup.scan', { module: 'backoffice', newCandidates: row?.NewCandidates ?? 0 });
    res.json({ ok: true, newCandidates: row?.NewCandidates ?? 0, totalPending: row?.TotalPending ?? 0 });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.cleanup.scan.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── POST /cleanup/:queueId/action ──────────────────────────────────────────

const cleanupActionSchema = z.object({
  action: z.enum(['CANCEL', 'NOTIFY', 'CONFIRM_DELETE']),
});

backofficeRouter.post("/cleanup/:queueId/action", async (req, res) => {
  const queueId = Number(req.params.queueId);
  if (!queueId || isNaN(queueId)) {
    res.status(400).json({ error: 'invalid_queue_id' });
    return;
  }

  const parsed = cleanupActionSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'validation_error', issues: parsed.error.flatten() });
    return;
  }

  const { action } = parsed.data;

  // Protect DEMO company (CompanyId <= 1) from deletion
  if (action === 'CONFIRM_DELETE') {
    const preCheck = await callSp<CleanupRow>("usp_Sys_Cleanup_List", { Status: 'PENDING' });
    const target = preCheck.find(r => r.QueueId === queueId);
    if (target && target.CompanyId <= 1) {
      res.status(403).json({ error: 'demo_protected', message: 'La empresa demo no puede ser eliminada' });
      return;
    }
  }

  try {
    const rows = await callSp<CleanupProcessRow>(
      "usp_Sys_Cleanup_Process",
      { QueueId: queueId, Action: action }
    );

    const row = rows[0];
    if (!row?.ok) {
      res.status(400).json({ error: row?.mensaje ?? 'cleanup_process_failed' });
      return;
    }

    // Si la acción es eliminar, también eliminar la BD del tenant
    if (action === 'CONFIRM_DELETE') {
      // Obtener companyId y companyCode del registro procesado
      const cleanupRows = await callSp<CleanupRow>(
        "usp_Sys_Cleanup_List",
        { Status: 'CONFIRMED' }
      );
      const target = cleanupRows.find(r => r.QueueId === queueId);
      if (target) {
        const dropResult = await dropTenantDatabase(target.CompanyId, target.CompanyCode);
        if (!dropResult.ok) {
          obs.error(`backoffice.cleanup.drop_db.failed: ${dropResult.message}`, { module: 'backoffice', queueId, companyId: target.CompanyId });
          // Continuamos — el registro ya fue marcado, loguear el error pero no fallar el endpoint
        } else {
          obs.audit('backoffice.cleanup.db_dropped', { module: 'backoffice', companyId: target.CompanyId, companyCode: target.CompanyCode });
        }
      }
    }

    obs.audit(`backoffice.cleanup.action.${action.toLowerCase()}`, { module: 'backoffice', queueId });
    res.json({ ok: true, message: row.mensaje ?? 'ok' });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.cleanup.action.failed: ${msg}`, { module: 'backoffice', queueId, action });
    res.status(500).json({ error: msg });
  }
});

// ── GET /dashboard ─────────────────────────────────────────────────────────

backofficeRouter.get("/dashboard", async (_req, res) => {
  try {
    const GITHUB_TOKEN = process.env.GITHUB_PAT || '';
    const SUPPORT_REPO = 'zentto-erp/zentto-support';

    const [tenantRows, cleanupRows, resourceRows, revenueRows, openIssuesRes, closedIssuesRes] = await Promise.all([
      callSp<DashboardTenantRow>("usp_Sys_Backoffice_TenantList", { Page: 1, PageSize: 1, Status: null, Plan: null, Search: null }).catch(() => [] as DashboardTenantRow[]),
      callSp<DashboardCleanupRow>("usp_Sys_Cleanup_List", { Status: 'PENDING' }).catch(() => [] as DashboardCleanupRow[]),
      callSp<DashboardResourceRow>("usp_Sys_Cleanup_List", { Status: null }).catch(() => [] as DashboardResourceRow[]),
      callSp<RevenueRow>("usp_Sys_Backoffice_RevenueMetrics", {}).catch(() => [] as RevenueRow[]),
      // Support stats from GitHub
      fetch(`https://api.github.com/repos/${SUPPORT_REPO}/issues?state=open&per_page=100`, {
        headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: 'application/vnd.github+json' },
      }).then(r => r.json()).catch(() => []),
      fetch(`https://api.github.com/repos/${SUPPORT_REPO}/issues?state=closed&per_page=100`, {
        headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: 'application/vnd.github+json' },
      }).then(r => r.json()).catch(() => []),
    ]);

    const tenantCount = (tenantRows[0] as any)?.TotalCount ?? 0;
    const trialCount = tenantRows.reduce((sum, r) => sum + (r.TrialCount ?? 0), 0);
    const cleanupPending = cleanupRows.length;
    const totalDbSizeMB = (resourceRows as any[]).reduce((sum, r) => sum + (Number(r.DbSizeMB) || 0), 0);
    const estimatedMRR = revenueRows.reduce((sum, r) => sum + (r.EstimatedMRR ?? 0), 0);

    // Support ticket stats
    const openIssues = Array.isArray(openIssuesRes) ? openIssuesRes : [];
    const closedIssues = Array.isArray(closedIssuesRes) ? closedIssuesRes : [];
    const allIssues = [...openIssues, ...closedIssues];

    res.json({
      ok: true,
      data: {
        TotalTenants: tenantCount,
        TrialCount: trialCount,
        CleanupPending: cleanupPending,
        TotalDbMB: totalDbSizeMB,
        MRR: estimatedMRR,
        // Support stats
        TicketsOpen: openIssues.length,
        TicketsClosed: closedIssues.length,
        TicketsUrgent: openIssues.filter((i: any) => i.labels?.some((l: any) => l.name === 'urgent')).length,
        TicketsAiPending: openIssues.filter((i: any) => i.labels?.some((l: any) => l.name === 'ai-fix') && !i.labels?.some((l: any) => l.name === 'ai-pr')).length,
        TicketsAiResolved: allIssues.filter((i: any) => i.labels?.some((l: any) => l.name === 'ai-pr')).length,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    obs.error(`backoffice.dashboard.failed: ${msg}`, { module: 'backoffice' });
    res.status(500).json({ error: msg });
  }
});

// ── GET /kafka/topics ──────────────────────────────────────────────────────
// Returns Kafka topic activity metrics for the backoffice dashboard.

backofficeRouter.get("/kafka/topics", async (_req, res) => {
  try {
    const KAFKA_BROKERS = process.env.KAFKA_BROKERS || "";
    const KAFKA_ENABLED = process.env.KAFKA_ENABLED === "true";

    const topics = [
      "zentto.logs",
      "zentto.errors",
      "zentto.audit",
      "zentto.performance",
      "zentto.events",
      "zentto-notifications",
    ];

    if (!KAFKA_ENABLED || !KAFKA_BROKERS) {
      // Kafka not configured — return zeros
      return res.json({
        ok: true,
        kafkaEnabled: false,
        data: topics.map((t) => ({ topic: t, messageCount: 0 })),
      });
    }

    // Try to get topic metrics from Kafka admin API
    try {
      const { Kafka } = await import("kafkajs");
      const kafka = new Kafka({
        clientId: "zentto-backoffice",
        brokers: KAFKA_BROKERS.split(","),
        connectionTimeout: 5000,
        requestTimeout: 5000,
      });
      const admin = kafka.admin();
      await admin.connect();

      const topicOffsets = await Promise.all(
        topics.map(async (topic) => {
          try {
            const offsets = await admin.fetchTopicOffsets(topic);
            const total = offsets.reduce(
              (sum, p) => sum + (Number(p.high) - Number(p.low)),
              0
            );
            return { topic, messageCount: total };
          } catch {
            return { topic, messageCount: 0 };
          }
        })
      );

      await admin.disconnect();
      return res.json({ ok: true, kafkaEnabled: true, data: topicOffsets });
    } catch (kafkaErr) {
      // Kafka connection failed — return zeros with status
      return res.json({
        ok: true,
        kafkaEnabled: true,
        kafkaError: String(kafkaErr instanceof Error ? kafkaErr.message : kafkaErr),
        data: topics.map((t) => ({ topic: t, messageCount: 0 })),
      });
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    res.status(500).json({ error: msg });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// ANALYTICS — Cross-tenant observability (Elasticsearch queries)
// ═══════════════════════════════════════════════════════════════════════════

const ES_HOST = process.env.ELASTICSEARCH_HOST || 'http://172.18.0.1:9200';

async function esQuery(index: string, body: any): Promise<any> {
  const res = await fetch(`${ES_HOST}/${index}/_search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) return { aggregations: {}, hits: { total: { value: 0 }, hits: [] } };
  return res.json();
}

function esRange(range: string) {
  const map: Record<string, string> = {
    '1h': 'now-1h', '24h': 'now-24h', '7d': 'now-7d', '30d': 'now-30d', '90d': 'now-90d',
  };
  return map[range] || 'now-24h';
}

function esInterval(range: string) {
  return range === '1h' ? '5m' : range === '24h' ? '1h' : '1d';
}

// GET /analytics/overview — KPIs + charts (cross-tenant, no companyId filter)
backofficeRouter.get("/analytics/overview", async (req, res) => {
  try {
    const range = (req.query.range as string) || '24h';
    const gte = esRange(range);
    const interval = esInterval(range);

    const result = await esQuery('zentto-api-logs-*,zentto-api-events-*', {
      size: 0,
      query: { range: { '@timestamp': { gte } } },
      aggs: {
        total_requests: { value_count: { field: 'method' } },
        unique_users: { cardinality: { field: 'userId' } },
        avg_latency: { avg: { field: 'durationMs' } },
        error_count: { filter: { range: { statusCode: { gte: 500 } } } },
        requests_over_time: { date_histogram: { field: '@timestamp', fixed_interval: interval } },
        status_codes: { terms: { field: 'statusCode', size: 10 } },
        top_endpoints: { terms: { field: 'path', size: 15 } },
        events_by_type: { terms: { field: 'event', size: 20 } },
        by_company: { terms: { field: 'companyId', size: 50 } },
      },
    });

    const aggs = result.aggregations || {};
    const totalReqs = aggs.total_requests?.value || 0;
    res.json({
      ok: true, range,
      kpis: {
        totalRequests: totalReqs,
        uniqueUsers: aggs.unique_users?.value || 0,
        avgLatencyMs: Math.round(aggs.avg_latency?.value || 0),
        errorCount: aggs.error_count?.doc_count || 0,
        errorRate: totalReqs ? ((aggs.error_count?.doc_count || 0) / totalReqs * 100).toFixed(2) : '0',
      },
      charts: {
        requestsOverTime: (aggs.requests_over_time?.buckets || []).map((b: any) => ({
          date: b.key_as_string, count: b.doc_count,
        })),
        statusCodes: (aggs.status_codes?.buckets || []).map((b: any) => ({
          code: String(b.key), count: b.doc_count,
        })),
        topEndpoints: (aggs.top_endpoints?.buckets || []).map((b: any) => ({
          path: b.key, count: b.doc_count,
        })),
        eventsByType: (aggs.events_by_type?.buckets || []).map((b: any) => ({
          event: b.key, count: b.doc_count,
        })),
        byCompany: (aggs.by_company?.buckets || []).map((b: any) => ({
          companyId: b.key, count: b.doc_count,
        })),
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    res.status(500).json({ error: msg });
  }
});

// GET /analytics/performance — Latency, percentiles, slowest endpoints (cross-tenant)
backofficeRouter.get("/analytics/performance", async (req, res) => {
  try {
    const range = (req.query.range as string) || '24h';
    const gte = esRange(range);
    const interval = esInterval(range);

    const result = await esQuery('zentto-api-logs-*,zentto-api-performance-*', {
      size: 0,
      query: { range: { '@timestamp': { gte } } },
      aggs: {
        latency_percentiles: { percentiles: { field: 'durationMs', percents: [50, 75, 90, 95, 99] } },
        latency_over_time: {
          date_histogram: { field: '@timestamp', fixed_interval: interval },
          aggs: {
            avg_latency: { avg: { field: 'durationMs' } },
            p95: { percentiles: { field: 'durationMs', percents: [95] } },
          },
        },
        slowest_endpoints: {
          terms: { field: 'path', size: 10, order: { avg_duration: 'desc' } },
          aggs: {
            avg_duration: { avg: { field: 'durationMs' } },
            max_duration: { max: { field: 'durationMs' } },
          },
        },
        errors_by_path: {
          filter: { range: { statusCode: { gte: 400 } } },
          aggs: { paths: { terms: { field: 'path', size: 10 } } },
        },
      },
    });

    const aggs = result.aggregations || {};
    const pcts = aggs.latency_percentiles?.values || {};
    res.json({
      ok: true,
      percentiles: {
        p50: Math.round(pcts['50.0'] || 0), p75: Math.round(pcts['75.0'] || 0),
        p90: Math.round(pcts['90.0'] || 0), p95: Math.round(pcts['95.0'] || 0),
        p99: Math.round(pcts['99.0'] || 0),
      },
      latencyTrend: (aggs.latency_over_time?.buckets || []).map((b: any) => ({
        date: b.key_as_string,
        avgMs: Math.round(b.avg_latency?.value || 0),
        p95Ms: Math.round(b.p95?.values?.['95.0'] || 0),
      })),
      slowestEndpoints: (aggs.slowest_endpoints?.buckets || []).map((b: any) => ({
        path: b.key,
        avgMs: Math.round(b.avg_duration?.value || 0),
        maxMs: Math.round(b.max_duration?.value || 0),
        count: b.doc_count,
      })),
      errorsByPath: (aggs.errors_by_path?.paths?.buckets || []).map((b: any) => ({
        path: b.key, count: b.doc_count,
      })),
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    res.status(500).json({ error: msg });
  }
});

// GET /analytics/business — Business events cross-tenant
backofficeRouter.get("/analytics/business", async (req, res) => {
  try {
    const range = (req.query.range as string) || '30d';
    const gte = esRange(range);

    const result = await esQuery('zentto-api-events-*', {
      size: 0,
      query: { range: { '@timestamp': { gte } } },
      aggs: {
        invoices: { filter: { term: { event: 'invoice.created' } }, aggs: { trend: { date_histogram: { field: '@timestamp', fixed_interval: '1d' } } } },
        purchases: { filter: { term: { event: 'purchase.created' } } },
        payments: { filter: { term: { event: 'payment.created' } } },
        customers: { filter: { term: { event: 'customer.created' } } },
        pos_sales: { filter: { term: { event: 'pos.sale' } } },
        leads: { filter: { term: { event: 'crm.lead.created' } } },
        all_events: { terms: { field: 'event', size: 30 } },
      },
    });

    const aggs = result.aggregations || {};
    res.json({
      ok: true,
      summary: {
        invoices: aggs.invoices?.doc_count || 0,
        purchases: aggs.purchases?.doc_count || 0,
        payments: aggs.payments?.doc_count || 0,
        newCustomers: aggs.customers?.doc_count || 0,
        posSales: aggs.pos_sales?.doc_count || 0,
        leadsCreated: aggs.leads?.doc_count || 0,
      },
      invoicesTrend: (aggs.invoices?.trend?.buckets || []).map((b: any) => ({
        date: b.key_as_string, count: b.doc_count,
      })),
      allEvents: (aggs.all_events?.buckets || []).map((b: any) => ({
        event: b.key, total: b.doc_count,
      })),
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'internal_error';
    res.status(500).json({ error: msg });
  }
});

// ── GET /backups ───────────────────────────────────────────────────────────
// Devuelve el último backup de cada tenant (para el dashboard de backoffice).

backofficeRouter.get("/backups", async (_req, res) => {
  try {
    const rows = await getLatestBackupsPerTenant();
    res.json({ ok: true, data: rows });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`backoffice.backups.latest.failed: ${msg}`, { module: "backup" });
    res.status(500).json({ error: msg });
  }
});

// ── GET /tenants/:companyId/backups ────────────────────────────────────────
// Historial completo de backups de un tenant específico.

backofficeRouter.get("/tenants/:companyId/backups", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: "invalid_company_id" });
    return;
  }
  try {
    const rows = await listTenantBackups(companyId);
    res.json({ ok: true, data: rows });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`backoffice.backups.list.failed: ${msg}`, { module: "backup", companyId });
    res.status(500).json({ error: msg });
  }
});

// ── POST /tenants/:companyId/backup ────────────────────────────────────────
// Lanza un backup manual en background. Retorna 202 inmediatamente.

backofficeRouter.post("/tenants/:companyId/backup", async (req, res) => {
  const companyId = Number(req.params.companyId);
  if (!companyId || isNaN(companyId)) {
    res.status(400).json({ error: "invalid_company_id" });
    return;
  }

  try {
    const tenantRows = await callSp<{ CompanyCode: string; DbName: string }>(
      "usp_Sys_Backup_TenantInfo",
      { CompanyId: companyId }
    );
    const tenant = tenantRows[0];
    if (!tenant) {
      res.status(404).json({ error: "tenant_not_found" });
      return;
    }

    // Si la BD del tenant no existe como DB independiente, usar PG_DATABASE (shared DB en dev)
    const dbName = tenant.DbName || process.env.PG_DATABASE || 'zentto_dev';

    // Responder inmediatamente — el backup corre en background
    res.status(202).json({ ok: true, message: "backup_queued" });

    setImmediate(async () => {
      await createTenantBackup(
        companyId,
        tenant.CompanyCode,
        dbName,
        "backoffice-manual"
      );
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`backoffice.backup.trigger.failed: ${msg}`, { module: "backup", companyId });
    res.status(500).json({ error: msg });
  }
});

// ── GET /tenants/:companyId/backup/progress ────────────────────────────────
// Progreso en tiempo real de un backup en curso.

backofficeRouter.get("/tenants/:companyId/backup/progress", (req, res) => {
  const companyId = Number(req.params.companyId);
  const progress = getBackupProgress(companyId);
  if (!progress) {
    res.json({ ok: true, running: false });
    return;
  }
  const elapsedMs = Date.now() - progress.startedAt;
  res.json({
    ok: true,
    running: progress.phase !== "DONE" && progress.phase !== "FAILED",
    phase: progress.phase,
    percent: progress.percent,
    detail: progress.detail,
    elapsedSeconds: Math.round(elapsedMs / 1000),
  });
});

// ── GET /storage/status ────────────────────────────────────────────────────
// Verifica la conexión con Hetzner Object Storage.

backofficeRouter.get("/storage/status", async (_req, res) => {
  const result = await verifyStorageConnection();
  res.json({ ok: result.ok, message: result.message });
});

// ── POST /tenants/:companyId/restore/:backupId ─────────────────────────────
// Restaura una BD de tenant desde un backup. OPERACIÓN DE ALTO RIESGO.
// Solo procede si el tenant existe y el backupId pertenece a ese companyId.

backofficeRouter.post("/tenants/:companyId/restore/:backupId", async (req, res) => {
  const companyId = Number(req.params.companyId);
  const backupId  = Number(req.params.backupId);

  if (!companyId || isNaN(companyId) || !backupId || isNaN(backupId)) {
    res.status(400).json({ error: "invalid_params" });
    return;
  }

  try {
    // La restauración es asíncrona — puede tomar varios minutos
    res.status(202).json({ ok: true, message: "restore_queued" });

    setImmediate(async () => {
      await restoreTenantBackup(companyId, backupId);
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`backoffice.restore.trigger.failed: ${msg}`, { module: "backup", companyId, backupId });
    res.status(500).json({ error: msg });
  }
});

// ── POST /tenants/provision-full ───────────────────────────────────────────
// Provisioning unificado: crea company + admin + BD + subdomain + welcome email.
// Un solo POST hace todo el pipeline (mismo flujo que paddle.service.ts pero manual).

const provisionFullSchema = z.object({
  companyCode:  z.string().min(2).max(20).regex(/^[A-Z0-9]+$/),
  legalName:    z.string().min(2).max(100),
  ownerEmail:   z.string().email(),
  countryCode:  z.string().length(2).default("VE"),
  baseCurrency: z.string().length(3).default("USD"),
  plan:         z.enum(["FREE", "STARTER", "PRO", "ENTERPRISE"]).default("STARTER"),
  subdomain:    z.string().min(2).max(30).regex(/^[a-z0-9][a-z0-9-]*$/).optional(),
});

backofficeRouter.post("/tenants/provision-full", async (req, res) => {
  const parsed = provisionFullSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  const { companyCode, legalName, ownerEmail, countryCode, baseCurrency, plan, subdomain } = parsed.data;
  const { randomBytes } = await import("node:crypto");
  const tempPassword = randomBytes(8).toString("hex");

  try {
    // 1. Crear company + admin en BD master
    const { provisionTenant, sendWelcomeEmail } = await import("../tenants/tenant.service.js");
    const result = await provisionTenant({
      companyCode,
      legalName,
      ownerEmail,
      countryCode,
      baseCurrency,
      adminUserCode: "ADMIN",
      adminPassword: tempPassword,
      plan,
    });

    if (!result.ok) {
      res.status(400).json({ error: "provision_failed", message: result.mensaje });
      return;
    }

    obs.audit("backoffice.provision.company_created", {
      module: "backoffice",
      companyId: result.companyId,
      companyCode,
      plan,
    });

    // 2. Set subdomain si se proporcionó
    const tenantSubdomain = subdomain || companyCode.toLowerCase();
    await callSp("usp_Cfg_Tenant_SetSubdomain", {
      CompanyId: result.companyId,
      Subdomain: tenantSubdomain,
    }).catch(() => {});

    // 3. Provisionar BD del tenant (crea BD + migra + registra en sys.TenantDatabase)
    const { provisionTenantDatabase } = await import("../../db/provision-tenant-db.js");
    const dbResult = await provisionTenantDatabase(result.companyId, companyCode);

    if (!dbResult.ok) {
      obs.error(`backoffice.provision.db_failed: ${dbResult.error}`, {
        module: "backoffice",
        companyId: result.companyId,
      });
      // Company fue creada pero BD falló — retornar warning
      res.status(207).json({
        ok: true,
        warning: "database_provision_failed",
        message: dbResult.error,
        companyId: result.companyId,
        tenantUrl: `https://${tenantSubdomain}.zentto.net`,
      });
      return;
    }

    obs.audit("backoffice.provision.db_created", {
      module: "backoffice",
      companyId: result.companyId,
      dbName: dbResult.dbName,
    });

    // 4. Enviar email de bienvenida (no bloquea)
    const tenantUrl = `https://${tenantSubdomain}.zentto.net`;
    sendWelcomeEmail(ownerEmail, legalName, tempPassword, result.companyId, tenantUrl)
      .catch((err) => console.error("[backoffice] Error enviando welcome email:", err));

    res.json({
      ok: true,
      companyId: result.companyId,
      companyCode,
      subdomain: tenantSubdomain,
      tenantUrl,
      dbName: dbResult.dbName,
      plan,
      adminUser: "ADMIN",
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    obs.error(`backoffice.provision.failed: ${msg}`, { module: "backoffice", companyCode });
    res.status(500).json({ error: msg });
  }
});

export default backofficeRouter;
