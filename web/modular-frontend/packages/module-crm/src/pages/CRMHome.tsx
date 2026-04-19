"use client";

import React, { useState, useMemo } from "react";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Card,
  CardContent,
  Typography,
  Skeleton,
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
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
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
import RocketLaunchIcon from "@mui/icons-material/RocketLaunch";
import NotificationsActiveIcon from "@mui/icons-material/NotificationsActive";
import InsightsIcon from "@mui/icons-material/Insights";
import ShowChartIcon from "@mui/icons-material/ShowChart";
import QueryStatsIcon from "@mui/icons-material/QueryStats";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors, DashboardShortcutCard, DashboardKpiCard } from "@zentto/shared-ui";
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

/* ─── Accordion keys & defaults ────────────────────────────── */

type AccordionKey = "shortcuts" | "alerts" | "kpis" | "trends" | "stats";

const DEFAULT_EXPANDED: Record<AccordionKey, boolean> = {
  shortcuts: true,
  alerts: true,
  kpis: true,
  trends: false,
  stats: false,
};

/* ─── Main Component ───────────────────────────────────────── */

export default function CRMHome() {
  const router = useRouter();

  // Accordion state (local; la persistencia se añade en un commit posterior).
  const [expanded, setExpanded] =
    useState<Record<AccordionKey, boolean>>(DEFAULT_EXPANDED);

  const setAccordion = (key: AccordionKey, value: boolean) =>
    setExpanded((prev) => ({ ...prev, [key]: value }));

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
    {
      title: "Perdidos",
      value: String(kpis?.LostCount ?? 0),
      subtitle: undefined,
      icon: <ThumbDownIcon />,
      color: brandColors.statRed,
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

  // Métricas auxiliares para chips en summaries.
  const overdueActivities = kpis?.ActivitiesOverdue ?? 0;
  const hasOverdue = !loadingKPIs && overdueActivities > 0;
  const newLeadsCount = kpis?.NewLeadsThisMonth ?? 0;

  // Estilos comunes del acordeón — foco visible y sin sombra extra.
  const accordionSx = {
    mb: 2,
    borderRadius: 2,
    "&:before": { display: "none" },
    boxShadow: "0 1px 3px rgba(0,0,0,0.06)",
    "&.Mui-expanded": { mb: 2 },
    "& .MuiAccordionSummary-root.Mui-focusVisible": {
      outline: `2px solid ${alpha(brandColors.shortcutDark, 0.6)}`,
      outlineOffset: 2,
    },
  } as const;

  const summaryTitleSx = {
    display: "flex",
    alignItems: "center",
    gap: 1,
    flex: 1,
  } as const;

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
      <Accordion
        expanded={!!expanded.shortcuts}
        onChange={(_, v) => setAccordion("shortcuts", v)}
        disableGutters
        sx={accordionSx}
        role="region"
        aria-label="Accesos rápidos"
      >
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="crm-home-shortcuts-content"
          id="crm-home-shortcuts-header"
        >
          <Box sx={summaryTitleSx}>
            <RocketLaunchIcon color="primary" />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Accesos rápidos
            </Typography>
            <Chip
              label={shortcuts.length}
              size="small"
              sx={{ ml: 1, height: 20, fontSize: "0.7rem" }}
            />
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Grid container spacing={3}>
            {shortcuts.map((sc, idx) => (
              <Grid size={{ xs: 12, sm: 6, md: 4 }} key={idx}>
                <DashboardShortcutCard
                  title={sc.title}
                  description={sc.description}
                  icon={sc.icon}
                  href={sc.href}
                  color={sc.bg}
                />
              </Grid>
            ))}
          </Grid>
        </AccordionDetails>
      </Accordion>

      {/* ─── STALE LEADS ALERT ──────────────────────────────── */}
      <Accordion
        expanded={!!expanded.alerts}
        onChange={(_, v) => setAccordion("alerts", v)}
        disableGutters
        sx={accordionSx}
        role="region"
        aria-label="Alertas de leads"
      >
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="crm-home-alerts-content"
          id="crm-home-alerts-header"
        >
          <Box sx={summaryTitleSx}>
            <NotificationsActiveIcon color="warning" />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Alertas
            </Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <StaleLeadsAlert pipelineId={pipelineId} days={7} maxDisplay={5} />
        </AccordionDetails>
      </Accordion>

      {/* ─── KPI CARDS (6) ───────────────────────────────────── */}
      <Accordion
        expanded={!!expanded.kpis}
        onChange={(_, v) => setAccordion("kpis", v)}
        disableGutters
        sx={accordionSx}
        role="region"
        aria-label="Indicadores KPI"
      >
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="crm-home-kpis-content"
          id="crm-home-kpis-header"
        >
          <Box sx={summaryTitleSx}>
            <InsightsIcon color="primary" />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              KPIs
            </Typography>
            <Chip
              label={kpiCards.length}
              size="small"
              sx={{ ml: 1, height: 20, fontSize: "0.7rem" }}
            />
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Grid container spacing={2}>
            {kpiCards.map((kpi, idx) => (
              <Grid size={{ xs: 12, sm: 6, md: 4 }} key={idx}>
                <DashboardKpiCard
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
        </AccordionDetails>
      </Accordion>

      {/* ─── CHART TABS (TENDENCIAS) ─────────────────────────── */}
      <Accordion
        expanded={!!expanded.trends}
        onChange={(_, v) => setAccordion("trends", v)}
        disableGutters
        sx={accordionSx}
        role="region"
        aria-label="Tendencias y gráficos"
        TransitionProps={{ unmountOnExit: true }}
      >
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="crm-home-trends-content"
          id="crm-home-trends-header"
        >
          <Box sx={summaryTitleSx}>
            <ShowChartIcon color="primary" />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Tendencias
            </Typography>
            <Typography
              variant="caption"
              sx={{ color: "text.secondary", ml: 1 }}
            >
              Forecast · Embudo · Ganados/Perdidos · Velocidad · Actividades
            </Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails sx={{ p: 0 }}>
          <Paper
            sx={{
              borderRadius: 2,
              overflow: "hidden",
              boxShadow: "none",
            }}
          >
            <Tabs
              value={chartTab}
              onChange={(_, v) => setChartTab(v)}
              variant="scrollable"
              scrollButtons="auto"
              sx={{
                borderBottom: "1px solid",
                borderColor: "divider",
                px: 1,
              }}
            >
              <Tab label="Forecast" />
              <Tab label="Embudo" />
              <Tab label="Ganados/Perdidos" />
              <Tab label="Velocidad" />
              <Tab label="Actividades" />
            </Tabs>
            <Box sx={{ p: 2 }}>{chartContent()}</Box>
          </Paper>
        </AccordionDetails>
      </Accordion>

      {/* ─── QUICK STATS ─────────────────────────────────────── */}
      <Accordion
        expanded={!!expanded.stats}
        onChange={(_, v) => setAccordion("stats", v)}
        disableGutters
        sx={accordionSx}
        role="region"
        aria-label="Estadísticas rápidas"
      >
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="crm-home-stats-content"
          id="crm-home-stats-header"
        >
          <Box sx={summaryTitleSx}>
            <QueryStatsIcon color="primary" />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Quick Stats
            </Typography>
            {hasOverdue && (
              <Chip
                label={`${overdueActivities} vencidas`}
                size="small"
                color="error"
                variant="outlined"
                sx={{ ml: 1, height: 20, fontSize: "0.65rem" }}
              />
            )}
            {!loadingKPIs && newLeadsCount > 0 && (
              <Chip
                label={`${newLeadsCount} nuevos`}
                size="small"
                color="info"
                variant="outlined"
                sx={{ ml: 1, height: 20, fontSize: "0.65rem" }}
              />
            )}
          </Box>
        </AccordionSummary>
        <AccordionDetails>
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
                      <Typography
                        variant="h4"
                        sx={{ fontWeight: 700, mt: 0.5 }}
                      >
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
                {hasOverdue && (
                  <Chip
                    label={`${overdueActivities} vencidas`}
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
                      <Typography
                        variant="h4"
                        sx={{ fontWeight: 700, mt: 0.5 }}
                      >
                        {kpis?.NewLeadsThisMonth ?? 0}
                      </Typography>
                    )}
                  </Box>
                  <FiberNewIcon sx={{ fontSize: 36, color: "#1976d2" }} />
                </Box>
                {!loadingKPIs && kpis && (
                  <Typography
                    variant="caption"
                    sx={{
                      color: "text.secondary",
                      mt: 0.5,
                      display: "block",
                    }}
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
        </AccordionDetails>
      </Accordion>
    </Box>
  );
}
