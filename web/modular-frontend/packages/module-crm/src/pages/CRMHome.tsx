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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Badge,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { alpha } from "@mui/material/styles";
import PeopleIcon from "@mui/icons-material/People";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import PercentIcon from "@mui/icons-material/Percent";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import TimerIcon from "@mui/icons-material/Timer";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import AssignmentLateIcon from "@mui/icons-material/AssignmentLate";
import FiberNewIcon from "@mui/icons-material/FiberNew";
import ViewKanbanIcon from "@mui/icons-material/ViewKanban";
import FormatListBulletedIcon from "@mui/icons-material/FormatListBulleted";
import EventNoteIcon from "@mui/icons-material/EventNote";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import { useRouter } from "next/navigation";
import { usePipelinesList } from "../hooks/useCRM";
import {
  useCRMKPIs,
  useCRMForecast,
  useCRMFunnel,
  useCRMWinLossByPeriod,
  useCRMWinLossBySource,
  useCRMVelocity,
  useCRMActivityReport,
} from "../hooks/useCRMAnalytics";
import {
  ForecastChart,
  FunnelChart,
  WinLossChart,
  VelocityChart,
  ActivityReportChart,
} from "../components/charts";
import { StaleLeadsAlert } from "../components/StaleLeadsAlert";

/* ─── Helpers ──────────────────────────────────────────────── */

function calcDateRange(range: string): { dateFrom?: string; dateTo?: string } {
  const now = new Date();
  const to = now.toISOString().slice(0, 10);
  let from: string;

  switch (range) {
    case "7d":
      from = new Date(now.getTime() - 7 * 86400000).toISOString().slice(0, 10);
      break;
    case "30d":
      from = new Date(now.getTime() - 30 * 86400000)
        .toISOString()
        .slice(0, 10);
      break;
    case "90d":
      from = new Date(now.getTime() - 90 * 86400000)
        .toISOString()
        .slice(0, 10);
      break;
    case "YTD":
      from = `${now.getFullYear()}-01-01`;
      break;
    default:
      from = new Date(now.getTime() - 30 * 86400000)
        .toISOString()
        .slice(0, 10);
  }

  return { dateFrom: from, dateTo: to };
}

function pctChange(current: number, previous: number): number | null {
  if (previous === 0) return current > 0 ? 100 : null;
  return ((current - previous) / previous) * 100;
}

/* ─── Shortcuts ────────────────────────────────────────────── */

const shortcuts = [
  {
    title: "Pipeline",
    description: "Tablero Kanban",
    icon: <ViewKanbanIcon sx={{ fontSize: 32 }} />,
    href: "/crm/pipeline",
    bg: brandColors.shortcutDark,
  },
  {
    title: "Leads",
    description: "Lista completa",
    icon: <FormatListBulletedIcon sx={{ fontSize: 32 }} />,
    href: "/crm/leads",
    bg: brandColors.shortcutTeal,
  },
  {
    title: "Actividades",
    description: "Tareas y seguimiento",
    icon: <EventNoteIcon sx={{ fontSize: 32 }} />,
    href: "/crm/actividades",
    bg: brandColors.shortcutViolet,
  },
];

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

