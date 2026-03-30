"use client";

import React from "react";
import {
  Box,
  Card,
  CardContent,
  Chip,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import { useRouter } from "next/navigation";
import { useCuentasBancarias, useMovimientosCuenta } from "../hooks/useBancosAuxiliares";
import { useConciliaciones } from "../hooks/useConciliacionBancaria";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";

export default function BancosHome() {
  const router = useRouter();
  const cuentas = useCuentasBancarias();
  const conciliaciones = useConciliaciones({ Estado: "ABIERTA", limit: 5 });

  const cuentasData: any[] = cuentas.data?.data ?? cuentas.data?.rows ?? [];
  const saldoTotal = cuentasData.reduce((sum: number, c: any) => sum + (Number(c.Saldo) || 0), 0);
  const conciliacionesPendientes = conciliaciones.data?.totalCount ?? conciliaciones.data?.total ?? 0;

  const now = new Date();
  const mesDesde = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
  const mesHasta = new Date(now.getFullYear(), now.getMonth() + 1, 0)
    .toISOString()
    .slice(0, 10);
  const primeraCuenta: string | undefined = cuentasData[0]?.NumeroCuenta ?? cuentasData[0]?.Nro_Cta;
  const movimientosMes = useMovimientosCuenta(
    primeraCuenta ? { nroCta: primeraCuenta, desde: mesDesde, hasta: mesHasta, limit: 500 } : undefined
  );
  const movimientosRows: any[] = movimientosMes.data?.rows ?? [];
  const totalMovimientosMes = !cuentas.isLoading && cuentasData.length === 0
    ? "0"
    : movimientosMes.data?.total != null
    ? String(movimientosMes.data.total)
    : "—";
  const depositos = movimientosRows
    .filter((m) => m.Tipo === "DEP")
    .reduce((s, m) => s + (Number(m.Monto) || 0), 0);
  const chequesEmitidos = movimientosRows
    .filter((m) => m.Tipo === "PCH")
    .reduce((s, m) => s + (Number(m.Monto) || 0), 0);
  const notasCredito = movimientosRows
    .filter((m) => m.Tipo === "NCR")
    .reduce((s, m) => s + (Number(m.Monto) || 0), 0);

  const statsCards = [
    {
      title: "Saldo total",
      value: cuentasData.length > 0 ? formatCurrency(saldoTotal) : "—",
      loading: cuentas.isLoading,
      color: brandColors.statBlue,
      icon: <AccountBalanceIcon />,
    },
    {
      title: "Cuentas activas",
      value: cuentasData.length > 0 ? String(cuentasData.length) : "—",
      loading: cuentas.isLoading,
      color: brandColors.statTeal,
      icon: <TrendingUpIcon />,
    },
    {
      title: "Movimientos del mes",
      value: totalMovimientosMes,
      loading: cuentas.isLoading || movimientosMes.isLoading,
      color: brandColors.statOrange,
      icon: <TrendingDownIcon />,
    },
    {
      title: "Conciliaciones pendientes",
      value: String(conciliacionesPendientes),
      loading: conciliaciones.isLoading,
      color: brandColors.statRed,
      icon: <CompareArrowsIcon />,
    },
  ];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        Bancos
      </Typography>

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
                    {s.loading ? (
                      <Skeleton variant="text" width={120} height={40} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                        {s.value}
                      </Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
                  </Box>
                  <Box sx={{ opacity: 0.6 }}>{s.icon}</Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* BOTTOM SECTION */}
      <Grid container spacing={3}>
        {/* Cuentas bancarias */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Cuentas bancarias
              </Typography>
            </Box>
            {cuentas.isLoading ? (
              <Box p={3}><Skeleton variant="rectangular" height={120} /></Box>
            ) : cuentasData.length > 0 ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Banco</TableCell>
                    <TableCell>Cuenta</TableCell>
                    <TableCell>Tipo</TableCell>
                    <TableCell align="right">Saldo</TableCell>
                    <TableCell>Estado</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {cuentasData.slice(0, 8).map((c: any, idx: number) => (
                    <TableRow
                      key={c.CuentaBancariaId ?? idx}
                      hover
                      sx={{ cursor: "pointer" }}
                      onClick={() => router.push("/cuentas")}
                    >
                      <TableCell>{c.NombreBanco ?? c.Banco ?? "—"}</TableCell>
                      <TableCell sx={{ fontFamily: "monospace" }}>{c.NumeroCuenta ?? "—"}</TableCell>
                      <TableCell>{c.TipoCuenta ?? "—"}</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>
                        {formatCurrency(Number(c.Saldo) || 0)}
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={c.Estado ?? "ACTIVA"}
                          size="small"
                          color={c.Estado === "INACTIVA" ? "error" : "success"}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Box p={3} textAlign="center">
                <Typography variant="body2" color="text.secondary">
                  No hay cuentas bancarias registradas
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Resumen */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ borderRadius: 2, p: 3 }}>
            <Typography variant="h6" fontWeight={600} mb={2}>
              Resumen general
            </Typography>
            <Box sx={{ borderLeft: `4px solid ${brandColors.statBlue}`, pl: 2, mb: 3 }}>
              <Typography variant="body2" color="text.secondary">Depósitos del mes</Typography>
              {movimientosMes.isLoading ? (
                <Skeleton variant="text" width={120} />
              ) : (
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {movimientosRows.length > 0 ? formatCurrency(depositos) : "—"}
                </Typography>
              )}
            </Box>
            <Box sx={{ borderLeft: `4px solid ${brandColors.statRed}`, pl: 2, mb: 3 }}>
              <Typography variant="body2" color="text.secondary">Cheques emitidos</Typography>
              {movimientosMes.isLoading ? (
                <Skeleton variant="text" width={120} />
              ) : (
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {movimientosRows.length > 0 ? formatCurrency(chequesEmitidos) : "—"}
                </Typography>
              )}
            </Box>
            <Box sx={{ borderLeft: `4px solid ${brandColors.statOrange}`, pl: 2 }}>
              <Typography variant="body2" color="text.secondary">Notas de crédito</Typography>
              {movimientosMes.isLoading ? (
                <Skeleton variant="text" width={120} />
              ) : (
                <Typography variant="h5" sx={{ fontWeight: 700 }}>
                  {movimientosRows.length > 0 ? formatCurrency(notasCredito) : "—"}
                </Typography>
              )}
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
