"use client";

import { useState, useEffect, useCallback } from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  IconButton,
  LinearProgress,
  Alert,
  Tooltip,
  Stack,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Refresh as RefreshIcon,
  BugReport as BugIcon,
  Visibility as ViewIcon,
} from "@mui/icons-material";
import { apiGet } from "@zentto/shared-api";

export default function SoportePage() {
  const [state, setState] = useState<"open" | "closed">("open");
  const [tickets, setTickets] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiGet(`/v1/support/tickets?state=${state}&scope=all`);
      setTickets(res?.tickets || []);
      setStats(res?.stats || null);
    } catch { /* */ }
    setLoading(false);
  }, [state]);

  useEffect(() => { load(); }, [load]);

  const statCards = stats ? [
    { label: "Total", value: stats.total, color: "#1a73e8" },
    { label: "Bugs", value: stats.bugs, color: "#d32f2f" },
    { label: "Features", value: stats.features, color: "#1976d2" },
    { label: "Urgentes", value: stats.urgent, color: "#ff5722" },
    { label: "IA en progreso", value: stats.aiPending, color: "#ff9800" },
    { label: "IA resueltos", value: stats.aiFixed, color: "#2e7d32" },
  ] : [];

  return (
    <Box>
      <Stack direction="row" alignItems="center" gap={1} mb={2}>
        <BugIcon color="primary" />
        <Typography variant="h5" fontWeight={700}>
          Soporte
        </Typography>
      </Stack>

      {stats && (
        <Grid container spacing={1.5} sx={{ mb: 3 }}>
          {statCards.map((s) => (
            <Grid key={s.label} size={{ xs: 6, sm: 4, md: 2 }}>
              <Card>
                <CardContent sx={{ textAlign: "center", py: 1.5 }}>
                  <Typography variant="h4" fontWeight={700} sx={{ color: s.color }}>
                    {s.value}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {s.label}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      <Stack direction="row" spacing={1} sx={{ mb: 2 }}>
        <Button
          variant={state === "open" ? "contained" : "outlined"}
          size="small"
          onClick={() => setState("open")}
        >
          Abiertos
        </Button>
        <Button
          variant={state === "closed" ? "contained" : "outlined"}
          size="small"
          onClick={() => setState("closed")}
        >
          Cerrados
        </Button>
        <IconButton onClick={load} size="small">
          <RefreshIcon />
        </IconButton>
      </Stack>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      {!loading && tickets.length === 0 && (
        <Alert severity="info">No hay tickets {state === "open" ? "abiertos" : "cerrados"}</Alert>
      )}

      {tickets.map((t: any) => (
        <Card key={t.number} sx={{ mb: 1 }}>
          <CardContent sx={{ py: 1.5, "&:last-child": { pb: 1.5 } }}>
            <Stack direction="row" alignItems="center" spacing={1.5}>
              <Typography fontWeight={700} sx={{ minWidth: 50 }}>#{t.number}</Typography>
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography fontWeight={600} noWrap>{t.title}</Typography>
                <Typography variant="caption" color="text.secondary">
                  {t.company || "--"} -- {t.email || "--"} -- {t.module || "general"} -- {new Date(t.createdAt).toLocaleDateString("es")}
                </Typography>
              </Box>
              <Stack direction="row" spacing={0.5} flexWrap="wrap">
                {t.labels?.map((l: string) => (
                  <Chip
                    key={l}
                    label={l}
                    size="small"
                    color={
                      l === "bug" || l === "urgent" ? "error" :
                      l === "ai-fix" ? "warning" :
                      l === "ai-pr" ? "success" :
                      l === "feature" ? "info" : "default"
                    }
                    variant={l.startsWith("modulo:") ? "outlined" : "filled"}
                  />
                ))}
              </Stack>
              <Tooltip title="Ver en GitHub">
                <IconButton size="small" onClick={() => window.open(t.url, "_blank")}>
                  <ViewIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Stack>
          </CardContent>
        </Card>
      ))}
    </Box>
  );
}
