"use client";

import React, { useMemo, useState } from "react";
import type { SxProps, Theme } from "@mui/material/styles";
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
  Stack,
  TextField,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import BarChartIcon from "@mui/icons-material/BarChart";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import { useRouter } from "next/navigation";
import { useDashboardResumen, useAsientosList } from "../hooks/useContabilidad";

const shortcuts = [
  {
    title: "Consultar asientos",
    description: "Revisar registros",
    icon: <AccountBalanceWalletIcon sx={{ fontSize: 32 }} />,
    href: "/asientos",
    bg: brandColors.shortcutDark,
  },
  {
    title: "Nuevo asiento",
    description: "Registrar operaci\u00F3n",
    icon: <MenuBookIcon sx={{ fontSize: 32 }} />,
    href: "/asientos/new",
    bg: brandColors.shortcutTeal,
  },
  {
    title: "Plan de cuentas",
    description: "Cat\u00E1logo contable",
    icon: <AccountTreeIcon sx={{ fontSize: 32 }} />,
    href: "/cuentas",
    bg: brandColors.shortcutViolet,
  },
  {
    title: "Reportes",
    description: "Balances y libros",
    icon: <BarChartIcon sx={{ fontSize: 32 }} />,
    href: "/reportes",
    bg: brandColors.statRed,
  },
];

type StatField = "totalIngresos" | "totalGastos" | "margenPorcentaje" | "cuentasPorPagar";

const STATS_CONFIG: Array<{ title: string; color: string; field: StatField; isPercent?: boolean }> = [
  { title: "Ingresos", color: brandColors.shortcutDark, field: "totalIngresos" },
  { title: "Gastos", color: brandColors.shortcutTeal, field: "totalGastos" },
  { title: "Margen", color: brandColors.shortcutViolet, field: "margenPorcentaje", isPercent: true },
  { title: "Cuentas por pagar", color: brandColors.statRed, field: "cuentasPorPagar" },
];

const DATE_INPUT_SX: SxProps<Theme> = {
  "& input": { color: "white", py: 0.5, fontSize: "0.75rem" },
  "& fieldset": { borderColor: "rgba(255,255,255,0.3)" },
  "&:hover fieldset": { borderColor: "rgba(255,255,255,0.5)" },
  "& input::-webkit-calendar-picker-indicator": { filter: "brightness(0) invert(1)", opacity: 1, cursor: "pointer" },
  maxWidth: 130,
};

function StatCard({
  title,
  color,
  field,
  isPercent,
  defaultDesde,
  defaultHasta,
}: {
  title: string;
  color: string;
  field: StatField;
  isPercent?: boolean;
  defaultDesde: string;
  defaultHasta: string;
}) {
  const [desde, setDesde] = useState(defaultDesde);
  const [hasta, setHasta] = useState(defaultHasta);
  const { data: resumen, isLoading } = useDashboardResumen(desde, hasta);
  const value = (resumen?.[field] as number | undefined) ?? 0;

  return (
    <Card
      sx={{
        height: "100%",
        bgcolor: color,
        color: "white",
        borderRadius: 2,
        boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
      }}
    >
      <CardContent sx={{ pb: "16px !important" }}>
        <Typography variant="body2" sx={{ mb: 0.5, opacity: 0.9, fontWeight: 500 }}>
          {title}
        </Typography>
        {isLoading ? (
          <Skeleton variant="text" width={120} height={32} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
        ) : (
          <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1.1 }}>
            {isPercent ? `${Number(value).toFixed(1)}%` : formatCurrency(value)}
          </Typography>
        )}
        <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
          <TextField
            type="date"
            size="small"
            value={desde}
            onChange={(e) => {
              const v = e.target.value;
              setDesde(v > hasta ? hasta : v);
            }}
            inputProps={{ max: hasta }}
            sx={DATE_INPUT_SX}
          />
          <TextField
            type="date"
            size="small"
            value={hasta}
            onChange={(e) => {
              const v = e.target.value;
              setHasta(v < desde ? desde : v);
            }}
            inputProps={{ min: desde }}
            sx={DATE_INPUT_SX}
          />
        </Stack>
      </CardContent>
    </Card>
  );
}

export default function ContabilidadHome() {
  const router = useRouter();

  const { defaultDesde, defaultHasta } = useMemo(() => {
    const now = new Date();
    return {
      defaultDesde: new Date(now.getFullYear(), 0, 1).toISOString().slice(0, 10),
      defaultHasta: now.toISOString().slice(0, 10),
    };
  }, []);

  const { data: resumen, isLoading, error } = useDashboardResumen(defaultDesde, defaultHasta);
  const { data: asientosData } = useAsientosList({ page: 1, limit: 5 });

  const ultimosAsientos = asientosData?.rows ?? [];

  return (
    <Box>
      {error && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se pudieron cargar los datos del dashboard. Verifique la conexi&oacute;n con el servidor.
        </Alert>
      )}

      {/* STATS CARDS */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {STATS_CONFIG.map((s) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={s.field}>
            <StatCard
              title={s.title}
              color={s.color}
              field={s.field}
              isPercent={s.isPercent}
              defaultDesde={defaultDesde}
              defaultHasta={defaultHasta}
            />
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
              <Box sx={(t) => ({ bgcolor: sc.bg, backgroundImage: t.palette.mode === 'dark' ? 'linear-gradient(rgba(255,255,255,0.05), rgba(255,255,255,0.05))' : 'none', color: "white", display: "flex", justifyContent: "center", py: 3 })}>
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
      <Grid container spacing={3} alignItems="stretch">
        {/* Ultimos Asientos */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden", height: "100%", display: "flex", flexDirection: "column" }}>
            <Box sx={(t) => ({ p: 2, borderBottom: `1px solid ${t.palette.divider}` })}>
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
          <Paper sx={{ borderRadius: 2, overflow: "hidden", height: "100%", display: "flex", flexDirection: "column" }}>
            <Box sx={(t) => ({ p: 2, borderBottom: `1px solid ${t.palette.divider}` })}>
              <Typography variant="h6" fontWeight={600}>
                Resumen general
              </Typography>
            </Box>
            <Box sx={{ p: 3, flex: 1 }}>
            <Box sx={{ borderLeft: `4px solid ${brandColors.shortcutTeal}`, pl: 2, mb: 3 }}>
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
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
