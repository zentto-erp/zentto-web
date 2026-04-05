"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, TextField, Chip, Dialog, DialogTitle, DialogContent,
  DialogActions, Stack, CircularProgress, Alert, Tab, Tabs,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync, formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useInflationIndices, useUpsertInflationIndex, useMonetaryClassifications, useUpsertMonetaryClass,
  useAutoClassifyAccounts, useCalculateInflation, usePostInflation, useVoidInflation,
  type InflationIndex, type MonetaryClassification,
} from "../hooks/useContabilidadLegal";


function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
const INDICES_COLUMNS: ColumnDef[] = [
  { field: "PeriodCode", header: "Periodo", width: 120, sortable: true },
  { field: "IndexValue", header: "Valor Indice", width: 150, type: "number" },
  { field: "SourceReference", header: "Fuente / Referencia", flex: 1, minWidth: 200 },
];

const CLASIFICACION_COLUMNS: ColumnDef[] = [
  { field: "AccountCode", header: "Codigo", width: 120, sortable: true },
  { field: "AccountName", header: "Cuenta", flex: 1, minWidth: 200, sortable: true },
  { field: "AccountType", header: "Tipo", width: 120, sortable: true, groupable: true },
  { field: "Classification", header: "Clasificacion", width: 180, sortable: true, statusColors: { MONETARY: "info", NON_MONETARY: "warning" } },
];

const CALC_PREVIEW_COLUMNS: ColumnDef[] = [
  { field: "AccountCode", header: "Cuenta", width: 120 },
  { field: "AccountName", header: "Nombre", flex: 1, minWidth: 180 },
  { field: "HistoricalBalance", header: "Saldo historico", width: 150, type: "number", currency: "VES" },
  { field: "AdjustedBalance", header: "Saldo ajustado", width: 150, type: "number", currency: "VES" },
  { field: "AdjustmentAmount", header: "Ajuste", width: 140, type: "number", currency: "VES" },
];

const HISTORIAL_COLUMNS: ColumnDef[] = [
  { field: "InflationAdjustmentId", header: "ID", width: 70 },
  { field: "PeriodCode", header: "Periodo", width: 120, sortable: true },
  { field: "FiscalYear", header: "Ejercicio", width: 100, sortable: true },
  { field: "CalculatedAt", header: "Fecha calculo", width: 160 },
  { field: "TotalAdjustment", header: "Ajuste total", width: 160, type: "number", currency: "VES" },
  { field: "Status", header: "Estado", width: 130, statusColors: { POSTED: "success", DRAFT: "warning" } },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 80,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view", color: "#1976d2" },
    ],
  },
];

const GRID_IDS = {
  indicesGridRef: buildContabilidadGridId("inflacion-ajuste", "indices"),
  clasificacionGridRef: buildContabilidadGridId("inflacion-ajuste", "clasificacion"),
  calcGridRef: buildContabilidadGridId("inflacion-ajuste", "calc"),
  historialGridRef: buildContabilidadGridId("inflacion-ajuste", "historial"),
} as const;

