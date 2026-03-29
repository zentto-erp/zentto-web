'use client';

import { useState } from 'react';
import {
  Box, Grid, Card, CardContent, Typography, ToggleButton, ToggleButtonGroup,
  Table, TableHead, TableRow, TableCell, TableBody, Chip, Skeleton, Alert,
} from '@mui/material';
import {
  TrendingUp, People, Speed, ErrorOutline,
  Receipt, ShoppingCart, Payment, PersonAdd, PointOfSale, Leaderboard,
} from '@mui/icons-material';
import { LineChart } from '@mui/x-charts/LineChart';
import { BarChart } from '@mui/x-charts/BarChart';
import { PieChart } from '@mui/x-charts/PieChart';
import {
  useAnalyticsDashboard,
  useAnalyticsBusiness,
  useAnalyticsPerformance,
  useAnalyticsActivity,
  type TimeRange,
} from '../hooks/useAnalytics';

// --- KPI Card ---
function KpiCard({ title, value, subtitle, icon, color }: {
  title: string; value: string | number; subtitle?: string;
  icon: React.ReactNode; color: string;
}) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography variant="body2" color="text.secondary">{title}</Typography>
            <Typography variant="h4" fontWeight={700} sx={{ my: 0.5 }}>{value}</Typography>
            {subtitle && <Typography variant="caption" color="text.secondary">{subtitle}</Typography>}
          </Box>
          <Box sx={{ p: 1, borderRadius: 2, bgcolor: `${color}15`, color }}>
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

