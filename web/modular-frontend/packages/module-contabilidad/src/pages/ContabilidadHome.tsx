"use client";

import React, { useMemo } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Skeleton,
  Alert,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import BarChartIcon from "@mui/icons-material/BarChart";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { brandColors } from "@zentto/shared-ui";
import { useRouter } from "next/navigation";
import { useDashboardResumen, useAsientosList } from "../hooks/useContabilidad";

const shortcuts = [
  {
    title: "Asientos",
    description: "Crear y consultar",
    icon: <AccountBalanceWalletIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/asientos",
    bg: brandColors.shortcutDark,
  },
  {
    title: "Plan de cuentas",
    description: "Cat\u00E1logo contable",
    icon: <AccountTreeIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/cuentas",
    bg: brandColors.shortcutTeal,
  },
  {
    title: "Reportes",
    description: "Balances y libros",
    icon: <BarChartIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/reportes",
    bg: brandColors.shortcutSlate,
  },
  {
    title: "Nuevo asiento",
    description: "Registrar operaci\u00F3n",
    icon: <MenuBookIcon sx={{ fontSize: 32 }} />,
    href: "/contabilidad/asientos/new",
    bg: brandColors.success,
  },
];

export default function ContabilidadHome() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  const { fechaDesde, fechaHasta } = useMemo(() => {
    const now = new Date();
    return {
      fechaDesde: new Date(now.getFullYear(), 0, 1).toISOString().slice(0, 10),
      fechaHasta: now.toISOString().slice(0, 10),
    };
  }, [timeZone]);

  const { data: resumen, isLoading, error } = useDashboardResumen(fechaDesde, fechaHasta);
  const { data: asientosData } = useAsientosList({ page: 1, limit: 5 });

  const ultimosAsientos = asientosData?.rows ?? [];

  const statsCards = [
    {
      title: "Ingresos",
      value: resumen?.totalIngresos ?? 0,
      color: brandColors.statBlue,
      icon: <TrendingUpIcon />,
    },
    {
      title: "Gastos",
      value: resumen?.totalGastos ?? 0,
      color: brandColors.statTeal,
      icon: <TrendingDownIcon />,
    },
    {
      title: "Margen",
      value: resumen?.margenPorcentaje ?? 0,
      isPercent: true,
      color: brandColors.statOrange,
      icon: <BarChartIcon />,
    },
    {
      title: "Ctas por pagar",
      value: resumen?.cuentasPorPagar ?? 0,
      color: brandColors.statRed,
      icon: <ReceiptLongIcon />,
    },
  ];

  return (
    <Box>
      {error && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se pudieron cargar los datos del dashboard. Verifique la conexi&oacute;n con el servidor.
        </Alert>
      )}

      {/* STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%",
                bgcolor: s.color,
                color: "white",
                borderRadius: 2,
                boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {isLoading ? (
                      <Skeleton variant="text" width={120} height={40} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                        {(s as any).isPercent
                          ? `${Number(s.value).toFixed(1)}%`
                          : formatCurrency(s.value)}
                      </Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
                  </Box>
                  <Box sx={{ opacity: 0.6 }}>{s.icon}</Box>
                </Box>
                <Typography variant="caption" sx={{ opacity: 0.7, mt: 1, display: "block" }}>
                  {fechaDesde} &mdash; {fechaHasta}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* SHORTCUTS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                borderRadius: 2,
                overflow: "hidden",
                boxShadow: "0 2px 4px rgba(0,0,0,0.05)",
                cursor: "pointer",
                transition: "transform 0.2s, box-shadow 0.2s",
                "&:hover": { transform: "translateY(-2px)", boxShadow: "0 4px 12px rgba(0,0,0,0.15)" },
              }}
              onClick={() => router.push(sc.href)}
            >
              <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3 }}>
                {sc.icon}
              </Box>
              <CardContent sx={{ textAlign: "center", py: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>
                  {sc.title}
                </Typography>
                <Typography
                  variant="body2"
                  color="text.secondary"
                  sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}
                >
                  {sc.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* BOTTOM SECTION */}
      <Grid container spacing={3}>
        {/* Ultimos Asientos */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Últimos asientos
              </Typography>
            </Box>
            {ultimosAsientos.length > 0 ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Fecha</TableCell>
                    <TableCell>Tipo</TableCell>
                    <TableCell>Concepto</TableCell>
                    <TableCell align="right">Debe</TableCell>
                    <TableCell align="right">Haber</TableCell>
                    <TableCell>Estado</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {ultimosAsientos.map((a: any, idx: number) => (
                    <TableRow
                      key={a.asientoId ?? a.id ?? idx}
                      hover
                      sx={{ cursor: "pointer" }}
                      onClick={() => router.push("/asientos")}
                    >
                      <TableCell>{a.fecha}</TableCell>
                      <TableCell>{a.tipoAsiento}</TableCell>
                      <TableCell sx={{ maxWidth: 250, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                        {a.concepto}
                      </TableCell>
                      <TableCell align="right">{formatCurrency(a.totalDebe ?? 0)}</TableCell>
                      <TableCell align="right">{formatCurrency(a.totalHaber ?? 0)}</TableCell>
                      <TableCell>
                        <Chip
                          label={a.estado}
                          size="small"
                          color={a.estado === "APPROVED" ? "success" : a.estado === "VOIDED" ? "error" : "default"}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Box p={3} textAlign="center">
                <Typography variant="body2" color="text.secondary">
                  No hay asientos registrados
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Contadores */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ borderRadius: 2, p: 3 }}>
            <Typography variant="h6" fontWeight={600} mb={2}>
              Resumen general
            </Typography>
            <Box sx={{ borderLeft: `4px solid ${brandColors.statBlue}`, pl: 2, mb: 3 }}>
              <Typography variant="body2" color="text.secondary">Total asientos</Typography>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {isLoading ? <Skeleton width={60} /> : resumen?.totalAsientos ?? 0}
              </Typography>
            </Box>
            <Box sx={{ borderLeft: `4px solid ${brandColors.success}`, pl: 2, mb: 3 }}>
              <Typography variant="body2" color="text.secondary">Cuentas activas</Typography>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {isLoading ? <Skeleton width={60} /> : resumen?.totalCuentas ?? 0}
              </Typography>
            </Box>
            <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2 }}>
              <Typography variant="body2" color="text.secondary">Asientos anulados</Typography>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {isLoading ? <Skeleton width={60} /> : resumen?.totalAnulados ?? 0}
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
