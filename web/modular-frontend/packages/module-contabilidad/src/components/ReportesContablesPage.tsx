"use client";

import React, { useState, useRef, useEffect } from "react";
import {
  Box, Paper, Typography, Button, Stack, Tab, Tabs, CircularProgress, Alert, Divider, IconButton, Tooltip,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import PrintIcon from "@mui/icons-material/Print";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useLibroMayor, useBalanceComprobacion, useEstadoResultados, useBalanceGeneral, useLibroDiario } from "../hooks/useContabilidad";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box pt={2} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

function SectionHeader({ title, total }: { title: string; total?: number }) {
  return (
    <Stack direction="row" justifyContent="space-between" py={1} px={1} sx={{ bgcolor: "grey.100", borderRadius: 1, mb: 0.5 }}>
      <Typography variant="subtitle1" fontWeight={700}>{title}</Typography>
      {total != null && <Typography variant="subtitle1" fontWeight={700}>{formatCurrency(total)}</Typography>}
    </Stack>
  );
}

const LIBRO_DIARIO_COLS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 100, type: "date", sortable: true },
  { field: "numeroAsiento", header: "N\u00B0 Asiento", width: 150, sortable: true },
  { field: "tipoAsiento", header: "Tipo", width: 90, sortable: true, groupable: true },
  { field: "concepto", header: "Concepto", width: 200, sortable: true },
  { field: "codCuenta", header: "Cuenta", width: 110, sortable: true },
  { field: "descripcionCuenta", header: "Descripci\u00F3n", flex: 1, minWidth: 180 },
  { field: "debe", header: "Debe", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

const LIBRO_MAYOR_COLS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 120, sortable: true },
  { field: "descripcion", header: "Descripci\u00F3n", flex: 1, sortable: true },
  { field: "debe", header: "Debe", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "saldo", header: "Saldo", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

const BALANCE_COLS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 120, sortable: true },
  { field: "descripcion", header: "Descripci\u00F3n", flex: 1, sortable: true },
  { field: "totalDebe", header: "Debe", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "totalHaber", header: "Haber", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "saldo", header: "Saldo", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

export default function ReportesContablesPage() {
  const { timeZone } = useTimezone();
  const [tab, setTab] = useState(0);
  const [reportSearch, setReportSearch] = useState("");
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);
  const printRef = useRef<HTMLDivElement>(null);
  const diarioGridRef = useRef<any>(null);
  const mayorGridRef = useRef<any>(null);
  const balanceGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [run, setRun] = useState(false);

  const libroDiario = useLibroDiario(fechaDesde, fechaHasta, run && tab === 0);
  const libroMayor = useLibroMayor(fechaDesde, fechaHasta, run && tab === 1);
  const balance = useBalanceComprobacion(fechaDesde, fechaHasta, run && tab === 2);
  const resultado = useEstadoResultados(fechaDesde, fechaHasta, run && tab === 3);
  const balanceGral = useBalanceGeneral(fechaCorte, run && tab === 4);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  // Bind libro diario
  useEffect(() => {
    const el = diarioGridRef.current;
    if (!el || !registered || tab !== 0 || !run) return;
    el.columns = LIBRO_DIARIO_COLS;
    el.rows = (libroDiario.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i }));
    el.loading = libroDiario.isLoading;
  }, [libroDiario.data, libroDiario.isLoading, registered, tab, run]);

  // Bind libro mayor
  useEffect(() => {
    const el = mayorGridRef.current;
    if (!el || !registered || tab !== 1 || !run) return;
    el.columns = LIBRO_MAYOR_COLS;
    el.rows = (libroMayor.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i }));
    el.loading = libroMayor.isLoading;
  }, [libroMayor.data, libroMayor.isLoading, registered, tab, run]);

  // Bind balance
  useEffect(() => {
    const el = balanceGridRef.current;
    if (!el || !registered || tab !== 2 || !run) return;
    el.columns = BALANCE_COLS;
    el.rows = (balance.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i }));
    el.loading = balance.isLoading;
  }, [balance.data, balance.isLoading, registered, tab, run]);

  const needsRange = tab < 4;

  if (!registered) return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;

  return (
    <Box ref={printRef} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ZenttoFilterPanel filters={[] as FilterFieldDef[]} values={{}} onChange={() => {}} searchPlaceholder="Buscar en reportes..." searchValue={reportSearch} onSearchChange={setReportSearch} />
      <Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
        <Tabs value={tab} onChange={(_, v) => { setTab(v); setRun(false); }} variant="scrollable" scrollButtons="auto">
          <Tab label="Libro diario" /><Tab label="Libro mayor" /><Tab label="Balance comprobacion" /><Tab label="Estado de resultados" /><Tab label="Balance general" />
        </Tabs>
        {run && <Tooltip title="Imprimir reporte"><IconButton onClick={() => window.print()} sx={{ "@media print": { display: "none" } }}><PrintIcon /></IconButton></Tooltip>}
      </Stack>
      <FormGrid spacing={2} sx={{ mt: 1, mb: 2, "@media print": { display: "none" } }} alignItems="center">
        {needsRange ? (<>
          <FormField xs={12} sm={4} md={3}><DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>
          <FormField xs={12} sm={4} md={3}><DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>
        </>) : (
          <FormField xs={12} sm={4} md={3}><DatePicker label="Fecha de Corte" value={fechaCorte ? dayjs(fechaCorte) : null} onChange={(v) => setFechaCorte(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>
        )}
        <FormField xs={12} sm="auto"><Button variant="contained" onClick={() => setRun(true)}>Generar</Button></FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <TabPanel value={tab} index={0}>
          {!run ? <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          : libroDiario.isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          : libroDiario.error ? <Alert severity="error">Error al cargar libro diario</Alert>
          : <zentto-grid ref={diarioGridRef} default-currency="VES" export-filename="libro-diario" height="100%" show-totals
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>}
        </TabPanel>
        <TabPanel value={tab} index={1}>
          {!run ? <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          : libroMayor.isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          : <zentto-grid ref={mayorGridRef} default-currency="VES" export-filename="libro-mayor" height="100%" show-totals
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>}
        </TabPanel>
        <TabPanel value={tab} index={2}>
          {!run ? <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          : balance.isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          : <zentto-grid ref={balanceGridRef} default-currency="VES" export-filename="balance-comprobacion" height="100%" show-totals
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>}
        </TabPanel>
        <TabPanel value={tab} index={3}>
          {!run ? <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          : resultado.isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          : resultado.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              <SectionHeader title="INGRESOS" total={resultado.data.resumen?.ingresos} />
              {(resultado.data.detalle ?? []).filter((item: any) => item.tipo === "I").map((item: any, i: number) => (
                <Stack key={`i-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                  <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                  <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                  <Typography variant="body2" fontWeight={500}>{formatCurrency(item.monto ?? item.saldo ?? 0)}</Typography>
                </Stack>
              ))}
              <Box my={2} />
              <SectionHeader title="COSTOS Y GASTOS" total={resultado.data.resumen?.gastos} />
              {(resultado.data.detalle ?? []).filter((item: any) => item.tipo === "G").map((item: any, i: number) => (
                <Stack key={`g-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                  <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                  <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                  <Typography variant="body2" fontWeight={500}>{formatCurrency(item.monto ?? item.saldo ?? 0)}</Typography>
                </Stack>
              ))}
              <Divider sx={{ my: 2, borderWidth: 2 }} />
              <Stack direction="row" justifyContent="space-between" py={1.5} px={1} sx={{ bgcolor: (resultado.data.resumen?.resultado ?? 0) >= 0 ? "success.light" : "error.light", borderRadius: 1 }}>
                <Typography variant="h6" fontWeight={700}>{(resultado.data.resumen?.resultado ?? 0) >= 0 ? "UTILIDAD NETA" : "PERDIDA NETA"}</Typography>
                <Typography variant="h6" fontWeight={700}>{formatCurrency(Math.abs(resultado.data.resumen?.resultado ?? 0))}</Typography>
              </Stack>
            </Box>
          ) : <Alert severity="info">Presione &quot;Generar&quot; para ver el reporte</Alert>}
        </TabPanel>
        <TabPanel value={tab} index={4}>
          {!run ? <Alert severity="info">Seleccione fecha de corte y presione &quot;Generar&quot;</Alert>
          : balanceGral.isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          : balanceGral.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              {["A","P","C"].map((tipo, secIdx) => {
                const titles: Record<string,string> = { A: "ACTIVOS", P: "PASIVOS", C: "PATRIMONIO" };
                const totals: Record<string,string> = { A: "totalActivo", P: "totalPasivo", C: "totalPatrimonio" };
                return (<React.Fragment key={tipo}>
                  {secIdx > 0 && <Box my={2} />}
                  <SectionHeader title={titles[tipo]} total={balanceGral.data.resumen?.[totals[tipo]]} />
                  {(balanceGral.data.detalle ?? []).filter((item: any) => item.tipo === tipo).map((item: any, i: number) => (
                    <Stack key={`${tipo}-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                      <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                      <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                      <Typography variant="body2" fontWeight={500}>{formatCurrency(item.saldo ?? 0)}</Typography>
                    </Stack>
                  ))}
                </React.Fragment>);
              })}
              <Divider sx={{ my: 2, borderWidth: 2 }} />
              <Stack spacing={1}>
                <Stack direction="row" justifyContent="space-between" px={1}><Typography variant="subtitle1" fontWeight={700}>Total Activos</Typography><Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalActivo ?? 0)}</Typography></Stack>
                <Stack direction="row" justifyContent="space-between" px={1}><Typography variant="subtitle1" fontWeight={700}>Total Pasivo + Patrimonio</Typography><Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0)}</Typography></Stack>
                <Box sx={{ bgcolor: "primary.light", borderRadius: 1, p: 1 }}>
                  <Stack direction="row" justifyContent="space-between">
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">Diferencia (debe ser 0)</Typography>
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">{formatCurrency((balanceGral.data.resumen?.totalActivo ?? 0) - (balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0))}</Typography>
                  </Stack>
                </Box>
              </Stack>
            </Box>
          ) : <Alert severity="info">Presione &quot;Generar&quot; para ver el balance</Alert>}
        </TabPanel>
      </Paper>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
