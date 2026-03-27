"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  Tab, Tabs, MenuItem, Select, FormControl, InputLabel,
} from "@mui/material";
import { DatePicker } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import PublishIcon from "@mui/icons-material/Publish";
import { formatCurrency, useCountries, useGridLayoutSync } from "@zentto/shared-api";
import {
  useObligationsList, useSaveObligation, useFilingsList, useGenerateFiling, useMarkFiled,
  type ObligationsFilter, type FilingsFilter, type SaveObligationInput, type GenerateFilingInput,
} from "../hooks/useRRHH";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

const OBL_COLUMNS: ColumnDef[] = [
  { field: "CountryCode", header: "País", width: 80 },
  { field: "Code", header: "Código", width: 120, sortable: true },
  { field: "Name", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "EmployeeRate", header: "% Empleado", width: 120 },
  { field: "EmployerRate", header: "% Patronal", width: 120 },
  { field: "FilingFrequency", header: "Frecuencia", width: 120, groupable: true },
  { field: "InstitutionName", header: "Entidad", width: 150 },
];

const FIL_COLUMNS: ColumnDef[] = [
  { field: "period", header: "Período", width: 150 },
  { field: "obligationName", header: "Obligación", flex: 1, minWidth: 200, sortable: true },
  { field: "employeeAmount", header: "Monto Empleado", width: 140, type: "number", aggregation: "sum" },
  { field: "employerAmount", header: "Monto Patronal", width: 140, type: "number", aggregation: "sum" },
  { field: "totalAmount", header: "Total", width: 130, type: "number", aggregation: "sum" },
  { field: "status", header: "Estado", width: 130, statusColors: { PRESENTADA: "success", GENERADA: "info", PENDIENTE: "warning" } },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: SVG_PUBLISH, label: "Generar declaracion", action: "generate", color: "#1976d2" },
      { icon: SVG_CHECK, label: "Marcar presentada", action: "mark", color: "#2e7d32" },
    ],
  },
];


const SVG_PUBLISH = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>';
const SVG_CHECK = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
const OBLIGACIONES_GRID_ID = buildNominaGridId("obligaciones", "main");
const DECLARACIONES_GRID_ID = buildNominaGridId("obligaciones", "declaraciones");

