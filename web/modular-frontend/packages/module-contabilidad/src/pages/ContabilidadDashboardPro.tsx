"use client";

import React, { useMemo } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Skeleton,
  Alert,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  Stack,
  LinearProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import PaidIcon from "@mui/icons-material/Paid";
import SavingsIcon from "@mui/icons-material/Savings";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import LockClockIcon from "@mui/icons-material/LockClock";
import AssessmentIcon from "@mui/icons-material/Assessment";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import ArrowUpwardIcon from "@mui/icons-material/ArrowUpward";
import ArrowDownwardIcon from "@mui/icons-material/ArrowDownward";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { brandColors } from "@zentto/shared-ui";
import { useRouter } from "next/navigation";
import { useDashboardResumen, useAsientosList } from "../hooks/useContabilidad";
import {
  usePeriodosList,
  useDueRecurrentes,
} from "../hooks/useContabilidadAdvanced";

// ─── KPI Card ────────────────────────────────────────────────

interface KpiCardProps {
  title: string;
  value: number;
  previousValue?: number;
  color: string;
  icon: React.ReactNode;
  isLoading: boolean;
  isPercent?: boolean;
}

function KpiCard({ title, value, previousValue, color, icon, isLoading, isPercent }: KpiCardProps) {
  const trend = previousValue != null && previousValue !== 0
    ? ((value - previousValue) / Math.abs(previousValue)) * 100
    : null;
  const trendUp = trend != null && trend > 0;

  return (
    <Card
      sx={{
        height: "100%",
        bgcolor: color,
        color: "white",
        borderRadius: 2,
        boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
        transition: "transform 0.2s",
        "&:hover": { transform: "translateY(-2px)" },
      }}
    >
      <CardContent sx={{ pb: "16px !important" }}>
        <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <Box sx={{ flex: 1 }}>
            {isLoading ? (
              <Skeleton variant="text" width={100} height={40} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
            ) : (
              <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1 }}>
                {isPercent ? `${value.toFixed(1)}%` : formatCurrency(value)}
              </Typography>
            )}
            <Typography variant="body2" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
              {title}
            </Typography>
          </Box>
          <Box sx={{ opacity: 0.5 }}>{icon}</Box>
        </Box>
        {trend != null && !isLoading && (
          <Stack direction="row" alignItems="center" spacing={0.5} sx={{ mt: 1 }}>
            {trendUp ? (
              <ArrowUpwardIcon sx={{ fontSize: 16 }} />
            ) : (
              <ArrowDownwardIcon sx={{ fontSize: 16 }} />
            )}
            <Typography variant="caption" sx={{ opacity: 0.85, fontWeight: 600 }}>
              {Math.abs(trend).toFixed(1)}% vs periodo anterior
            </Typography>
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}

// ─── Simple Bar Chart ────────────────────────────────────────

function SimpleBarChart({
  data,
  maxHeight = 160,
}: {
  data: { label: string; income: number; expense: number }[];
  maxHeight?: number;
}) {
  const maxVal = Math.max(
    ...data.map((d) => Math.max(d.income, d.expense)),
    1
  );

  return (
    <Box sx={{ display: "flex", alignItems: "flex-end", gap: 1, height: maxHeight, px: 1 }}>
      {data.map((d, i) => (
        <Box
          key={i}
          sx={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 0.5,
          }}
        >
          <Box sx={{ display: "flex", gap: "2px", alignItems: "flex-end", height: maxHeight - 20 }}>
            <Box
              sx={{
                width: 14,
                height: Math.max((d.income / maxVal) * (maxHeight - 30), 4),
                bgcolor: "#4caf50",
                borderRadius: "2px 2px 0 0",
                transition: "height 0.5s ease",
              }}
            />
            <Box
              sx={{
                width: 14,
                height: Math.max((d.expense / maxVal) * (maxHeight - 30), 4),
                bgcolor: "#f44336",
                borderRadius: "2px 2px 0 0",
                transition: "height 0.5s ease",
              }}
            />
          </Box>
          <Typography variant="caption" sx={{ fontSize: "0.65rem", color: "text.secondary" }}>
            {d.label}
          </Typography>
        </Box>
      ))}
    </Box>
  );
}

// ─── Simple Donut Chart ──────────────────────────────────────

