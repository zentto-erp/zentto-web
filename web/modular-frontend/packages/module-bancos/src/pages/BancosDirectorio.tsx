"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  IconButton,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import CreditCardIcon from "@mui/icons-material/CreditCard";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import PlaylistAddCheckIcon from "@mui/icons-material/PlaylistAddCheck";
import AssessmentIcon from "@mui/icons-material/Assessment";
import LocalAtmIcon from "@mui/icons-material/LocalAtm";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import { useBancosList, useCuentasBancarias } from "../hooks/useBancosAuxiliares";
import { useConciliaciones } from "../hooks/useConciliacionBancaria";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";

export default function BancosDirectorio() {
  const cuentas = useCuentasBancarias();
  const conciliaciones = useConciliaciones({ Estado: "ABIERTA", limit: 1 });

  const cuentasData: any[] = cuentas.data?.data ?? cuentas.data?.rows ?? [];
  const saldoTotal = cuentasData.length > 0
    ? formatCurrency(cuentasData.reduce((sum: number, c: any) => sum + (Number(c.Saldo) || 0), 0))
    : "—";
  const cuentasActivas = cuentasData.length > 0 ? String(cuentasData.length) : "—";
  const conciliacionesPendientes = conciliaciones.data?.totalCount ?? conciliaciones.data?.total ?? "—";

  const statsCards = [
    {
      title: "Saldo Total",
      value: saldoTotal,
      subtitle: "Todas las Cuentas",
      loading: cuentas.isLoading,
      color: brandColors.statBlue,
      chartType: "line" as const,
    },
    {
      title: "Cuentas Activas",
      value: cuentasActivas,
      subtitle: "Registradas",
      loading: cuentas.isLoading,
      color: brandColors.statTeal,
      chartType: "bar" as const,
    },
    {
      title: "Movimientos del Mes",
      value: "—",
      subtitle: "Este Mes",
      loading: false,
      color: brandColors.statOrange,
      chartType: "bar" as const,
    },
    {
      title: "Conciliaciones Pendientes",
      value: String(conciliacionesPendientes),
      subtitle: "Abiertas",
      loading: conciliaciones.isLoading,
      color: brandColors.statRed,
      chartType: "line" as const,
    },
  ];

  const shortcuts = [
    {
      title: "Bancos",
      description: "Gestión de Bancos",
      icon: <AccountBalanceIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/entidades",
      bg: brandColors.shortcutGreen,
    },
    {
      title: "Cuentas Bancarias",
      description: "Saldos y Movimientos",
      icon: <CreditCardIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/cuentas",
      bg: brandColors.shortcutDark,
    },
    {
      title: "Movimientos",
      description: "Generar Movimiento",
      icon: <SwapHorizIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/movimientos/generar",
      bg: brandColors.shortcutTeal,
    },
    {
      title: "Conciliaciones",
      description: "Listado",
      icon: <CompareArrowsIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/conciliacion",
      bg: brandColors.shortcutSlate,
    },
    {
      title: "Nueva Conciliación",
      description: "Wizard Paso a Paso",
      icon: <PlaylistAddCheckIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/conciliacion/wizard",
      bg: brandColors.success,
    },
    {
      title: "Caja Chica",
      description: "Gastos y Sesiones",
      icon: <LocalAtmIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/caja-chica",
      bg: brandColors.shortcutNavy,
    },
    {
      title: "Reportes",
      description: "Informes Bancarios",
      icon: <AssessmentIcon sx={{ fontSize: 32 }} />,
      href: "/bancos/cuentas",
      bg: brandColors.shortcutOrange,
    },
  ];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Directorio
      </Typography>

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
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {s.loading ? (
                      <Skeleton variant="text" width={80} sx={{ bgcolor: "rgba(255,255,255,0.3)", fontSize: "2rem" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                        {s.value}
                      </Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
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

      {/* CORE-UI WIDGETS (SOCIAL-LIKE SHORTCUTS) */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card sx={{ borderRadius: 2, overflow: "hidden", boxShadow: "0 2px 4px rgba(0,0,0,0.05)" }}>
              <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3, position: "relative" }}>
                {sc.icon}
                <svg preserveAspectRatio="none" style={{ position: "absolute", bottom: 0, left: 0, width: "100%", height: "30px" }} viewBox="0 0 100 100">
                  <path d="M0,100 C20,0 50,0 100,100 Z" fill="rgba(255,255,255,0.15)" />
                </svg>
              </Box>
              <CardContent sx={{ textAlign: "center", py: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>
                  {sc.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}>
                  {sc.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Large Bottom Card */}
      <Card sx={{ borderRadius: 2, boxShadow: "0 2px 8px rgba(0,0,0,0.08)" }}>
        <CardContent>
          <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>
            Resumen Financiero Bancario
          </Typography>

          <Grid container spacing={4}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statBlue}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Depósitos del Mes</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>—</Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2, mb: 3 }}>
                <Typography variant="body2" color="text.secondary">Cheques Emitidos</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>—</Typography>
              </Box>
              <Box sx={{ borderLeft: `4px solid ${brandColors.statOrange}`, pl: 2 }}>
                <Typography variant="body2" color="text.secondary">Notas de Crédito</Typography>
                <Typography variant="h5" sx={{ fontWeight: 700 }}>—</Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 8 }} sx={{ display: "flex", alignItems: "center", justifyContent: "center", bgcolor: "#f8f9fa", borderRadius: 2, minHeight: 200 }}>
              <Typography variant="body2" color="text.secondary" sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <TrendingUpIcon /> Resumen bancario se actualizará con datos reales
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
}