export default function ObligacionesPage() {
  const oblGridRef = useRef<any>(null);
  const filGridRef = useRef<any>(null);
  const { data: countries = [] } = useCountries();
  const [tab, setTab] = useState(0);
  const [oblFilter, setOblFilter] = useState<ObligationsFilter>({ page: 1, limit: 25 });
  const [filFilter, setFilFilter] = useState<FilingsFilter>({ page: 1, limit: 25 });
  const [oblDialogOpen, setOblDialogOpen] = useState(false);
  const [filDialogOpen, setFilDialogOpen] = useState(false);
  const [oblForm, setOblForm] = useState<SaveObligationInput>({ code: "", name: "", countryCode: "", employeeRate: 0, employerRate: 0, frequency: "MENSUAL" });
  const [filForm, setFilForm] = useState<GenerateFilingInput>({ obligationCode: "", periodFrom: "", periodTo: "" });

  const { data: oblData, isLoading: oblLoading } = useObligationsList(oblFilter);
  const { data: filData, isLoading: filLoading } = useFilingsList(filFilter);
  const saveOblMutation = useSaveObligation();
  const generateFilMutation = useGenerateFiling();
  const markFiledMutation = useMarkFiled();
  const { ready: obligacionesLayoutReady } = useGridLayoutSync(OBLIGACIONES_GRID_ID);
  const { ready: declaracionesLayoutReady } = useGridLayoutSync(DECLARACIONES_GRID_ID);
  const { registered } = useNominaGridRegistration(obligacionesLayoutReady && declaracionesLayoutReady);

  const oblRows = oblData?.data ?? oblData?.rows ?? [];
  const filRows = filData?.data ?? filData?.rows ?? [];
  useNominaGridId(oblGridRef, OBLIGACIONES_GRID_ID);
  useNominaGridId(filGridRef, DECLARACIONES_GRID_ID);

  useEffect(() => {
    const el = oblGridRef.current; if (!el || !registered) return;
    el.columns = OBL_COLUMNS; el.rows = oblRows; el.loading = oblLoading;
    el.getRowId = (r: any) => r.LegalObligationId ?? r.Code;
  }, [oblRows, oblLoading, registered]);

  useEffect(() => {
    const el = filGridRef.current; if (!el || !registered) return;
    el.columns = FIL_COLUMNS; el.rows = filRows; el.loading = filLoading;
    el.getRowId = (r: any) => r.id ?? `${r.obligationCode}-${r.period}`;
  }, [filRows, filLoading, registered]);

  useEffect(() => {
    const el = filGridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "generate" && row.status === "PENDIENTE") { setFilForm({ obligationCode: row.obligationCode, periodFrom: "", periodTo: "" }); setFilDialogOpen(true); }
      if (action === "mark" && row.status !== "PRESENTADA") markFiledMutation.mutate({ filingId: row.id });
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, filRows]);

  const handleSaveObligation = async () => { await saveOblMutation.mutateAsync(oblForm); setOblDialogOpen(false); setOblForm({ code: "", name: "", countryCode: "", employeeRate: 0, employerRate: 0, frequency: "MENSUAL" }); };
  const handleGenerateFiling = async () => { await generateFilMutation.mutateAsync(filForm); setFilDialogOpen(false); setFilForm({ obligationCode: "", periodFrom: "", periodTo: "" }); };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Obligaciones Legales</Typography>
        <Stack direction="row" spacing={1}>
          {tab === 0 && <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOblDialogOpen(true)}>Nueva Obligación</Button>}
          {tab === 1 && <Button variant="contained" startIcon={<PublishIcon />} onClick={() => setFilDialogOpen(true)}>Generar Declaración</Button>}
        </Stack>
      </Stack>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
        <Tab label="Obligaciones" /><Tab label="Declaraciones" />
      </Tabs>

      <TabPanel value={tab} index={0}>
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid ref={oblGridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
        </Box>
      </TabPanel>

      <TabPanel value={tab} index={1}>
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid ref={filGridRef} height="calc(100vh - 200px)" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
        </Box>
      </TabPanel>

      {/* New Obligation Dialog */}
      <Dialog open={oblDialogOpen} onClose={() => setOblDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Obligación Legal</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Código" fullWidth value={oblForm.code} onChange={(e) => setOblForm((f) => ({ ...f, code: e.target.value }))} />
            <TextField label="Nombre" fullWidth value={oblForm.name} onChange={(e) => setOblForm((f) => ({ ...f, name: e.target.value }))} />
            <FormControl fullWidth><InputLabel>País</InputLabel>
              <Select value={oblForm.countryCode} label="País" onChange={(e) => setOblForm((f) => ({ ...f, countryCode: e.target.value }))}>
                {countries.map(c => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
              </Select>
            </FormControl>
            <TextField label="% Empleado" type="number" fullWidth value={oblForm.employeeRate || ""} onChange={(e) => setOblForm((f) => ({ ...f, employeeRate: Number(e.target.value) }))} />
            <TextField label="% Patronal" type="number" fullWidth value={oblForm.employerRate || ""} onChange={(e) => setOblForm((f) => ({ ...f, employerRate: Number(e.target.value) }))} />
            <FormControl fullWidth><InputLabel>Frecuencia</InputLabel>
              <Select value={oblForm.frequency || "MENSUAL"} label="Frecuencia" onChange={(e) => setOblForm((f) => ({ ...f, frequency: e.target.value }))}>
                <MenuItem value="MENSUAL">Mensual</MenuItem><MenuItem value="TRIMESTRAL">Trimestral</MenuItem><MenuItem value="ANUAL">Anual</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Descripción" fullWidth multiline rows={2} value={oblForm.description || ""} onChange={(e) => setOblForm((f) => ({ ...f, description: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOblDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSaveObligation} disabled={saveOblMutation.isPending}>Guardar</Button>
        </DialogActions>
      </Dialog>

      {/* Generate Filing Dialog */}
      <Dialog open={filDialogOpen} onClose={() => setFilDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Generar Declaración</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Código Obligación" fullWidth value={filForm.obligationCode} onChange={(e) => setFilForm((f) => ({ ...f, obligationCode: e.target.value }))} />
            <DatePicker label="Período Desde" value={filForm.periodFrom ? dayjs(filForm.periodFrom) : null} onChange={(v) => setFilForm((f) => ({ ...f, periodFrom: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <DatePicker label="Período Hasta" value={filForm.periodTo ? dayjs(filForm.periodTo) : null} onChange={(v) => setFilForm((f) => ({ ...f, periodTo: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFilDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleGenerateFiling} disabled={generateFilMutation.isPending}>Generar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