function KPICard({
  title,
  value,
  subtitle,
  icon,
  color,
  change,
  loading,
}: KPICardProps) {
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
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
          }}
        >
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography
              variant="caption"
              sx={{
                color: "text.secondary",
                fontWeight: 600,
                textTransform: "uppercase",
                letterSpacing: 0.5,
                fontSize: "0.7rem",
              }}
            >
              {title}
            </Typography>
            {loading ? (
              <Skeleton
                variant="text"
                width={100}
                height={36}
                sx={{ mt: 0.5 }}
              />
            ) : (
              <Typography
                variant="h5"
                sx={{ fontWeight: 700, color, mt: 0.5, lineHeight: 1.1 }}
              >
                {value}
              </Typography>
            )}
            {subtitle && !loading && (
              <Typography
                variant="caption"
                sx={{ color: "text.secondary", mt: 0.3, display: "block" }}
              >
                {subtitle}
              </Typography>
            )}
            {change !== undefined && change !== null && !loading && (
              <Box sx={{ display: "flex", alignItems: "center", mt: 0.5 }}>
                {change >= 0 ? (
                  <TrendingUpIcon
                    sx={{ fontSize: 14, color: "success.main", mr: 0.3 }}
                  />
                ) : (
                  <TrendingDownIcon
                    sx={{ fontSize: 14, color: "error.main", mr: 0.3 }}
                  />
                )}
                <Typography
                  variant="caption"
                  sx={{
                    color: change >= 0 ? "success.main" : "error.main",
                    fontWeight: 600,
                  }}
                >
                  {change >= 0 ? "+" : ""}
                  {Number(change).toFixed(1)}% vs mes anterior
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

/* ─── Main Component ───────────────────────────────────────── */

export default function CRMHome() {
  const router = useRouter();

  // State
  const [selectedPipeline, setSelectedPipeline] = useState<
    number | undefined
  >();
  const [dateRange, setDateRange] = useState("30d");
  const [chartTab, setChartTab] = useState(0);

  // Pipelines list
  const { data: pipelinesRaw } = usePipelinesList();
  const pipelines = useMemo(
    () => pipelinesRaw?.data ?? pipelinesRaw?.rows ?? pipelinesRaw ?? [],
    [pipelinesRaw],
  );

  const pipelineId = selectedPipeline ?? pipelines[0]?.PipelineId;
  const { dateFrom, dateTo } = useMemo(
    () => calcDateRange(dateRange),
    [dateRange],
  );

  // Analytics hooks
  const { data: kpis, isLoading: loadingKPIs } = useCRMKPIs(pipelineId);
  const { data: forecastRaw, isLoading: loadingForecast } =
    useCRMForecast(pipelineId);
  const { data: funnelRaw, isLoading: loadingFunnel } =
    useCRMFunnel(pipelineId);
  const { data: winLossPeriodRaw, isLoading: loadingWLP } =
    useCRMWinLossByPeriod(pipelineId, dateFrom, dateTo);
  const { data: winLossSourceRaw, isLoading: loadingWLS } =
    useCRMWinLossBySource(pipelineId);
  const { data: velocityRaw, isLoading: loadingVelocity } =
    useCRMVelocity(pipelineId);
  const { data: activityRaw, isLoading: loadingActivity } =
    useCRMActivityReport(pipelineId);

  // Normalize arrays (API may return { data: [...] } or [...])
  const forecast = Array.isArray(forecastRaw)
    ? forecastRaw
    : (forecastRaw as any)?.data ?? [];
  const funnel = Array.isArray(funnelRaw)
    ? funnelRaw
    : (funnelRaw as any)?.data ?? [];
  const winLossPeriod = Array.isArray(winLossPeriodRaw)
    ? winLossPeriodRaw
    : (winLossPeriodRaw as any)?.data ?? [];
  const winLossSource = Array.isArray(winLossSourceRaw)
    ? winLossSourceRaw
    : (winLossSourceRaw as any)?.data ?? [];
  const velocity = Array.isArray(velocityRaw)
    ? velocityRaw
    : (velocityRaw as any)?.data ?? [];
  const activityReport = Array.isArray(activityRaw)
    ? activityRaw
    : (activityRaw as any)?.data ?? [];

  // KPI derived values
  const leadsChange = kpis
    ? pctChange(kpis.NewLeadsThisMonth, kpis.NewLeadsLastMonth)
    : null;

  const kpiCards = [
    {
      title: "Leads Abiertos",
      value: String(kpis?.OpenCount ?? 0),
      subtitle: kpis ? formatCurrency(kpis.OpenValue) : undefined,
      icon: <PeopleIcon />,
      color: brandColors.shortcutDark,
      change: leadsChange,
    },
    {
      title: "Ganados",
      value: String(kpis?.WonCount ?? 0),
      subtitle: kpis ? formatCurrency(kpis.WonValue) : undefined,
      icon: <EmojiEventsIcon />,
      color: brandColors.success,
    },
    {
      title: "Perdidos",
      value: String(kpis?.LostCount ?? 0),
      subtitle: undefined,
      icon: <ThumbDownIcon />,
      color: brandColors.statRed,
    },
    {
      title: "Tasa Conversion",
      value: `${Number(kpis?.ConversionRate ?? 0).toFixed(1)}%`,
      subtitle: undefined,
      icon: <PercentIcon />,
      color: brandColors.shortcutViolet,
    },
    {
      title: "Ticket Promedio",
      value: formatCurrency(kpis?.AvgDealSize ?? 0),
      subtitle: undefined,
      icon: <AttachMoneyIcon />,
      color: brandColors.shortcutTeal,
    },
    {
      title: "Dias Cierre Prom",
      value: `${Number(kpis?.AvgDaysToClose ?? 0).toFixed(0)}d`,
      subtitle: undefined,
      icon: <TimerIcon />,
      color: brandColors.shortcutSlate,
    },
  ];

  // Chart tab rendering
  const chartContent = () => {
    switch (chartTab) {
      case 0:
        return loadingForecast ? (
          <Skeleton variant="rectangular" height={360} />
        ) : (
          <ForecastChart data={forecast} />
        );
      case 1:
        return loadingFunnel ? (
          <Skeleton variant="rectangular" height={360} />
        ) : (
          <FunnelChart data={funnel} />
        );
      case 2:
        return loadingWLP || loadingWLS ? (
          <Skeleton variant="rectangular" height={360} />
        ) : (
          <WinLossChart byPeriod={winLossPeriod} bySource={winLossSource} />
        );
      case 3:
        return loadingVelocity ? (
          <Skeleton variant="rectangular" height={360} />
        ) : (
          <VelocityChart data={velocity} />
        );
      case 4:
        return loadingActivity ? (
          <Skeleton variant="rectangular" height={360} />
        ) : (
          <ActivityReportChart data={activityReport} />
        );
      default:
        return null;
    }
  };

  return (
    <Box>
      {/* ─── HEADER ──────────────────────────────────────────── */}
      <Box
        sx={{
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
          gap: 2,
        }}
      >
        <Box sx={{ display: "flex", gap: 2, alignItems: "center" }}>
          {pipelines.length > 1 && (
            <FormControl size="small" sx={{ minWidth: 180 }}>
              <InputLabel>Pipeline</InputLabel>
              <Select
                value={pipelineId ?? ""}
                label="Pipeline"
                onChange={(e) =>
                  setSelectedPipeline(e.target.value as number)
                }
              >
                {pipelines.map((p: any) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>
                    {p.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          )}

          <ToggleButtonGroup
            value={dateRange}
            exclusive
            onChange={(_, v) => v && setDateRange(v)}
            size="small"
          >
            <ToggleButton value="7d">7d</ToggleButton>
            <ToggleButton value="30d">30d</ToggleButton>
            <ToggleButton value="90d">90d</ToggleButton>
            <ToggleButton value="YTD">YTD</ToggleButton>
          </ToggleButtonGroup>
        </Box>
      </Box>

      {/* ─── SHORTCUTS ───────────────────────────────────────── */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)", height: "100%", cursor: "pointer", transition: "transform 0.2s, box-shadow 0.2s", "&:hover": { transform: "translateY(-2px)", boxShadow: "0 4px 12px rgba(0,0,0,0.15)" } }} onClick={() => router.push(sc.href)}>
              <Box sx={(t) => ({ bgcolor: sc.bg, backgroundImage: t.palette.mode === 'dark' ? 'linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))' : 'none', color: "white", display: "flex", justifyContent: "center", py: 3 })}>
                {sc.icon}
              </Box>
              <CardContent sx={{ textAlign: "center", py: 2, flex: 1 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>{sc.title}</Typography>
                <Typography variant="body2" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}>{sc.description}</Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ─── STALE LEADS ALERT ──────────────────────────────── */}
      <StaleLeadsAlert pipelineId={pipelineId} days={7} maxDisplay={5} />

      {/* ─── KPI CARDS (6) ───────────────────────────────────── */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {kpiCards.map((kpi, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 4 }} key={idx}>
            <KPICard
              title={kpi.title}
              value={kpi.value}
              subtitle={kpi.subtitle}
              icon={kpi.icon}
              color={kpi.color}
              change={kpi.change}
              loading={loadingKPIs}
            />
          </Grid>
        ))}
      </Grid>

      {/* ─── CHART TABS ──────────────────────────────────────── */}
      <Paper sx={{ borderRadius: 2, mb: 3, overflow: "hidden" }}>
        <Tabs
          value={chartTab}
          onChange={(_, v) => setChartTab(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: "1px solid", borderColor: "divider", px: 1 }}
        >
          <Tab label="Forecast" />
          <Tab label="Embudo" />
          <Tab label="Ganados/Perdidos" />
          <Tab label="Velocidad" />
          <Tab label="Actividades" />
        </Tabs>
        <Box sx={{ p: 2 }}>{chartContent()}</Box>
      </Paper>

      {/* ─── QUICK STATS (Fila 3) ────────────────────────────── */}
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2.5 }}>
            <Box
              sx={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <Box>
                <Typography
                  variant="caption"
                  sx={{
                    color: "text.secondary",
                    fontWeight: 600,
                    textTransform: "uppercase",
                  }}
                >
                  Actividades pendientes
                </Typography>
                {loadingKPIs ? (
                  <Skeleton variant="text" width={60} height={32} />
                ) : (
                  <Typography variant="h4" sx={{ fontWeight: 700, mt: 0.5 }}>
                    {kpis?.ActivitiesPending ?? 0}
                  </Typography>
                )}
              </Box>
              <Badge
                badgeContent={kpis?.ActivitiesOverdue ?? 0}
                color="error"
                max={99}
              >
                <AssignmentLateIcon
                  sx={{ fontSize: 36, color: "text.secondary" }}
                />
              </Badge>
            </Box>
            {!loadingKPIs && (kpis?.ActivitiesOverdue ?? 0) > 0 && (
              <Chip
                label={`${kpis!.ActivitiesOverdue} vencidas`}
                size="small"
                color="error"
                variant="outlined"
                sx={{ mt: 1 }}
              />
            )}
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, sm: 6 }}>
          <Paper sx={{ borderRadius: 2, p: 2.5 }}>
            <Box
              sx={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <Box>
                <Typography
                  variant="caption"
                  sx={{
                    color: "text.secondary",
                    fontWeight: 600,
                    textTransform: "uppercase",
                  }}
                >
                  Leads nuevos este mes
                </Typography>
                {loadingKPIs ? (
                  <Skeleton variant="text" width={60} height={32} />
                ) : (
                  <Typography variant="h4" sx={{ fontWeight: 700, mt: 0.5 }}>
                    {kpis?.NewLeadsThisMonth ?? 0}
                  </Typography>
                )}
              </Box>
              <FiberNewIcon sx={{ fontSize: 36, color: "#1976d2" }} />
            </Box>
            {!loadingKPIs && kpis && (
              <Typography
                variant="caption"
                sx={{ color: "text.secondary", mt: 0.5, display: "block" }}
              >
                Mes anterior: {kpis.NewLeadsLastMonth}
                {leadsChange !== null && (
                  <Chip
                    label={`${leadsChange >= 0 ? "+" : ""}${Number(leadsChange).toFixed(0)}%`}
                    size="small"
                    color={leadsChange >= 0 ? "success" : "error"}
                    variant="outlined"
                    sx={{ ml: 1, height: 20, fontSize: "0.65rem" }}
                  />
                )}
              </Typography>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
