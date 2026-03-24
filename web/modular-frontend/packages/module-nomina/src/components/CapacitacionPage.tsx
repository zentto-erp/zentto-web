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
  Switch,
  FormControlLabel,
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
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

const CAPACITACION_FILTERS: FilterFieldDef[] = [
  {
    field: "type", label: "Tipo", type: "select",
    options: [
      { value: "INDUCCION", label: "Induccion" },
      { value: "TECNICA", label: "Tecnica" },
      { value: "SEGURIDAD", label: "Seguridad" },
      { value: "LIDERAZGO", label: "Liderazgo" },
      { value: "CUMPLIMIENTO", label: "Cumplimiento" },
    ],
  },
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
];

export default function CapacitacionPage() {
  const [filter, setFilter] = useState<TrainingFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<TrainingInput>({ ...emptyForm });

  const { data, isLoading } = useTrainingList(filter);
  const saveMutation = useSaveTraining();
  const deleteMutation = useDeleteTraining();

  const rows = data?.data ?? data?.rows ?? [];

  const handleNew = () => {
    setForm({ ...emptyForm });
    setEditMode(false);
    setDialogOpen(true);
  };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      id: row.TrainingRecordId,
      employeeCode: row.EmployeeCode ?? "",
      title: row.Title ?? "",
      type: row.TrainingType ?? "",
      provider: row.Provider ?? "",
      hours: row.DurationHours ?? 0,
      result: row.Result ?? "",
      regulatory: row.IsRegulatory ?? false,
      startDate: row.StartDate ?? "",
      endDate: row.EndDate ?? "",
    });
    setEditMode(true);
    setDialogOpen(true);
  };

  const handleDelete = async (row: Record<string, any>) => {
    const id = row.TrainingRecordId;
    if (!id) return;
    if (!window.confirm(`¿Eliminar la capacitación "${row.Title}"?`)) return;
    await deleteMutation.mutateAsync(id);
  };

  const columns: ZenttoColDef[] = [
    { field: "Title", headerName: "Título", flex: 1, minWidth: 200 },
    { field: "EmployeeName", headerName: "Empleado", flex: 1, minWidth: 180 },
    {
      field: "TrainingType",
      headerName: "Tipo",
      width: 130,
      renderCell: (p) => (
        <Chip label={p.value || "—"} size="small" variant="outlined" color="primary" />
      ),
      statusColors: { 'INDUCCION': 'info', 'TECNICA': 'success', 'SEGURIDAD': 'warning', 'LIDERAZGO': 'info', 'CUMPLIMIENTO': 'warning' },
    },
    { field: "Provider", headerName: "Proveedor", width: 150 },
    { field: "DurationHours", headerName: "Horas", width: 80, type: "number" },
    { field: "StartDate", headerName: "Fecha Inicio", width: 120 },
    { field: "EndDate", headerName: "Fecha Fin", width: 120 },
    {
      field: "Result",
      headerName: "Resultado",
      width: 120,
      renderCell: (p) =>
        p.value ? (
          <Chip
            label={p.value}
            size="small"
            color={
              p.value === "APROBADO" ? "success" :
              p.value === "REPROBADO" ? "error" : "default"
            }
          />
        ) : null,
      statusColors: { 'APROBADO': 'success', 'REPROBADO': 'error' },
    },
    {
      field: "IsRegulatory",
      headerName: "Regulatorio",
      width: 110,
      renderCell: (p) =>
        p.value ? (
          <Chip label="Regulatorio" size="small" color="warning" variant="outlined" />
        ) : null,
    },
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
        <Typography variant="h6">Capacitación</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
          Nueva Capacitación
        </Button>
      </Stack>

      <ZenttoFilterPanel
        filters={CAPACITACION_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setFilter((f) => ({ ...f, type: v.type || undefined }));
        }}
        searchPlaceholder="Buscar capacitaciones..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setFilter((f) => ({ ...f, search: v || undefined }));
        }}
      />

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
            gridId="nomina-capacitacion-list"
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.TrainingRecordId ?? `${r.EmployeeCode}-${r.Title}-${r.StartDate}`}
          enableGrouping
          enableClipboard
          enableHeaderFilters
          mobileVisibleFields={['Title', 'EmployeeName']}
          smExtraFields={['TrainingType', 'StartDate']}
        />
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Capacitación" : "Registrar Capacitación"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector
              value={form.employeeCode}
              onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))}
            />
            <TextField
              label="Título"
              fullWidth
              value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={form.type}
                label="Tipo"
                onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}
              >
                <MenuItem value="INDUCCION">Inducción</MenuItem>
                <MenuItem value="TECNICA">Técnica</MenuItem>
                <MenuItem value="SEGURIDAD">Seguridad</MenuItem>
                <MenuItem value="LIDERAZGO">Liderazgo</MenuItem>
                <MenuItem value="CUMPLIMIENTO">Cumplimiento</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Proveedor"
              fullWidth
              value={form.provider || ""}
              onChange={(e) => setForm((f) => ({ ...f, provider: e.target.value }))}
            />
            <TextField
              label="Horas"
              type="number"
              fullWidth
              value={form.hours || ""}
              onChange={(e) => setForm((f) => ({ ...f, hours: Number(e.target.value) }))}
            />
            <TextField
              label="Resultado"
              fullWidth
              value={form.result || ""}
              onChange={(e) => setForm((f) => ({ ...f, result: e.target.value }))}
            />
            <FormControlLabel
              control={
                <Switch
                  checked={form.regulatory || false}
                  onChange={(e) => setForm((f) => ({ ...f, regulatory: e.target.checked }))}
                />
              }
              label="Capacitación regulatoria"
            />
            <DatePicker
              label="Fecha Inicio"
              value={form.startDate ? dayjs(form.startDate) : null}
              onChange={(v) => setForm((f) => ({ ...f, startDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <DatePicker
              label="Fecha Fin"
              value={form.endDate ? dayjs(form.endDate) : null}
              onChange={(v) => setForm((f) => ({ ...f, endDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
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
