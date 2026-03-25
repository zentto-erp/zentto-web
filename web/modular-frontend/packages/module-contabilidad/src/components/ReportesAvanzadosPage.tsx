"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, Stack, Alert, Tab, Tabs, CircularProgress, Divider,
  IconButton, Tooltip, Dialog, DialogTitle, DialogContent, DialogActions, Chip, Card,
  CardContent, LinearProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import PrintIcon from "@mui/icons-material/Print";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import ZoomInIcon from "@mui/icons-material/ZoomIn";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useLibroMayor, useBalanceComprobacion, useEstadoResultados, useBalanceGeneral, useLibroDiario } from "../hooks/useContabilidad";
import {
  useCashFlowReport, useAgingCxC, useAgingCxP, useFinancialRatios, useTaxSummary, useDrillDown,
  type CashFlowSection, type AgingBucket, type FinancialRatio, type TaxSummaryRow, type DrillDownRow,
} from "../hooks/useContabilidadAdvanced";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box pt={2} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

function SectionHeader({ title, total }: { title: string; total?: number }) {
  return (<Stack direction="row" justifyContent="space-between" py={1} px={1} sx={{ bgcolor: "grey.100", borderRadius: 1, mb: 0.5 }}>
    <Typography variant="subtitle1" fontWeight={700}>{title}</Typography>
    {total != null && <Typography variant="subtitle1" fontWeight={700}>{formatCurrency(total)}</Typography>}
  </Stack>);
}

// ---- Drill Down Dialog ----
const DRILL_COLUMNS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 100, type: "date" },
  { field: "numeroAsiento", header: "N Asiento", width: 120 },
  { field: "tipoAsiento", header: "Tipo", width: 90 },
  { field: "concepto", header: "Concepto", flex: 1, minWidth: 200, sortable: true },
  { field: "debe", header: "Debe", width: 130, type: "number", currency: "VES" },
  { field: "haber", header: "Haber", width: 130, type: "number", currency: "VES" },
  { field: "saldoAcum", header: "Saldo acum.", width: 140, type: "number", currency: "VES" },
];

function DrillDownDialog({ open, onClose, accountCode, accountName, fechaDesde, fechaHasta }: {
  open: boolean; onClose: () => void; accountCode: string; accountName?: string; fechaDesde: string; fechaHasta: string;
}) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { data, isLoading } = useDrillDown(accountCode, fechaDesde, fechaHasta, open && !!accountCode);
  const rows: DrillDownRow[] = useMemo(() => { const items = data?.data ?? data?.rows ?? []; return items.map((r: any, i: number) => ({ ...r, id: i })); }, [data]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = DRILL_COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Stack direction="row" alignItems="center" justifyContent="space-between">
          <Typography variant="h6" fontWeight={600}>Drill-Down: {accountCode} {accountName ? `- ${accountName}` : ""}</Typography>
          <Tooltip title="Cerrar"><IconButton onClick={onClose} size="small"><CloseIcon /></IconButton></Tooltip>
        </Stack>
        <Typography variant="body2" color="text.secondary">{fechaDesde} a {fechaHasta}</Typography>
      </DialogTitle>
      <DialogContent>
        {!registered || isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
        : rows.length === 0 ? <Alert severity="info">No hay movimientos para esta cuenta en el periodo</Alert>
        : <Box sx={{ height: 400 }}>
            <zentto-grid ref={gridRef} default-currency="VES" height="100%" show-totals
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
          </Box>}
      </DialogContent>
      <DialogActions><Button onClick={onClose}>Cerrar</Button></DialogActions>
    </Dialog>
  );
}