function SimpleDonut({
  segments,
  size = 140,
}: {
  segments: { label: string; value: number; color: string }[];
  size?: number;
}) {
  const total = segments.reduce((s, seg) => s + seg.value, 0) || 1;
  const radius = size / 2 - 10;
  const innerRadius = radius * 0.55;

  let cumAngle = -90;

  const paths = segments.map((seg, i) => {
    const angle = (seg.value / total) * 360;
    const startAngle = cumAngle;
    cumAngle += angle;
    const endAngle = cumAngle;

    const startRad = (startAngle * Math.PI) / 180;
    const endRad = (endAngle * Math.PI) / 180;

    const x1 = size / 2 + radius * Math.cos(startRad);
    const y1 = size / 2 + radius * Math.sin(startRad);
    const x2 = size / 2 + radius * Math.cos(endRad);
    const y2 = size / 2 + radius * Math.sin(endRad);

    const ix1 = size / 2 + innerRadius * Math.cos(endRad);
    const iy1 = size / 2 + innerRadius * Math.sin(endRad);
    const ix2 = size / 2 + innerRadius * Math.cos(startRad);
    const iy2 = size / 2 + innerRadius * Math.sin(startRad);

    const largeArc = angle > 180 ? 1 : 0;

    const d = [
      `M ${x1} ${y1}`,
      `A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}`,
      `L ${ix1} ${iy1}`,
      `A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${ix2} ${iy2}`,
      "Z",
    ].join(" ");

    return <path key={i} d={d} fill={seg.color} />;
  });

  return (
    <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
      <svg width={size} height={size}>
        {paths}
      </svg>
      <Box>
        {segments.map((seg, i) => (
          <Stack key={i} direction="row" alignItems="center" spacing={1} sx={{ mb: 0.5 }}>
            <Box sx={{ width: 10, height: 10, borderRadius: "50%", bgcolor: seg.color }} />
            <Typography variant="caption">
              {seg.label}: {formatCurrency(seg.value)}
            </Typography>
          </Stack>
        ))}
      </Box>
    </Box>
  );
}

// ─── Main Dashboard ──────────────────────────────────────────

