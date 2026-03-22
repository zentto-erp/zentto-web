"use client";

import React from "react";
import {
  Box,
  Card,
  CardActionArea,
  CardContent,
  IconButton,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Chip,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import DirectionsCarIcon from "@mui/icons-material/DirectionsCar";
import LocalGasStationIcon from "@mui/icons-material/LocalGasStation";
import BuildIcon from "@mui/icons-material/Build";
import RouteIcon from "@mui/icons-material/Route";
import SpeedIcon from "@mui/icons-material/Speed";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { useFlotaDashboard, useVehiclesList, useTripsList } from "../hooks/useFlota";
import { brandColors } from "@zentto/shared-ui";

const vehicleStatusLabels: Record<string, string> = {
  ACTIVE: "Activo",
  MAINTENANCE: "Mantenimiento",
  INACTIVE: "Inactivo",
};

const vehicleStatusColors: Record<string, "success" | "warning" | "default"> = {
  ACTIVE: "success",
  MAINTENANCE: "warning",
  INACTIVE: "default",
};

const tripStatusLabels: Record<string, string> = {
  PLANNED: "Planificado",
  IN_TRANSIT: "En Transito",
  COMPLETED: "Completado",
};

const tripStatusColors: Record<string, "info" | "warning" | "success" | "default"> = {
  PLANNED: "info",
  IN_TRANSIT: "warning",
  COMPLETED: "success",
};

export default function FlotaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const { data: dashboard, isLoading: dashLoading } = useFlotaDashboard();
  const { data: lastVehicles } = useVehiclesList({ limit: 5 });
  const { data: lastTrips } = useTripsList({ limit: 5 });

  const statsCards = [
    {
      title: "Vehiculos Activos",
      value: dashboard ? String(dashboard.VehiculosActivos) : "\u2014",
      subtitle: "En operacion",
      loading: dashLoading,
      color: brandColors.statBlue,
      chartType: "bar" as const,
    },
    {
      title: "Km Total Mes",
      value: dashboard ? Number(dashboard.KmTotalMes).toLocaleString("es") : "\u2014",
      subtitle: "Kilometros recorridos",
      loading: dashLoading,
      color: brandColors.statTeal,
      chartType: "line" as const,
    },
    {
      title: "Costo Combustible Mes",
      value: dashboard ? formatCurrency(dashboard.CostoCombustibleMes) : "\u2014",
      subtitle: "Gasto acumulado",
      loading: dashLoading,
      color: brandColors.statRed,
      chartType: "bar" as const,
    },
    {
      title: "Mant. Pendientes",
      value: dashboard ? String(dashboard.MantenimientosPendientes) : "\u2014",
      subtitle: "Ordenes abiertas",
      loading: dashLoading,
      color: brandColors.statOrange,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    { title: "Vehiculos", description: "Catalogo de vehiculos", icon: <DirectionsCarIcon sx={{ fontSize: 32 }} />, href: `${bp}/vehiculos`, bg: brandColors.shortcutGreen },
    { title: "Combustible", description: "Control de cargas", icon: <LocalGasStationIcon sx={{ fontSize: 32 }} />, href: `${bp}/combustible`, bg: brandColors.shortcutDark },
    { title: "Mantenimiento", description: "Ordenes de servicio", icon: <BuildIcon sx={{ fontSize: 32 }} />, href: `${bp}/mantenimiento`, bg: brandColors.shortcutNavy },
    { title: "Viajes", description: "Control de rutas", icon: <RouteIcon sx={{ fontSize: 32 }} />, href: `${bp}/viajes`, bg: brandColors.shortcutSlate },
  ];

  const vehicleRows = (lastVehicles?.rows ?? []) as Record<string, unknown>[];
  const tripRows = (lastTrips?.rows ?? []) as Record<string, unknown>[];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard de Flota
      </Typography>

      {/* STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%", bgcolor: s.color, color: "white", borderRadius: 2,
                position: "relative", overflow: "hidden", boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {s.loading ? (
                      <Skeleton variant="text" width={80} sx={{ bgcolor: "rgba(255,255,255,0.3)", fontSize: "2rem" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>{s.value}</Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>{s.title}</Typography>
                  </Box>
                  <IconButton size="small" sx={{ color: "white", opacity: 0.8, p: 0 }}>
                    <MoreVertIcon />
                  </IconButton>
                </Box>
                <Box sx={{ mt: 3, height: 40, width: "100%" }}>
                  {s.chartType === "line" ? (
                    <svg viewBox="0 0 100 30" width="100%" height="100%" preserveAspectRatio="none">
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10 L100,30 L0,30 Z" fill="rgba(255,255,255,0.1)" />
                      <path d="M0,20 Q10,10 20,25 T40,15 T60,20 T80,5 T100,10" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" />
                    </svg>
                  ) : (
                    <svg viewBox="0 0 100 30" width="100%" height="100%" preserveAspectRatio="none">
                      <rect x="5" y="10" width="15" height="20" fill="rgba(255,255,255,0.4)" rx="2" />
                      <rect x="30" y="5" width="15" height="25" fill="rgba(255,255,255,0.6)" rx="2" />
                      <rect x="55" y="15" width="15" height="15" fill="rgba(255,255,255,0.3)" rx="2" />
                      <rect x="80" y="8" width="15" height="22" fill="rgba(255,255,255,0.5)" rx="2" />
                    </svg>
                  )}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* SHORTCUTS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 6, sm: 4, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <CardActionArea onClick={() => router.push(sc.href)}>
                <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3, position: "relative" }}>
                  {sc.icon}
                  <svg preserveAspectRatio="none" style={{ position: "absolute", bottom: 0, left: 0, width: "100%", height: "30px" }} viewBox="0 0 100 100">
                    <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                  </svg>
                </Box>
                <CardContent sx={{ textAlign: "center", py: 1.5 }}>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700, color: "text.primary", mb: 0, lineHeight: 1.3 }}>{sc.title}</Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, letterSpacing: 1 }}>{sc.description}</Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ULTIMOS VEHICULOS + ULTIMOS VIAJES */}
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Vehiculos Recientes</Typography>
              {vehicleRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Placa</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Marca/Modelo</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Km</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {vehicleRows.map((r, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(r.VehiclePlate ?? "")}</TableCell>
                        <TableCell>{String(r.Brand ?? "")} {String(r.Model ?? "")}</TableCell>
                        <TableCell>{Number(r.CurrentMileage ?? 0).toLocaleString("es")}</TableCell>
                        <TableCell>
                          <Chip
                            label={vehicleStatusLabels[String(r.Status)] ?? String(r.Status)}
                            size="small"
                            color={vehicleStatusColors[String(r.Status)] ?? "default"}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <DirectionsCarIcon /> No hay vehiculos registrados aun
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)", height: "100%" }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>Ultimos Viajes</Typography>
              {tripRows.length > 0 ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>N. Viaje</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Ruta</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {tripRows.map((t, i) => (
                      <TableRow key={i}>
                        <TableCell>{String(t.TripNumber ?? "")}</TableCell>
                        <TableCell>{String(t.Origin ?? "")} - {String(t.Destination ?? "")}</TableCell>
                        <TableCell>{String(t.DepartureDate ?? "").slice(0, 10)}</TableCell>
                        <TableCell>
                          <Chip
                            label={tripStatusLabels[String(t.Status)] ?? String(t.Status)}
                            size="small"
                            color={tripStatusColors[String(t.Status)] ?? "default"}
                            variant="outlined"
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: 150, bgcolor: "#f8f9fa", borderRadius: 2 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <RouteIcon /> No hay viajes registrados aun
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
