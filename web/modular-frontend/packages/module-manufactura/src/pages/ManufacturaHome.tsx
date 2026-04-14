"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Alert,
  Box,
  Card,
  CardActionArea,
  CardContent,
  Chip,
  Paper,
  Skeleton,
  Typography,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { alpha } from "@mui/material/styles";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import PrecisionManufacturingIcon from "@mui/icons-material/PrecisionManufacturing";
import FactoryIcon from "@mui/icons-material/Factory";
import AssignmentIcon from "@mui/icons-material/Assignment";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import RouteIcon from "@mui/icons-material/Route";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import InventoryIcon from "@mui/icons-material/Inventory";
import TimerIcon from "@mui/icons-material/Timer";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";
import { useRouter } from "next/navigation";
import {
  useManufacturaDashboard,
  useProductionByProduct,
  useOrdersByStatus,
  useRecentOrders,
  useBOMList,
} from "../hooks/useManufactura";
import { brandColors } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useManufacturaGridRegistration } from "../components/zenttoGridPersistence";

/* ─── Helpers ─────────────────────────────────────────────── */

function pctChange(current: number, previous: number): number | null {
  if (previous === 0) return current > 0 ? 100 : null;
  return ((current - previous) / previous) * 100;
}

/* ─── KPI Card ─────────────────────────────────────────────── */

interface KPICardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: React.ReactNode;
  color: string;
  change?: number | null;
  loading?: boolean;
}

