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
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import AddShoppingCartIcon from "@mui/icons-material/AddShoppingCart";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import PaymentIcon from "@mui/icons-material/Payment";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import PeopleIcon from "@mui/icons-material/People";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { BarChart } from "@mui/x-charts/BarChart";
import { LineChart } from "@mui/x-charts/LineChart";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import {
  usePurchaseKPIs,
  usePurchasesByMonth,
  usePurchasesBySupplier,
  useAPAging,
  usePaymentSchedule,
} from "../hooks/useComprasAnalytics";

/* ─── Helpers ──────────────────────────────────────────────── */

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

/* ─── KPI Card ─────────────────────────────────────────────── */

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
            sx={{
              width: 40,
              height: 40,
              borderRadius: 1.5,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              bgcolor: alpha(color, 0.1),
              color: color,
            }}
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

/* ─── Component ────────────────────────────────────────────── */

export default function ComprasHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");

  const [range, setRange] = useState("30d");
  const [chartTab, setChartTab] = useState(0);

  const { from, to } = useMemo(() => calcDateRange(range), [range]);

  // Queries
  const kpis = usePurchaseKPIs(from, to);
  const byMonth = usePurchasesByMonth(12);
  const bySupplier = usePurchasesBySupplier(10, from, to);
  const aging = useAPAging();
  const schedule = usePaymentSchedule(3);

  const k = kpis.data;
  const isLoading = kpis.isLoading;

  const comprasTrend = k ? pctChange(k.ComprasMes, k.CompraMesAnterior) : null;

  /* ─── Shortcuts ──── */
  const shortcuts = [
    { label: "Nueva Compra", icon: <AddShoppingCartIcon fontSize="small" />, href: `${bp}/compras/new`, color: brandColors.success },
    { label: "Proveedores", icon: <LocalShippingIcon fontSize="small" />, href: `${bp}/proveedores`, color: brandColors.teal },
    { label: "CxP Estado", icon: <AccountBalanceIcon fontSize="small" />, href: `${bp}/cxp`, color: brandColors.statBlue },
    { label: "Pagos", icon: <PaymentIcon fontSize="small" />, href: `${bp}/cuentas-por-pagar`, color: brandColors.accent },
  ];

  return (
    <Box>
      {/* ── Header ──────────────────────────────────────────── */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", mb: 3, gap: 2 }}>
        <Box>
          <Typography variant="body2" color="text.secondary">
            Dashboard de compras, proveedores y cuentas por pagar
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

      {/* ── KPI Cards ───────────────────────────────────────── */}
      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="Compras del Mes"
            value={isLoading ? "..." : String(k?.ComprasMes ?? 0)}
            subtitle="vs mes anterior"
            icon={<ShoppingCartIcon fontSize="small" />}
            color="#1976d2"
            loading={isLoading}
            trend={comprasTrend}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="Monto Total"
            value={isLoading ? "..." : formatCurrency(k?.MontoTotal ?? 0)}
            subtitle={`${k?.TotalCompras ?? 0} documentos`}
            icon={<AttachMoneyIcon fontSize="small" />}
            color="#2e7d32"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="Proveedores Activos"
            value={isLoading ? "..." : String(k?.ProveedoresActivos ?? 0)}
            subtitle={k?.TopProveedor ? `Top: ${k.TopProveedor}` : undefined}
            icon={<PeopleIcon fontSize="small" />}
            color={brandColors.teal}
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="CxP Pendiente"
            value={isLoading ? "..." : formatCurrency(k?.CxPPendiente ?? 0)}
            subtitle="saldo total"
            icon={<ReceiptLongIcon fontSize="small" />}
            color="#ed6c02"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="CxP Vencida"
            value={isLoading ? "..." : formatCurrency(k?.CxPVencida ?? 0)}
            subtitle="requiere atencion"
            icon={<WarningAmberIcon fontSize="small" />}
            color="#d32f2f"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <KPICard
            title="Promedio por Compra"
            value={isLoading ? "..." : formatCurrency(k?.PromedioCompra ?? 0)}
            subtitle={k?.DiasPromPago ? `~${k.DiasPromPago} dias prom. pago` : undefined}
            icon={<CalendarMonthIcon fontSize="small" />}
            color="#7b1fa2"
            loading={isLoading}
          />
        </Grid>
      </Grid>

      {/* ── Charts Tabs ─────────────────────────────────────── */}
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
          <Tab label="Compras por Mes" />
          <Tab label="Top Proveedores" />
          <Tab label="Aging CxP" />
          <Tab label="Proyeccion Pagos" />
        </Tabs>

        <Box sx={{ p: 3 }}>
          {/* Tab 0: Compras por Mes */}
          {chartTab === 0 && (
            <Box>
              {byMonth.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !byMonth.data || byMonth.data.length === 0 ? (
                <Alert severity="info">Sin datos de compras mensuales</Alert>
              ) : (
                <Grid container spacing={3}>
                  <Grid size={{ xs: 12, md: 7 }}>
                    <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                      Compras por mes
                    </Typography>
                    <Box sx={{ width: "100%", height: 350 }}>
                      <BarChart
                        height={330}
                        xAxis={[{ data: byMonth.data.map((d) => d.Month), scaleType: "band", label: "Mes" }]}
                        yAxis={[{ label: "Monto ($)" }]}
                        series={[
                          {
                            data: byMonth.data.map((d) => d.Total),
                            label: "Total compras",
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

          {/* Tab 1: Top Proveedores */}
          {chartTab === 1 && (
            <Box>
              {bySupplier.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !bySupplier.data || bySupplier.data.length === 0 ? (
                <Alert severity="info">Sin datos de proveedores</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Top 10 proveedores por monto
                  </Typography>
                  <Box sx={{ width: "100%", height: 400 }}>
                    <BarChart
                      height={380}
                      layout="horizontal"
                      yAxis={[{
                        data: bySupplier.data.map((d) => d.SupplierName.length > 20 ? d.SupplierName.slice(0, 20) + "..." : d.SupplierName),
                        scaleType: "band",
                      }]}
                      xAxis={[{ label: "Monto ($)" }]}
                      series={[
                        {
                          data: bySupplier.data.map((d) => d.Total),
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

          {/* Tab 2: Aging CxP */}
          {chartTab === 2 && (
            <Box>
              {aging.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !aging.data || aging.data.length === 0 ? (
                <Alert severity="info">Sin datos de aging</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Aging de Cuentas por Pagar (dias vencidos)
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

          {/* Tab 3: Proyeccion Pagos */}
          {chartTab === 3 && (
            <Box>
              {schedule.isLoading ? (
                <Skeleton variant="rectangular" height={350} sx={{ borderRadius: 2 }} />
              ) : !schedule.data || schedule.data.length === 0 ? (
                <Alert severity="info">Sin proyeccion de pagos</Alert>
              ) : (
                <>
                  <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
                    Proyeccion de pagos proximos 3 meses
                  </Typography>
                  <Box sx={{ width: "100%", height: 350 }}>
                    <BarChart
                      height={330}
                      xAxis={[{
                        data: schedule.data.map((d) => d.Month),
                        scaleType: "band",
                        label: "Mes",
                      }]}
                      yAxis={[{ label: "Monto a pagar ($)" }]}
                      series={[
                        {
                          data: schedule.data.map((d) => d.DueAmount),
                          label: "Monto vencimiento",
                          color: "#e65100",
                        },
                      ]}
                    />
                  </Box>
                  <Grid container spacing={2} sx={{ mt: 1 }}>
                    {schedule.data.map((d) => (
                      <Grid key={d.Month} size={{ xs: 12, sm: 4 }}>
                        <Box
                          sx={{
                            p: 2,
                            borderRadius: 2,
                            bgcolor: alpha("#e65100", 0.04),
                            border: "1px solid",
                            borderColor: alpha("#e65100", 0.15),
                            textAlign: "center",
                          }}
                        >
                          <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: "uppercase" }}>
                            {d.Month}
                          </Typography>
                          <Typography variant="h6" sx={{ fontWeight: 700, color: "#e65100" }}>
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

      {/* ── Footer: CxP Vencida Alert ───────────────────────── */}
      {k && k.CxPVencida > 0 && (
        <Alert
          severity="warning"
          variant="outlined"
          icon={<WarningAmberIcon />}
          action={
            <Button
              size="small"
              color="warning"
              onClick={() => router.push(`${bp}/cuentas-por-pagar`)}
              sx={{ textTransform: "none", fontWeight: 600 }}
            >
              Ver CxP
            </Button>
          }
          sx={{ borderRadius: 2 }}
        >
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            Hay {formatCurrency(k.CxPVencida)} en cuentas por pagar vencidas que requieren atencion inmediata.
          </Typography>
        </Alert>
      )}
    </Box>
  );
}
