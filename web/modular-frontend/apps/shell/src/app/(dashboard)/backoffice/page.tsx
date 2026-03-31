"use client";

import { useState, useEffect, useCallback } from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  IconButton,
  LinearProgress,
  Tooltip,
  Stack,
  Paper,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Refresh as RefreshIcon,
  Storage as StorageIcon,
  People as PeopleIcon,
  AttachMoney as MoneyIcon,
  Warning as WarningIcon,
  BugReport as BugIcon,
  SmartToy as SmartToyIcon,
} from "@mui/icons-material";
import { BarChart } from "@mui/x-charts/BarChart";
import { PieChart } from "@mui/x-charts/PieChart";
import { useBackoffice, apiFetch, type DashboardData, type TenantRow } from "./context";

// ─── Types ───────────────────────────────────────────────────────────────────

interface KafkaTopicMetrics {
  topic: string;
  count: number;
  label: string;
  color: string;
}

// ─── Kafka topics config ─────────────────────────────────────────────────────

const KAFKA_TOPICS: KafkaTopicMetrics[] = [
  { topic: "zentto.logs", count: 0, label: "Logs", color: "#1976d2" },
  { topic: "zentto.errors", count: 0, label: "Errors", color: "#d32f2f" },
  { topic: "zentto.audit", count: 0, label: "Audit", color: "#ed6c02" },
  { topic: "zentto.performance", count: 0, label: "Performance", color: "#2e7d32" },
  { topic: "zentto.events", count: 0, label: "Events", color: "#9c27b0" },
  { topic: "zentto-notifications", count: 0, label: "Notifications", color: "#0288d1" },
];

// ─── Dashboard Cards ─────────────────────────────────────────────────────────

function DashboardCards({
  data,
  loading,
}: {
  data: DashboardData | null;
  loading: boolean;
}) {
  const cards = [
    {
      label: "Total Tenants",
      value: data?.TotalTenants ?? "--",
      icon: <PeopleIcon fontSize="large" color="primary" />,
    },
    {
      label: "MRR Estimado",
      value: data ? `$${(Number(data.MRR) || 0).toLocaleString("es-VE")}` : "--",
      icon: <MoneyIcon fontSize="large" color="success" />,
    },
    {
      label: "BD Total (MB)",
      value: data ? `${Number(data.TotalDbMB).toFixed(1)} MB` : "--",
      icon: <StorageIcon fontSize="large" color="info" />,
    },
    {
      label: "Cola Pendiente",
      value: data?.CleanupPending ?? "--",
      icon: <WarningIcon fontSize="large" color="warning" />,
    },
    {
      label: "Tickets Abiertos",
      value: data?.TicketsOpen ?? "--",
      icon: <BugIcon fontSize="large" color="error" />,
    },
    {
      label: "IA Resueltos",
      value: data?.TicketsAiResolved ?? "--",
      icon: <SmartToyIcon fontSize="large" color="success" />,
    },
  ];

  return (
    <Grid container spacing={2} mb={3}>
      {cards.map((c) => (
        <Grid key={c.label} size={{ xs: 6, sm: 4, md: 2 }}>
          <Card variant="outlined">
            <CardContent>
              <Stack
                direction="row"
                justifyContent="space-between"
                alignItems="center"
              >
                <Box>
                  <Typography variant="caption" color="text.secondary">
                    {c.label}
                  </Typography>
                  {loading ? (
                    <LinearProgress sx={{ mt: 1, width: 80 }} />
                  ) : (
                    <Typography variant="h5" fontWeight={700}>
                      {c.value}
                    </Typography>
                  )}
                </Box>
                {c.icon}
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}

// ─── Kafka Topics Chart ──────────────────────────────────────────────────────

function KafkaTopicsChart({ token }: { token: string }) {
  const [metrics, setMetrics] = useState<KafkaTopicMetrics[]>(KAFKA_TOPICS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        const res = await apiFetch<{ ok: boolean; data: { topic: string; messageCount: number }[] }>(
          "/v1/backoffice/kafka/topics",
          token
        );
        if (res.data) {
          setMetrics(
            KAFKA_TOPICS.map((t) => {
              const found = res.data.find((d) => d.topic === t.topic);
              return { ...t, count: found?.messageCount ?? 0 };
            })
          );
        }
      } catch {
        // Kafka no disponible — mostrar zeros
        setMetrics(KAFKA_TOPICS);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token]);

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Typography variant="h6" fontWeight={600} mb={1}>
        Kafka — Tópicos (mensajes/hora)
      </Typography>
      {loading ? (
        <LinearProgress />
      ) : (
        <BarChart
          xAxis={[{ scaleType: "band", data: metrics.map((m) => m.label) }]}
          series={[
            {
              data: metrics.map((m) => m.count),
              color: "#1976d2",
              label: "Mensajes",
            },
          ]}
          height={280}
          slotProps={{ legend: { hidden: true } }}
        />
      )}
    </Paper>
  );
}

// ─── Tenants por Plan (Pie) ──────────────────────────────────────────────────

function TenantsByPlanChart({ token }: { token: string }) {
  const [data, setData] = useState<{ id: number; value: number; label: string; color: string }[]>([]);
  const [loading, setLoading] = useState(true);

  const PLAN_COLORS: Record<string, string> = {
    FREE: "#90a4ae",
    STARTER: "#42a5f5",
    PRO: "#66bb6a",
    ENTERPRISE: "#ffa726",
  };

  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        const res = await apiFetch<{ ok: boolean; data: TenantRow[] }>(
          "/v1/backoffice/tenants?page=1&limit=500",
          token
        );
        const rows = res.data ?? [];
        const planCounts: Record<string, number> = {};
        rows.forEach((t) => {
          const plan = t.Plan || "FREE";
          planCounts[plan] = (planCounts[plan] || 0) + 1;
        });
        setData(
          Object.entries(planCounts).map(([plan, count], i) => ({
            id: i,
            value: count,
            label: plan,
            color: PLAN_COLORS[plan] || "#bdbdbd",
          }))
        );
      } catch {
        setData([]);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [token]);

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Typography variant="h6" fontWeight={600} mb={1}>
        Tenants por Plan
      </Typography>
      {loading ? (
        <LinearProgress />
      ) : data.length > 0 ? (
        <PieChart
          series={[
            {
              data,
              highlightScope: { fade: "global", highlight: "item" },
              innerRadius: 40,
              paddingAngle: 2,
              cornerRadius: 4,
            },
          ]}
          height={280}
        />
      ) : (
        <Typography color="text.secondary" py={4} textAlign="center">
          Sin datos de tenants
        </Typography>
      )}
    </Paper>
  );
}

