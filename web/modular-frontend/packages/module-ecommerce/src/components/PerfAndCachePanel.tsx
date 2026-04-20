"use client";

import { useState } from "react";
import {
  Box, Paper, Typography, Button, Chip, Stack, LinearProgress, Divider,
  Table, TableBody, TableCell, TableHead, TableRow, MenuItem, TextField, Alert,
} from "@mui/material";
import SpeedIcon from "@mui/icons-material/Speed";
import CachedIcon from "@mui/icons-material/Cached";
import RefreshIcon from "@mui/icons-material/Refresh";
import {
  usePerfAudit, useCacheStats, useInvalidateCache,
} from "../hooks/usePerfAndCache";

const CACHE_PREFIXES = [
  { value: "products:", label: "Productos (lista + detalle + recomendaciones)" },
  { value: "products:list", label: "Solo lista de productos" },
  { value: "products:detail", label: "Solo detalle de productos" },
  { value: "products:recs", label: "Solo recomendaciones" },
  { value: "categories:", label: "Categorías" },
  { value: "brands:", label: "Marcas" },
  { value: "search:", label: "Búsqueda full-text" },
  { value: "compare", label: "Comparador" },
  { value: "storefront:", label: "Storefront (países, monedas)" },
];

function rateColor(ms: number): "success" | "warning" | "error" {
  if (ms < 100) return "success";
  if (ms < 400) return "warning";
  return "error";
}

export default function PerfAndCachePanel() {
  const [auditEnabled, setAuditEnabled] = useState(false);
  const { data: report, isFetching, refetch } = usePerfAudit(auditEnabled);
  const { data: stats } = useCacheStats();
  const invalidate = useInvalidateCache();
  const [prefix, setPrefix] = useState(CACHE_PREFIXES[0].value);
  const [msg, setMsg] = useState<string>("");

  const runAudit = async () => {
    setAuditEnabled(true);
    await refetch();
  };

  const doInvalidate = async () => {
    try {
      const res = await invalidate.mutateAsync(prefix);
      setMsg(`Cache invalidado (${res?.removed ?? 0} entradas borradas con prefix "${prefix}")`);
    } catch (err) {
      setMsg(err instanceof Error ? err.message : String(err));
    }
  };

  const maxMs = report?.measurements.reduce((m, x) => Math.max(m, x.durationMs), 0) ?? 1;

  return (
    <Box>
      {/* Cache stats */}
      <Paper sx={{ p: 2.5, mb: 2 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 1.5 }}>
          <CachedIcon color="action" />
          <Typography variant="subtitle1" fontWeight={700}>Cache in-memory</Typography>
          {stats && (
            <Chip
              size="small"
              color={stats.active > 0 ? "success" : "default"}
              label={`${stats.active}/${stats.total} entradas activas`}
            />
          )}
        </Box>
        <Stack direction={{ xs: "column", sm: "row" }} spacing={2} alignItems={{ xs: "stretch", sm: "center" }}>
          <TextField
            select
            size="small"
            label="Prefix a invalidar"
            value={prefix}
            onChange={(e) => setPrefix(e.target.value)}
            sx={{ minWidth: 320 }}
          >
            {CACHE_PREFIXES.map((p) => (
              <MenuItem key={p.value} value={p.value}>
                <code>{p.value}</code> — {p.label}
              </MenuItem>
            ))}
          </TextField>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={doInvalidate}
            disabled={invalidate.isPending}
          >
            Invalidar cache
          </Button>
        </Stack>
        {msg && <Alert severity="info" sx={{ mt: 2 }} onClose={() => setMsg("")}>{msg}</Alert>}
      </Paper>

      {/* Performance audit */}
      <Paper sx={{ p: 2.5 }}>
        <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mb: 1.5 }}>
          <Typography variant="subtitle1" fontWeight={700}>Auditoría de latencia</Typography>
          <Button
            variant="contained"
            startIcon={<SpeedIcon />}
            onClick={runAudit}
            disabled={isFetching}
          >
            {isFetching ? "Midiendo…" : "Ejecutar audit"}
          </Button>
        </Box>

        {!report && !isFetching && (
          <Typography variant="body2" color="text.secondary">
            Ejecuta el audit para medir la latencia de los endpoints clave del storefront.
            Las mediciones se hacen contra la base de datos sin cache (cada llamada es fresca).
          </Typography>
        )}

        {isFetching && <LinearProgress sx={{ my: 2 }} />}

        {report && (
          <>
            <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
              <Chip label={`Total: ${report.totalMs}ms`} color="primary" />
              <Chip label={`Promedio: ${report.averageMs}ms`} color="default" />
              {report.worstCase && (
                <Chip
                  label={`Peor: ${report.worstCase.endpoint} (${report.worstCase.durationMs}ms)`}
                  color={rateColor(report.worstCase.durationMs)}
                />
              )}
            </Stack>

            <Divider sx={{ mb: 1 }} />

            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Endpoint</TableCell>
                  <TableCell>Descripción</TableCell>
                  <TableCell align="right">Filas</TableCell>
                  <TableCell align="right">Latencia</TableCell>
                  <TableCell>Velocidad</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {report.measurements.map((m) => (
                  <TableRow key={m.endpoint}>
                    <TableCell sx={{ fontFamily: "monospace", fontSize: 12 }}>{m.endpoint}</TableCell>
                    <TableCell>{m.description}</TableCell>
                    <TableCell align="right">{m.rowCount}</TableCell>
                    <TableCell align="right">
                      <strong>{m.durationMs}</strong> ms
                    </TableCell>
                    <TableCell sx={{ width: 200 }}>
                      <LinearProgress
                        variant="determinate"
                        value={Math.min(100, (m.durationMs / Math.max(maxMs, 1)) * 100)}
                        color={m.ok ? rateColor(m.durationMs) : "error"}
                      />
                      {!m.ok && (
                        <Typography variant="caption" color="error">{m.error}</Typography>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </>
        )}
      </Paper>
    </Box>
  );
}
