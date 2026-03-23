"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  Tooltip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  useMedExamList,
  useSaveMedExam,
  useDeleteMedExam,
  usePendingExams,
  type MedExamFilter,
  type MedExamInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

const TYPE_LABELS: Record<string, string> = {
  PREEMPLEO: "Pre-Empleo",
  PERIODICO: "Periódico",
  EGRESO: "Egreso",
  ESPECIAL: "Especial",
};

const emptyForm: MedExamInput = {
  employeeCode: "",
  type: "",
  examDate: "",
  nextDueDate: "",
  result: "",
  provider: "",
  notes: "",
};

export default function ExamenesMedicosPage() {
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

  const isOverdue = (nextDue: string | null | undefined): boolean => {
    if (!nextDue) return false;
    return new Date(nextDue) < new Date();
  };

  const handleNew = () => {
    setForm({ ...emptyForm });
    setEditMode(false);
    setDialogOpen(true);
  };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      id: row.id,
      employeeCode: row.employeeCode ?? "",
      type: row.type ?? "",
      examDate: row.examDate ?? "",
      nextDueDate: row.nextDueDate ?? "",
      result: row.result ?? "",
      provider: row.provider ?? "",
      notes: row.notes ?? "",
    });
    setEditMode(true);
    setDialogOpen(true);
  };

  const handleDelete = async (row: Record<string, any>) => {
    const id = row.id;
    if (!id) return;
    if (!window.confirm(`¿Eliminar el examen médico de "${row.employeeName ?? row.employeeCode}"?`)) return;
    await deleteMutation.mutateAsync(id);
  };

  const columns: GridColDef[] = [
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    {
      field: "type",
      headerName: "Tipo Examen",
      width: 140,
      renderCell: (p) => (
        <Chip
          label={TYPE_LABELS[p.value] || p.value || "—"}
          size="small"
          variant="outlined"
          color="primary"
        />
      ),
    },
    { field: "examDate", headerName: "Fecha", width: 120 },
    { field: "result", headerName: "Resultado", width: 130 },
    {
      field: "nextDueDate",
      headerName: "Próximo Vencimiento",
      width: 180,
      renderCell: (p) =>
        p.value ? (
          <Chip
            label={p.value}
            size="small"
            color={isOverdue(p.value) ? "error" : "default"}
            variant={isOverdue(p.value) ? "filled" : "outlined"}
          />
        ) : (
          <Typography variant="body2" color="text.secondary">—</Typography>
        ),
    },
    { field: "provider", headerName: "Proveedor", width: 150 },
    {
      field: "actions",
      headerName: "Acciones",
      width: 110,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Editar">
            <IconButton size="small" color="primary" onClick={() => handleEdit(params.row)}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Eliminar">
            <IconButton size="small" color="error" onClick={() => handleDelete(params.row)}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const handleSave = async () => {
    await saveMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ ...emptyForm });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Stack direction="row" spacing={2} alignItems="center">
          <Typography variant="h6">Exámenes Médicos</Typography>
          {pendingCount > 0 && (
            <Chip
              label={`${pendingCount} vencido${pendingCount > 1 ? "s" : ""}`}
              color="warning"
              size="small"
            />
          )}
        </Stack>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
          Nuevo Examen
        </Button>
      </Stack>

      <FormGrid spacing={2} sx={{ mb: 2 }}>
        <FormField xs={12} sm={6}>
          <TextField
            label="Buscar"
            size="small"
            fullWidth
            value={filter.search || ""}
            onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
          />
        </FormField>
        <FormField xs={12} sm={6}>
          <FormControl size="small" fullWidth>
            <InputLabel>Tipo</InputLabel>
            <Select
              value={filter.type || ""}
              label="Tipo"
              onChange={(e) => setFilter((f) => ({ ...f, type: e.target.value || undefined }))}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="PREEMPLEO">Pre-Empleo</MenuItem>
              <MenuItem value="PERIODICO">Periódico</MenuItem>
              <MenuItem value="EGRESO">Egreso</MenuItem>
              <MenuItem value="ESPECIAL">Especial</MenuItem>
            </Select>
          </FormControl>
        </FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? `${r.employeeCode}-${r.examDate}`}
          getRowClassName={(params) => isOverdue(params.row.nextDueDate) ? "row-overdue" : ""}
          mobileVisibleFields={['employeeName', 'type']}
          smExtraFields={['examDate', 'nextDueDate']}
          sx={{
            "& .row-overdue": {
              backgroundColor: "rgba(211, 47, 47, 0.04)",
            },
          }}
        />
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Examen Médico" : "Registrar Examen Médico"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector
              value={form.employeeCode}
              onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={form.type}
                label="Tipo"
                onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}
              >
                <MenuItem value="PREEMPLEO">Pre-Empleo</MenuItem>
                <MenuItem value="PERIODICO">Periódico</MenuItem>
                <MenuItem value="EGRESO">Egreso</MenuItem>
                <MenuItem value="ESPECIAL">Especial</MenuItem>
              </Select>
            </FormControl>
            <DatePicker
              label="Fecha del Examen"
              value={form.examDate ? dayjs(form.examDate) : null}
              onChange={(v) => setForm((f) => ({ ...f, examDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <DatePicker
              label="Próximo Vencimiento"
              value={form.nextDueDate ? dayjs(form.nextDueDate) : null}
              onChange={(v) => setForm((f) => ({ ...f, nextDueDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <TextField
              label="Resultado"
              fullWidth
              value={form.result || ""}
              onChange={(e) => setForm((f) => ({ ...f, result: e.target.value }))}
            />
            <TextField
              label="Proveedor"
              fullWidth
              value={form.provider || ""}
              onChange={(e) => setForm((f) => ({ ...f, provider: e.target.value }))}
            />
            <TextField
              label="Notas"
              fullWidth
              multiline
              rows={2}
              value={form.notes || ""}
              onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saveMutation.isPending}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
