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
import { useBackoffice, apiFetch, type DashboardData } from "./context";

// ─── Dashboard Cards ──────────────────────────────────────────────────────────

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
    </Box>
  );
}
