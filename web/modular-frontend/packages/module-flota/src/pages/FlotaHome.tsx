"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Alert,
  AlertTitle,
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
import DirectionsCarIcon from "@mui/icons-material/DirectionsCar";
import LocalGasStationIcon from "@mui/icons-material/LocalGasStation";
import BuildIcon from "@mui/icons-material/Build";
import RouteIcon from "@mui/icons-material/Route";
import SpeedIcon from "@mui/icons-material/Speed";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import { BarChart } from "@mui/x-charts/BarChart";
import { LineChart } from "@mui/x-charts/LineChart";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import {
  useFlotaDashboard,
  useFleetAlerts,
  useFuelCostByVehicle,
  useKmByMonth,
  useNextMaintenance,
  useFlotaTrends,
} from "../hooks/useFlota";
import { brandColors } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";

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

/* ─── Maintenance Table Columns ──────────────────────────── */

const maintenanceCols: ColumnDef[] = [
  { field: "OrderNumber", header: "N. Orden", flex: 0.8, minWidth: 90 },
  { field: "LicensePlate", header: "Placa", flex: 0.7, minWidth: 80 },
  { field: "MaintenanceType", header: "Tipo", flex: 1, minWidth: 120, mobileHide: true },
  {
    field: "ScheduledDate",
    header: "Fecha",
    width: 100,
    valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
  },
  {
    field: "EstimatedCost",
    header: "Costo Est.",
    width: 100,
    type: "number",
    valueFormatter: (value: unknown) => formatCurrency(Number(value ?? 0)),
    mobileHide: true,
  },
];

/* ─── Main Component ──────────────────────────────────────── */

