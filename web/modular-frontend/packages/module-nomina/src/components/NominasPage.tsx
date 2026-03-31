"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Chip, Dialog, DialogTitle, DialogContent, DialogActions,
  Stack, CircularProgress, Switch, FormControlLabel,
} from "@mui/material";
import { DatePicker, ContextActionHeader } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import { formatCurrency } from "@zentto/shared-api";
import {
  useNominasList, useNominaDetalle, useProcesarNominaCompleta, useCerrarNomina, type NominaFilter,
} from "../hooks/useNomina";
import NominaBatchWizard from "./NominaBatchWizard";
import { useGridLayoutSync } from "@zentto/shared-api";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const SVG_LOCK = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';

const COLUMNS: ColumnDef[] = [
  { field: "nomina", header: "Nómina", width: 120, sortable: true, groupable: true },
  { field: "cedula", header: "Cédula", width: 120, sortable: true },
  { field: "nombreEmpleado", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "fechaInicio", header: "Desde", width: 110 },
  { field: "fechaHasta", header: "Hasta", width: 110 },
  { field: "totalAsignaciones", header: "Asignaciones", width: 130, type: "number", aggregation: "sum" },
  { field: "totalDeducciones", header: "Deducciones", width: 130, type: "number", aggregation: "sum" },
  { field: "totalNeto", header: "Neto", width: 130, type: "number", aggregation: "sum" },
  { field: "cerrada", header: "Estado", width: 100, statusColors: { true: "default", false: "success" } },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver nómina", action: "view" },
      { icon: SVG_LOCK, label: "Cerrar nómina", action: "close", color: "#ed6c02" },
    ],
  },
];

const DETAIL_COLUMNS: ColumnDef[] = [
  { field: "concepto", header: "Concepto", flex: 1, minWidth: 200 },
  { field: "tipo", header: "Tipo", width: 120, statusColors: { ASIGNACION: "success", DEDUCCION: "error" }, statusVariant: "outlined" },
  { field: "monto", header: "Monto", width: 130, type: "number" },
];

const NOMINAS_GRID_ID = buildNominaGridId("nominas");
const NOMINAS_DETAIL_GRID_ID = buildNominaGridId("nominas", "detalle");

export default function NominasPage() {
  const gridRef = useRef<any>(null);
  const detalleGridRef = useRef<any>(null);
  const [filter, setFilter] = useState<NominaFilter>({ page: 1, limit: 25 });
  const [selectedNomina, setSelectedNomina] = useState<string | null>(null);
  const [selectedCedula, setSelectedCedula] = useState<string | null>(null);
  const [procesarOpen, setProcesarOpen] = useState(false);
  const [view, setView] = useState<"list" | "batch">("list");
  const [procesarData, setProcesarData] = useState({ nomina: "", fechaInicio: "", fechaHasta: "", soloActivos: true });

  const { data, isLoading } = useNominasList(filter);
  const detalle = useNominaDetalle(selectedNomina, selectedCedula);
  const procesarMutation = useProcesarNominaCompleta();
  const cerrarMutation = useCerrarNomina();
  const { ready: nominasLayoutReady } = useGridLayoutSync(NOMINAS_GRID_ID);
  const { ready: detalleLayoutReady } = useGridLayoutSync(NOMINAS_DETAIL_GRID_ID);
  const { registered } = useNominaGridRegistration(nominasLayoutReady && detalleLayoutReady);

  const rows = data?.data ?? data?.rows ?? [];
  useNominaGridId(gridRef, NOMINAS_GRID_ID);
  useNominaGridId(detalleGridRef, NOMINAS_DETAIL_GRID_ID);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => `${r.nomina}-${r.cedula}-${r.fechaInicio ?? Math.random()}`;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") { setSelectedNomina(row.nomina); setSelectedCedula(row.cedula); }
      if (action === "close" && row.estado !== "CERRADA") cerrarMutation.mutate({ nomina: row.nomina, cedula: row.cedula });
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  // Detalle grid in dialog
  useEffect(() => {
    const el = detalleGridRef.current; if (!el || !registered || !selectedNomina) return;
    const detalleRows = ((detalle.data?.detalle ?? []) as any[]).map((d: any, i: number) => ({ ...d, _id: i }));
    el.columns = DETAIL_COLUMNS; el.rows = detalleRows; el.loading = detalle.isLoading;
    el.getRowId = (r: any) => r._id;
  }, [detalle.data, detalle.isLoading, registered, selectedNomina]);

  const handleProcesar = async () => { await procesarMutation.mutateAsync(procesarData); setProcesarOpen(false); };

  if (view === "batch") return <NominaBatchWizard onBack={() => setView("list")} />;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Procesos de Nómina"
        primaryAction={{ label: "Nómina Masiva", onClick: () => setView("batch") }}
        secondaryActions={[{ label: "Procesar Individual", onClick: () => setProcesarOpen(true) }]}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid ref={gridRef} height="calc(100vh - 200px)" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
        </Box>

        {/* Detalle Dialog */}
        <Dialog open={selectedNomina != null} onClose={() => { setSelectedNomina(null); setSelectedCedula(null); }} maxWidth="md" fullWidth>
          <DialogTitle>Detalle de Nómina</DialogTitle>
          <DialogContent>
            {detalle.isLoading ? <CircularProgress /> : detalle.data?.cabecera ? (
              <Box>
                <Typography variant="body2" mb={1}><strong>Empleado:</strong> {detalle.data.cabecera.nombre} ({detalle.data.cabecera.cedula})</Typography>
                <Typography variant="body2" mb={2}><strong>Período:</strong> {detalle.data.cabecera.fechaInicio} - {detalle.data.cabecera.fechaHasta}</Typography>
                <Box sx={{ height: 350 }}>
                  <zentto-grid ref={detalleGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
                </Box>
              </Box>
            ) : <Typography>No se encontró información</Typography>}
          </DialogContent>
          <DialogActions><Button onClick={() => { setSelectedNomina(null); setSelectedCedula(null); }}>Cerrar</Button></DialogActions>
        </Dialog>

        {/* Procesar Dialog */}
        <Dialog open={procesarOpen} onClose={() => setProcesarOpen(false)}>
          <DialogTitle>Procesar Nómina Completa</DialogTitle>
          <DialogContent>
            <Stack spacing={2} mt={1}>
              <TextField label="Código Nómina" fullWidth value={procesarData.nomina} onChange={(e) => setProcesarData((d) => ({ ...d, nomina: e.target.value }))} />
              <DatePicker label="Fecha Inicio" value={procesarData.fechaInicio ? dayjs(procesarData.fechaInicio) : null} onChange={(v) => setProcesarData((d) => ({ ...d, fechaInicio: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
              <DatePicker label="Fecha Hasta" value={procesarData.fechaHasta ? dayjs(procesarData.fechaHasta) : null} onChange={(v) => setProcesarData((d) => ({ ...d, fechaHasta: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
              <FormControlLabel control={<Switch checked={procesarData.soloActivos} onChange={(e) => setProcesarData((d) => ({ ...d, soloActivos: e.target.checked }))} />} label="Solo empleados activos" />
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setProcesarOpen(false)}>Cancelar</Button>
            <Button variant="contained" onClick={handleProcesar} disabled={procesarMutation.isPending}>Procesar</Button>
          </DialogActions>
        </Dialog>
      </Box>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
