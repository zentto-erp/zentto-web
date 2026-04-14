"use client";

import { Box, Typography, Paper, Grid2 as Grid, Button, CircularProgress, Chip } from "@mui/material";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import InventoryIcon from "@mui/icons-material/Inventory";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import WarningIcon from "@mui/icons-material/Warning";
import GavelIcon from "@mui/icons-material/Gavel";
import ErrorIcon from "@mui/icons-material/Error";
import AddBoxIcon from "@mui/icons-material/AddBox";
import { useShippingDashboard, useShipmentsList } from "../hooks/useShipping";

interface Props {
  onNavigate: (path: string) => void;
}

export default function ShippingDashboard({ onNavigate }: Props) {
  const { data: dashboard, isLoading } = useShippingDashboard();
  const { data: recentData } = useShipmentsList({ page: 1, limit: 5 });

  if (isLoading) {
    return <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}><CircularProgress /></Box>;
  }

  const kpis = [
    { label: "Total Envíos", value: dashboard?.TotalShipments || 0, icon: <InventoryIcon />, color: "#1565c0" },
    { label: "En Tránsito", value: dashboard?.InTransitCount || 0, icon: <LocalShippingIcon />, color: "#f57c00" },
    { label: "Entregados", value: dashboard?.DeliveredCount || 0, icon: <CheckCircleIcon />, color: "#2e7d32" },
    { label: "En Aduana", value: dashboard?.InCustomsCount || 0, icon: <GavelIcon />, color: "#7b1fa2" },
    { label: "Incidencias", value: dashboard?.ExceptionCount || 0, icon: <ErrorIcon />, color: "#d32f2f" },
    { label: "Gasto Total", value: `$${(dashboard?.TotalSpent || 0).toFixed(2)}`, icon: <WarningIcon />, color: "#455a64" },
  ];

  const recent = recentData?.rows || [];

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "flex-end", alignItems: "center", mb: 3 }}>
        <Button variant="contained" startIcon={<AddBoxIcon />} onClick={() => onNavigate("/envios/nuevo")}
          sx={{ bgcolor: "#1565c0" }}>
          Nuevo Envío
        </Button>
      </Box>

      {/* KPI Cards */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {kpis.map((kpi) => (
          <Grid key={kpi.label} size={{ xs: 6, sm: 4, md: 2 }}>
            <Paper sx={{ p: 2, textAlign: "center", borderRadius: 2, borderTop: `3px solid ${kpi.color}` }}>
              <Box sx={{ color: kpi.color, mb: 0.5 }}>{kpi.icon}</Box>
              <Typography variant="h5" fontWeight={800}>{kpi.value}</Typography>
              <Typography variant="caption" color="text.secondary">{kpi.label}</Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

      {/* Quick Actions */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {[
          { label: "Crear Envío", path: "/envios/nuevo", color: "#1565c0" },
          { label: "Mis Envíos", path: "/envios", color: "#f57c00" },
          { label: "Rastrear Paquete", path: "/rastreo", color: "#2e7d32" },
          { label: "Mis Direcciones", path: "/perfil", color: "#7b1fa2" },
        ].map((action) => (
          <Grid key={action.label} size={{ xs: 6, sm: 3 }}>
            <Paper
              onClick={() => onNavigate(action.path)}
              sx={{
                p: 2, textAlign: "center", cursor: "pointer", borderRadius: 2,
                border: `2px solid ${action.color}20`,
                "&:hover": { bgcolor: `${action.color}08`, borderColor: action.color },
                transition: "all 0.2s",
              }}
            >
              <Typography variant="subtitle2" fontWeight={700} sx={{ color: action.color }}>
                {action.label}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

      {/* Recent Shipments */}
      <Paper sx={{ p: 3, borderRadius: 2 }}>
        <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>Últimos Envíos</Typography>
        {recent.length === 0 ? (
          <Box sx={{ textAlign: "center", py: 4 }}>
            <LocalShippingIcon sx={{ fontSize: 48, color: "#ccc", mb: 1 }} />
            <Typography color="text.secondary">No tienes envíos aún</Typography>
            <Button variant="contained" size="small" sx={{ mt: 2, bgcolor: "#1565c0" }} onClick={() => onNavigate("/envios/nuevo")}>
              Crear primer envío
            </Button>
          </Box>
        ) : (
          recent.map((s: any) => (
            <Paper
              key={s.ShipmentId}
              variant="outlined"
              onClick={() => onNavigate(`/envios/${s.ShipmentId}`)}
              sx={{ p: 2, mb: 1, cursor: "pointer", "&:hover": { bgcolor: "#f5f5f5" }, borderRadius: 1 }}
            >
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 1 }}>
                <Box>
                  <Typography variant="subtitle2" fontWeight={700}>{s.ShipmentNumber}</Typography>
                  <Typography variant="caption" color="text.secondary">
                    {s.OriginCity} → {s.DestCity} · {s.DestContactName}
                  </Typography>
                </Box>
                <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
                  {s.CarrierCode && <Chip label={s.CarrierCode} size="small" variant="outlined" />}
                  <StatusChip status={s.Status} />
                </Box>
              </Box>
            </Paper>
          ))
        )}
      </Paper>
    </Box>
  );
}

function StatusChip({ status }: { status: string }) {
  const map: Record<string, { label: string; color: any }> = {
    DRAFT: { label: "Borrador", color: "default" },
    QUOTED: { label: "Cotizado", color: "info" },
    LABEL_READY: { label: "Guía lista", color: "info" },
    PICKED_UP: { label: "Recogido", color: "warning" },
    IN_TRANSIT: { label: "En tránsito", color: "warning" },
    IN_CUSTOMS: { label: "En aduana", color: "secondary" },
    CUSTOMS_HELD: { label: "Retenido", color: "error" },
    CUSTOMS_CLEARED: { label: "Liberado", color: "success" },
    OUT_FOR_DELIVERY: { label: "En camino", color: "warning" },
    DELIVERED: { label: "Entregado", color: "success" },
    RETURNED: { label: "Devuelto", color: "error" },
    EXCEPTION: { label: "Incidencia", color: "error" },
    CANCELLED: { label: "Cancelado", color: "default" },
  };
  const m = map[status] || { label: status, color: "default" };
  return <Chip label={m.label} size="small" color={m.color} />;
}

export { StatusChip };
