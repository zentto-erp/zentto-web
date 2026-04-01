"use client";

import { useState, useEffect, useCallback } from "react";
import {
  Box, Typography, Card, CardContent, Chip, IconButton, LinearProgress,
  Tooltip, Stack, Paper, Tabs, Tab, Skeleton,
  Table, TableHead, TableRow, TableCell, TableBody,
  ToggleButton, ToggleButtonGroup, Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Refresh as RefreshIcon, Storage as StorageIcon, People as PeopleIcon,
  AttachMoney as MoneyIcon, Warning as WarningIcon, BugReport as BugIcon,
  SmartToy as SmartToyIcon, TrendingUp, Speed, ErrorOutline,
  Receipt, ShoppingCart, Payment, PersonAdd, PointOfSale, Leaderboard,
} from "@mui/icons-material";
import { LineChart } from "@mui/x-charts/LineChart";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";
import { useBackoffice, apiFetch, type DashboardData } from "./context";

type TimeRange = "1h" | "24h" | "7d" | "30d" | "90d";

// ─── KPI Card (same pattern as Analytics) ────────────────────────────────────

function KpiCard({ title, value, subtitle, icon, color, loading }: {
  title: string; value: string | number; subtitle?: string;
  icon: React.ReactNode; color: string; loading?: boolean;
}) {
  if (loading) return <Skeleton variant="rounded" height={120} />;
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <Box>
            <Typography variant="body2" color="text.secondary">{title}</Typography>
            <Typography variant="h4" fontWeight={700} sx={{ my: 0.5 }}>{value}</Typography>
            {subtitle && <Typography variant="caption" color="text.secondary">{subtitle}</Typography>}
          </Box>
          <Box sx={{ p: 1, borderRadius: 2, bgcolor: `${color}15`, color }}>{icon}</Box>
        </Box>
      </CardContent>
    </Card>
  );
}

// ─── Activity Card ───────────────────────────────────────────────────────────

function ActivityCard({ label, value, icon, loading }: {
  label: string; value: number; icon: React.ReactNode; loading?: boolean;
}) {
  if (loading) return <Skeleton variant="rounded" height={80} />;
  return (
    <Card variant="outlined" sx={{ textAlign: "center", py: 1 }}>
      <CardContent sx={{ py: "8px !important" }}>
        <Box sx={{ color: "text.secondary", mb: 0.5 }}>{icon}</Box>
        <Typography variant="h5" fontWeight={700}>{value}</Typography>
        <Typography variant="caption" color="text.secondary">{label}</Typography>
      </CardContent>
    </Card>
  );
}

// ─── Chart helpers ───────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
  "200": "#4caf50", "201": "#66bb6a", "204": "#81c784",
  "400": "#ff9800", "401": "#ffa726", "403": "#ffb74d", "404": "#ffcc80",
  "500": "#f44336", "502": "#e57373", "503": "#ef9a9a",
};

