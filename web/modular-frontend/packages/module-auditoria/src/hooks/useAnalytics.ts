import { useQuery } from '@tanstack/react-query';
import { apiGet } from '@zentto/shared-api';

export type TimeRange = '1h' | '24h' | '7d' | '30d' | '90d';

// --- Dashboard KPIs ---
export interface AnalyticsDashboard {
  range: string;
  kpis: {
    totalRequests: number;
    uniqueUsers: number;
    avgLatencyMs: number;
    errorCount: number;
    errorRate: string;
  };
  charts: {
    requestsOverTime: { date: string; count: number }[];
    topEndpoints: { path: string; count: number }[];
    statusCodes: { code: number; count: number }[];
    eventsByType: { event: string; count: number }[];
  };
}

export function useAnalyticsDashboard(range: TimeRange = '24h') {
  return useQuery<AnalyticsDashboard>({
    queryKey: ['analytics-dashboard', range],
    queryFn: () => apiGet(`/v1/analytics/dashboard?range=${range}`),
    refetchInterval: 30000, // refresh cada 30s
    staleTime: 10000,
  });
}

// --- Actividad de usuarios ---
export interface UserActivity {
  users: {
    userId: number;
    requestCount: number;
    lastSeen: string;
    topModules: string[];
  }[];
  moduleUsage: { path: string; count: number }[];
  heatmap: { hour: string; requests: number; users: number }[];
}

export function useAnalyticsActivity(range: TimeRange = '7d') {
  return useQuery<UserActivity>({
    queryKey: ['analytics-activity', range],
    queryFn: () => apiGet(`/v1/analytics/activity?range=${range}`),
    staleTime: 60000,
  });
}

// --- Eventos de negocio ---
export interface BusinessEvents {
  summary: {
    invoices: number;
    purchases: number;
    payments: number;
    newCustomers: number;
    posSales: number;
    leadsCreated: number;
  };
  invoicesTrend: { date: string; count: number }[];
  allEvents: {
    event: string;
    total: number;
    trend: { date: string; count: number }[];
  }[];
}

export function useAnalyticsBusiness(range: TimeRange = '30d') {
  return useQuery<BusinessEvents>({
    queryKey: ['analytics-business', range],
    queryFn: () => apiGet(`/v1/analytics/business?range=${range}`),
    staleTime: 60000,
  });
}

// --- Performance ---
export interface PerformanceData {
  percentiles: { p50: number; p75: number; p90: number; p95: number; p99: number };
  latencyTrend: { date: string; avgMs: number; p95Ms: number }[];
  slowestEndpoints: { path: string; avgMs: number; maxMs: number; count: number }[];
  errorsByPath: { path: string; count: number }[];
}

export function useAnalyticsPerformance(range: TimeRange = '24h') {
  return useQuery<PerformanceData>({
    queryKey: ['analytics-performance', range],
    queryFn: () => apiGet(`/v1/analytics/performance?range=${range}`),
    refetchInterval: 30000,
    staleTime: 10000,
  });
}

// --- Auditoría detallada ---
export interface AuditRecord {
  timestamp: string;
  action: string;
  userId: number;
  userName: string;
  module: string;
  entity: string;
  entityId: string;
  ip: string;
  before: any;
  after: any;
}

export interface AuditData {
  total: number;
  records: AuditRecord[];
  filters: {
    actions: { value: string; count: number }[];
    users: { value: number; count: number }[];
    modules: { value: string; count: number }[];
  };
}

export function useAnalyticsAudit(params: {
  range?: TimeRange;
  action?: string;
  userId?: number;
  module?: string;
  page?: number;
  limit?: number;
}) {
  const { range = '7d', action, userId, module: mod, page = 1, limit = 50 } = params;
  const qs = new URLSearchParams({ range, page: String(page), limit: String(limit) });
  if (action) qs.set('action', action);
  if (userId) qs.set('userId', String(userId));
  if (mod) qs.set('module', mod);

  return useQuery<AuditData>({
    queryKey: ['analytics-audit', range, action, userId, mod, page],
    queryFn: () => apiGet(`/v1/analytics/audit?${qs}`),
    staleTime: 30000,
  });
}
