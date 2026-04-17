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
import { brandColors, DashboardShortcutCard, DashboardKpiCard, DashboardSection } from "@zentto/shared-ui";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import TrendingDownIcon from "@mui/icons-material/TrendingDown";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
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

const STATS_CONFIG: Array<{ title: string; color: string; field: StatField; icon: React.ReactNode; isPercent?: boolean }> = [
  { title: "Ingresos", color: brandColors.shortcutDark, field: "totalIngresos", icon: <TrendingUpIcon /> },
  { title: "Gastos", color: brandColors.shortcutTeal, field: "totalGastos", icon: <TrendingDownIcon /> },
  { title: "Margen", color: brandColors.shortcutViolet, field: "margenPorcentaje", icon: <BarChartIcon />, isPercent: true },
  { title: "Cuentas por pagar", color: brandColors.statRed, field: "cuentasPorPagar", icon: <ReceiptLongIcon /> },
];

const DATE_INPUT_SX: SxProps<Theme> = {
  "& input": { py: 0.5, fontSize: "0.75rem" },
  maxWidth: 130,
};

function StatCard({
  title,
  color,
  field,
  icon,
  isPercent,
  defaultDesde,
  defaultHasta,
}: {
  title: string;
  color: string;
  field: StatField;
  icon: React.ReactNode;
  isPercent?: boolean;
  defaultDesde: string;
  defaultHasta: string;
}) {
  const [desde, setDesde] = useState(defaultDesde);
  const [hasta, setHasta] = useState(defaultHasta);
  const { data: resumen, isLoading } = useDashboardResumen(desde, hasta);
  const raw = (resumen?.[field] as number | undefined) ?? 0;
  const value = isPercent ? raw : formatCurrency(raw);

  return (
    <DashboardKpiCard
      title={title}
      value={value}
      color={color}
      icon={icon}
      isPercent={isPercent}
      loading={isLoading}
      footer={
        <Stack direction="row" spacing={1}>
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
      }
    />
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
              icon={s.icon}
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
            <DashboardShortcutCard
              title={sc.title}
              description={sc.description}
              icon={sc.icon}
              href={sc.href}
              color={sc.bg}
            />
          </Grid>
        ))}
      </Grid>

      {/* BOTTOM SECTION */}
      <Grid container spacing={3} alignItems="stretch">
        {/* Ultimos Asientos */}
        <Grid size={{ xs: 12, md: 8 }}>
          <DashboardSection title="Últimos asientos" padded={false}>
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
          </DashboardSection>
        </Grid>

        {/* Contadores */}
        <Grid size={{ xs: 12, md: 4 }}>
          <DashboardSection title="Resumen general">
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
          </DashboardSection>
        </Grid>
      </Grid>
    </Box>
  );
}