function ChartPaper({ title, children, height = 300 }: { title: string; children: React.ReactNode; height?: number }) {
  return (
    <Paper variant="outlined" sx={{ p: 2, height }}>
      <Typography variant="subtitle1" fontWeight={600} mb={1}>{title}</Typography>
      {children}
    </Paper>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB: Overview (KPIs + tenants + main charts)
// ═══════════════════════════════════════════════════════════════════════════════

function OverviewTab({ token, range }: { token: string; range: TimeRange }) {
  const [dash, setDash] = useState<DashboardData | null>(null);
  const [analytics, setAnalytics] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    const [d, a] = await Promise.allSettled([
      apiFetch<{ ok: boolean; data: DashboardData }>("/v1/backoffice/dashboard", token),
      apiFetch<any>(`/v1/backoffice/analytics/overview?range=${range}`, token),
    ]);
    if (d.status === "fulfilled") setDash(d.value.data);
    if (a.status === "fulfilled") setAnalytics(a.value);
    setLoading(false);
  }, [token, range]);

  useEffect(() => { load(); }, [load]);

  const kpis = analytics?.kpis;
  const charts = analytics?.charts;

  return (
    <Box>
      {/* Business KPIs */}
      <Grid container spacing={2} mb={3}>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Total Tenants" value={dash?.TotalTenants ?? "--"} icon={<PeopleIcon />} color="#1976d2" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="MRR Estimado" value={dash ? `$${(Number(dash.MRR) || 0).toLocaleString("es-VE")}` : "--"} icon={<MoneyIcon />} color="#2e7d32" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Operaciones" value={kpis?.totalRequests?.toLocaleString() || "0"} subtitle={`${range} período`} icon={<TrendingUp />} color="#6C63FF" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Latencia" value={`${kpis?.avgLatencyMs || 0}ms`} subtitle={`P95: ${kpis?.p95Ms || "—"}`} icon={<Speed />} color="#ff9800" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Errores" value={kpis?.errorCount || 0} subtitle={`Tasa: ${kpis?.errorRate || 0}%`} icon={<ErrorOutline />} color="#f44336" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Usuarios" value={kpis?.uniqueUsers || 0} subtitle="Únicos" icon={<People />} color="#00C9A7" loading={loading} />
        </Grid>
      </Grid>

      {/* Tickets row */}
      <Grid container spacing={2} mb={3}>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Tickets Abiertos" value={dash?.TicketsOpen ?? 0} icon={<BugIcon />} color="#d32f2f" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="IA Resueltos" value={dash?.TicketsAiResolved ?? 0} icon={<SmartToyIcon />} color="#2e7d32" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="BD Total" value={dash ? `${Number(dash.TotalDbMB).toFixed(1)} MB` : "--"} icon={<StorageIcon />} color="#0288d1" loading={loading} />
        </Grid>
        <Grid size={{ xs: 6, sm: 4, md: 2 }}>
          <KpiCard title="Cola Pendiente" value={dash?.CleanupPending ?? 0} icon={<WarningIcon />} color="#ed6c02" loading={loading} />
        </Grid>
      </Grid>

      {/* Charts row 1 */}
      <Grid container spacing={3} mb={3}>
        <Grid size={{ xs: 12, md: 8 }}>
          <ChartPaper title="Actividad en el tiempo" height={340}>
            {loading || !charts?.requestsOverTime?.length ? (
              <Skeleton variant="rounded" height={260} />
            ) : (
              <LineChart
                xAxis={[{ data: charts.requestsOverTime.map((_: any, i: number) => i), scaleType: "point", valueFormatter: (_: any, ctx: any) => charts.requestsOverTime[ctx.location === "tick" ? _ : 0]?.date?.split("T")[1]?.substring(0, 5) || "" }]}
                series={[{ data: charts.requestsOverTime.map((d: any) => d.count), area: true, color: "#6C63FF", label: "Requests" }]}
                height={260}
                slotProps={{ legend: { hidden: true } }}
              />
            )}
          </ChartPaper>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <ChartPaper title="Códigos de respuesta" height={340}>
            {loading || !charts?.statusCodes?.length ? (
              <Skeleton variant="rounded" height={260} />
            ) : (
              <PieChart
                series={[{
                  data: charts.statusCodes.map((s: any, i: number) => ({
                    id: i, value: s.count, label: String(s.code),
                    color: STATUS_COLORS[s.code] || "#bdbdbd",
                  })),
                  innerRadius: 40, paddingAngle: 2, cornerRadius: 4,
                }]}
                height={260}
              />
            )}
          </ChartPaper>
        </Grid>
      </Grid>

      {/* Charts row 2 */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <ChartPaper title="Eventos de negocio" height={300}>
            {loading || !charts?.eventsByType?.length ? (
              <Alert severity="info" sx={{ mt: 2 }}>Sin eventos en este período</Alert>
            ) : (
              <BarChart
                xAxis={[{ scaleType: "band", data: charts.eventsByType.slice(0, 10).map((e: any) => e.event.split(".").pop()) }]}
                series={[{ data: charts.eventsByType.slice(0, 10).map((e: any) => e.count), color: "#9c27b0", label: "Eventos" }]}
                height={230}
                slotProps={{ legend: { hidden: true } }}
              />
            )}
          </ChartPaper>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <ChartPaper title="Top Endpoints" height={300}>
            {loading || !charts?.topEndpoints?.length ? (
              <Alert severity="info" sx={{ mt: 2 }}>Sin datos</Alert>
            ) : (
              <BarChart
                yAxis={[{ scaleType: "band", data: charts.topEndpoints.slice(0, 8).map((e: any) => e.path.replace("/v1/", "").replace("/api/v1/", "")) }]}
                series={[{ data: charts.topEndpoints.slice(0, 8).map((e: any) => e.count), color: "#1976d2" }]}
                layout="horizontal"
                height={230}
                slotProps={{ legend: { hidden: true } }}
              />
            )}
          </ChartPaper>
        </Grid>
      </Grid>
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB: Performance (Latency, P95, slowest endpoints)
// ═══════════════════════════════════════════════════════════════════════════════

function PerformanceTab({ token, range }: { token: string; range: TimeRange }) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    apiFetch<any>(`/v1/backoffice/analytics/performance?range=${range}`, token)
      .then(setData).catch(() => setData(null)).finally(() => setLoading(false));
  }, [token, range]);

  const pcts = data?.percentiles;

  return (
    <Box>
      {/* Percentile cards */}
      <Grid container spacing={2} mb={3}>
        {["p50", "p75", "p90", "p95", "p99"].map((p) => (
          <Grid key={p} size={{ xs: 4, sm: 2.4 }}>
            <KpiCard title={p.toUpperCase()} value={`${pcts?.[p] || 0}ms`} icon={<Speed />} color={p === "p99" ? "#f44336" : p === "p95" ? "#ff9800" : "#4caf50"} loading={loading} />
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3} mb={3}>
        <Grid size={{ xs: 12, md: 8 }}>
          <ChartPaper title="Latencia (Promedio vs P95)" height={340}>
            {loading || !data?.latencyTrend?.length ? (
              <Skeleton variant="rounded" height={260} />
            ) : (
              <LineChart
                xAxis={[{ data: data.latencyTrend.map((_: any, i: number) => i), scaleType: "point", valueFormatter: (_: any, ctx: any) => data.latencyTrend[ctx.location === "tick" ? _ : 0]?.date?.split("T")[1]?.substring(0, 5) || "" }]}
                series={[
                  { data: data.latencyTrend.map((d: any) => d.avgMs), label: "Promedio", color: "#1976d2" },
                  { data: data.latencyTrend.map((d: any) => d.p95Ms), label: "P95", color: "#f44336" },
                ]}
                height={260}
              />
            )}
          </ChartPaper>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <ChartPaper title="Errores por ruta" height={340}>
            {loading || !data?.errorsByPath?.length ? (
              <Alert severity="success" sx={{ mt: 4 }}>Sin errores en este período</Alert>
            ) : (
              <BarChart
                yAxis={[{ scaleType: "band", data: data.errorsByPath.map((e: any) => e.path.replace("/v1/", "")) }]}
                series={[{ data: data.errorsByPath.map((e: any) => e.count), color: "#f44336" }]}
                layout="horizontal"
                height={260}
                slotProps={{ legend: { hidden: true } }}
              />
            )}
          </ChartPaper>
        </Grid>
      </Grid>

      {/* Slowest endpoints table */}
      <Paper variant="outlined" sx={{ p: 2 }}>
        <Typography variant="subtitle1" fontWeight={600} mb={2}>Endpoints más lentos</Typography>
        {loading ? <Skeleton height={200} /> : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Endpoint</TableCell>
                <TableCell align="right">Avg (ms)</TableCell>
                <TableCell align="right">Max (ms)</TableCell>
                <TableCell align="right">Requests</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.slowestEndpoints || []).map((ep: any, i: number) => (
                <TableRow key={i}>
                  <TableCell><Chip label={ep.path} size="small" variant="outlined" /></TableCell>
                  <TableCell align="right">
                    <Typography color={ep.avgMs > 500 ? "error" : ep.avgMs > 200 ? "warning.main" : "success.main"} fontWeight={600}>
                      {ep.avgMs}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">{ep.maxMs}</TableCell>
                  <TableCell align="right">{ep.count}</TableCell>
                </TableRow>
              ))}
              {!data?.slowestEndpoints?.length && (
                <TableRow><TableCell colSpan={4} align="center">Sin datos</TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        )}
      </Paper>
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB: Business Events
// ═══════════════════════════════════════════════════════════════════════════════

function BusinessTab({ token, range }: { token: string; range: TimeRange }) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    apiFetch<any>(`/v1/backoffice/analytics/business?range=${range}`, token)
      .then(setData).catch(() => setData(null)).finally(() => setLoading(false));
  }, [token, range]);

  const summary = data?.summary;
  const activities = [
    { label: "Facturas", value: summary?.invoices || 0, icon: <Receipt /> },
    { label: "Compras", value: summary?.purchases || 0, icon: <ShoppingCart /> },
    { label: "Pagos", value: summary?.payments || 0, icon: <Payment /> },
    { label: "Nuevos clientes", value: summary?.newCustomers || 0, icon: <PersonAdd /> },
    { label: "Ventas POS", value: summary?.posSales || 0, icon: <PointOfSale /> },
    { label: "Leads CRM", value: summary?.leadsCreated || 0, icon: <Leaderboard /> },
  ];

  return (
    <Box>
      {/* Activity cards */}
      <Grid container spacing={2} mb={3}>
        {activities.map((a) => (
          <Grid key={a.label} size={{ xs: 4, sm: 2 }}>
            <ActivityCard label={a.label} value={a.value} icon={a.icon} loading={loading} />
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3} mb={3}>
        <Grid size={{ xs: 12, md: 7 }}>
          <ChartPaper title="Facturación diaria" height={320}>
            {loading || !data?.invoicesTrend?.length ? (
              <Alert severity="info" sx={{ mt: 4 }}>Sin datos de facturación</Alert>
            ) : (
              <BarChart
                xAxis={[{ scaleType: "band", data: data.invoicesTrend.map((d: any) => new Date(d.date).toLocaleDateString("es", { day: "2-digit", month: "short" })) }]}
                series={[{ data: data.invoicesTrend.map((d: any) => d.count), color: "#6C63FF", label: "Facturas" }]}
                height={250}
                slotProps={{ legend: { hidden: true } }}
              />
            )}
          </ChartPaper>
        </Grid>
        <Grid size={{ xs: 12, md: 5 }}>
          <ChartPaper title="Eventos de negocio" height={320}>
            {loading || !data?.allEvents?.length ? (
              <Alert severity="info" sx={{ mt: 4 }}>Sin eventos</Alert>
            ) : (
              <PieChart
                series={[{
                  data: data.allEvents.slice(0, 8).map((e: any, i: number) => ({
                    id: i, value: e.total, label: e.event.split(".").pop(),
                  })),
                  innerRadius: 30, paddingAngle: 2, cornerRadius: 4,
                  highlightScope: { fade: "global", highlight: "item" },
                }]}
                height={250}
              />
            )}
          </ChartPaper>
        </Grid>
      </Grid>
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN: Dashboard Page with Tabs
// ═══════════════════════════════════════════════════════════════════════════════

export default function BackofficeDashboardPage() {
  const { token, isSet, clear } = useBackoffice();
  const [tab, setTab] = useState(0);
  const [range, setRange] = useState<TimeRange>("24h");

  if (!isSet) return null;

  return (
    <Box>
      {/* Header */}
      <Stack direction="row" alignItems="center" gap={1} mb={2} flexWrap="wrap">
        <StorageIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>Dashboard</Typography>
        <Chip label="SYSADMIN" size="small" color="warning" sx={{ ml: 1 }} />
        <Box flex={1} />
        <ToggleButtonGroup value={range} exclusive onChange={(_, v) => v && setRange(v)} size="small">
          <ToggleButton value="1h">1h</ToggleButton>
          <ToggleButton value="24h">24h</ToggleButton>
          <ToggleButton value="7d">7d</ToggleButton>
          <ToggleButton value="30d">30d</ToggleButton>
          <ToggleButton value="90d">90d</ToggleButton>
        </ToggleButtonGroup>
      </Stack>

      {/* Tabs */}
      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3, borderBottom: 1, borderColor: "divider" }}>
        <Tab label="Resumen" />
        <Tab label="Rendimiento" />
        <Tab label="Negocio" />
      </Tabs>

      {tab === 0 && <OverviewTab token={token} range={range} />}
      {tab === 1 && <PerformanceTab token={token} range={range} />}
      {tab === 2 && <BusinessTab token={token} range={range} />}
    </Box>
  );
}
