"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  Chip, MenuItem, Select, FormControl, InputLabel,
} from "@mui/material";
import { DatePicker } from "@zentto/shared-ui";
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
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  },
];



export default function ExamenesMedicosPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<MedExamFilter>({ page: 1, limit: 25 });
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

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
      </Box>

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