export default function InflacionAjustePage() {
  const [tab, setTab] = useState(0);
  const indicesGridRef = useRef<any>(null);
  const clasificacionGridRef = useRef<any>(null);
  const calcGridRef = useRef<any>(null);
  const historialGridRef = useRef<any>(null);
    const { ready: indicesGridLayoutReady } = useGridLayoutSync(GRID_IDS.indicesGridRef);
  const { ready: clasificacionGridLayoutReady } = useGridLayoutSync(GRID_IDS.clasificacionGridRef);
  const { ready: calcGridLayoutReady } = useGridLayoutSync(GRID_IDS.calcGridRef);
  const { ready: historialGridLayoutReady } = useGridLayoutSync(GRID_IDS.historialGridRef);
  useContabilidadGridId(indicesGridRef, GRID_IDS.indicesGridRef);
  useContabilidadGridId(clasificacionGridRef, GRID_IDS.clasificacionGridRef);
  useContabilidadGridId(calcGridRef, GRID_IDS.calcGridRef);
  useContabilidadGridId(historialGridRef, GRID_IDS.historialGridRef);
  const layoutReady = indicesGridLayoutReady && clasificacionGridLayoutReady && calcGridLayoutReady && historialGridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);

  // Tab 0: Indices INPC
  const currentYear = new Date().getFullYear();
  const [indiceYear, setIndiceYear] = useState(currentYear);
  const [indiceDialogOpen, setIndiceDialogOpen] = useState(false);
  const [newIndice, setNewIndice] = useState({ periodCode: "", indexValue: "", sourceReference: "" });
  const indicesQuery = useInflationIndices("VE", indiceYear, indiceYear);
  const upsertIndiceMutation = useUpsertInflationIndex();
  const indicesRows: InflationIndex[] = indicesQuery.data?.data ?? indicesQuery.data?.rows ?? [];

  // Tab 1: Clasificacion Monetaria
  const [clasDialogRow, setClasDialogRow] = useState<MonetaryClassification | null>(null);
  const [clasNewValue, setClasNewValue] = useState<"MONETARY" | "NON_MONETARY">("MONETARY");
  const clasificacionQuery = useMonetaryClassifications(undefined, undefined);
  const upsertClasMutation = useUpsertMonetaryClass();
  const autoClassifyMutation = useAutoClassifyAccounts();
  const clasificacionRows: MonetaryClassification[] = clasificacionQuery.data?.data ?? clasificacionQuery.data?.rows ?? [];

  // Tab 2: Calcular Ajuste
  const [calcPeriod, setCalcPeriod] = useState("");
  const [calcFiscalYear, setCalcFiscalYear] = useState(currentYear);
  const calculateMutation = useCalculateInflation();
  const postMutation = usePostInflation();
  const calcResult = calculateMutation.data as any;
  const calcPreviewRows = calcResult?.data ?? calcResult?.rows ?? [];

  // Tab 3: Historial
  const [voidDialogId, setVoidDialogId] = useState<number | null>(null);
  const [voidMotivo, setVoidMotivo] = useState("");
  const voidMutation = useVoidInflation();
  const historialQuery = useInflationIndices("VE");
  const historialData = historialQuery.data as any;
  const historialRows = useMemo(() => { const raw = historialData?.adjustments ?? historialData?.data ?? []; return Array.isArray(raw) ? raw : []; }, [historialData]);

  // Bind indices grid
  useEffect(() => {
    const el = indicesGridRef.current;
    if (!el || !registered || tab !== 0) return;
    el.columns = INDICES_COLUMNS;
    el.rows = indicesRows.map((r: any) => ({ ...r, id: r.InflationIndexId ?? r.PeriodCode ?? r.id }));
    el.loading = indicesQuery.isLoading;
  }, [indicesRows, indicesQuery.isLoading, registered, tab]);

  // Bind clasificacion grid
  useEffect(() => {
    const el = clasificacionGridRef.current;
    if (!el || !registered || tab !== 1) return;
    el.columns = CLASIFICACION_COLUMNS;
    el.rows = clasificacionRows.map((r: any) => ({ ...r, id: r.AccountMonetaryClassId ?? r.AccountId ?? r.id }));
    el.loading = clasificacionQuery.isLoading;
  }, [clasificacionRows, clasificacionQuery.isLoading, registered, tab]);

  // Bind calc preview grid
  useEffect(() => {
    const el = calcGridRef.current;
    if (!el || !registered || tab !== 2 || calcPreviewRows.length === 0) return;
    el.columns = CALC_PREVIEW_COLUMNS;
    el.rows = calcPreviewRows.map((r: any) => ({ ...r, id: r.AccountCode ?? r.AccountId ?? r.id }));
  }, [calcPreviewRows, registered, tab]);

  // Bind historial grid
  useEffect(() => {
    const el = historialGridRef.current;
    if (!el || !registered || tab !== 3) return;
    el.columns = HISTORIAL_COLUMNS;
    el.rows = historialRows.map((r: any) => ({ ...r, id: r.InflationAdjustmentId ?? r.id }));
    el.loading = historialQuery.isLoading;
  }, [historialRows, historialQuery.isLoading, registered, tab]);

  useEffect(() => {
    const el = historialGridRef.current;
    if (!el || !registered || tab !== 3) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") {
        const id = row.InflationAdjustmentId ?? row.id;
        console.log("Ver ajuste inflacion:", id, row);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, tab]);

  const handleSaveIndice = async () => {
    if (!newIndice.periodCode || !newIndice.indexValue) return;
    await upsertIndiceMutation.mutateAsync({ countryCode: "VE", indexName: "INPC", periodCode: newIndice.periodCode, indexValue: Number(newIndice.indexValue), sourceReference: newIndice.sourceReference || undefined });
    setIndiceDialogOpen(false); setNewIndice({ periodCode: "", indexValue: "", sourceReference: "" });
  };

  const handleSaveClasificacion = async () => {
    if (!clasDialogRow) return;
    await upsertClasMutation.mutateAsync({ accountId: clasDialogRow.AccountId, classification: clasNewValue });
    setClasDialogRow(null);
  };

  const handleCalculate = () => { if (!calcPeriod || !calcFiscalYear) return; calculateMutation.mutate({ periodCode: calcPeriod, fiscalYear: calcFiscalYear }); };
  const handlePost = () => { const id = calcResult?.InflationAdjustmentId ?? calcResult?.id; if (!id) return; postMutation.mutate(id); };
  const handleVoid = async () => { if (!voidDialogId) return; await voidMutation.mutateAsync({ id: voidDialogId, motivo: voidMotivo || undefined }); setVoidDialogId(null); setVoidMotivo(""); };

  if (!registered) { return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>; }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Ajuste por Inflacion" />
      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Stack direction="row" alignItems="center" spacing={1} mb={1}>
          <Chip label="BA VEN-NIF 2 / NIC 29 / DPC-10" color="primary" size="small" variant="outlined" />
        </Stack>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}>
            <Tab label="Indices INPC" /><Tab label="Clasificacion monetaria" /><Tab label="Calcular ajuste" /><Tab label="Historial" />
          </Tabs>

          {/* Tab 0: Indices INPC */}
          <TabPanel value={tab} index={0}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ px: 2, py: 1 }}>
              <TextField label="Ano" type="number" value={indiceYear} onChange={(e) => setIndiceYear(Number(e.target.value))} sx={{ width: 120 }} size="small" />
              <Button variant="contained" size="small" onClick={() => setIndiceDialogOpen(true)}>Agregar Indice</Button>
            </Stack>
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              <zentto-grid ref={indicesGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
            </Box>
          </TabPanel>

          {/* Tab 1: Clasificacion Monetaria */}
          <TabPanel value={tab} index={1}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ px: 2, pt: 2, pb: 1 }}>
              <Button variant="outlined" size="small" onClick={() => autoClassifyMutation.mutate()} disabled={autoClassifyMutation.isPending}>
                {autoClassifyMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}Auto-clasificar
              </Button>
            </Stack>
            {autoClassifyMutation.isSuccess && <Alert severity="success" sx={{ mx: 2, mb: 1 }}>Clasificacion automatica completada.</Alert>}
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              <zentto-grid ref={clasificacionGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
            </Box>
          </TabPanel>

          {/* Tab 2: Calcular Ajuste */}
          <TabPanel value={tab} index={2}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
              <TextField label="Periodo (YYYYMM)" value={calcPeriod} onChange={(e) => setCalcPeriod(e.target.value)} placeholder="202601" sx={{ width: 180 }} />
              <TextField label="Ejercicio fiscal" type="number" value={calcFiscalYear} onChange={(e) => setCalcFiscalYear(Number(e.target.value))} sx={{ width: 150 }} />
              <Button variant="contained" size="small" onClick={handleCalculate} disabled={calculateMutation.isPending || !calcPeriod}>
                {calculateMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}Calcular
              </Button>
              {calcPreviewRows.length > 0 && (
                <Button variant="contained" color="success" size="small" onClick={handlePost} disabled={postMutation.isPending}>
                  {postMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}Publicar
                </Button>
              )}
              <Chip label="BA VEN-NIF 2 / NIC 29" size="small" color="secondary" variant="outlined" />
            </Stack>
            {calculateMutation.isError && <Alert severity="error" sx={{ mx: 2, mb: 1 }}>Error al calcular: {(calculateMutation.error as any)?.message ?? "Error desconocido"}</Alert>}
            {postMutation.isSuccess && <Alert severity="success" sx={{ mx: 2, mb: 1 }}>Ajuste publicado exitosamente.</Alert>}
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              {calcPreviewRows.length > 0 ? (
                <zentto-grid ref={calcGridRef} default-currency="VES" height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", minHeight: 200 }}>
                  <Typography color="text.secondary">Seleccione periodo y ejercicio fiscal, luego presione &quot;Calcular&quot; para generar la vista previa del ajuste.</Typography>
                </Box>
              )}
            </Box>
          </TabPanel>

          {/* Tab 3: Historial */}
          <TabPanel value={tab} index={3}>
            <Box sx={{ flex: 1, minHeight: 0, p: 2 }}>
              <zentto-grid ref={historialGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
            </Box>
          </TabPanel>
        </Paper>
      </Box>

      {/* Dialog: Agregar Indice INPC */}
      <Dialog open={indiceDialogOpen} onClose={() => setIndiceDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Agregar Indice INPC</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Periodo (YYYYMM)" fullWidth value={newIndice.periodCode} onChange={(e) => setNewIndice((v) => ({ ...v, periodCode: e.target.value }))} placeholder="202601" />
            <TextField label="Valor del Indice" type="number" fullWidth value={newIndice.indexValue} onChange={(e) => setNewIndice((v) => ({ ...v, indexValue: e.target.value }))} />
            <TextField label="Fuente / Referencia" fullWidth value={newIndice.sourceReference} onChange={(e) => setNewIndice((v) => ({ ...v, sourceReference: e.target.value }))} placeholder="Gaceta Oficial N..." />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIndiceDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSaveIndice} disabled={upsertIndiceMutation.isPending || !newIndice.periodCode || !newIndice.indexValue}>Guardar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Cambiar Clasificacion Monetaria */}
      <Dialog open={clasDialogRow != null} onClose={() => setClasDialogRow(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Clasificacion monetaria</DialogTitle>
        <DialogContent>
          {clasDialogRow && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Typography variant="body2"><strong>Cuenta:</strong> {clasDialogRow.AccountCode} - {clasDialogRow.AccountName}</Typography>
              <Stack direction="row" spacing={1}>
                <Button variant={clasNewValue === "MONETARY" ? "contained" : "outlined"} size="small" onClick={() => setClasNewValue("MONETARY")}>Monetaria</Button>
                <Button variant={clasNewValue === "NON_MONETARY" ? "contained" : "outlined"} size="small" onClick={() => setClasNewValue("NON_MONETARY")}>No monetaria</Button>
              </Stack>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setClasDialogRow(null)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSaveClasificacion} disabled={upsertClasMutation.isPending}>Guardar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Anular Ajuste */}
      <Dialog open={voidDialogId != null} onClose={() => setVoidDialogId(null)}>
        <DialogTitle>Anular ajuste #{voidDialogId}</DialogTitle>
        <DialogContent>
          <TextField label="Motivo de anulacion" fullWidth multiline rows={3} value={voidMotivo} onChange={(e) => setVoidMotivo(e.target.value)} sx={{ mt: 1 }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setVoidDialogId(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleVoid} disabled={voidMutation.isPending}>Anular</Button>
        </DialogActions>
      </Dialog>
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
