"use client";

import { Box, Paper, Typography, Stack, Skeleton, Chip } from "@mui/material";
import Grid from "@mui/material/Grid2";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import PaymentsIcon from "@mui/icons-material/Payments";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import HomeIcon from "@mui/icons-material/Home";
import CancelIcon from "@mui/icons-material/Cancel";
import AssignmentReturnIcon from "@mui/icons-material/AssignmentReturn";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import { useAdminMetrics } from "../hooks/useAdminEcommerce";

interface MetricCardProps {
  label: string;
  value: string | number;
  icon: React.ReactNode;
  color?: string;
  hint?: string;
}

function MetricCard({ label, value, icon, color = "#0072c6", hint }: MetricCardProps) {
  return (
    <Paper sx={{ p: 2.5, display: "flex", alignItems: "center", gap: 2, borderRadius: 2 }}>
      <Box
        sx={{
          width: 48, height: 48, borderRadius: "12px",
          bgcolor: `${color}15`, color, display: "flex",
          alignItems: "center", justifyContent: "center", flexShrink: 0,
        }}
      >
        {icon}
      </Box>
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Typography variant="caption" color="text.secondary" sx={{ display: "block", lineHeight: 1.2 }}>
          {label}
        </Typography>
        <Typography variant="h5" fontWeight={700} sx={{ lineHeight: 1.2 }}>
          {value}
        </Typography>
        {hint && (
          <Typography variant="caption" color="text.secondary">
            {hint}
          </Typography>
        )}
      </Box>
    </Paper>
  );
}

const fmtUsd = (n: number) =>
  Number(n).toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

export default function AdminEcommerceDashboard() {
  const { data: m, isLoading } = useAdminMetrics();

  if (isLoading || !m) {
    return (
      <Grid container spacing={2}>
        {Array.from({ length: 8 }).map((_, i) => (
          <Grid key={i} size={{ xs: 12, sm: 6, md: 3 }}>
            <Skeleton variant="rectangular" height={92} sx={{ borderRadius: 2 }} />
          </Grid>
        ))}
      </Grid>
    );
  }

  const conversion = m.totalOrders > 0 ? Math.round((m.paidOrders / m.totalOrders) * 100) : 0;

  return (
    <Box>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 2 }}>
        <Chip size="small" label="Últimos 30 días" />
      </Box>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Pedidos totales"
            value={m.totalOrders}
            icon={<ReceiptLongIcon />}
            color="#0072c6"
            hint={`${conversion}% pagados`}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Pendientes de pago"
            value={m.pendingOrders}
            icon={<PaymentsIcon />}
            color="#b12704"
            hint="Acción requerida"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Pagados / por enviar"
            value={m.paidOrders - m.shippedOrders - m.deliveredOrders}
            icon={<PaymentsIcon />}
            color="#067D62"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="En tránsito"
            value={m.shippedOrders}
            icon={<LocalShippingIcon />}
            color="#ff9900"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Entregados"
            value={m.deliveredOrders}
            icon={<HomeIcon />}
            color="#067D62"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Cancelados"
            value={m.cancelledOrders}
            icon={<CancelIcon />}
            color="#cc0c39"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Devoluciones activas"
            value={m.pendingReturns}
            icon={<AssignmentReturnIcon />}
            color="#9b54e6"
            hint={m.pendingReturns > 0 ? "Revisar workflow" : "Sin pendientes"}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <MetricCard
            label="Ingreso (USD eq.)"
            value={fmtUsd(m.totalRevenueUsd)}
            icon={<TrendingUpIcon />}
            color="#00a884"
            hint={`Ticket promedio ${fmtUsd(m.avgTicketUsd)}`}
          />
        </Grid>
      </Grid>
    </Box>
  );
}
