"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  CardActionArea,
  Typography,
  IconButton,
  CircularProgress,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import PeopleIcon from "@mui/icons-material/People";
import ListAltIcon from "@mui/icons-material/ListAlt";
import BeachAccessIcon from "@mui/icons-material/BeachAccess";
import ExitToAppIcon from "@mui/icons-material/ExitToApp";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import SupervisorAccountIcon from "@mui/icons-material/SupervisorAccount";
import EventIcon from "@mui/icons-material/Event";
import BatchPredictionIcon from "@mui/icons-material/BatchPrediction";
import SettingsIcon from "@mui/icons-material/Settings";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import { useRouter } from "next/navigation";
import { useEmpleadosList } from "../hooks/useEmpleados";
import { useNominasList } from "../hooks/useNomina";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";

export default function NominaHome({ basePath = "" }: { basePath?: string }) {
  const router = useRouter();
  const bp = basePath.replace(/\/+$/, "");
  const empleados = useEmpleadosList({ status: "ACTIVO", limit: 1 });
  const nominas = useNominasList({ limit: 1 });

  const totalEmpleados = empleados.data?.totalCount ?? empleados.data?.total ?? "—";
  const nominaRows = Array.isArray(nominas.data) ? nominas.data : nominas.data?.rows ?? [];
  const ultimaNomina = nominaRows[0];
  const nominaTotal = ultimaNomina?.totalAsignaciones
    ? formatCurrency(ultimaNomina.totalAsignaciones)
    : "—";

  const salarioBase = ultimaNomina?.totalAsignaciones != null
    ? formatCurrency(ultimaNomina.totalAsignaciones)
    : "—";
  const impuestosYss = ultimaNomina?.totalDeducciones != null
    ? formatCurrency(ultimaNomina.totalDeducciones)
    : "—";
  const netoNomina = ultimaNomina?.totalNeto != null
    ? formatCurrency(ultimaNomina.totalNeto)
    : "—";

  const statsCards = [
    {
      title: "Nómina Mensual",
      value: nominaTotal,
      subtitle: "Total Pagos",
      loading: nominas.isLoading,
      color: brandColors.shortcutDark,
      chartType: "line" as const,
    },
    {
      title: "Empleados Activos",
      value: String(totalEmpleados),
      subtitle: "Staffing",
      loading: empleados.isLoading,
      color: brandColors.shortcutTeal,
      chartType: "bar" as const,
    },
    {
      title: "Horas Extras",
      value: "—",
      subtitle: "Este Mes",
      loading: false,
      color: brandColors.shortcutViolet,
      chartType: "bar" as const,
    },
    {
      title: "Ausentismo",
      value: "—",
      subtitle: "Rate",
      loading: false,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
  ];

  const PALETTE = [brandColors.shortcutDark, brandColors.shortcutTeal, brandColors.shortcutViolet, brandColors.statRed];
  const shortcutItems = [
    { title: "Empleados", description: "Gestión RRHH", icon: <PeopleIcon sx={{ fontSize: 32 }} />, href: `${bp}/empleados` },
    { title: "Nóminas", description: "Procesos y Lotes", icon: <SupervisorAccountIcon sx={{ fontSize: 32 }} />, href: `${bp}/nominas` },
    { title: "Conceptos", description: "Asignaciones", icon: <ListAltIcon sx={{ fontSize: 32 }} />, href: `${bp}/conceptos` },
    { title: "Vacaciones", description: "Calendario", icon: <BeachAccessIcon sx={{ fontSize: 32 }} />, href: `${bp}/vacaciones` },
    { title: "Solicitar Vacaciones", description: "Solicitudes", icon: <EventIcon sx={{ fontSize: 32 }} />, href: `${bp}/vacaciones/solicitar` },
    { title: "Aprobar Solicitudes", description: "Revisión", icon: <ReceiptLongIcon sx={{ fontSize: 32 }} />, href: `${bp}/vacaciones/solicitudes` },
    { title: "Liquidaciones", description: "Retiros", icon: <ExitToAppIcon sx={{ fontSize: 32 }} />, href: `${bp}/liquidaciones` },
    { title: "Constantes", description: "Configuración", icon: <SettingsIcon sx={{ fontSize: 32 }} />, href: `${bp}/constantes` },
  ];
  const shortcuts = shortcutItems.map((sc, i) => ({ ...sc, bg: PALETTE[i % PALETTE.length] }));

  return (
    <Box>
      {/* CORE-UI STYLE STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%",
                bgcolor: s.color,
                color: "white",
                borderRadius: 2,
                position: "relative",
                overflow: "hidden",
                boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Typography variant="body2" sx={{ mb: 0.5, opacity: 0.9, fontWeight: 500 }}>
                  {s.title}
                </Typography>
                {s.loading ? (
                  <Skeleton variant="text" width={80} height={32} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
                ) : (
                  <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1.1 }}>
                    {s.value}
                  </Typography>
                )}

              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* CORE-UI WIDGETS (SOCIAL-LIKE SHORTCUTS) */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)", height: "100%" }}>
              <CardActionArea onClick={() => router.push(sc.href)} sx={{ height: "100%", display: "flex", flexDirection: "column", alignItems: "stretch" }}>
                <Box sx={(t) => ({ bgcolor: sc.bg, backgroundImage: t.palette.mode === 'dark' ? 'linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))' : 'none', color: "white", display: "flex", justifyContent: "center", py: 3 })}>
                  {sc.icon}
                </Box>
                <CardContent sx={{ textAlign: "center", py: 2, flex: 1 }}>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>
                    {sc.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}>
                    {sc.description}
                  </Typography>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Large Bottom Card */}
      <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)" }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            Desempeño y Cargas Laborales
          </Typography>

          <Grid container spacing={4}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ borderLeft: `4px solid ${brandColors.shortcutTeal}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Total Asignaciones</Typography>
                {nominas.isLoading ? (
                  <Skeleton variant="text" width={120} />
                ) : (
                  <Typography variant="h5" sx={{ fontWeight: 700 }}>{salarioBase}</Typography>
                )}
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Total Deducciones</Typography>
                {nominas.isLoading ? (
                  <Skeleton variant="text" width={120} />
                ) : (
                  <Typography variant="h5" sx={{ fontWeight: 700 }}>{impuestosYss}</Typography>
                )}
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.success}`, pl: 2 }}>
                <Typography variant="body2" color="text.secondary">Neto a Pagar</Typography>
                {nominas.isLoading ? (
                  <Skeleton variant="text" width={120} />
                ) : (
                  <Typography variant="h5" sx={{ fontWeight: 700 }}>{netoNomina}</Typography>
                )}
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 8 }} sx={{ bgcolor: "#f8f9fa", borderRadius: 2, p: 3, minHeight: 200 }}>
              {nominas.isLoading ? (
                <Skeleton variant="rectangular" height={160} />
              ) : ultimaNomina ? (
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1, display: "flex", alignItems: "center", gap: 1 }}>
                    <TrendingUpIcon fontSize="small" /> Última nómina procesada
                  </Typography>
                  <Typography variant="h6" sx={{ fontWeight: 700, mb: 0.5 }}>
                    {ultimaNomina.nomina ?? ultimaNomina.Nomina ?? "—"}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {ultimaNomina.fechaInicio
                      ? `${ultimaNomina.fechaInicio} — ${ultimaNomina.fechaHasta ?? ""}`
                      : ""}
                  </Typography>
                  <Box sx={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Asignaciones</Typography>
                      <Typography variant="body1" sx={{ fontWeight: 600 }}>
                        {formatCurrency(ultimaNomina.totalAsignaciones ?? 0)}
                      </Typography>
                    </Box>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Deducciones</Typography>
                      <Typography variant="body1" sx={{ fontWeight: 600 }}>
                        {formatCurrency(ultimaNomina.totalDeducciones ?? 0)}
                      </Typography>
                    </Box>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Neto</Typography>
                      <Typography variant="body1" sx={{ fontWeight: 700, color: "success.main" }}>
                        {formatCurrency(ultimaNomina.totalNeto ?? 0)}
                      </Typography>
                    </Box>
                  </Box>
                </Box>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", minHeight: 160 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                    <TrendingUpIcon /> No hay nóminas procesadas
                  </Typography>
                </Box>
              )}
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}
