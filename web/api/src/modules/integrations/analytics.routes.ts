import { Router, Request, Response, NextFunction } from 'express';

const router = Router();

const ES_HOST = process.env.ELASTICSEARCH_HOST || 'http://172.18.0.1:9200';

async function esQuery(index: string, body: any): Promise<any> {
  const res = await fetch(`${ES_HOST}/${index}/_search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return res.json();
}

// GET /v1/analytics/debug — diagnóstico del pipeline Kafka→ES (solo admins)
router.get('/debug', async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (!user?.isAdmin) return res.status(403).json({ error: 'forbidden' });

    // 1. Listar índices zentto-*
    const catRes = await fetch(`${ES_HOST}/_cat/indices/zentto-*?format=json&h=index,docs.count,store.size,status`);
    const indices = catRes.ok ? await catRes.json() : [];

    // 2. Muestra de un documento de cada índice (sin filtro de companyId)
    const samples: Record<string, any> = {};
    for (const idx of indices.slice(0, 5)) {
      const sample = await esQuery(idx.index, { size: 1, sort: [{ '@timestamp': 'desc' }] });
      samples[idx.index] = sample.hits?.hits?.[0]?._source || null;
    }

    // 3. Verificar conectividad ES
    const pingRes = await fetch(`${ES_HOST}/_cluster/health`);
    const health = pingRes.ok ? await pingRes.json() : { error: 'ES no disponible' };

    res.json({
      ok: true,
      esHost: ES_HOST,
      clusterHealth: health,
      indices,
      sampleDocs: samples,
    });
  } catch (err: any) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// GET /v1/analytics/dashboard — KPIs principales del cliente
router.get('/dashboard', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = (req as any).user;
    const companyId = user?.companyId;
    const range = (req.query.range as string) || '24h';

    const rangeMap: Record<string, string> = {
      '1h': 'now-1h', '24h': 'now-24h', '7d': 'now-7d', '30d': 'now-30d', '90d': 'now-90d',
    };
    const gte = rangeMap[range] || 'now-24h';

    const result = await esQuery('zentto-api-logs-*,zentto-api-events-*', {
      size: 0,
      query: {
        bool: {
          must: [
            { term: { companyId } },
            { range: { '@timestamp': { gte } } },
          ],
        },
      },
      aggs: {
        total_requests: { value_count: { field: 'method' } },
        unique_users: { cardinality: { field: 'userId' } },
        avg_latency: { avg: { field: 'durationMs' } },
        error_count: {
          filter: { range: { statusCode: { gte: 500 } } },
        },
        events_by_type: {
          terms: { field: 'event', size: 20 },
        },
        requests_over_time: {
          date_histogram: { field: '@timestamp', fixed_interval: range === '1h' ? '5m' : range === '24h' ? '1h' : '1d' },
        },
        top_endpoints: {
          terms: { field: 'path', size: 10 },
        },
        status_codes: {
          terms: { field: 'statusCode', size: 10 },
        },
      },
    });

    const aggs = result.aggregations || {};
    res.json({
      ok: true,
      range,
      kpis: {
        totalRequests: aggs.total_requests?.value || 0,
        uniqueUsers: aggs.unique_users?.value || 0,
        avgLatencyMs: Math.round(aggs.avg_latency?.value || 0),
        errorCount: aggs.error_count?.doc_count || 0,
        errorRate: aggs.total_requests?.value
          ? ((aggs.error_count?.doc_count || 0) / aggs.total_requests.value * 100).toFixed(2)
          : '0',
      },
      charts: {
        requestsOverTime: (aggs.requests_over_time?.buckets || []).map((b: any) => ({
          date: b.key_as_string,
          count: b.doc_count,
        })),
        topEndpoints: (aggs.top_endpoints?.buckets || []).map((b: any) => ({
          path: b.key,
          count: b.doc_count,
        })),
        statusCodes: (aggs.status_codes?.buckets || []).map((b: any) => ({
          code: b.key,
          count: b.doc_count,
        })),
        eventsByType: (aggs.events_by_type?.buckets || []).map((b: any) => ({
          event: b.key,
          count: b.doc_count,
        })),
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /v1/analytics/activity — Actividad de usuarios de la empresa
router.get('/activity', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId;
    const range = (req.query.range as string) || '7d';
    const gte = `now-${range}`;

    const result = await esQuery('zentto-api-logs-*', {
      size: 0,
      query: {
        bool: {
          must: [
            { term: { companyId } },
            { range: { '@timestamp': { gte } } },
          ],
        },
      },
      aggs: {
        by_user: {
          terms: { field: 'userId', size: 50 },
          aggs: {
            last_seen: { max: { field: '@timestamp' } },
            request_count: { value_count: { field: 'method' } },
            modules: { terms: { field: 'path', size: 5 } },
          },
        },
        by_module: {
          terms: { field: 'path', size: 20 },
        },
        activity_heatmap: {
          date_histogram: { field: '@timestamp', fixed_interval: '1h' },
          aggs: {
            users: { cardinality: { field: 'userId' } },
          },
        },
      },
    });

    const aggs = result.aggregations || {};
    res.json({
      ok: true,
      users: (aggs.by_user?.buckets || []).map((b: any) => ({
        userId: b.key,
        requestCount: b.request_count?.value || b.doc_count,
        lastSeen: b.last_seen?.value_as_string,
        topModules: (b.modules?.buckets || []).map((m: any) => m.key),
      })),
      moduleUsage: (aggs.by_module?.buckets || []).map((b: any) => ({
        path: b.key,
        count: b.doc_count,
      })),
      heatmap: (aggs.activity_heatmap?.buckets || []).map((b: any) => ({
        hour: b.key_as_string,
        requests: b.doc_count,
        users: b.users?.value || 0,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /v1/analytics/business — Eventos de negocio del cliente
router.get('/business', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId;
    const range = (req.query.range as string) || '30d';
    const gte = `now-${range}`;

    const result = await esQuery('zentto-api-events-*', {
      size: 0,
      query: {
        bool: {
          must: [
            { term: { companyId } },
            { range: { '@timestamp': { gte } } },
          ],
        },
      },
      aggs: {
        invoices: {
          filter: { term: { event: 'invoice.created' } },
          aggs: {
            over_time: { date_histogram: { field: '@timestamp', fixed_interval: '1d' } },
          },
        },
        purchases: {
          filter: { term: { event: 'purchase.created' } },
        },
        payments: {
          filter: { term: { event: 'payment.created' } },
        },
        customers_created: {
          filter: { term: { event: 'customer.created' } },
        },
        pos_sales: {
          filter: { term: { event: 'pos.sale' } },
        },
        leads_created: {
          filter: { term: { event: 'crm.lead.created' } },
        },
        all_events: {
          terms: { field: 'event', size: 30 },
          aggs: {
            trend: { date_histogram: { field: '@timestamp', fixed_interval: '1d' } },
          },
        },
      },
    });

    const aggs = result.aggregations || {};
    res.json({
      ok: true,
      summary: {
        invoices: aggs.invoices?.doc_count || 0,
        purchases: aggs.purchases?.doc_count || 0,
        payments: aggs.payments?.doc_count || 0,
        newCustomers: aggs.customers_created?.doc_count || 0,
        posSales: aggs.pos_sales?.doc_count || 0,
        leadsCreated: aggs.leads_created?.doc_count || 0,
      },
      invoicesTrend: (aggs.invoices?.over_time?.buckets || []).map((b: any) => ({
        date: b.key_as_string,
        count: b.doc_count,
      })),
      allEvents: (aggs.all_events?.buckets || []).map((b: any) => ({
        event: b.key,
        total: b.doc_count,
        trend: (b.trend?.buckets || []).map((t: any) => ({
          date: t.key_as_string,
          count: t.doc_count,
        })),
      })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /v1/analytics/performance — Rendimiento de la empresa
router.get('/performance', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId;
    const range = (req.query.range as string) || '24h';
    const gte = `now-${range}`;

    const result = await esQuery('zentto-api-logs-*,zentto-api-performance-*', {
      size: 0,
      query: {
        bool: {
          must: [
            { term: { companyId } },
            { range: { '@timestamp': { gte } } },
          ],
        },
      },
      aggs: {
        latency_percentiles: {
          percentiles: { field: 'durationMs', percents: [50, 75, 90, 95, 99] },
        },
        latency_over_time: {
          date_histogram: { field: '@timestamp', fixed_interval: range === '24h' ? '1h' : '1d' },
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
            count: { value_count: { field: 'method' } },
          },
        },
        errors_by_path: {
          filter: { range: { statusCode: { gte: 400 } } },
          aggs: {
            paths: { terms: { field: 'path', size: 10 } },
          },
        },
      },
    });

    const aggs = result.aggregations || {};
    const pcts = aggs.latency_percentiles?.values || {};
    res.json({
      ok: true,
      percentiles: {
        p50: Math.round(pcts['50.0'] || 0),
        p75: Math.round(pcts['75.0'] || 0),
        p90: Math.round(pcts['90.0'] || 0),
        p95: Math.round(pcts['95.0'] || 0),
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
        count: b.count?.value || b.doc_count,
      })),
      errorsByPath: (aggs.errors_by_path?.paths?.buckets || []).map((b: any) => ({
        path: b.key,
        count: b.doc_count,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// GET /v1/analytics/audit — Auditoría del cliente (quién hizo qué)
router.get('/audit', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId;
    const { range = '7d', action, userId, module: mod, page = '1', limit = '50' } = req.query;
    const gte = `now-${range}`;

    const must: any[] = [
      { term: { companyId } },
      { range: { '@timestamp': { gte } } },
    ];
    if (action) must.push({ term: { 'action': action } });
    if (userId) must.push({ term: { userId: Number(userId) } });
    if (mod) must.push({ term: { 'module': mod } });

    const from = (Number(page) - 1) * Number(limit);

    const result = await esQuery('zentto-api-audit-*', {
      size: Number(limit),
      from,
      sort: [{ '@timestamp': 'desc' }],
      query: { bool: { must } },
      aggs: {
        actions: { terms: { field: 'action', size: 20 } },
        by_user: { terms: { field: 'userId', size: 20 } },
        by_module: { terms: { field: 'module', size: 20 } },
      },
    });

    res.json({
      ok: true,
      total: result.hits?.total?.value || 0,
      records: (result.hits?.hits || []).map((h: any) => ({
        timestamp: h._source['@timestamp'] || h._source.timestamp,
        action: h._source.action,
        userId: h._source.userId,
        userName: h._source.userName,
        module: h._source.module,
        entity: h._source.entity,
        entityId: h._source.entityId,
        ip: h._source.ip,
        before: h._source.before,
        after: h._source.after,
      })),
      filters: {
        actions: (result.aggregations?.actions?.buckets || []).map((b: any) => ({ value: b.key, count: b.doc_count })),
        users: (result.aggregations?.by_user?.buckets || []).map((b: any) => ({ value: b.key, count: b.doc_count })),
        modules: (result.aggregations?.by_module?.buckets || []).map((b: any) => ({ value: b.key, count: b.doc_count })),
      },
    });
  } catch (err) {
    next(err);
  }
});

export { router as analyticsRouter };
