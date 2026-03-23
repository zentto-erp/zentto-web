"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Tabs,
  Tab,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  ToggleButton,
  ToggleButtonGroup,
  CircularProgress,
  Alert,
} from "@mui/material";
import { toDateOnly } from "@zentto/shared-api";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useTimezone } from "@zentto/shared-auth";
import {
  useBalanceReexpresado,
  useREME,
  useEquityChangesReport,
} from "../hooks/useContabilidadLegal";
import {
  useBalanceGeneral,
  useEstadoResultados,
  useBalanceComprobacion,
  useLibroDiario,
} from "../hooks/useContabilidad";
import { useCashFlowReport } from "../hooks/useContabilidadAdvanced";

// ─── Helpers ──────────────────────────────────────────────────

type Country = "VE" | "ES";

interface TabDef {
  label: string;
  framework: string;
  legalRef: string;
}

const VE_TABS: TabDef[] = [
  { label: "Balance general", framework: "VEN-NIF", legalRef: "VEN-NIF BA-8 / NIC 1" },
  { label: "Estado de resultados", framework: "VEN-NIF", legalRef: "VEN-NIF BA-8 / NIC 1 par. 81-105" },
  { label: "Cambios patrimonio", framework: "VEN-NIF", legalRef: "VEN-NIF BA-8 / NIC 1 par. 106-110" },
  { label: "Flujos de efectivo", framework: "VEN-NIF", legalRef: "VEN-NIF BA-8 / NIC 7" },
  { label: "REME", framework: "VEN-NIF", legalRef: "VEN-NIF BA-8 / NIC 29 - Reexpresion por inflacion" },
  { label: "Balance comprobación", framework: "VEN-NIF", legalRef: "Art. 35 Codigo de Comercio venezolano" },
];

const ES_TABS: TabDef[] = [
  { label: "Balance situación", framework: "PGC", legalRef: "PGC - Tercera parte / Real Decreto 1514/2007" },
  { label: "Pérdidas y ganancias", framework: "PGC", legalRef: "PGC - Tercera parte, Cuenta de PyG" },
  { label: "ECPN", framework: "PGC", legalRef: "PGC - Tercera parte, Estado de cambios en el patrimonio neto" },
  { label: "EFE", framework: "PGC", legalRef: "PGC - Tercera parte, Estado de flujos de efectivo / NIC 7" },
];

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box pt={2}>{children}</Box> : null;
}

// ─── Generic report table ─────────────────────────────────────

