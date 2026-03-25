"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  Chip, MenuItem, Select, FormControl, InputLabel,
} from "@mui/material";
import { DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import {
  useMedExamList, useSaveMedExam, useDeleteMedExam, usePendingExams,
  type MedExamFilter, type MedExamInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

const emptyForm: MedExamInput = { employeeCode: "", type: "", examDate: "", nextDueDate: "", result: "", provider: "", notes: "" };

const COLUMNS: ColumnDef[] = [
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "ExamType", header: "Tipo Examen", width: 140, statusColors: { PREEMPLEO: "info", PERIODICO: "success", EGRESO: "warning", ESPECIAL: "error" }, statusVariant: "outlined" },
  { field: "ExamDate", header: "Fecha", width: 120 },
  { field: "Result", header: "Resultado", width: 130 },
  { field: "NextDueDate", header: "Próximo Vencimiento", width: 180 },
  { field: "ClinicName", header: "Proveedor", width: 150 },
];

const EXAMENES_FILTERS: FilterFieldDef[] = [
  { field: "type", label: "Tipo", type: "select", options: [
    { value: "PREEMPLEO", label: "Pre-Empleo" }, { value: "PERIODICO", label: "Periodico" },
    { value: "EGRESO", label: "Egreso" }, { value: "ESPECIAL", label: "Especial" },
  ]},
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
];

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

export default function ExamenesMedicosPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<MedExamFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<MedExamInput>({ ...emptyForm });

  const { data, isLoading } = useMedExamList(filter);
  const pendingExams = usePendingExams();
  const saveMutation = useSaveMedExam();
  const deleteMutation = useDeleteMedExam();

  const rows = data?.data ?? data?.rows ?? [];
  const pendingCount = pendingExams.data?.data?.length ?? pendingExams.data?.length ?? 0;

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.MedicalExamId ?? `${r.EmployeeCode}-${r.ExamDate}`;
    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

  const handleNew = () => { setForm({ ...emptyForm }); setEditMode(false); setDialogOpen(true); };
  const handleEdit = (row: Record<string, any>) => {
    setForm({ id: row.MedicalExamId, employeeCode: row.EmployeeCode ?? "", type: row.ExamType ?? "", examDate: row.ExamDate ?? "", nextDueDate: row.NextDueDate ?? "", result: row.Result ?? "", provider: row.ClinicName ?? "", notes: row.Notes ?? "" });
    setEditMode(true); setDialogOpen(true);
  };
  const handleDelete = async (row: Record<string, any>) => {
    const id = row.MedicalExamId; if (!id) return;
    if (!window.confirm(`¿Eliminar el examen médico de "${row.EmployeeName ?? row.EmployeeCode}"?`)) return;
    await deleteMutation.mutateAsync(id);
  };

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => { const { action, row } = e.detail; if (action === "edit") handleEdit(row); if (action === "delete") handleDelete(row); };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  const handleSave = async () => { await saveMutation.mutateAsync(form); setDialogOpen(false); setForm({ ...emptyForm }); };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Stack direction="row" spacing={2} alignItems="center">
          <Typography variant="h6">Exámenes Médicos</Typography>
          {pendingCount > 0 && <Chip label={`${pendingCount} vencido${pendingCount > 1 ? "s" : ""}`} color="warning" size="small" />}
        </Stack>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>Nuevo Examen</Button>
      </Stack>

      <ZenttoFilterPanel filters={EXAMENES_FILTERS} values={filterValues}
        onChange={(v) => { setFilterValues(v); setFilter((f) => ({ ...f, type: v.type || undefined })); }}
        searchPlaceholder="Buscar examenes..." searchValue={search}
        onSearchChange={(v) => { setSearch(v); setFilter((f) => ({ ...f, search: v || undefined })); }}
      />

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <zentto-grid ref={gridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      </Paper>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Examen Médico" : "Registrar Examen Médico"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={form.employeeCode} onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel>
              <Select value={form.type} label="Tipo" onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <MenuItem value="PREEMPLEO">Pre-Empleo</MenuItem><MenuItem value="PERIODICO">Periódico</MenuItem>
                <MenuItem value="EGRESO">Egreso</MenuItem><MenuItem value="ESPECIAL">Especial</MenuItem>
              </Select>
            </FormControl>
            <DatePicker label="Fecha del Examen" value={form.examDate ? dayjs(form.examDate) : null} onChange={(v) => setForm((f) => ({ ...f, examDate: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <DatePicker label="Próximo Vencimiento" value={form.nextDueDate ? dayjs(form.nextDueDate) : null} onChange={(v) => setForm((f) => ({ ...f, nextDueDate: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <TextField label="Resultado" fullWidth value={form.result || ""} onChange={(e) => setForm((f) => ({ ...f, result: e.target.value }))} />
            <TextField label="Proveedor" fullWidth value={form.provider || ""} onChange={(e) => setForm((f) => ({ ...f, provider: e.target.value }))} />
            <TextField label="Notas" fullWidth multiline rows={2} value={form.notes || ""} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} />
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