export default function FlotaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  // Register zentto-grid web component
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  // Data hooks
  const { data: dashboard, isLoading: dashLoading } = useFlotaDashboard();
  const { data: alerts } = useFleetAlerts();
  const { data: fuelByVehicleRaw, isLoading: loadingFuel } = useFuelCostByVehicle();
  const { data: kmByMonthRaw, isLoading: loadingKm } = useKmByMonth();
  const { data: nextMaintRaw, isLoading: loadingMaint } = useNextMaintenance();
  const { data: trends, isLoading: loadingTrends } = useFlotaTrends();

  // Normalize
  const fuelByVehicle = Array.isArray(fuelByVehicleRaw) ? fuelByVehicleRaw : [];
  const kmByMonth = Array.isArray(kmByMonthRaw) ? kmByMonthRaw : [];
  const nextMaint = Array.isArray(nextMaintRaw) ? nextMaintRaw : [];

  // Alert summary
  const summary = alerts?.summary;
  const hasAlerts = summary && (summary.expiredDocsCount > 0 || summary.expiringSoonDocsCount > 0 || summary.overdueMaintenanceCount > 0);

  // Trends
  const fuelChange = trends ? pctChange(trends.FuelCostThisMonth, trends.FuelCostLastMonth) : null;
  const kmChange = trends ? pctChange(trends.KmThisMonth, trends.KmLastMonth) : null;

  const db = dashboard as Record<string, unknown> | undefined;
  const kpiCards = [
    {
      title: "Vehiculos Activos",
      value: String(db?.VehiculosActivos ?? db?.TotalActiveVehicles ?? 0),
      icon: <DirectionsCarIcon />,
      color: "#1976d2",
    },
    {
      title: "Km Total Mes",
      value: db ? Number(db.KmTotalMes ?? trends?.KmThisMonth ?? 0).toLocaleString("es") : "\u2014",
      icon: <SpeedIcon />,
      color: "#00897b",
      change: kmChange,
    },
    {
      title: "Costo Combustible Mes",
      value: db ? formatCurrency(Number(db.CostoCombustibleMes ?? db.FuelCostThisMonth ?? 0)) : "\u2014",
      icon: <LocalGasStationIcon />,
      color: "#f44336",
      change: fuelChange,
    },
    {
      title: "Mant. Pendientes",
      value: String(db?.MantenimientosPendientes ?? db?.MaintenancePending ?? 0),
      icon: <BuildIcon />,
      color: "#ff9800",
    },
  ];

  const shortcuts = [
    { title: "Vehiculos", description: "Catalogo de vehiculos", icon: <DirectionsCarIcon sx={{ fontSize: 32 }} />, href: `${bp}/vehiculos`, bg: brandColors.shortcutGreen },
    { title: "Combustible", description: "Control de cargas", icon: <LocalGasStationIcon sx={{ fontSize: 32 }} />, href: `${bp}/combustible`, bg: brandColors.shortcutDark },
    { title: "Mantenimiento", description: "Ordenes de servicio", icon: <BuildIcon sx={{ fontSize: 32 }} />, href: `${bp}/mantenimiento`, bg: brandColors.shortcutNavy },
    { title: "Viajes", description: "Control de rutas", icon: <RouteIcon sx={{ fontSize: 32 }} />, href: `${bp}/viajes`, bg: brandColors.shortcutSlate },
  ];

  const maintRows = nextMaint.map((m, i) => ({ id: m.MaintenanceOrderId ?? i, ...m }));

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = maintenanceCols;
    el.rows = maintRows;
    el.loading = loadingMaint;
  }, [maintRows, loadingMaint, registered]);

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Flota
      </Typography>

      {/* ─── ALERTAS ────────────────────────────────────────── */}
      {hasAlerts && (
        <Grid container spacing={2} sx={{ mb: 3 }}>
          {(summary.expiredDocsCount > 0) && (
            <Grid size={{ xs: 12, md: 4 }}>
              <Alert severity="error" icon={<ErrorOutlineIcon />} sx={{ borderRadius: 2 }}>
                <AlertTitle sx={{ fontWeight: 700 }}>Documentos Vencidos</AlertTitle>
                {summary.expiredDocsCount} documento{summary.expiredDocsCount > 1 ? "s" : ""} vencido{summary.expiredDocsCount > 1 ? "s" : ""}
                {alerts.expired.length > 0 && (
                  <Box sx={{ mt: 1 }}>
                    {alerts.expired.slice(0, 3).map((a, i) => (
                      <Typography key={i} variant="caption" display="block" sx={{ opacity: 0.85 }}>
                        {a.LicensePlate} - {a.DocumentType} ({a.DaysOverdue}d vencido)
                      </Typography>
                    ))}
                  </Box>
                )}
              </Alert>
            </Grid>
          )}
          {(summary.expiringSoonDocsCount > 0) && (
            <Grid size={{ xs: 12, md: 4 }}>
              <Alert severity="warning" icon={<WarningAmberIcon />} sx={{ borderRadius: 2 }}>
                <AlertTitle sx={{ fontWeight: 700 }}>Documentos por Vencer</AlertTitle>
                {summary.expiringSoonDocsCount} por vencer (30 dias)
                {alerts.expiringSoon.length > 0 && (
                  <Box sx={{ mt: 1 }}>
                    {alerts.expiringSoon.slice(0, 3).map((a, i) => (
                      <Typography key={i} variant="caption" display="block" sx={{ opacity: 0.85 }}>
                        {a.LicensePlate} - {a.DocumentType} ({a.DaysUntilExpiry}d restantes)
                      </Typography>
                    ))}
                  </Box>
                )}
              </Alert>
            </Grid>
          )}
          {(summary.overdueMaintenanceCount > 0) && (
            <Grid size={{ xs: 12, md: 4 }}>
              <Alert severity="error" icon={<BuildIcon />} sx={{ borderRadius: 2 }}>
                <AlertTitle sx={{ fontWeight: 700 }}>Mantenimientos Vencidos</AlertTitle>
                {summary.overdueMaintenanceCount} atrasado{summary.overdueMaintenanceCount > 1 ? "s" : ""}
                {alerts.maintenanceOverdue.length > 0 && (
                  <Box sx={{ mt: 1 }}>
                    {alerts.maintenanceOverdue.slice(0, 3).map((a, i) => (
                      <Typography key={i} variant="caption" display="block" sx={{ opacity: 0.85 }}>
                        {a.LicensePlate} - {a.MaintenanceTypeName} ({a.DaysOverdue}d atrasado)
                      </Typography>
                    ))}
                  </Box>
                )}
              </Alert>
            </Grid>
          )}
        </Grid>
      )}

      {/* ─── KPI CARDS ──────────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {kpiCards.map((kpi, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
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
        {/* Bar Chart: Costo combustible por vehiculo */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Costo Combustible por Vehiculo (Top 5)</Typography>
            {loadingFuel ? (
              <Skeleton variant="rectangular" height={300} />
            ) : fuelByVehicle.length > 0 ? (
              <Box sx={{ width: "100%", height: 300 }}>
                <BarChart
                  height={280}
                  layout="horizontal"
                  yAxis={[{ data: fuelByVehicle.map(v => v.LicensePlate), scaleType: "band" }]}
                  xAxis={[{ valueFormatter: (v: number) => formatCurrency(v) }]}
                  series={[{
                    data: fuelByVehicle.map(v => Number(v.TotalCost)),
                    label: "Costo",
                    color: "#f44336",
                    valueFormatter: (v) => formatCurrency(v ?? 0),
                  }]}
                />
              </Box>
            ) : (
              <Alert severity="info">Sin datos de combustible este mes</Alert>
            )}
          </Paper>
        </Grid>

        {/* Line Chart: Km por mes */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2, height: "100%" }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>Km Recorridos por Mes</Typography>
            {loadingKm ? (
              <Skeleton variant="rectangular" height={300} />
            ) : kmByMonth.length > 0 ? (
              <Box sx={{ width: "100%", height: 300 }}>
                <LineChart
                  height={280}
                  xAxis={[{ data: kmByMonth.map(k => k.MonthLabel), scaleType: "band" }]}
                  series={[{
                    data: kmByMonth.map(k => Number(k.TotalKm)),
                    label: "Km",
                    color: "#00897b",
                    area: true,
                  }]}
                />
              </Box>
            ) : (
              <Alert severity="info">Sin datos de kilometraje</Alert>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* ─── NEXT MAINTENANCE TABLE ─────────────────────────── */}
      <Paper sx={{ borderRadius: 2, p: 2 }}>
        <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Proximos Mantenimientos</Typography>
        {loadingMaint ? (
          <Skeleton variant="rectangular" height={250} />
        ) : maintRows.length > 0 ? (
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
      ></zentto-grid>
        ) : (
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
            <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <BuildIcon /> No hay mantenimientos pendientes
            </Typography>
          </Box>
        )}
      </Paper>
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