// ---- Financial Ratio Gauge ----
function RatioGauge({ ratio }: { ratio: FinancialRatio }) {
  const maxDisplay = ratio.unit === "%" ? 100 : 5;
  const progress = Math.min((Math.abs(ratio.value) / maxDisplay) * 100, 100);
  const isGood = ratio.name.toLowerCase().includes("liquidez") ? ratio.value >= 1 : ratio.name.toLowerCase().includes("endeudamiento") ? ratio.value < 0.6 : ratio.value > 0;
  return (
    <Card sx={{ borderRadius: 2, height: "100%" }}>
      <CardContent>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>{ratio.name}</Typography>
        <Typography variant="h4" fontWeight={700} sx={{ color: isGood ? "success.main" : "error.main" }}>{ratio.value.toFixed(2)}{ratio.unit === "%" ? "%" : "x"}</Typography>
        <LinearProgress variant="determinate" value={progress} sx={{ mt: 1, height: 8, borderRadius: 4, bgcolor: "grey.200", "& .MuiLinearProgress-bar": { bgcolor: isGood ? "success.main" : "error.main", borderRadius: 4 } }} />
        {ratio.benchmark != null && <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block" }}>Benchmark: {ratio.benchmark.toFixed(2)}</Typography>}
        <Chip label={ratio.category} size="small" variant="outlined" sx={{ mt: 1, fontSize: "0.7rem" }} />
      </CardContent>
    </Card>
  );
}

// ---- Column definitions ----
const DIARIO_COLS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 100, type: "date", sortable: true },
  { field: "numeroAsiento", header: "N Asiento", width: 130, sortable: true },
  { field: "tipoAsiento", header: "Tipo", width: 90, sortable: true, groupable: true },
  { field: "concepto", header: "Concepto", width: 200, sortable: true },
  { field: "codCuenta", header: "Cuenta", width: 110, sortable: true },
  { field: "descripcionCuenta", header: "Descripcion", flex: 1, minWidth: 180 },
  { field: "debe", header: "Debe", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

const MAYOR_COLS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 120, sortable: true },
  { field: "descripcion", header: "Descripcion", flex: 1, sortable: true },
  { field: "debe", header: "Debe", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "saldo", header: "Saldo", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

const BALANCE_COLS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 120, sortable: true },
  { field: "descripcion", header: "Descripcion", flex: 1, sortable: true },
  { field: "totalDebe", header: "Debe", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "totalHaber", header: "Haber", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "saldo", header: "Saldo", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

const AGING_COLS: ColumnDef[] = [
  { field: "entity", header: "Codigo", width: 120 },
  { field: "entityName", header: "Nombre", flex: 1, minWidth: 180, sortable: true },
  { field: "current", header: "Corriente", width: 120, type: "number", currency: "VES" },
  { field: "days30", header: "1-30 dias", width: 120, type: "number", currency: "VES" },
  { field: "days60", header: "31-60 dias", width: 120, type: "number", currency: "VES" },
  { field: "days90", header: "61-90 dias", width: 120, type: "number", currency: "VES" },
  { field: "over90", header: ">90 dias", width: 120, type: "number", currency: "VES" },
  { field: "total", header: "Total", width: 140, type: "number", currency: "VES" },
];

const TAX_COLS: ColumnDef[] = [
  { field: "taxType", header: "Tipo", width: 100 },
  { field: "taxName", header: "Impuesto", flex: 1, minWidth: 200, sortable: true },
  { field: "base", header: "Base imponible", width: 150, type: "number", currency: "VES" },
  { field: "taxAmount", header: "Monto impuesto", width: 150, type: "number", currency: "VES" },
  { field: "total", header: "Total", width: 150, type: "number", currency: "VES" },
];

// ---- Main Component ----
export default function ReportesAvanzadosPage() {
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);

  const [tab, setTab] = useState(0);
  const [reportSearch, setReportSearch] = useState("");
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [run, setRun] = useState(false);
  const [agingSubTab, setAgingSubTab] = useState(0);
  const [drillDown, setDrillDown] = useState<{ accountCode: string; accountName?: string } | null>(null);
  const [registered, setRegistered] = useState(false);

  // Grid refs for tabs 0,1,2,6(cxc),6(cxp),8
  const diarioRef = useRef<any>(null);
  const mayorRef = useRef<any>(null);
  const balanceRef = useRef<any>(null);
  const agingCxCRef = useRef<any>(null);
  const agingCxPRef = useRef<any>(null);
  const taxRef = useRef<any>(null);

  const libroDiario = useLibroDiario(fechaDesde, fechaHasta, run && tab === 0);
  const libroMayor = useLibroMayor(fechaDesde, fechaHasta, run && tab === 1);
  const balance = useBalanceComprobacion(fechaDesde, fechaHasta, run && tab === 2);
  const resultado = useEstadoResultados(fechaDesde, fechaHasta, run && tab === 3);
  const balanceGral = useBalanceGeneral(fechaCorte, run && tab === 4);
  const cashFlow = useCashFlowReport(fechaDesde, fechaHasta, run && tab === 5);
  const agingCxC = useAgingCxC(fechaCorte, run && tab === 6 && agingSubTab === 0);
  const agingCxP = useAgingCxP(fechaCorte, run && tab === 6 && agingSubTab === 1);
  const ratios = useFinancialRatios(fechaCorte, run && tab === 7);
  const taxSummary = useTaxSummary(fechaDesde, fechaHasta, run && tab === 8);

  const needsRange = [0, 1, 2, 3, 5, 8].includes(tab);
  const needsCorte = [4, 6, 7].includes(tab);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  // Bind grids
  useEffect(() => { const el = diarioRef.current; if (!el || !registered || tab !== 0 || !run) return; el.columns = DIARIO_COLS; el.rows = (libroDiario.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i })); el.loading = libroDiario.isLoading; }, [libroDiario.data, libroDiario.isLoading, registered, tab, run]);
  useEffect(() => { const el = mayorRef.current; if (!el || !registered || tab !== 1 || !run) return; el.columns = MAYOR_COLS; el.rows = (libroMayor.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i })); el.loading = libroMayor.isLoading; }, [libroMayor.data, libroMayor.isLoading, registered, tab, run]);
  useEffect(() => { const el = balanceRef.current; if (!el || !registered || tab !== 2 || !run) return; el.columns = BALANCE_COLS; el.rows = (balance.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i })); el.loading = balance.isLoading; }, [balance.data, balance.isLoading, registered, tab, run]);
  useEffect(() => { const el = agingCxCRef.current; if (!el || !registered || tab !== 6 || agingSubTab !== 0 || !run) return; el.columns = AGING_COLS; el.rows = ((agingCxC.data?.data ?? agingCxC.data?.rows ?? []) as AgingBucket[]).map((r, i) => ({ ...r, id: i })); el.loading = agingCxC.isLoading; }, [agingCxC.data, agingCxC.isLoading, registered, tab, agingSubTab, run]);
  useEffect(() => { const el = agingCxPRef.current; if (!el || !registered || tab !== 6 || agingSubTab !== 1 || !run) return; el.columns = AGING_COLS; el.rows = ((agingCxP.data?.data ?? agingCxP.data?.rows ?? []) as AgingBucket[]).map((r, i) => ({ ...r, id: i })); el.loading = agingCxP.isLoading; }, [agingCxP.data, agingCxP.isLoading, registered, tab, agingSubTab, run]);
  useEffect(() => { const el = taxRef.current; if (!el || !registered || tab !== 8 || !run) return; el.columns = TAX_COLS; const txRows = (taxSummary.data?.data ?? taxSummary.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i })); el.rows = txRows; el.loading = taxSummary.isLoading; }, [taxSummary.data, taxSummary.isLoading, registered, tab, run]);

  const renderNotRun = () => <Alert severity="info">Seleccione el rango y presione &quot;Generar&quot;</Alert>;
  const renderLoading = () => <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>;
  const renderError = (err: unknown) => <Alert severity="error">Error: {String(err)}</Alert>;

  if (!registered) return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ZenttoFilterPanel filters={[] as FilterFieldDef[]} values={{}} onChange={() => {}} searchPlaceholder="Buscar en reportes avanzados..." searchValue={reportSearch} onSearchChange={setReportSearch} />
      <Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
        <Tabs value={tab} onChange={(_, v) => { setTab(v); setRun(false); }} variant="scrollable" scrollButtons="auto" sx={{ "& .MuiTab-root": { minWidth: "auto", px: 1.5 } }}>
          <Tab label="Libro diario" /><Tab label="Libro mayor" /><Tab label="Balance comp." /><Tab label="Estado result." /><Tab label="Balance general" /><Tab label="Flujo efectivo" /><Tab label="Aging CxC/CxP" /><Tab label="Ratios" /><Tab label="Fiscal" />
        </Tabs>
        {run && (
          <Stack direction="row" spacing={0.5} sx={{ "@media print": { display: "none" } }}>
            <Tooltip title="Imprimir"><IconButton onClick={() => window.print()}><PrintIcon /></IconButton></Tooltip>
          </Stack>
        )}
      </Stack>
      <FormGrid spacing={2} sx={{ mt: 1, mb: 2, "@media print": { display: "none" } }}>
        {needsRange && (<>
          <FormField xs={12} sm={4} md={3}><DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>
          <FormField xs={12} sm={4} md={3}><DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>
        </>)}
        {needsCorte && <FormField xs={12} sm={4} md={3}><DatePicker label="Fecha de Corte" value={fechaCorte ? dayjs(fechaCorte) : null} onChange={(v) => setFechaCorte(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} /></FormField>}
        <FormField xs={12} sm="auto"><Button variant="contained" onClick={() => setRun(true)}>Generar</Button></FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        {/* Tab 0-2: Grids */}
        {[0,1,2].map((idx) => {
          const refs = [diarioRef, mayorRef, balanceRef];
          const queries = [libroDiario, libroMayor, balance];
          return (
            <TabPanel key={idx} value={tab} index={idx}>
              {!run ? renderNotRun() : queries[idx].isLoading ? renderLoading() : queries[idx].error ? renderError(queries[idx].error)
              : <zentto-grid ref={refs[idx]} default-currency="VES" height="100%" show-totals
                  enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>}
            </TabPanel>
          );
        })}

        {/* Tab 3: Estado Resultados (narrative) */}
        <TabPanel value={tab} index={3}>
          {!run ? renderNotRun() : resultado.isLoading ? renderLoading() : resultado.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              <SectionHeader title="INGRESOS" total={resultado.data.resumen?.ingresos} />
              {(resultado.data.detalle ?? []).filter((item: any) => item.tipo === "I").map((item: any, i: number) => (
                <Stack key={`i-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0" sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                  onClick={() => setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })}>
                  <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                  <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                  <Stack direction="row" alignItems="center" spacing={0.5}><Typography variant="body2" fontWeight={500}>{formatCurrency(item.monto ?? item.saldo ?? 0)}</Typography><ZoomInIcon sx={{ fontSize: 14, color: "text.secondary" }} /></Stack>
                </Stack>
              ))}
              <Box my={2} />
              <SectionHeader title="COSTOS Y GASTOS" total={resultado.data.resumen?.gastos} />
              {(resultado.data.detalle ?? []).filter((item: any) => item.tipo === "G").map((item: any, i: number) => (
                <Stack key={`g-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0" sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                  onClick={() => setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })}>
                  <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                  <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                  <Stack direction="row" alignItems="center" spacing={0.5}><Typography variant="body2" fontWeight={500}>{formatCurrency(item.monto ?? item.saldo ?? 0)}</Typography><ZoomInIcon sx={{ fontSize: 14, color: "text.secondary" }} /></Stack>
                </Stack>
              ))}
              <Divider sx={{ my: 2, borderWidth: 2 }} />
              <Stack direction="row" justifyContent="space-between" py={1.5} px={1} sx={{ bgcolor: (resultado.data.resumen?.resultado ?? 0) >= 0 ? "success.light" : "error.light", borderRadius: 1 }}>
                <Typography variant="h6" fontWeight={700}>{(resultado.data.resumen?.resultado ?? 0) >= 0 ? "UTILIDAD NETA" : "PERDIDA NETA"}</Typography>
                <Typography variant="h6" fontWeight={700}>{formatCurrency(Math.abs(resultado.data.resumen?.resultado ?? 0))}</Typography>
              </Stack>
            </Box>
          ) : renderNotRun()}
        </TabPanel>

        {/* Tab 4: Balance General (narrative) */}
        <TabPanel value={tab} index={4}>
          {!run ? renderNotRun() : balanceGral.isLoading ? renderLoading() : balanceGral.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              {["A","P","C"].map((tipo, si) => {
                const titles: Record<string,string> = { A: "ACTIVOS", P: "PASIVOS", C: "PATRIMONIO" };
                const totals: Record<string,string> = { A: "totalActivo", P: "totalPasivo", C: "totalPatrimonio" };
                return (<React.Fragment key={tipo}>{si > 0 && <Box my={2} />}<SectionHeader title={titles[tipo]} total={balanceGral.data.resumen?.[totals[tipo]]} />
                  {(balanceGral.data.detalle ?? []).filter((item: any) => item.tipo === tipo).map((item: any, i: number) => (
                    <Stack key={`${tipo}-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0" sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                      onClick={() => setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })}>
                      <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>{item.codCuenta}</Typography>
                      <Typography variant="body2" sx={{ flex: 1 }}>{item.cuenta || item.descripcion}</Typography>
                      <Typography variant="body2" fontWeight={500}>{formatCurrency(item.saldo ?? 0)}</Typography>
                    </Stack>
                  ))}</React.Fragment>);
              })}
              <Divider sx={{ my: 2, borderWidth: 2 }} />
              <Stack spacing={1}>
                <Stack direction="row" justifyContent="space-between" px={1}><Typography variant="subtitle1" fontWeight={700}>Total Activos</Typography><Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalActivo ?? 0)}</Typography></Stack>
                <Stack direction="row" justifyContent="space-between" px={1}><Typography variant="subtitle1" fontWeight={700}>Total Pasivo + Patrimonio</Typography><Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0)}</Typography></Stack>
                <Box sx={{ bgcolor: "primary.light", borderRadius: 1, p: 1 }}><Stack direction="row" justifyContent="space-between"><Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">Diferencia (debe ser 0)</Typography><Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">{formatCurrency((balanceGral.data.resumen?.totalActivo ?? 0) - (balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0))}</Typography></Stack></Box>
              </Stack>
            </Box>
          ) : renderNotRun()}
        </TabPanel>

        {/* Tab 5: Flujo de Efectivo */}
        <TabPanel value={tab} index={5}>
          {!run ? renderNotRun() : cashFlow.isLoading ? renderLoading() : cashFlow.error ? renderError(cashFlow.error) : (
            <Box p={2} sx={{ overflow: "auto" }}>
              {(() => {
                const sections: CashFlowSection[] = cashFlow.data?.data ?? cashFlow.data?.sections ?? cashFlow.data?.rows ?? [];
                if (sections.length === 0) return <Alert severity="info">No hay datos de flujo de efectivo</Alert>;
                let grandTotal = 0;
                return (<>{sections.map((section, idx) => { grandTotal += section.total ?? 0; return (<Box key={idx} sx={{ mb: 3 }}><SectionHeader title={section.section} total={section.total} />
                  {(section.items ?? []).map((item, i) => (<Stack key={i} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                    <Typography variant="body2">{item.description}</Typography><Typography variant="body2" fontWeight={500} sx={{ color: item.amount >= 0 ? "success.main" : "error.main" }}>{formatCurrency(item.amount)}</Typography>
                  </Stack>))}</Box>); })}
                  <Divider sx={{ my: 2, borderWidth: 2 }} /><Stack direction="row" justifyContent="space-between" px={1}><Typography variant="h6" fontWeight={700}>Variacion Neta de Efectivo</Typography>
                  <Typography variant="h6" fontWeight={700} sx={{ color: grandTotal >= 0 ? "success.main" : "error.main" }}>{formatCurrency(grandTotal)}</Typography></Stack></>);
              })()}
            </Box>
          )}
        </TabPanel>

        {/* Tab 6: Aging */}
        <TabPanel value={tab} index={6}>
          {!run ? renderNotRun() : (<Box>
            <Tabs value={agingSubTab} onChange={(_, v) => setAgingSubTab(v)} sx={{ mb: 2 }}><Tab label="Cuentas por cobrar" /><Tab label="Cuentas por pagar" /></Tabs>
            {agingSubTab === 0 && (agingCxC.isLoading ? renderLoading() : agingCxC.error ? renderError(agingCxC.error)
              : <Box sx={{ height: 400 }}><zentto-grid ref={agingCxCRef} default-currency="VES" height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid></Box>)}
            {agingSubTab === 1 && (agingCxP.isLoading ? renderLoading() : agingCxP.error ? renderError(agingCxP.error)
              : <Box sx={{ height: 400 }}><zentto-grid ref={agingCxPRef} default-currency="VES" height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid></Box>)}
          </Box>)}
        </TabPanel>

        {/* Tab 7: Ratios */}
        <TabPanel value={tab} index={7}>
          {!run ? renderNotRun() : ratios.isLoading ? renderLoading() : ratios.error ? renderError(ratios.error) : (
            <Box p={2}>{(() => {
              const ratioList: FinancialRatio[] = ratios.data?.data ?? ratios.data?.rows ?? [];
              if (ratioList.length === 0) return <Alert severity="info">No hay datos de ratios financieros</Alert>;
              const categories = new Map<string, FinancialRatio[]>();
              for (const r of ratioList) { const cat = r.category || "General"; if (!categories.has(cat)) categories.set(cat, []); categories.get(cat)!.push(r); }
              return Array.from(categories.entries()).map(([cat, items]) => (<Box key={cat} sx={{ mb: 3 }}><Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1.5 }}>{cat}</Typography>
                <Grid container spacing={2}>{items.map((ratio, i) => (<Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }} key={i}><RatioGauge ratio={ratio} /></Grid>))}</Grid></Box>));
            })()}</Box>
          )}
        </TabPanel>

        {/* Tab 8: Fiscal */}
        <TabPanel value={tab} index={8}>
          {!run ? renderNotRun() : taxSummary.isLoading ? renderLoading() : taxSummary.error ? renderError(taxSummary.error) : (
            <Box>{(() => {
              const txRows: TaxSummaryRow[] = (taxSummary.data?.data ?? taxSummary.data?.rows ?? []).map((r: any, i: number) => ({ ...r, id: i }));
              if (txRows.length === 0) return <Alert severity="info">No hay datos fiscales para este periodo</Alert>;
              const totalBase = txRows.reduce((s, r) => s + (r.base ?? 0), 0);
              const totalTax = txRows.reduce((s, r) => s + (r.taxAmount ?? 0), 0);
              const totalTotal = txRows.reduce((s, r) => s + (r.total ?? 0), 0);
              return (<>
                <Grid container spacing={2} sx={{ mb: 3 }}>
                  {[{ val: totalBase, label: "Base Imponible Total", color: "#1565c0" }, { val: totalTax, label: "Total Impuestos", color: "#e65100" }, { val: totalTotal, label: "Total con Impuesto", color: "#2e7d32" }].map((c, i) => (
                    <Grid key={i} size={{ xs: 4 }}><Card sx={{ borderRadius: 2, borderTop: `3px solid ${c.color}` }}><CardContent>
                      <Typography variant="h5" fontWeight={700} sx={{ color: c.color }}>{formatCurrency(c.val)}</Typography>
                      <Typography variant="body2" color="text.secondary">{c.label}</Typography>
                    </CardContent></Card></Grid>
                  ))}
                </Grid>
                <Box sx={{ height: 400 }}><zentto-grid ref={taxRef} default-currency="VES" height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid></Box>
              </>);
            })()}</Box>
          )}
        </TabPanel>
      </Paper>

      {drillDown && <DrillDownDialog open={!!drillDown} onClose={() => setDrillDown(null)} accountCode={drillDown.accountCode} accountName={drillDown.accountName} fechaDesde={fechaDesde} fechaHasta={fechaHasta} />}
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
