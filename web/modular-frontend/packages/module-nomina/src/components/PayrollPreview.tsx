"use client";

import React from "react";
import {
  Box, Paper, Typography, Chip, Alert, Stack, Divider, Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";
import PeopleIcon from "@mui/icons-material/People";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import PaymentIcon from "@mui/icons-material/Payment";
import { formatCurrency } from "@datqbox/shared-api";
import { brandColors } from "@datqbox/shared-ui";
import { useBatchSummary } from "../hooks/useNominaBatch";

interface Props {
  batchId: number;
}

function StatCard({
  title, value, icon, color, subtitle,
}: {
  title: string;
  value: string;
  icon: React.ReactNode;
  color: string;
  subtitle?: string;
}) {
  return (
    <Paper
      sx={{
        p: 2.5,
        borderRadius: 2,
        bgcolor: color,
        color: "#fff",
        position: "relative",
        overflow: "hidden",
      }}
    >
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <Box>
          <Typography variant="body2" sx={{ opacity: 0.85, mb: 0.5, fontWeight: 500 }}>
            {title}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1.2 }}>
            {value}
          </Typography>
          {subtitle && (
            <Typography variant="caption" sx={{ opacity: 0.7, mt: 0.5, display: "block" }}>
              {subtitle}
            </Typography>
          )}
        </Box>
        <Box sx={{ opacity: 0.3, fontSize: 48 }}>{icon}</Box>
      </Box>
    </Paper>
  );
}

function DeltaChip({ current, previous, label }: { current: number; previous?: number; label: string }) {
  if (!previous || previous === 0) return null;
  const delta = current - previous;
  const pct = ((delta / previous) * 100).toFixed(1);
  const isUp = delta > 0;
  return (
    <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 1 }}>
      <Typography variant="body2" color="text.secondary" sx={{ minWidth: 100 }}>
        {label}:
      </Typography>
      <Chip
        icon={isUp ? <TrendingUpIcon sx={{ fontSize: 14 }} /> : <TrendingDownIcon sx={{ fontSize: 14 }} />}
        label={`${isUp ? "+" : ""}${pct}% (${formatCurrency(Math.abs(delta))})`}
        size="small"
        color={isUp ? (label === "Deducciones" ? "error" : "success") : "default"}
        variant="outlined"
        sx={{ fontWeight: 600, fontSize: 11 }}
      />
    </Box>
  );
}

export default function PayrollPreview({ batchId }: Props) {
  const summary = useBatchSummary(batchId);
  const data = summary.data?.data ?? summary.data ?? null;

  if (summary.isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 2, mb: 2 }} />
        <Grid container spacing={2}>
          {[1, 2, 3, 4].map((i) => (
            <Grid key={i} size={{ xs: 12, md: 3 }}>
              <Skeleton variant="rectangular" height={100} sx={{ borderRadius: 2 }} />
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  if (!data) {
    return (
      <Alert severity="warning">No se encontró información del lote</Alert>
    );
  }

  const totalGross = Number(data.totalGross ?? 0);
  const totalDeductions = Number(data.totalDeductions ?? 0);
  const totalNet = Number(data.totalNet ?? 0);
  const totalEmployees = Number(data.totalEmployees ?? 0);
  const alertCount = Number(data.alertCount ?? 0);
  const status = data.status ?? "BORRADOR";

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
      {/* Status Banner */}
      <Paper sx={{ p: 2, borderRadius: 2, display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 1 }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <Typography variant="h6" sx={{ fontWeight: 700 }}>
            Pre-Nómina
          </Typography>
          <Chip
            label={status}
            color={status === "BORRADOR" ? "warning" : status === "APROBADA" ? "success" : "default"}
            size="small"
            sx={{ fontWeight: 600 }}
          />
          <Typography variant="body2" color="text.secondary">
            {data.payrollCode} | {data.fromDate} — {data.toDate}
          </Typography>
        </Box>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          {alertCount > 0 ? (
            <Chip
              icon={<WarningAmberIcon />}
              label={`${alertCount} alerta${alertCount > 1 ? "s" : ""}`}
              color="error"
              size="small"
              variant="outlined"
            />
          ) : (
            <Chip
              icon={<CheckCircleOutlineIcon />}
              label="Sin alertas"
              color="success"
              size="small"
              variant="outlined"
            />
          )}
        </Box>
      </Paper>

      {/* Main Stats */}
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Empleados"
            value={String(totalEmployees)}
            icon={<PeopleIcon sx={{ fontSize: 48 }} />}
            color={brandColors.statTeal}
            subtitle="en este lote"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Total Bruto"
            value={formatCurrency(totalGross)}
            icon={<AccountBalanceWalletIcon sx={{ fontSize: 48 }} />}
            color={brandColors.statBlue}
            subtitle="asignaciones"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Deducciones"
            value={formatCurrency(totalDeductions)}
            icon={<RemoveCircleOutlineIcon sx={{ fontSize: 48 }} />}
            color={brandColors.statRed}
            subtitle="retenciones"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatCard
            title="Neto a Pagar"
            value={formatCurrency(totalNet)}
            icon={<PaymentIcon sx={{ fontSize: 48 }} />}
            color={brandColors.accent}
            subtitle="total transferir"
          />
        </Grid>
      </Grid>

      {/* Comparison with previous period */}
      {(data.prevGross || data.prevDeductions || data.prevNet) && (
        <Paper sx={{ p: 2.5, borderRadius: 2 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
            Comparación con Período Anterior
          </Typography>
          <DeltaChip current={totalGross} previous={data.prevGross} label="Bruto" />
          <DeltaChip current={totalDeductions} previous={data.prevDeductions} label="Deducciones" />
          <DeltaChip current={totalNet} previous={data.prevNet} label="Neto" />
        </Paper>
      )}

      {/* Summary Breakdown */}
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ p: 2.5, borderRadius: 2, height: "100%" }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
              Desglose
            </Typography>
            <Stack spacing={1.5}>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Total Asignaciones</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600, color: brandColors.success }}>
                  {formatCurrency(totalGross)}
                </Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Total Deducciones</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600, color: brandColors.danger }}>
                  - {formatCurrency(totalDeductions)}
                </Typography>
              </Box>
              <Divider />
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body1" sx={{ fontWeight: 700 }}>Neto a Pagar</Typography>
                <Typography variant="body1" sx={{ fontWeight: 700 }}>
                  {formatCurrency(totalNet)}
                </Typography>
              </Box>
              <Divider />
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Promedio por empleado</Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {totalEmployees > 0 ? formatCurrency(totalNet / totalEmployees) : "—"}
                </Typography>
              </Box>
            </Stack>
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ p: 2.5, borderRadius: 2, height: "100%" }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
              Información del Lote
            </Typography>
            <Stack spacing={1.5}>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Lote #</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{batchId}</Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Tipo de Nómina</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>{data.payrollCode}</Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Período</Typography>
                <Typography variant="body2">{data.fromDate} — {data.toDate}</Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Creado por</Typography>
                <Typography variant="body2">{data.createdBy ?? "—"}</Typography>
              </Box>
              <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                <Typography variant="body2" color="text.secondary">Fecha creación</Typography>
                <Typography variant="body2">{data.createdAt ?? "—"}</Typography>
              </Box>
              {data.approvedBy && (
                <Box sx={{ display: "flex", justifyContent: "space-between" }}>
                  <Typography variant="body2" color="text.secondary">Aprobado por</Typography>
                  <Typography variant="body2">{data.approvedBy}</Typography>
                </Box>
              )}
            </Stack>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