export default function AnalyticsDashboardPage() {
  const [range, setRange] = useState<TimeRange>('24h');

  const { data: dash, isLoading: loadDash } = useAnalyticsDashboard(range);
  const { data: biz, isLoading: loadBiz } = useAnalyticsBusiness(range);
  const { data: perf, isLoading: loadPerf } = useAnalyticsPerformance(range);
  const { data: activity, isLoading: loadActivity } = useAnalyticsActivity(range);

  const loading = loadDash || loadBiz || loadPerf || loadActivity;

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Estadísticas y Analíticas</Typography>
        <ToggleButtonGroup
          value={range}
          exclusive
          onChange={(_, v) => v && setRange(v)}
          size="small"
        >
          <ToggleButton value="1h">1h</ToggleButton>
          <ToggleButton value="24h">24h</ToggleButton>
          <ToggleButton value="7d">7d</ToggleButton>
          <ToggleButton value="30d">30d</ToggleButton>
          <ToggleButton value="90d">90d</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* KPI Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          {loading ? <Skeleton height={120} /> : (
            <KpiCard
              title="Operaciones"
              value={dash?.kpis.totalRequests?.toLocaleString() || '0'}
              subtitle={`${range} período`}
              icon={<TrendingUp />}
              color="#6C63FF"
            />
          )}
        </Grid>
        <Grid item xs={6} md={3}>
          {loading ? <Skeleton height={120} /> : (
            <KpiCard
              title="Usuarios activos"
              value={dash?.kpis.uniqueUsers || 0}
              subtitle="Únicos en el período"
              icon={<People />}
              color="#00C9A7"
            />
          )}
        </Grid>
        <Grid item xs={6} md={3}>
          {loading ? <Skeleton height={120} /> : (
            <KpiCard
              title="Latencia promedio"
              value={`${dash?.kpis.avgLatencyMs || 0}ms`}
              subtitle={`P95: ${perf?.percentiles.p95 || 0}ms`}
              icon={<Speed />}
              color="#FFB547"
            />
          )}
        </Grid>
        <Grid item xs={6} md={3}>
          {loading ? <Skeleton height={120} /> : (
            <KpiCard
              title="Errores"
              value={dash?.kpis.errorCount || 0}
              subtitle={`Tasa: ${dash?.kpis.errorRate || '0'}%`}
              icon={<ErrorOutline />}
              color={Number(dash?.kpis.errorRate || 0) > 5 ? '#EF4444' : '#10B981'}
            />
          )}
        </Grid>
      </Grid>

      {/* Business KPIs */}
      {biz && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {[
            { label: 'Facturas', value: biz.summary.invoices, icon: <Receipt />, color: '#3498DB' },
            { label: 'Compras', value: biz.summary.purchases, icon: <ShoppingCart />, color: '#F39C12' },
            { label: 'Pagos', value: biz.summary.payments, icon: <Payment />, color: '#27AE60' },
            { label: 'Nuevos clientes', value: biz.summary.newCustomers, icon: <PersonAdd />, color: '#9B59B6' },
            { label: 'Ventas POS', value: biz.summary.posSales, icon: <PointOfSale />, color: '#E84393' },
            { label: 'Leads CRM', value: biz.summary.leadsCreated, icon: <Leaderboard />, color: '#6C63FF' },
          ].map((item) => (
            <Grid item xs={4} md={2} key={item.label}>
              <Card>
                <CardContent sx={{ textAlign: 'center', py: 1.5, '&:last-child': { pb: 1.5 } }}>
                  <Box sx={{ color: item.color, mb: 0.5 }}>{item.icon}</Box>
                  <Typography variant="h6" fontWeight={700}>{item.value}</Typography>
                  <Typography variant="caption" color="text.secondary">{item.label}</Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Charts Row 1: Activity + Status Codes */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Actividad en el tiempo
              </Typography>
              {dash?.charts.requestsOverTime && dash.charts.requestsOverTime.length > 0 ? (
                <LineChart
                  height={300}
                  series={[{
                    data: dash.charts.requestsOverTime.map(d => d.count),
                    label: 'Requests',
                    color: '#6C63FF',
                    area: true,
                  }]}
                  xAxis={[{
                    data: dash.charts.requestsOverTime.map(d =>
                      new Date(d.date).toLocaleString('es', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: 'short' })
                    ),
                    scaleType: 'point',
                  }]}
                />
              ) : (
                <Alert severity="info" sx={{ mt: 2 }}>Sin datos para el período seleccionado</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ height: '100%' }}>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Códigos de respuesta
              </Typography>
              {dash?.charts.statusCodes && dash.charts.statusCodes.length > 0 ? (
                <PieChart
                  height={250}
                  series={[{
                    data: dash.charts.statusCodes.map((s, i) => ({
                      id: i,
                      value: s.count,
                      label: `${s.code}`,
                      color: s.code < 300 ? '#10B981' : s.code < 400 ? '#6C63FF' : s.code < 500 ? '#FFB547' : '#EF4444',
                    })),
                    innerRadius: 40,
                  }]}
                />
              ) : (
                <Alert severity="info">Sin datos</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts Row 2: Invoices Trend + Latency */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Facturación diaria
              </Typography>
              {biz?.invoicesTrend && biz.invoicesTrend.length > 0 ? (
                <BarChart
                  height={250}
                  series={[{
                    data: biz.invoicesTrend.map(d => d.count),
                    label: 'Facturas',
                    color: '#3498DB',
                  }]}
                  xAxis={[{
                    data: biz.invoicesTrend.map(d =>
                      new Date(d.date).toLocaleDateString('es', { day: '2-digit', month: 'short' })
                    ),
                    scaleType: 'band',
                  }]}
                />
              ) : (
                <Alert severity="info">Sin datos de facturación</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Latencia (P95 vs Promedio)
              </Typography>
              {perf?.latencyTrend && perf.latencyTrend.length > 0 ? (
                <LineChart
                  height={250}
                  series={[
                    { data: perf.latencyTrend.map(d => d.avgMs), label: 'Promedio', color: '#6C63FF' },
                    { data: perf.latencyTrend.map(d => d.p95Ms), label: 'P95', color: '#FF6584' },
                  ]}
                  xAxis={[{
                    data: perf.latencyTrend.map(d =>
                      new Date(d.date).toLocaleString('es', { hour: '2-digit', day: '2-digit', month: 'short' })
                    ),
                    scaleType: 'point',
                  }]}
                />
              ) : (
                <Alert severity="info">Sin datos de latencia</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Charts Row 3: Modules + Events + Slowest */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Módulos más usados
              </Typography>
              {activity?.moduleUsage && activity.moduleUsage.length > 0 ? (
                <BarChart
                  height={250}
                  layout="horizontal"
                  series={[{
                    data: activity.moduleUsage.slice(0, 8).map(m => m.count),
                    color: '#00C9A7',
                  }]}
                  yAxis={[{
                    data: activity.moduleUsage.slice(0, 8).map(m => m.path.split('/').pop() || m.path),
                    scaleType: 'band',
                  }]}
                />
              ) : (
                <Alert severity="info">Sin datos</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Eventos de negocio
              </Typography>
              {dash?.charts.eventsByType && dash.charts.eventsByType.length > 0 ? (
                <PieChart
                  height={250}
                  series={[{
                    data: dash.charts.eventsByType.map((e, i) => ({
                      id: i,
                      value: e.count,
                      label: e.event.replace('.', ' '),
                    })),
                    innerRadius: 30,
                  }]}
                />
              ) : (
                <Alert severity="info">Sin eventos</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" fontWeight={600} gutterBottom>
                Endpoints más lentos
              </Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Ruta</TableCell>
                    <TableCell align="right">Prom.</TableCell>
                    <TableCell align="right">Máx.</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(perf?.slowestEndpoints || []).slice(0, 6).map((ep, i) => (
                    <TableRow key={i}>
                      <TableCell sx={{ fontFamily: 'monospace', fontSize: 12 }}>
                        {ep.path.length > 25 ? '...' + ep.path.slice(-22) : ep.path}
                      </TableCell>
                      <TableCell align="right">
                        <Chip
                          size="small"
                          label={`${ep.avgMs}ms`}
                          color={ep.avgMs > 1000 ? 'error' : ep.avgMs > 300 ? 'warning' : 'success'}
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell align="right" sx={{ fontSize: 12 }}>{ep.maxMs}ms</TableCell>
                    </TableRow>
                  ))}
                  {(!perf?.slowestEndpoints || perf.slowestEndpoints.length === 0) && (
                    <TableRow><TableCell colSpan={3}><Alert severity="info">Sin datos</Alert></TableCell></TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Activity Heatmap */}
      {activity?.heatmap && activity.heatmap.length > 0 && (
        <Card>
          <CardContent>
            <Typography variant="subtitle1" fontWeight={600} gutterBottom>
              Heatmap de actividad (requests por hora)
            </Typography>
            <BarChart
              height={200}
              series={[
                { data: activity.heatmap.map(h => h.requests), label: 'Requests', color: '#6C63FF' },
                { data: activity.heatmap.map(h => h.users * 10), label: 'Usuarios (x10)', color: '#FF6584' },
              ]}
              xAxis={[{
                data: activity.heatmap.map(h =>
                  new Date(h.hour).toLocaleString('es', { hour: '2-digit', minute: '2-digit' })
                ),
                scaleType: 'band',
              }]}
            />
          </CardContent>
        </Card>
      )}
    </Box>
  );
}
