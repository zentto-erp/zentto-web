"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Skeleton,
  Alert,
  Chip,
  Paper,
  Tabs,
  Tab,
  ToggleButtonGroup,
  ToggleButton,
  Button,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { alpha } from "@mui/material/styles";
import ReceiptIcon from "@mui/icons-material/Receipt";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import PeopleIcon from "@mui/icons-material/People";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import PaymentIcon from "@mui/icons-material/Payment";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { BarChart } from "@mui/x-charts/BarChart";
import { LineChart } from "@mui/x-charts/LineChart";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors, DashboardKpiCard } from "@zentto/shared-ui";
import {
  useSalesKPIs,
  useSalesByMonth,
  useSalesByCustomer,
  useARAging,
  useCollectionForecast,
  useSalesByProduct,
} from "../hooks/useVentasAnalytics";

/* --- Helpers --------------------------------------------------------------- */

function calcDateRange(range: string): { from?: string; to?: string } {
  const now = new Date();
  const to = now.toISOString().slice(0, 10);
  let from: string;

  switch (range) {
    case "7d":
      from = new Date(now.getTime() - 7 * 86400000).toISOString().slice(0, 10);
      break;
    case "30d":
      from = new Date(now.getTime() - 30 * 86400000).toISOString().slice(0, 10);
      break;
    case "90d":
      from = new Date(now.getTime() - 90 * 86400000).toISOString().slice(0, 10);
      break;
    case "ytd": {
      from = `${now.getFullYear()}-01-01`;
      break;
    }
    default:
      from = new Date(now.getTime() - 30 * 86400000).toISOString().slice(0, 10);
  }

  return { from, to };
}

function pctChange(current: number, previous: number): { value: number; positive: boolean } {
  if (previous === 0) return { value: current > 0 ? 100 : 0, positive: current >= 0 };
  const pct = ((current - previous) / previous) * 100;
  return { value: Math.abs(Math.round(pct)), positive: pct >= 0 };
}

const AGING_COLORS: Record<string, string> = {
  "0-30": "#4caf50",
  "31-60": "#ff9800",
  "61-90": "#f57c00",
  "91-120": "#e65100",
  "120+": "#d32f2f",
};

/* --- KPI Card -------------------------------------------------------------- */

interface KPIProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: React.ReactNode;
  color: string;
  loading?: boolean;
  trend?: { value: number; positive: boolean } | null;
}

function KPICard({ title, value, subtitle, icon, color, loading, trend }: KPIProps) {
  return (
    <Card
      elevation={0}
      sx={{
        height: "100%",
        borderRadius: 2,
        border: "1px solid",
        borderColor: "divider",
        transition: "box-shadow 0.2s",
        "&:hover": { boxShadow: "0 4px 20px rgba(0,0,0,0.08)" },
      }}
    >
      <CardContent sx={{ p: 2.5, "&:last-child": { pb: 2.5 } }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", mb: 1.5 }}>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500, fontSize: "0.8rem" }}>
            {title}
          </Typography>
          <Box
            sx={(t) => ({
              width: 48,
              height: 48,
              borderRadius: 3,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              bgcolor: t.palette.mode === "dark" ? "rgba(255,255,255,0.08)" : "#fff",
              border: `1px solid ${t.palette.divider}`,
              boxShadow: t.palette.mode === "dark" ? "none" : "0 2px 8px rgba(0,0,0,0.12)",
              color: color,
            })}
          >
            {icon}
          </Box>
        </Box>
        {loading ? (
          <Skeleton variant="text" width={100} sx={{ fontSize: "1.8rem" }} />
        ) : (
          <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1.2, mb: 0.5 }}>
            {value}
          </Typography>
        )}
        <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
          {trend && trend.value > 0 && (
            <Chip
              size="small"
              icon={trend.positive ? <TrendingUpIcon sx={{ fontSize: 14 }} /> : <TrendingDownIcon sx={{ fontSize: 14 }} />}
              label={`${trend.value}%`}
              sx={{
                height: 22,
                fontSize: "0.7rem",
                fontWeight: 600,
                bgcolor: alpha(trend.positive ? "#4caf50" : "#f44336", 0.1),
                color: trend.positive ? "#2e7d32" : "#d32f2f",
                "& .MuiChip-icon": { color: "inherit" },
              }}
            />
          )}
          {subtitle && (
            <Typography variant="caption" color="text.secondary">
              {subtitle}
            </Typography>
          )}
        </Box>
      </CardContent>
    </Card>
  );
}

/* --- Component ------------------------------------------------------------- */