function KPICard({ title, value, subtitle, icon, color, change, loading }: KPICardProps) {
  return (
    <Card
      sx={{
        height: "100%",
        borderRadius: 2,
        border: `1px solid ${alpha(color, 0.2)}`,
        boxShadow: `0 2px 8px ${alpha(color, 0.08)}`,
      }}
    >
      <CardContent sx={{ pb: "12px !important", pt: 2 }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography
              variant="caption"
              sx={{ color: "text.secondary", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5, fontSize: "0.7rem" }}
            >
              {title}
            </Typography>
            {loading ? (
              <Skeleton variant="text" width={80} height={36} sx={{ mt: 0.5 }} />
            ) : (
              <Typography variant="h5" sx={{ fontWeight: 700, color, mt: 0.5, lineHeight: 1.1 }}>
                {value}
              </Typography>
            )}
            {subtitle && !loading && (
              <Typography variant="caption" sx={{ color: "text.secondary", mt: 0.3, display: "block" }}>
                {subtitle}
              </Typography>
            )}
            {change !== undefined && change !== null && !loading && (
              <Box sx={{ display: "flex", alignItems: "center", mt: 0.5 }}>
                {change >= 0 ? (
                  <TrendingUpIcon sx={{ fontSize: 14, color: "success.main", mr: 0.3 }} />
                ) : (
                  <TrendingDownIcon sx={{ fontSize: 14, color: "error.main", mr: 0.3 }} />
                )}
                <Typography
                  variant="caption"
                  sx={{ color: change >= 0 ? "success.main" : "error.main", fontWeight: 600 }}
                >
                  {change >= 0 ? "+" : ""}{change.toFixed(1)}% vs mes anterior
                </Typography>
              </Box>
            )}
          </Box>
          <Box
            sx={{
              bgcolor: alpha(color, 0.1),
              borderRadius: 1.5,
              p: 1,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color,
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── Order Status Colors ─────────────────────────────────── */

const ORDER_STATUS_COLORS: Record<string, string> = {
  DRAFT: "#9e9e9e",
  CONFIRMED: "#2196f3",
  IN_PROGRESS: "#ff9800",
  COMPLETED: "#4caf50",
  CANCELLED: "#f44336",
};

/* ─── Recent Orders Columns ──────────────────────────────── */

const recentOrderCols: ColumnDef[] = [
  { field: "WorkOrderNumber", header: "N. Orden", flex: 0.8, minWidth: 100 },
  { field: "ProductName", header: "Producto", flex: 1.2, minWidth: 130, mobileHide: true },
  {
    field: "PlannedQuantity",
    header: "Planificada",
    width: 90,
    type: "number",
    aggregation: "sum",
    renderCell: (value: unknown) => Number(value ?? 0).toLocaleString("es"),
    mobileHide: true,
  },
  {
    field: "ProducedQuantity",
    header: "Producida",
    width: 90,
    type: "number",
    aggregation: "sum",
    renderCell: (value: unknown) => Number(value ?? 0).toLocaleString("es"),
    mobileHide: true,
  },
  {
    field: "StatusLabel",
    header: "Estado",
    width: 120,
    statusColors: {
      Borrador: "default",
      "En Proceso": "warning",
      Completada: "success",
      Cancelada: "error",
    },
  },
];

/* ─── Recent BOMs Columns ────────────────────────────────── */

const recentBomCols: ColumnDef[] = [
  { field: "BOMCode", header: "Codigo", flex: 0.7, minWidth: 90 },
  { field: "BOMName", header: "Nombre", flex: 1.3, minWidth: 140 },
  { field: "ProductName", header: "Producto", flex: 1, minWidth: 120, mobileHide: true },
  {
    field: "TotalCost",
    header: "Costo",
    width: 100,
    currency: true,
    mobileHide: true,
  },
  {
    field: "Status",
    header: "Estado",
    width: 100,
    statusColors: {
      DRAFT: "default",
      ACTIVE: "success",
      OBSOLETE: "error",
    },
  },
];

const DASHBOARD_BOMS_GRID_ID = "module-manufactura:dashboard:boms";
const DASHBOARD_ORDERS_GRID_ID = "module-manufactura:dashboard:orders";

/* ─── Main Component ──────────────────────────────────────── */

export default function ManufacturaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const bomGridRef = useRef<any>(null);
  const ordersGridRef = useRef<any>(null);
  const { ready: dashboardBomsLayoutReady } = useGridLayoutSync(DASHBOARD_BOMS_GRID_ID);
  const { ready: dashboardOrdersLayoutReady } = useGridLayoutSync(DASHBOARD_ORDERS_GRID_ID);
  const layoutReady = dashboardBomsLayoutReady && dashboardOrdersLayoutReady;
  const { gridReady, registered } = useManufacturaGridRegistration(layoutReady);

  // Data hooks
  const { data: dashboard, isLoading: dashLoading } = useManufacturaDashboard();
  const { data: prodByProductRaw, isLoading: loadingProd } = useProductionByProduct();
  const { data: ordersByStatusRaw, isLoading: loadingStatus } = useOrdersByStatus();
  const { data: recentOrdersRaw, isLoading: loadingRecent } = useRecentOrders();
  const { data: bomData, isLoading: loadingBom } = useBOMList({ limit: 5, page: 1 });

  // Normalize
  const prodByProduct = Array.isArray(prodByProductRaw) ? prodByProductRaw : [];
  const ordersByStatus = Array.isArray(ordersByStatusRaw) ? ordersByStatusRaw : [];
  const recentOrders = Array.isArray(recentOrdersRaw) ? recentOrdersRaw : [];
  const recentBoms = (bomData?.rows ?? []) as Record<string, unknown>[];

  // Calculations
  const completedChange = dashboard
    ? pctChange(dashboard.CompletadasEsteMes ?? 0, dashboard.CompletadasMesAnterior ?? 0)
    : null;

  const efficiencyPct = dashboard && (dashboard.OrdenesTotalesMes ?? 0) > 0
    ? ((dashboard.OrdenesATiempo ?? 0) / dashboard.OrdenesTotalesMes * 100).toFixed(1)
    : null;

  // Total produced this month (sum from ordersByStatus for COMPLETED)
  const cancelledCount = ordersByStatus.find(s => s.Status === "CANCELLED")?.Count ?? 0;
  const totalProduced = prodByProduct.reduce((acc, p) => acc + Number(p.TotalQuantity ?? 0), 0);

  const kpiCards = [
    {
      title: "BOMs Activos",
      value: String(dashboard?.BOMsActivos ?? 0),
      subtitle: "Listas de materiales",
      icon: <AccountTreeIcon />,
      color: "#1976d2",
    },
    {
      title: "Centros de Trabajo",
      value: String(dashboard?.CentrosTrabajo ?? 0),
      icon: <FactoryIcon />,
      color: "#00897b",
    },
    {
      title: "Ordenes en Proceso",
      value: String(dashboard?.OrdenesEnProceso ?? 0),
      icon: <PrecisionManufacturingIcon />,
      color: "#ff9800",
    },
    {
      title: "Completadas este Mes",
      value: String(dashboard?.CompletadasEsteMes ?? dashboard?.OrdenesCompletadas ?? 0),
      icon: <CheckCircleIcon />,
      color: "#4caf50",
      change: completedChange,
    },
    {
      title: "Canceladas",
      value: String(cancelledCount),
      subtitle: "Ordenes canceladas",
      icon: <CancelIcon />,
      color: "#f44336",
    },
    {
      title: "Produccion Total",
      value: totalProduced.toLocaleString("es"),
      subtitle: "Cantidad producida este mes",
      icon: <InventoryIcon />,
      color: "#7b1fa2",
    },
  ];

  const shortcuts = [
    { title: "BOM", description: "Lista de materiales", icon: <AccountTreeIcon sx={{ fontSize: 32 }} />, href: `${bp}/bom`, bg: brandColors.shortcutGreen },
    { title: "Centros de Trabajo", description: "Configuracion", icon: <FactoryIcon sx={{ fontSize: 32 }} />, href: `${bp}/centros-trabajo`, bg: brandColors.shortcutDark },
    { title: "Rutas", description: "Produccion", icon: <RouteIcon sx={{ fontSize: 32 }} />, href: `${bp}/rutas`, bg: brandColors.shortcutGreen },
    { title: "Ordenes", description: "Produccion", icon: <AssignmentIcon sx={{ fontSize: 32 }} />, href: `${bp}/ordenes`, bg: brandColors.shortcutNavy },
  ];

  const recentRows = recentOrders.map((o, i) => ({ id: o.WorkOrderId ?? i, ...o }));
  const bomRows = recentBoms.map((b, i) => ({ id: (b.BOMId as number) ?? i, ...b }));

  // Bind data to zentto-grid web components
  useEffect(() => {
    const el = bomGridRef.current;
    if (!el || !registered) return;
    el.columns = recentBomCols;
    el.rows = bomRows;
    el.loading = loadingBom;
  }, [bomRows, loadingBom, registered]);

  useEffect(() => {
    const el = ordersGridRef.current;
    if (!el || !registered) return;
    el.columns = recentOrderCols;
    el.rows = recentRows;
    el.loading = loadingRecent;
  }, [recentRows, loadingRecent, registered]);

  // Pie data
  const pieData = ordersByStatus.map((d, idx) => ({
    id: idx,
    value: d.Count,
    label: d.StatusLabel,
    color: ORDER_STATUS_COLORS[d.Status] || "#9e9e9e",
  }));

  return (
    <Box>
      {/* ─── KPI CARDS (6) ────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {kpiCards.map((kpi, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 2 }} key={idx}>
            <KPICard
              title={kpi.title}
              value={kpi.value}
              subtitle={kpi.subtitle}
              icon={kpi.icon}
              color={kpi.color}
              change={kpi.change}
              loading={dashLoading}
            />
          </Grid>
        ))}
      </Grid>

      {/* ─── EFFICIENCY CARD ────────────────────────────────── */}
      {efficiencyPct !== null && (
        <Paper sx={{ borderRadius: 2, p: 2.5, mb: 3 }}>
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <Box>
              <Typography
                variant="caption"
                sx={{ color: "text.secondary", fontWeight: 600, textTransform: "uppercase" }}
              >
                Eficiencia de Produccion
              </Typography>
              <Typography variant="h4" sx={{ fontWeight: 700, mt: 0.5 }}>
                {efficiencyPct}%
              </Typography>
              <Typography variant="caption" sx={{ color: "text.secondary" }}>
                Ordenes completadas a tiempo vs total este mes
              </Typography>
            </Box>
            <Box
              sx={{
                bgcolor: alpha("#4caf50", 0.1),
                borderRadius: 2,
                p: 2,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <TimerIcon sx={{ fontSize: 40, color: "#4caf50" }} />
            </Box>
          </Box>
          <Box sx={{ mt: 1.5, height: 8, bgcolor: "grey.100", borderRadius: 4, overflow: "hidden" }}>
            <Box
              sx={{
                height: "100%",
                width: `${Math.min(parseFloat(efficiencyPct), 100)}%`,
                bgcolor: parseFloat(efficiencyPct) >= 80 ? "#4caf50" : parseFloat(efficiencyPct) >= 50 ? "#ff9800" : "#f44336",
                borderRadius: 4,
                transition: "width 0.5s ease",
              }}
            />
          </Box>
        </Paper>
      )}

      {/* ─── SHORTCUTS ──────────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 6, sm: 4, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <CardActionArea onClick={() => router.push(sc.href)}>
                <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3, position: "relative" }}>
                  {sc.icon}
                  <svg preserveAspectRatio="none" style={{ position: "absolute", bottom: 0, left: 0, width: "100%", height: "30px" }} viewBox="0 0 100 100">
                    <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                  </svg>
                </Box>
                <CardContent sx={{ textAlign: "center", py: 1.5 }}>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, color: "text.primary", mb: 0, lineHeight: 1.3 }}>{sc.title}</Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>{sc.description}</Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ─── CHARTS ─────────────────────────────────────────── */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {/* Bar Chart: Produccion por producto */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Produccion por Producto (Top 5)</Typography>
            {loadingProd ? (
              <Skeleton variant="rectangular" height={300} />
            ) : prodByProduct.length > 0 ? (
              <Box sx={{ width: "100%", height: 300 }}>
                <BarChart
                  height={280}
                  xAxis={[{ data: prodByProduct.map(p => p.ProductName), scaleType: "band" }]}
                  series={[{
                    data: prodByProduct.map(p => Number(p.TotalQuantity)),
                    label: "Cantidad Producida",
                    color: "#1976d2",
                  }]}
                />
              </Box>
            ) : (
              <Alert severity="info">Sin datos de produccion este mes</Alert>
            )}
          </Paper>
        </Grid>

        {/* Pie Chart: Ordenes por estado */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Ordenes por Estado</Typography>
            {loadingStatus ? (
              <Skeleton variant="rectangular" height={300} />
            ) : pieData.length > 0 ? (
              <Box sx={{ width: "100%", height: 300 }}>
                <PieChart
                  height={280}
                  series={[{
                    data: pieData,
                    highlightScope: { fade: "global", highlight: "item" },
                    innerRadius: 40,
                    paddingAngle: 2,
                    cornerRadius: 4,
                  }]}
                />
              </Box>
            ) : (
              <Alert severity="info">Sin datos de ordenes</Alert>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* ─── QUICK STATS: Recent BOMs + Recent Orders ─────── */}
      <Grid container spacing={3}>
        {/* Ultimas 5 BOMs */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas BOMs</Typography>
            {loadingBom ? (
              <Skeleton variant="rectangular" height={200} />
            ) : bomRows.length > 0 ? (
              <zentto-grid
        ref={bomGridRef}
        grid-id={DASHBOARD_BOMS_GRID_ID}
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-header-filters
      ></zentto-grid>
            ) : (
              <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 100, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  No hay BOMs registradas aun
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Ultimas 5 Ordenes */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ordenes Recientes</Typography>
            {loadingRecent ? (
              <Skeleton variant="rectangular" height={200} />
            ) : recentRows.length > 0 ? (
              <zentto-grid
        ref={ordersGridRef}
        grid-id={DASHBOARD_ORDERS_GRID_ID}
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-header-filters
      ></zentto-grid>
            ) : (
              <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 100, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                  <PrecisionManufacturingIcon /> No hay ordenes registradas aun
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