export default function ContabilidadDashboardPro() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  const { fechaDesde, fechaHasta } = useMemo(() => {
    const now = new Date();
    return {
      fechaDesde: toDateOnly(new Date(now.getFullYear(), 0, 1), timeZone),
      fechaHasta: toDateOnly(now, timeZone),
    };
  }, [timeZone]);

  const { data: resumen, isLoading, error } = useDashboardResumen(fechaDesde, fechaHasta);
  const { data: asientosData } = useAsientosList({ page: 1, limit: 10 });
  const { data: periodosData } = usePeriodosList(new Date().getFullYear());
  const { data: dueData } = useDueRecurrentes();

  const ultimosAsientos = asientosData?.rows ?? asientosData?.data ?? [];
  const periodosAbiertos = (periodosData?.data ?? periodosData?.rows ?? []).filter(
    (p: any) => p.status === "OPEN"
  ).length;
  const recurrentesVencidos = dueData?.data?.length ?? dueData?.rows?.length ?? 0;

  const ingresos = resumen?.totalIngresos ?? 0;
  const gastos = resumen?.totalGastos ?? 0;
  const utilidad = ingresos - gastos;
  const caja = resumen?.posicionCaja ?? resumen?.totalActivo ?? 0;
  const cxc = resumen?.cuentasPorCobrar ?? 0;
  const cxp = resumen?.cuentasPorPagar ?? 0;

  // Simulated monthly data for chart (would come from API)
  const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun"];
  const chartData = months.map((label, i) => ({
    label,
    income: ingresos > 0 ? ingresos / 6 * (0.8 + Math.random() * 0.4) : 0,
    expense: gastos > 0 ? gastos / 6 * (0.8 + Math.random() * 0.4) : 0,
  }));

  // Simulated expense breakdown
  const expenseSegments = [
    { label: "Personal", value: gastos * 0.35, color: "#f44336" },
    { label: "Operativo", value: gastos * 0.25, color: "#ff9800" },
    { label: "Servicios", value: gastos * 0.20, color: "#2196f3" },
    { label: "Otros", value: gastos * 0.20, color: "#9c27b0" },
  ];

  const kpiCards: KpiCardProps[] = [
    {
      title: "Ingresos del periodo",
      value: ingresos,
      color: "#1565c0",
      icon: <TrendingUpIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
    {
      title: "Gastos del periodo",
      value: gastos,
      color: "#c62828",
      icon: <TrendingDownIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
    {
      title: "Utilidad neta",
      value: utilidad,
      color: utilidad >= 0 ? "#2e7d32" : "#b71c1c",
      icon: <PaidIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
    {
      title: "Posición de caja",
      value: caja,
      color: "#00695c",
      icon: <SavingsIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
    {
      title: "CxC Pendiente",
      value: cxc,
      color: "#4527a0",
      icon: <ReceiptLongIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
    {
      title: "CxP Pendiente",
      value: cxp,
      color: "#e65100",
      icon: <AccountBalanceWalletIcon sx={{ fontSize: 32 }} />,
      isLoading,
    },
  ];

  const statusColor = (estado: string) => {
    switch (estado) {
      case "APPROVED": return "success";
      case "VOIDED": return "error";
      case "PENDING": return "warning";
      default: return "default";
    }
  };

  const quickActions = [
    {
      label: "Nuevo asiento",
      icon: <AddCircleOutlineIcon />,
      href: "/contabilidad/asientos/new",
      color: "#2e7d32",
    },
    {
      label: "Conciliar banco",
      icon: <AccountBalanceIcon />,
      href: "/contabilidad/conciliacion",
      color: "#1565c0",
    },
    {
      label: "Cerrar periodo",
      icon: <LockClockIcon />,
      href: "/contabilidad/cierre",
      color: "#e65100",
    },
    {
      label: "Ver reportes",
      icon: <AssessmentIcon />,
      href: "/contabilidad/reportes",
      color: "#6a1b9a",
    },
  ];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard contable pro
      </Typography>

      {error && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se pudieron cargar los datos del dashboard. Verifique la conexion con el servidor.
        </Alert>
      )}

      {/* ROW 1 - KPI Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {kpiCards.map((kpi, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 2 }} key={idx}>
            <KpiCard {...kpi} />
          </Grid>
        ))}
      </Grid>

      {/* ROW 2 - Charts */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ borderRadius: 2, p: 3, height: "100%" }}>
            <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
              Ingresos vs Gastos (Ultimos 6 meses)
            </Typography>
            <Stack direction="row" spacing={2} sx={{ mb: 1 }}>
              <Stack direction="row" alignItems="center" spacing={0.5}>
                <Box sx={{ width: 12, height: 12, bgcolor: "#4caf50", borderRadius: 1 }} />
                <Typography variant="caption">Ingresos</Typography>
              </Stack>
              <Stack direction="row" alignItems="center" spacing={0.5}>
                <Box sx={{ width: 12, height: 12, bgcolor: "#f44336", borderRadius: 1 }} />
                <Typography variant="caption">Gastos</Typography>
              </Stack>
            </Stack>
            {isLoading ? (
              <Skeleton variant="rectangular" height={160} />
            ) : (
              <SimpleBarChart data={chartData} />
            )}
          </Paper>
        </Grid>
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper sx={{ borderRadius: 2, p: 3, height: "100%" }}>
            <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
              Desglose de Gastos
            </Typography>
            {isLoading ? (
              <Skeleton variant="circular" width={140} height={140} />
            ) : gastos > 0 ? (
              <SimpleDonut segments={expenseSegments} />
            ) : (
              <Typography variant="body2" color="text.secondary">
                Sin datos de gastos
              </Typography>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* ROW 3 - Tables */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {/* Ultimos Asientos */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Últimos asientos
              </Typography>
            </Box>
            {ultimosAsientos.length > 0 ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Fecha</TableCell>
                    <TableCell>Tipo</TableCell>
                    <TableCell>Concepto</TableCell>
                    <TableCell align="right">Debe</TableCell>
                    <TableCell align="right">Haber</TableCell>
                    <TableCell>Estado</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {ultimosAsientos.slice(0, 10).map((a: any, idx: number) => (
                    <TableRow
                      key={a.asientoId ?? a.id ?? idx}
                      hover
                      sx={{ cursor: "pointer" }}
                      onClick={() => router.push("/contabilidad/asientos")}
                    >
                      <TableCell sx={{ fontSize: "0.8rem" }}>{a.fecha}</TableCell>
                      <TableCell sx={{ fontSize: "0.8rem" }}>{a.tipoAsiento}</TableCell>
                      <TableCell
                        sx={{
                          maxWidth: 220,
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                          fontSize: "0.8rem",
                        }}
                      >
                        {a.concepto}
                      </TableCell>
                      <TableCell align="right" sx={{ fontSize: "0.8rem" }}>
                        {formatCurrency(a.totalDebe ?? 0)}
                      </TableCell>
                      <TableCell align="right" sx={{ fontSize: "0.8rem" }}>
                        {formatCurrency(a.totalHaber ?? 0)}
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={a.estado}
                          size="small"
                          color={statusColor(a.estado) as any}
                          sx={{ fontSize: "0.7rem" }}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Box p={3} textAlign="center">
                <Typography variant="body2" color="text.secondary">
                  No hay asientos registrados
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Tareas Pendientes */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ borderRadius: 2, p: 3, height: "100%" }}>
            <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
              Tareas pendientes
            </Typography>

            <Stack spacing={2}>
              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  p: 1.5,
                  borderRadius: 1,
                  bgcolor: periodosAbiertos > 0 ? "warning.light" : "success.light",
                  cursor: "pointer",
                  "&:hover": { opacity: 0.85 },
                }}
                onClick={() => router.push("/contabilidad/cierre")}
              >
                <Stack direction="row" alignItems="center" spacing={1}>
                  <LockClockIcon sx={{ color: periodosAbiertos > 0 ? "warning.dark" : "success.dark" }} />
                  <Typography variant="body2" fontWeight={500}>
                    Periodos sin cerrar
                  </Typography>
                </Stack>
                <Chip
                  label={periodosAbiertos}
                  size="small"
                  color={periodosAbiertos > 0 ? "warning" : "success"}
                />
              </Box>

              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  p: 1.5,
                  borderRadius: 1,
                  bgcolor: recurrentesVencidos > 0 ? "error.light" : "success.light",
                  cursor: "pointer",
                  "&:hover": { opacity: 0.85 },
                }}
                onClick={() => router.push("/contabilidad/recurrentes")}
              >
                <Stack direction="row" alignItems="center" spacing={1}>
                  <WarningAmberIcon
                    sx={{ color: recurrentesVencidos > 0 ? "error.dark" : "success.dark" }}
                  />
                  <Typography variant="body2" fontWeight={500}>
                    Asientos recurrentes vencidos
                  </Typography>
                </Stack>
                <Chip
                  label={recurrentesVencidos}
                  size="small"
                  color={recurrentesVencidos > 0 ? "error" : "success"}
                />
              </Box>

              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  p: 1.5,
                  borderRadius: 1,
                  bgcolor: "info.light",
                  cursor: "pointer",
                  "&:hover": { opacity: 0.85 },
                }}
                onClick={() => router.push("/contabilidad/conciliacion")}
              >
                <Stack direction="row" alignItems="center" spacing={1}>
                  <AccountBalanceIcon sx={{ color: "info.dark" }} />
                  <Typography variant="body2" fontWeight={500}>
                    Partidas sin conciliar
                  </Typography>
                </Stack>
                <Chip label="--" size="small" color="info" />
              </Box>
            </Stack>
          </Paper>
        </Grid>
      </Grid>

      {/* ROW 4 - Quick Actions */}
      <Paper sx={{ borderRadius: 2, p: 2 }}>
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5, textTransform: "uppercase", letterSpacing: 1 }}>
          Acciones rápidas
        </Typography>
        <Stack direction="row" spacing={2} flexWrap="wrap">
          {quickActions.map((action, idx) => (
            <Card
              key={idx}
              sx={{
                flex: "1 1 180px",
                cursor: "pointer",
                borderRadius: 2,
                transition: "transform 0.2s, box-shadow 0.2s",
                "&:hover": { transform: "translateY(-2px)", boxShadow: "0 4px 12px rgba(0,0,0,0.15)" },
              }}
              onClick={() => router.push(action.href)}
            >
              <CardContent
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  py: 2,
                  px: 1,
                }}
              >
                <Box sx={{ color: action.color, mb: 1 }}>
                  {React.cloneElement(action.icon as React.ReactElement, { sx: { fontSize: 36 } })}
                </Box>
                <Typography variant="body2" fontWeight={600} textAlign="center">
                  {action.label}
                </Typography>
              </CardContent>
            </Card>
          ))}
        </Stack>
      </Paper>
    </Box>
  );
}
