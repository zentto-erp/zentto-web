"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import {
  Box, Paper, Typography, TextField, Button, Chip, Dialog, DialogTitle, DialogContent, DialogActions,
  Stack, FormControl, InputLabel, Select, MenuItem, Alert, Switch, FormControlLabel,
} from "@mui/material";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import GroupWorkIcon from "@mui/icons-material/GroupWork";
import { useBatchGrid, useBatchBulkUpdate, type BatchGridFilter } from "../hooks/useNominaBatch";
import PayrollEmployeePanel from "./PayrollEmployeePanel";

const COLUMNS: ColumnDef[] = [
  { field: "employeeCode", header: "Cédula", width: 110, sortable: true },
  { field: "employeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "department", header: "Depto.", width: 120, sortable: true, groupable: true },
  { field: "sueldoBase", header: "Sueldo Base", width: 130, type: "number", aggregation: "sum" },
  { field: "totalAsignaciones", header: "Asignaciones", width: 130, type: "number", aggregation: "sum" },
  { field: "totalDeducciones", header: "Deducciones", width: 130, type: "number", aggregation: "sum" },
  { field: "totalNeto", header: "Neto a Pagar", width: 140, type: "number", aggregation: "sum" },
  { field: "lineCount", header: "Conceptos", width: 90, type: "number" },
];

interface Props { batchId: number; }

const BATCH_FILTERS: FilterFieldDef[] = [
  { field: "estado", label: "Estado", type: "select", options: [{ value: "EDITADO", label: "Editado" }, { value: "SIN_EDITAR", label: "Sin editar" }] },
  { field: "departamento", label: "Departamento", type: "text", placeholder: "Filtrar por departamento..." },
];

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';

export default function PayrollBatchGrid({ batchId }: Props) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<BatchGridFilter>({ page: 1, limit: 50 });
  const [searchText, setSearchText] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [selectedEmployee, setSelectedEmployee] = useState<string | null>(null);
  const [bulkOpen, setBulkOpen] = useState(false);
  const [onlyModified, setOnlyModified] = useState(false);
  const [bulkData, setBulkData] = useState({ conceptCode: "", conceptName: "", conceptType: "ASIGNACION" as "ASIGNACION" | "DEDUCCION" | "BONO", amount: 0 });

  const grid = useBatchGrid(batchId, { ...filter, onlyModified });
  const bulkUpdate = useBatchBulkUpdate();

  const gridData = grid.data?.data ?? grid.data ?? { rows: [], total: 0 };
  const rows = Array.isArray(gridData) ? gridData : (gridData.rows ?? []);
  const totalCount = gridData.total ?? rows.length;

  const handleBulkApply = useCallback(async () => {
    await bulkUpdate.mutateAsync({ batchId, conceptCode: bulkData.conceptCode, conceptType: bulkData.conceptType, amount: bulkData.amount });
    setBulkOpen(false);
  }, [batchId, bulkData, bulkUpdate]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = grid.isLoading;
    el.getRowId = (r: any) => r.employeeCode || r.employeeId || Math.random();
    el.actionButtons = [{ icon: SVG_EDIT, label: "Editar detalle", action: "edit" }];
  }, [rows, grid.isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      if (e.detail.action === "edit") setSelectedEmployee(e.detail.row.employeeCode);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Toolbar */}
      <Box sx={{ mb: 2 }}>
        <ZenttoFilterPanel filters={BATCH_FILTERS} values={filterValues}
          onChange={(v) => { setFilterValues(v); if (v.estado === "EDITADO") setOnlyModified(true); else setOnlyModified(false); }}
          searchPlaceholder="Buscar por nombre o cedula..." searchValue={searchText}
          onSearchChange={(v) => { setSearchText(v); setFilter((f) => ({ ...f, search: v || undefined, page: 1 })); }}
        />
        <Stack direction="row" spacing={1} alignItems="center" sx={{ mt: 1 }}>
          <FormControlLabel control={<Switch size="small" checked={onlyModified} onChange={(e) => setOnlyModified(e.target.checked)} />} label={<Typography variant="body2">Solo editados</Typography>} />
          <Box sx={{ flexGrow: 1 }} />
          <Button size="small" variant="outlined" color="secondary" startIcon={<GroupWorkIcon />} onClick={() => setBulkOpen(true)}>Accion Masiva</Button>
          <Chip label={`${totalCount} empleados`} variant="outlined" size="small" sx={{ fontWeight: 600 }} />
        </Stack>
      </Box>

      {/* Grid */}
      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, borderRadius: 2, overflow: "hidden" }}>
        <zentto-grid ref={gridRef} height="100%" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      </Paper>

      <PayrollEmployeePanel batchId={batchId} employeeCode={selectedEmployee} onClose={() => setSelectedEmployee(null)} />

      {/* Bulk Update Dialog */}
      <Dialog open={bulkOpen} onClose={() => setBulkOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Acción Masiva</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>Aplicar un concepto a todos los empleados del lote.</Typography>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Código del Concepto" fullWidth value={bulkData.conceptCode} onChange={(e) => setBulkData((d) => ({ ...d, conceptCode: e.target.value }))} />
            <TextField label="Nombre del Concepto" fullWidth value={bulkData.conceptName} onChange={(e) => setBulkData((d) => ({ ...d, conceptName: e.target.value }))} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel>
              <Select value={bulkData.conceptType} label="Tipo" onChange={(e) => setBulkData((d) => ({ ...d, conceptType: e.target.value as any }))}>
                <MenuItem value="ASIGNACION">Asignación</MenuItem><MenuItem value="DEDUCCION">Deducción</MenuItem><MenuItem value="BONO">Bono</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Monto" type="number" fullWidth value={bulkData.amount} onChange={(e) => setBulkData((d) => ({ ...d, amount: Number(e.target.value) }))} />
          </Stack>
          {bulkUpdate.isError && <Alert severity="error" sx={{ mt: 2 }}>{String((bulkUpdate.error as Error)?.message || "Error")}</Alert>}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBulkOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleBulkApply} disabled={!bulkData.conceptCode || !bulkData.amount || bulkUpdate.isPending}>Aplicar a Todos</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
