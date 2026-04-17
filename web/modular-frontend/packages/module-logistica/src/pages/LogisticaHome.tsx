"use client";

import React, { useEffect, useRef, useState } from "react";
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
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import AssignmentReturnIcon from "@mui/icons-material/AssignmentReturn";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import PeopleIcon from "@mui/icons-material/People";
import DescriptionIcon from "@mui/icons-material/Description";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";
import { useRouter } from "next/navigation";
import {
  useLogisticaDashboard,
  useReceiptsByMonth,
  useDeliveryByStatus,
  useRecentActivity,
  useLogisticaTrends,
  useReceiptsList,
  useDeliveryNotesList,
} from "../hooks/useLogistica";
import { brandColors } from "@zentto/shared-ui";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import type { ColumnDef } from "@zentto/datagrid-core";
import {
  buildLogisticaGridId,
  useLogisticaGridId,
  useLogisticaGridRegistration,
} from "../components/zenttoGridPersistence";

/* ─── Helpers ─────────────────────────────────────────────── */

function pctChange(current: number, previous: number): number | null {
  if (previous === 0) return current > 0 ? 100 : null;
  return ((current - previous) / previous) * 100;
}

/* ─── KPI Card ─────────────────────────────────────────────── */

interface KPICardProps {
  title: string;
  value: string;
  icon: React.ReactNode;
  color: string;
  change?: number | null;
  loading?: boolean;
}