export default function AdminHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");

  const [range, setRange] = useState("30d");
  const [chartTab, setChartTab] = useState(0);

  const { from, to } = useMemo(() => calcDateRange(range), [range]);

  // Queries
  const kpis = useSalesKPIs(from, to);
  const byMonth = useSalesByMonth(12);
  const byCustomer = useSalesByCustomer(10, from, to);
  const aging = useARAging();
  const forecast = useCollectionForecast(3);
  const byProduct = useSalesByProduct(10, from, to);

  const k = kpis.data;
  const isLoading = kpis.isLoading;

  const facturasTrend = k ? pctChange(k.FacturasMes, k.FacturasMesAnterior) : null;

  /* --- Shortcuts --- */
  const shortcuts = [
    { label: "Nueva Factura", icon: <AddCircleOutlineIcon fontSize="small" />, href: `${bp}/facturas/new`, color: brandColors.shortcutDark },
    { label: "Clientes", icon: <PeopleIcon fontSize="small" />, href: `${bp}/clientes`, color: brandColors.shortcutTeal },
    { label: "CxC", icon: <AccountBalanceIcon fontSize="small" />, href: `${bp}/cxc`, color: brandColors.shortcutViolet },
    { label: "Cobros", icon: <PaymentIcon fontSize="small" />, href: `${bp}/abonos`, color: brandColors.statRed },
  ];

  return (
    <Box>
      {/* -- Header ---------------------------------------------------------- */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", mb: 3, gap: 2 }}>
        <Box>
          <Typography variant="body2" color="text.secondary">
            Dashboard de ventas, clientes y cuentas por cobrar
          </Typography>
        </Box>
        <Box sx={{ display: "flex", gap: 1, alignItems: "center", flexWrap: "wrap" }}>
          <ToggleButtonGroup
            size="small"
            exclusive
            value={range}
            onChange={(_, v) => v && setRange(v)}
            sx={{ height: 32 }}
          >
            <ToggleButton value="7d">7d</ToggleButton>
            <ToggleButton value="30d">30d</ToggleButton>
            <ToggleButton value="90d">90d</ToggleButton>
            <ToggleButton value="ytd">YTD</ToggleButton>
          </ToggleButtonGroup>
          {shortcuts.map((s) => (
            <Button
              key={s.label}
              size="small"
              variant="outlined"
              startIcon={s.icon}
              onClick={() => router.push(s.href)}
              sx={{
                height: 32,
                textTransform: "none",
                fontWeight: 600,
                fontSize: "0.75rem",
                borderColor: alpha(s.color, 0.4),
                color: s.color,
                "&:hover": { borderColor: s.color, bgcolor: alpha(s.color, 0.04) },
              }}
            >
              {s.label}
            </Button>
          ))}
        </Box>
      </Box>

      {/* -- KPI Cards ------------------------------------------------------- */}
      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="Facturas del Mes"
            value={isLoading ? "..." : String(k?.FacturasMes ?? 0)}
            subtitle="vs mes anterior"
            icon={<ReceiptIcon fontSize="small" />}
            color="#1976d2"
            loading={isLoading}
            trend={facturasTrend}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="Monto Total"
            value={isLoading ? "..." : formatCurrency(k?.MontoTotal ?? 0)}
            subtitle={`${k?.TotalFacturas ?? 0} documentos`}
            icon={<AttachMoneyIcon fontSize="small" />}
            color="#2e7d32"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="Clientes Activos"
            value={isLoading ? "..." : String(k?.ClientesActivos ?? 0)}
            subtitle={k?.TopCliente ? `Top: ${k.TopCliente}` : undefined}
            icon={<PeopleIcon fontSize="small" />}
            color={brandColors.teal}
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="CxC Pendiente"
            value={isLoading ? "..." : formatCurrency(k?.CxCPendiente ?? 0)}
            subtitle="saldo total"
            icon={<AccountBalanceIcon fontSize="small" />}
            color="#ed6c02"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="CxC Vencida"
            value={isLoading ? "..." : formatCurrency(k?.CxCVencida ?? 0)}
            subtitle="requiere atencion"
            icon={<WarningAmberIcon fontSize="small" />}
            color="#d32f2f"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <DashboardKpiCard
            title="Promedio por Factura"
            value={isLoading ? "..." : formatCurrency(k?.PromedioFactura ?? 0)}
            subtitle={k?.DiasPromCobro ? `~${k.DiasPromCobro} dias prom. cobro` : undefined}
            icon={<CalendarMonthIcon fontSize="small" />}
            color="#7b1fa2"
            loading={isLoading}
          />
        </Grid>
      </Grid>

      {/* -- Charts Tabs ----------------------------------------------------- */}
      <Paper elevation={0} sx={{ borderRadius: 2, border: "1px solid", borderColor: "divider", mb: 3 }}>
        <Tabs
          value={chartTab}
          onChange={(_, v) => setChartTab(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            borderBottom: "1px solid",
            borderColor: "divider",
            px: 2,
            "& .MuiTab-root": { textTransform: "none", fontWeight: 600, fontSize: "0.85rem" },
          }}
        >
          <Tab label="Ventas por Mes" />
          <Tab label="Top Clientes" />
          <Tab label="Aging CxC" />
          <Tab label="Top Productos" />
          <Tab label="Proyeccion Cobros" />
        </Tabs>

        <Box sx={{ p: 3 }}>
          {/* Tab 0: Ventas por Mes */}
          {chartTab === 0 && (
            <Box>
              {byMonth.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !byMonth.data || byMonth.data.length === 0 ? (
                <Alert severity="info">Sin datos de ventas mensuales</Alert>
              ) : (
                <Grid container spacing={3}>
                  <Grid size={{ xs: 12, md: 7 }}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                      Ventas por mes
                    </Typography>
                    <Box sx={{ width: "100%", height: 350 }}>
                      <BarChart
                        height={330}
                        xAxis={[{ data: byMonth.data.map((d) => d.Month), scaleType: "band", label: "Mes" }]}
                        yAxis={[{ label: "Monto ($)" }]}
                        series={[
                          {
                            data: byMonth.data.map((d) => d.Total),
                            label: "Total ventas",
                            color: "#1976d2",
                          },
                        ]}
                      />
                    </Box>
                  </Grid>
                  <Grid size={{ xs: 12, md: 5 }}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                      Acumulado
                    </Typography>
                    <Box sx={{ width: "100%", height: 350 }}>
                      <LineChart
                        height={330}
                        xAxis={[{ data: byMonth.data.map((d) => d.Month), scaleType: "band", label: "Mes" }]}
                        yAxis={[{ label: "Acumulado ($)" }]}
                        series={[
                          {
                            data: byMonth.data.map((d) => d.Accumulated),
                            label: "Acumulado",
                            color: "#1565c0",
                            area: true,
                          },
                        ]}
                      />
                    </Box>
                  </Grid>
                </Grid>
              )}
            </Box>
          )}

          {/* Tab 1: Top Clientes */}
          {chartTab === 1 && (
            <Box>
              {byCustomer.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !byCustomer.data || byCustomer.data.length === 0 ? (
                <Alert severity="info">Sin datos de clientes</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Top 10 clientes por monto
                  </Typography>
                  <Box sx={{ width: "100%", height: 400 }}>
                    <BarChart
                      height={380}
                      layout="horizontal"
                      yAxis={[{
                        data: byCustomer.data.map((d) => d.CustomerName.length > 20 ? d.CustomerName.slice(0, 20) + "..." : d.CustomerName),
                        scaleType: "band",
                      }]}
                      xAxis={[{ label: "Monto ($)" }]}
                      series={[
                        {
                          data: byCustomer.data.map((d) => d.Total),
                          label: "Total",
                          color: brandColors.teal,
                        },
                      ]}
                    />
                  </Box>
                </>
              )}
            </Box>
          )}

          {/* Tab 2: Aging CxC */}
          {chartTab === 2 && (
            <Box>
              {aging.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !aging.data || aging.data.length === 0 ? (
                <Alert severity="info">Sin datos de aging</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Aging de Cuentas por Cobrar (dias vencidos)
                  </Typography>
                  <Box sx={{ width: "100%", height: 350 }}>
                    <BarChart
                      height={330}
                      layout="horizontal"
                      yAxis={[{
                        data: aging.data.map((d) => `${d.Bucket} dias`),
                        scaleType: "band",
                      }]}
                      xAxis={[{ label: "Monto ($)" }]}
                      series={[
                        {
                          data: aging.data.map((d) => d.Total),
                          label: "Pendiente",
                          color: "#ff9800",
                        },
                      ]}
                      slotProps={{
                        bar: {
                          rx: 4,
                          ry: 4,
                        },
                      }}
                    />
                  </Box>
                  <Grid container spacing={1} sx={{ mt: 2 }}>
                    {aging.data.map((d) => (
                      <Grid key={d.Bucket} size={{ xs: 6, sm: 4, md: 2.4 }}>
                        <Box
                          sx={{
                            p: 1.5,
                            borderRadius: 1.5,
                            bgcolor: alpha(AGING_COLORS[d.Bucket] || "#999", 0.08),
                            borderLeft: `4px solid ${AGING_COLORS[d.Bucket] || "#999"}`,
                          }}
                        >
                          <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
                            {d.Bucket} dias
                          </Typography>
                          <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                            {formatCurrency(d.Total)}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {d.Count} doc. ({d.Percentage}%)
                          </Typography>
                        </Box>
                      </Grid>
                    ))}
                  </Grid>
                </>
              )}
            </Box>
          )}

          {/* Tab 3: Top Productos */}
          {chartTab === 3 && (
            <Box>
              {byProduct.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !byProduct.data || byProduct.data.length === 0 ? (
                <Alert severity="info">Sin datos de productos</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Top 10 productos mas vendidos
                  </Typography>
                  <Box sx={{ width: "100%", height: 400 }}>
                    <BarChart
                      height={380}
                      layout="horizontal"
                      yAxis={[{
                        data: byProduct.data.map((d) => d.ProductName.length > 25 ? d.ProductName.slice(0, 25) + "..." : d.ProductName),
                        scaleType: "band",
                      }]}
                      xAxis={[{ label: "Monto ($)" }]}
                      series={[
                        {
                          data: byProduct.data.map((d) => d.Total),
                          label: "Total vendido",
                          color: "#7b1fa2",
                        },
                      ]}
                    />
                  </Box>
                  <Grid container spacing={1} sx={{ mt: 2 }}>
                    {byProduct.data.slice(0, 5).map((d) => (
                      <Grid key={d.ProductCode} size={{ xs: 12, sm: 6, md: 2.4 }}>
                        <Box
                          sx={{
                            p: 1.5,
                            borderRadius: 1.5,
                            bgcolor: alpha("#7b1fa2", 0.05),
                            borderLeft: `4px solid #7b1fa2`,
                          }}
                        >
                          <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
                            {d.ProductCode}
                          </Typography>
                          <Typography variant="subtitle2" sx={{ fontWeight: 700, fontSize: "0.8rem" }} noWrap>
                            {d.ProductName}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {formatCurrency(d.Total)} ({d.Percentage}%)
                          </Typography>
                        </Box>
                      </Grid>
                    ))}
                  </Grid>
                </>
              )}
            </Box>
          )}

          {/* Tab 4: Proyeccion Cobros */}
          {chartTab === 4 && (
            <Box>
              {forecast.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !forecast.data || forecast.data.length === 0 ? (
                <Alert severity="info">Sin proyeccion de cobros</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Proyeccion de cobros proximos 3 meses
                  </Typography>
                  <Box sx={{ width: "100%", height: 350 }}>
                    <BarChart
                      height={330}
                      xAxis={[{
                        data: forecast.data.map((d) => d.Month),
                        scaleType: "band",
                        label: "Mes",
                      }]}
                      yAxis={[{ label: "Monto a cobrar ($)" }]}
                      series={[
                        {
                          data: forecast.data.map((d) => d.DueAmount),
                          label: "Monto vencimiento",
                          color: "#2e7d32",
                        },
                      ]}
                    />
                  </Box>
                  <Grid container spacing={2} sx={{ mt: 1 }}>
                    {forecast.data.map((d) => (
                      <Grid key={d.Month} size={{ xs: 12, sm: 4 }}>
                        <Box
                          sx={{
                            p: 2,
                            borderRadius: 2,
                            bgcolor: alpha("#2e7d32", 0.04),
                            border: "1px solid",
                            borderColor: alpha("#2e7d32", 0.15),
                            textAlign: "center",
                          }}
                        >
                          <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: "uppercase" }}>
                            {d.Month}
                          </Typography>
                          <Typography variant="h6" sx={{ fontWeight: 700, color: "#2e7d32" }}>
                            {formatCurrency(d.DueAmount)}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {d.DocumentCount} documentos
                          </Typography>
                        </Box>
                      </Grid>
                    ))}
                  </Grid>
                </>
              )}
            </Box>
          )}
        </Box>
      </Paper>

      {/* -- Footer: CxC Vencida Alert --------------------------------------- */}
      {k && k.CxCVencida > 0 && (
        <Alert
          severity="warning"
          variant="outlined"
          icon={<WarningAmberIcon />}
          action={
            <Button
              size="small"
              color="warning"
              onClick={() => router.push(`${bp}/cxc`)}
              sx={{ textTransform: "none", fontWeight: 600 }}
            >
              Ver CxC
            </Button>
          }
          sx={{ borderRadius: 2 }}
        >
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            Hay {formatCurrency(k.CxCVencida)} en cuentas por cobrar vencidas que requieren atencion inmediata.
          </Typography>
        </Alert>
      )}
    </Box>
  );
}
