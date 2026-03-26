"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Switch,
  FormControlLabel,
} from "@mui/material";
import { DatePicker } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import {
  useTrainingList,
  useSaveTraining,
  useDeleteTraining,
  type TrainingFilter,
  type TrainingInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

const emptyForm: TrainingInput = {
  employeeCode: "", title: "", type: "", provider: "",
  hours: 0, result: "", regulatory: false, startDate: "", endDate: "",
};

const COLUMNS: ColumnDef[] = [
  { field: "Title", header: "Título", flex: 1, minWidth: 200, sortable: true },
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 180, sortable: true },
  {
    field: "TrainingType", header: "Tipo", width: 130, sortable: true, groupable: true,
    statusColors: { INDUCCION: "info", TECNICA: "success", SEGURIDAD: "warning", LIDERAZGO: "info", CUMPLIMIENTO: "warning" },
    statusVariant: "outlined",
  },
  { field: "Provider", header: "Proveedor", width: 150 },
  { field: "DurationHours", header: "Horas", width: 80, type: "number" },
  { field: "StartDate", header: "Fecha Inicio", width: 120 },
  { field: "EndDate", header: "Fecha Fin", width: 120 },
  {
    field: "Result", header: "Resultado", width: 120,
    statusColors: { APROBADO: "success", REPROBADO: "error" },
  },
  {
    field: "IsRegulatory", header: "Regulatorio", width: 110,
  },
];


const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

export default function CapacitacionPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<TrainingFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<TrainingInput>({ ...emptyForm });

  const { data, isLoading } = useTrainingList(filter);
  const saveMutation = useSaveTraining();
  const deleteMutation = useDeleteTraining();

  const rows = data?.data ?? data?.rows ?? [];

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.TrainingRecordId ?? `${r.EmployeeCode}-${r.Title}-${r.StartDate}`;
    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

  const handleNew = () => { setForm({ ...emptyForm }); setEditMode(false); setDialogOpen(true); };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      id: row.TrainingRecordId, employeeCode: row.EmployeeCode ?? "", title: row.Title ?? "",
      type: row.TrainingType ?? "", provider: row.Provider ?? "", hours: row.DurationHours ?? 0,
      result: row.Result ?? "", regulatory: row.IsRegulatory ?? false,
      startDate: row.StartDate ?? "", endDate: row.EndDate ?? "",
    });
    setEditMode(true); setDialogOpen(true);
  };

  const handleDelete = async (row: Record<string, any>) => {
    const id = row.TrainingRecordId;
    if (!id) return;
    if (!window.confirm(`¿Eliminar la capacitación "${row.Title}"?`)) return;
    await deleteMutation.mutateAsync(id);
  };

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
      if (action === "delete") handleDelete(row);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false); setForm({ ...emptyForm });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Capacitación</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>Nueva Capacitación</Button>
      </Stack>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
      </Box>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Capacitación" : "Registrar Capacitación"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={form.employeeCode} onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))} />
            <TextField label="Título" fullWidth value={form.title} onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel>
              <Select value={form.type} label="Tipo" onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <MenuItem value="INDUCCION">Inducción</MenuItem><MenuItem value="TECNICA">Técnica</MenuItem>
                <MenuItem value="SEGURIDAD">Seguridad</MenuItem><MenuItem value="LIDERAZGO">Liderazgo</MenuItem>
                <MenuItem value="CUMPLIMIENTO">Cumplimiento</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Proveedor" fullWidth value={form.provider || ""} onChange={(e) => setForm((f) => ({ ...f, provider: e.target.value }))} />
            <TextField label="Horas" type="number" fullWidth value={form.hours || ""} onChange={(e) => setForm((f) => ({ ...f, hours: Number(e.target.value) }))} />
            <TextField label="Resultado" fullWidth value={form.result || ""} onChange={(e) => setForm((f) => ({ ...f, result: e.target.value }))} />
            <FormControlLabel control={<Switch checked={form.regulatory || false} onChange={(e) => setForm((f) => ({ ...f, regulatory: e.target.checked }))} />} label="Capacitación regulatoria" />
            <DatePicker label="Fecha Inicio" value={form.startDate ? dayjs(form.startDate) : null} onChange={(v) => setForm((f) => ({ ...f, startDate: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <DatePicker label="Fecha Fin" value={form.endDate ? dayjs(form.endDate) : null} onChange={(v) => setForm((f) => ({ ...f, endDate: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saveMutation.isPending}>Guardar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