function KPICard({ title, value, icon, color, change, loading }: KPICardProps) {
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

/* ─── Activity Table Columns ─────────────────────────────── */

const activityCols: ColumnDef[] = [
  {
    field: "ActivityType",
    header: "Tipo",
    width: 100,
    statusColors: { RECEIPT: "info", DELIVERY: "success" },
    statusVariant: "outlined",
    renderCell: (value: unknown) => value === "RECEIPT" ? "Recepcion" : "Despacho",
  },
  { field: "DocNumber", header: "Documento", flex: 1, minWidth: 120 },
  { field: "EntityName", header: "Entidad", flex: 1.2, minWidth: 130, mobileHide: true },
  {
    field: "ActivityDate",
    header: "Fecha",
    width: 100,
    renderCell: (value: unknown) => String(value ?? "").slice(0, 10),
    mobileHide: true,
  },
  {
    field: "StatusLabel",
    header: "Estado",
    width: 110,
    renderCell: (value: unknown) => String(value ?? ""),
  },
];

/* ─── Quick Stats Columns ────────────────────────────────── */

const recentReceiptCols: ColumnDef[] = [
  { field: "ReceiptNumber", header: "N. Recepcion", flex: 1, minWidth: 120 },
  { field: "SupplierName", header: "Proveedor", flex: 1.2, minWidth: 130 },
  {
    field: "ReceiptDate",
    header: "Fecha",
    width: 100,
    renderCell: (value: unknown) => String(value ?? "").slice(0, 10),
  },
  {
    field: "Status",
    header: "Estado",
    width: 100,
    statusColors: { DRAFT: "#9e9e9e", PARTIAL: "#ff9800", COMPLETE: "#4caf50", VOIDED: "#f44336" },
    statusVariant: "outlined",
  },
];

const recentDeliveryCols: ColumnDef[] = [
  { field: "DeliveryNumber", header: "N. Albaran", flex: 1, minWidth: 120 },
  { field: "CustomerName", header: "Cliente", flex: 1.2, minWidth: 130 },
  {
    field: "DeliveryDate",
    header: "Fecha",
    width: 100,
    renderCell: (value: unknown) => String(value ?? "").slice(0, 10),
  },
  {
    field: "Status",
    header: "Estado",
    width: 110,
    statusColors: {
      DRAFT: "#9e9e9e", CONFIRMED: "#2196f3", PICKING: "#ff9800", PACKED: "#ff9800",
      DISPATCHED: "#1976d2", DELIVERED: "#4caf50", VOIDED: "#f44336",
    },
    statusVariant: "outlined",
  },
];

/* ─── Colors for pie chart ────────────────────────────────── */

const STATUS_COLORS: Record<string, string> = {
  DRAFT: "#9e9e9e",
  CONFIRMED: "#2196f3",
  PICKING: "#ff9800",
  PACKED: "#9c27b0",
  DISPATCHED: "#1976d2",
  DELIVERED: "#4caf50",
  VOIDED: "#f44336",
};

const GRID_IDS = {
  gridRef: buildLogisticaGridId("logistica-home", "actividad"),
  gridReceiptsRef: buildLogisticaGridId("logistica-home", "recepciones"),
  gridDeliveriesRef: buildLogisticaGridId("logistica-home", "despachos"),
} as const;

/* ─── Main Component ──────────────────────────────────────── */

export default function LogisticaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const gridRef = useRef<any>(null);
  const gridReceiptsRef = useRef<any>(null);
  const gridDeliveriesRef = useRef<any>(null);
  const { ready: activityLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  const { ready: receiptsLayoutReady } = useGridLayoutSync(GRID_IDS.gridReceiptsRef);
  const { ready: deliveriesLayoutReady } = useGridLayoutSync(GRID_IDS.gridDeliveriesRef);
  useLogisticaGridId(gridRef, GRID_IDS.gridRef);
  useLogisticaGridId(gridReceiptsRef, GRID_IDS.gridReceiptsRef);
  useLogisticaGridId(gridDeliveriesRef, GRID_IDS.gridDeliveriesRef);
  const layoutReady = activityLayoutReady && receiptsLayoutReady && deliveriesLayoutReady;
  const { registered } = useLogisticaGridRegistration(layoutReady);

const { data: dashboard, isLoading: dashLoading } = useLogisticaDashboard();
  const { data: receiptsMonthRaw, isLoading: loadingReceipts } = useReceiptsByMonth();
  const { data: deliveryStatusRaw, isLoading: loadingDelivery } = useDeliveryByStatus();
  const { data: activityRaw, isLoading: loadingActivity } = useRecentActivity();
  const { data: trends, isLoading: loadingTrends } = useLogisticaTrends();
  const { data: recentReceipts, isLoading: loadingRecentReceipts } = useReceiptsList({ page: 1, limit: 5 });
  const { data: recentDeliveries, isLoading: loadingRecentDeliveries } = useDeliveryNotesList({ page: 1, limit: 5 });

  // Normalize
  const receiptsMonth = Array.isArray(receiptsMonthRaw) ? receiptsMonthRaw : [];
  const deliveryStatus = Array.isArray(deliveryStatusRaw) ? deliveryStatusRaw : [];
  const activity = Array.isArray(activityRaw) ? activityRaw : [];

  // Trend calculations
  const receiptChange = trends ? pctChange(trends.ReceiptsThisMonth, trends.ReceiptsLastMonth) : null;
  const deliveryChange = trends ? pctChange(trends.DeliveriesThisMonth, trends.DeliveriesLastMonth) : null;

  const d = dashboard as Record<string, unknown> | undefined;

  // Entregas completadas del mes y valor de recepciones
  const entregasCompletadasMes = trends?.DeliveriesThisMonth ?? 0;
  const valorRecepcionesMes = Number(d?.ValorRecepcionesMes ?? d?.valorRecepcionesMes ?? 0);

  const kpiCards = [
    {
      title: "Recepciones Pendientes",
      value: String(d?.RecepcionesPendientes ?? d?.recepcionesPendientes ?? 0),
      icon: <ReceiptLongIcon />,
      color: brandColors.shortcutDark,
      change: receiptChange,
    },
    {
      title: "Devoluciones en Proceso",
      value: String(d?.DevolucionesEnProceso ?? d?.devolucionesEnProceso ?? 0),
      icon: <AssignmentReturnIcon />,
      color: brandColors.statRed,
    },
    {
      title: "Albaranes en Transito",
      value: String(d?.AlbaranesEnTransito ?? d?.albaranesEnTransito ?? 0),
      icon: <LocalShippingIcon />,
      color: brandColors.shortcutTeal,
      change: deliveryChange,
    },
    {
      title: "Entregas Completadas Mes",
      value: String(entregasCompletadasMes),
      icon: <CheckCircleIcon />,
      color: brandColors.success,
    },
    {
      title: "Transportistas Activos",
      value: String(d?.TransportistasActivos ?? d?.transportistasActivos ?? 0),
      icon: <PeopleIcon />,
      color: brandColors.shortcutViolet,
    },
    {
      title: "Valor Recepciones Mes",
      value: formatCurrency(valorRecepcionesMes),
      icon: <AttachMoneyIcon />,
      color: brandColors.shortcutSlate,
    },
  ];

  const shortcuts = [
    { title: "Recepciones", description: "Recepcion de mercancia", icon: <ReceiptLongIcon sx={{ fontSize: 32 }} />, href: `${bp}/recepciones`, bg: brandColors.shortcutDark },
    { title: "Devoluciones", description: "Gestionar devoluciones", icon: <AssignmentReturnIcon sx={{ fontSize: 32 }} />, href: `${bp}/devoluciones`, bg: brandColors.shortcutTeal },
    { title: "Albaranes", description: "Notas de entrega", icon: <DescriptionIcon sx={{ fontSize: 32 }} />, href: `${bp}/albaranes`, bg: brandColors.shortcutViolet },
    { title: "Transportistas", description: "Catalogo", icon: <LocalShippingIcon sx={{ fontSize: 32 }} />, href: `${bp}/transportistas`, bg: brandColors.statRed },
  ];

  const activityRows = activity.map((a, i) => ({ id: a.ActivityId ?? i, ...a }));

  // Pie chart data
  const pieData = deliveryStatus.map((d, idx) => ({
    id: idx,
    value: d.Count,
    label: d.StatusLabel,
    color: STATUS_COLORS[d.Status] || "#9e9e9e",
  }));

  // Quick stats rows
  const receiptRows = (recentReceipts?.rows ?? []).map((r, i) => ({
    id: (r as Record<string, unknown>).ReceiptId ?? i,
    ...(r as Record<string, unknown>),
  }));
  const deliveryRows = (recentDeliveries?.rows ?? []).map((r, i) => ({
    id: (r as Record<string, unknown>).DeliveryId ?? i,
    ...(r as Record<string, unknown>),
  }));

  // Bind activity grid
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = activityCols;
    el.rows = activityRows;
    el.loading = loadingActivity;
  }, [activityRows, loadingActivity, registered]);

  // Bind receipts grid
  useEffect(() => {
    const el = gridReceiptsRef.current;
    if (!el || !registered) return;
    el.columns = recentReceiptCols;
    el.rows = receiptRows;
    el.loading = loadingRecentReceipts;
  }, [receiptRows, loadingRecentReceipts, registered]);

  // Bind deliveries grid
  useEffect(() => {
    const el = gridDeliveriesRef.current;
    if (!el || !registered) return;
    el.columns = recentDeliveryCols;
    el.rows = deliveryRows;
    el.loading = loadingRecentDeliveries;
  }, [deliveryRows, loadingRecentDeliveries, registered]);

  return (
    <Box>
      {/* ─── KPI CARDS ──────────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {kpiCards.map((kpi, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 2 }} key={idx}>
            <KPICard
              title={kpi.title}
              value={kpi.value}
              icon={kpi.icon}
              color={kpi.color}
              change={kpi.change}
              loading={dashLoading || loadingTrends}
            />
          </Grid>
        ))}
      </Grid>

      {/* ─── SHORTCUTS ──────────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 6, sm: 4, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <CardActionArea onClick={() => router.push(sc.href)}>
                <Box sx={(t) => ({ bgcolor: sc.bg, backgroundImage: t.palette.mode === 'dark' ? 'linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))' : 'none', color: "white", display: "flex", justifyContent: "center", py: 3 })}>
                  {sc.icon}
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

      {/* ─── TREND MINI-CARDS ───────────────────────────────── */}
      {trends && !loadingTrends && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {[
            { label: "Recepciones este mes", current: trends.ReceiptsThisMonth, prev: trends.ReceiptsLastMonth },
            { label: "Despachos este mes", current: trends.DeliveriesThisMonth, prev: trends.DeliveriesLastMonth },
            { label: "Devoluciones este mes", current: trends.ReturnsThisMonth, prev: trends.ReturnsLastMonth },
          ].map((t, idx) => {
            const change = pctChange(t.current, t.prev);
            return (
              <Grid size={{ xs: 12, sm: 4 }} key={idx}>
                <Paper sx={{ borderRadius: 2, p: 2 }}>
                  <Typography variant="caption" sx={{ color: "text.secondary", fontWeight: 600, textTransform: "uppercase" }}>
                    {t.label}
                  </Typography>
                  <Box sx={{ display: "flex", alignItems: "baseline", gap: 1, mt: 0.5 }}>
                    <Typography variant="h5" sx={{ fontWeight: 700 }}>{t.current}</Typography>
                    {change !== null && (
                      <Chip
                        icon={change >= 0 ? <TrendingUpIcon sx={{ fontSize: 14 }} /> : <TrendingDownIcon sx={{ fontSize: 14 }} />}
                        label={`${change >= 0 ? "+" : ""}${change.toFixed(0)}%`}
                        size="small"
                        color={change >= 0 ? "success" : "error"}
                        variant="outlined"
                        sx={{ height: 22, fontSize: "0.7rem" }}
                      />
                    )}
                  </Box>
                  <Typography variant="caption" sx={{ color: "text.secondary" }}>
                    Mes anterior: {t.prev}
                  </Typography>
                </Paper>
              </Grid>
            );
          })}
        </Grid>
      )}

      {/* ─── CHARTS ─────────────────────────────────────────── */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {/* Bar Chart: Recepciones por mes */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Recepciones por Mes</Typography>
            {loadingReceipts ? (
              <Skeleton variant="rectangular" height={300} />
            ) : receiptsMonth.length > 0 ? (
              <Box sx={{ width: "100%", height: 300 }}>
                <BarChart
                  height={280}
                  xAxis={[{ data: receiptsMonth.map(r => r.MonthLabel), scaleType: "band" }]}
                  series={[{
                    data: receiptsMonth.map(r => r.Total),
                    label: "Recepciones",
                    color: "#1976d2",
                  }]}
                />
              </Box>
            ) : (
              <Alert severity="info">Sin datos de recepciones</Alert>
            )}
          </Paper>
        </Grid>

        {/* Pie Chart: Albaranes por estado */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Albaranes por Estado</Typography>
            {loadingDelivery ? (
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
              <Alert severity="info">Sin datos de albaranes</Alert>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* ─── RECENT ACTIVITY TABLE ──────────────────────────── */}
      <Paper sx={{ borderRadius: 2, p: 2, mb: 3 }}>
        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Actividad Reciente</Typography>
        {loadingActivity ? (
          <Skeleton variant="rectangular" height={300} />
        ) : activityRows.length > 0 ? (
          <zentto-grid
        ref={gridRef}
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
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
            <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <ReceiptLongIcon /> No hay actividad registrada aun
            </Typography>
          </Box>
        )}
      </Paper>

      {/* ─── QUICK STATS: Ultimas recepciones y entregas ────── */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas 5 Recepciones</Typography>
            {loadingRecentReceipts ? (
              <Skeleton variant="rectangular" height={200} />
            ) : receiptRows.length > 0 ? (
              <zentto-grid
        ref={gridReceiptsRef}
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
              <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
                Sin recepciones recientes
              </Typography>
            )}
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimas 5 Entregas</Typography>
            {loadingRecentDeliveries ? (
              <Skeleton variant="rectangular" height={200} />
            ) : deliveryRows.length > 0 ? (
              <zentto-grid
        ref={gridDeliveriesRef}
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-header-filters
        enable-configurator
      ></zentto-grid>
            ) : (
              <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
                Sin entregas recientes
              </Typography>
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