function ReportTable({ data, isLoading, isError }: { data: any; isLoading: boolean; isError: boolean }) {
  if (isLoading) return <Box py={4} textAlign="center"><CircularProgress /></Box>;
  if (isError) return <Alert severity="error">Error al cargar el reporte.</Alert>;

  const rows: any[] = Array.isArray(data) ? data : data?.rows ?? data?.data ?? [];
  if (rows.length === 0) return <Alert severity="info">Sin datos para el periodo seleccionado.</Alert>;

  const columns = Object.keys(rows[0]);

  return (
    <TableContainer component={Paper} variant="outlined" sx={{ maxHeight: 520 }}>
      <Table stickyHeader size="small">
        <TableHead>
          <TableRow>
            {columns.map((col) => (
              <TableCell key={col} sx={{ fontWeight: 700, whiteSpace: "nowrap" }}>
                {col}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row: any, idx: number) => (
            <TableRow key={idx} hover>
              {columns.map((col) => (
                <TableCell key={col}>
                  {typeof row[col] === "number" ? row[col].toLocaleString("es", { minimumFractionDigits: 2 }) : String(row[col] ?? "")}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

// ─── Main Component ───────────────────────────────────────────

export default function ReportesLegalesPage() {
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);

  const [country, setCountry] = useState<Country>("VE");
  const [tab, setTab] = useState(0);
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [reexpresado, setReexpresado] = useState(false);

  const tabs = country === "VE" ? VE_TABS : ES_TABS;
  const currentTab = tabs[tab] ?? tabs[0];
  const fiscalYear = new Date(fechaHasta).getFullYear();

  // Reset tab when switching country
  const handleCountryChange = (_: React.MouseEvent<HTMLElement>, val: Country | null) => {
    if (val) {
      setCountry(val);
      setTab(0);
    }
  };

  // ─── Hook calls (enabled based on active tab + country) ─────

  // VE tab 0 / ES tab 0: Balance General
  const isBalanceGeneralTab = (country === "VE" && tab === 0) || (country === "ES" && tab === 0);
  const balanceGeneral = useBalanceGeneral(fechaCorte, isBalanceGeneralTab);
  const balanceReexpresado = useBalanceReexpresado(fechaCorte, country === "VE" && tab === 0 && reexpresado);

  // VE tab 1 / ES tab 1: Estado de Resultados
  const isResultadosTab = (country === "VE" && tab === 1) || (country === "ES" && tab === 1);
  const estadoResultados = useEstadoResultados(fechaDesde, fechaHasta, isResultadosTab);

  // VE tab 2 / ES tab 2: Cambios Patrimonio / ECPN
  const isEquityTab = (country === "VE" && tab === 2) || (country === "ES" && tab === 2);
  const equityChanges = useEquityChangesReport(fiscalYear, isEquityTab);

  // VE tab 3 / ES tab 3: Flujos de Efectivo / EFE
  const isCashFlowTab = (country === "VE" && tab === 3) || (country === "ES" && tab === 3);
  const cashFlow = useCashFlowReport(fechaDesde, fechaHasta, isCashFlowTab);

  // VE tab 4: REME
  const reme = useREME(fechaDesde, fechaHasta, country === "VE" && tab === 4);

  // VE tab 5: Balance Comprobacion
  const balanceComprobacion = useBalanceComprobacion(fechaDesde, fechaHasta, country === "VE" && tab === 5);

  // Libro Diario not directly used as a tab here but available if needed
  // const libroDiario = useLibroDiario(fechaDesde, fechaHasta, false);

  // ─── Resolve active query ──────────────────────────────────

  const activeQuery = useMemo(() => {
    if (country === "VE") {
      switch (tab) {
        case 0: return reexpresado ? balanceReexpresado : balanceGeneral;
        case 1: return estadoResultados;
        case 2: return equityChanges;
        case 3: return cashFlow;
        case 4: return reme;
        case 5: return balanceComprobacion;
      }
    } else {
      switch (tab) {
        case 0: return balanceGeneral;
        case 1: return estadoResultados;
        case 2: return equityChanges;
        case 3: return cashFlow;
      }
    }
    return balanceGeneral;
  }, [country, tab, reexpresado, balanceGeneral, balanceReexpresado, estadoResultados, equityChanges, cashFlow, reme, balanceComprobacion]);

  // ─── Actions ────────────────────────────────────────────────

  const handleDownloadPdf = () => {
    console.log("Descargar PDF:", { country, tab: currentTab.label, fechaDesde, fechaHasta, fechaCorte });
  };

  const handlePrint = () => {
    window.print();
  };

  // ─── Render ─────────────────────────────────────────────────

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      <Typography variant="h5" fontWeight={700} gutterBottom>
        Reportes Legales
      </Typography>

      {/* Country selector + date filters */}
      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Stack direction={{ xs: "column", md: "row" }} spacing={2} alignItems="center">
          <ToggleButtonGroup
            value={country}
            exclusive
            onChange={handleCountryChange}
            size="small"
          >
            <ToggleButton value="VE">VE</ToggleButton>
            <ToggleButton value="ES">ES</ToggleButton>
          </ToggleButtonGroup>

          <DatePicker
            label="Fecha desde"
            value={fechaDesde ? dayjs(fechaDesde) : null}
            onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
          <DatePicker
            label="Fecha hasta"
            value={fechaHasta ? dayjs(fechaHasta) : null}
            onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
          <DatePicker
            label="Fecha corte"
            value={fechaCorte ? dayjs(fechaCorte) : null}
            onChange={(v) => setFechaCorte(v ? v.format('YYYY-MM-DD') : '')}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Stack>
      </Paper>

      {/* Tabs */}
      <Box sx={{ borderBottom: 1, borderColor: "divider" }}>
        <Tabs
          value={tab}
          onChange={(_, v) => setTab(v)}
          variant="scrollable"
          scrollButtons="auto"
        >
          {tabs.map((t, i) => (
            <Tab key={i} label={t.label} />
          ))}
        </Tabs>
      </Box>

      {/* Tab content */}
      {tabs.map((t, i) => (
        <TabPanel key={i} value={tab} index={i}>
          {/* Legal chip + reference */}
          <Stack direction="row" spacing={1} alignItems="center" mb={1}>
            <Chip label={t.framework} color="primary" size="small" />
            <Typography variant="caption" color="text.secondary">
              {t.legalRef}
            </Typography>
          </Stack>

          {/* Toggle historico/reexpresado (only VE Balance General) */}
          {country === "VE" && i === 0 && (
            <Box mb={1}>
              <ToggleButtonGroup
                value={reexpresado ? "reexpresado" : "historico"}
                exclusive
                onChange={(_, val) => {
                  if (val) setReexpresado(val === "reexpresado");
                }}
                size="small"
              >
                <ToggleButton value="historico">Historico</ToggleButton>
                <ToggleButton value="reexpresado">Reexpresado</ToggleButton>
              </ToggleButtonGroup>
            </Box>
          )}

          {/* Report table */}
          <ReportTable
            data={activeQuery.data}
            isLoading={activeQuery.isLoading}
            isError={activeQuery.isError}
          />

          {/* Actions */}
          <Stack direction="row" spacing={1} mt={2}>
            <Button variant="contained" onClick={handleDownloadPdf}>
              Descargar PDF
            </Button>
            <Button variant="outlined" onClick={handlePrint}>
              Imprimir
            </Button>
          </Stack>
        </TabPanel>
      ))}
    </Box>
  );
}