// ─── Tickets Chart ───────────────────────────────────────────────────────────

function TicketsChart({ data }: { data: DashboardData | null }) {
  if (!data) return null;

  const ticketData = [
    { label: "Abiertos", value: data.TicketsOpen ?? 0 },
    { label: "Cerrados", value: data.TicketsClosed ?? 0 },
    { label: "Urgentes", value: data.TicketsUrgent ?? 0 },
    { label: "IA Pendiente", value: data.TicketsAiPending ?? 0 },
    { label: "IA Resueltos", value: data.TicketsAiResolved ?? 0 },
  ];

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Typography variant="h6" fontWeight={600} mb={1}>
        Tickets de Soporte
      </Typography>
      <BarChart
        xAxis={[{ scaleType: "band", data: ticketData.map((d) => d.label) }]}
        series={[
          {
            data: ticketData.map((d) => d.value),
            label: "Tickets",
            color: "#ef5350",
          },
        ]}
        height={280}
        slotProps={{ legend: { hidden: true } }}
      />
    </Paper>
  );
}

// ─── Pagina principal del Dashboard ──────────────────────────────────────────

export default function BackofficeDashboardPage() {
  const { token, isSet, clear } = useBackoffice();
  const [dashboard, setDashboard] = useState<DashboardData | null>(null);
  const [dashLoading, setDashLoading] = useState(false);

  const loadDashboard = useCallback(async () => {
    if (!isSet) return;
    setDashLoading(true);
    try {
      const res = await apiFetch<{ ok: boolean; data: DashboardData }>(
        "/v1/backoffice/dashboard",
        token
      );
      setDashboard(res.data);
    } catch (e: unknown) {
      if (e instanceof Error && e.message.startsWith("401")) {
        clear();
      }
    } finally {
      setDashLoading(false);
    }
  }, [isSet, token, clear]);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  return (
    <Box>
      <Stack direction="row" alignItems="center" gap={1} mb={3}>
        <StorageIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Dashboard
        </Typography>
        <Chip label="SYSADMIN" size="small" color="warning" sx={{ ml: 1 }} />
        <Box flex={1} />
        <Tooltip title="Refrescar dashboard">
          <IconButton onClick={loadDashboard} disabled={dashLoading}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Stack>

      <DashboardCards data={dashboard} loading={dashLoading} />

      <Grid container spacing={3} mb={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <KafkaTopicsChart token={token} />
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <TenantsByPlanChart token={token} />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <TicketsChart data={dashboard} />
        </Grid>
      </Grid>
    </Box>
  );
}
