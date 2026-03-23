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
  CircularProgress,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import VisibilityIcon from "@mui/icons-material/Visibility";
import IconButton from "@mui/material/IconButton";
import {
  useOccHealthList,
  useCreateOccHealth,
  useUpdateOccHealth,
  useOccHealthDetail,
  type OccHealthFilter,
  type OccHealthInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

const STATUS_COLORS: Record<string, "warning" | "info" | "primary" | "default"> = {
  OPEN: "warning",
  REPORTED: "info",
  INVESTIGATING: "primary",
  CLOSED: "default",
};

const STATUS_LABELS: Record<string, string> = {
  OPEN: "Abierto",
  REPORTED: "Reportado",
  INVESTIGATING: "En Investigación",
  CLOSED: "Cerrado",
};

const SEVERITY_COLORS: Record<string, "success" | "warning" | "error" | "default"> = {
  LEVE: "success",
  MODERADO: "warning",
  GRAVE: "error",
  FATAL: "error",
};

const emptyForm: OccHealthInput = {
  employeeCode: "", type: "", date: "", severity: "LEVE",
  daysLost: 0, description: "", status: "OPEN", correctiveActions: "",
};

export default function SaludOcupacionalPage() {
  const [filter, setFilter] = useState<OccHealthFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailId, setDetailId] = useState<number | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<OccHealthInput>({ ...emptyForm });

  const { data, isLoading } = useOccHealthList(filter);
  const createMutation = useCreateOccHealth();
  const updateMutation = useUpdateOccHealth();
  const detail = useOccHealthDetail(detailId);

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "date", headerName: "Fecha", width: 110 },
    {
      field: "type",
      headerName: "Tipo",
      width: 140,
      renderCell: (p) => (
        <Chip
          label={
            p.value === "ACCIDENTE" ? "Accidente" :
            p.value === "INCIDENTE" ? "Incidente" :
            p.value === "ENFERMEDAD" ? "Enfermedad" : p.value
          }
          size="small"
          variant="outlined"
          color={
            p.value === "ACCIDENTE" ? "error" :
            p.value === "INCIDENTE" ? "warning" : "info"
          }
        />
      ),
    },
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    {
      field: "severity",
      headerName: "Severidad",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value || "—"}
          size="small"
          color={SEVERITY_COLORS[p.value] || "default"}
        />
      ),
    },
    { field: "daysLost", headerName: "Días Perdidos", width: 120, type: "number" },
    {
      field: "status",
      headerName: "Estado",
      width: 140,
      renderCell: (p) => (
        <Chip
          label={STATUS_LABELS[p.value] || p.value || "Abierto"}
          size="small"
          color={STATUS_COLORS[p.value] || "default"}
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <IconButton size="small" onClick={() => setDetailId(p.row.id)}>
            <VisibilityIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            onClick={() => {
              setForm({
                id: p.row.id,
                employeeCode: p.row.employeeCode ?? "",
                type: p.row.type ?? "",
                date: p.row.date ?? "",
                severity: p.row.severity ?? "LEVE",
                daysLost: p.row.daysLost ?? 0,
                description: p.row.description ?? "",
                status: p.row.status ?? "OPEN",
                correctiveActions: p.row.correctiveActions ?? "",
              });
              setEditMode(true);
              setDialogOpen(true);
            }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Stack>
      ),
    },
  ];

  const handleSave = async () => {
    if (editMode && form.id) {
      await updateMutation.mutateAsync(form);
    } else {
      await createMutation.mutateAsync(form);
    }
    setDialogOpen(false);
    setEditMode(false);
    setForm({ ...emptyForm });
  };

  const handleOpenCreate = () => {
    setEditMode(false);
    setForm({ ...emptyForm });
    setDialogOpen(true);
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Salud Ocupacional</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleOpenCreate}>
          Nuevo Registro
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar"
          size="small"
          value={filter.search || ""}
          onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
        />
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Tipo</InputLabel>
          <Select
            value={filter.type || ""}
            label="Tipo"
            onChange={(e) => setFilter((f) => ({ ...f, type: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="ACCIDENTE">Accidente</MenuItem>
            <MenuItem value="INCIDENTE">Incidente</MenuItem>
            <MenuItem value="ENFERMEDAD">Enfermedad</MenuItem>
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Estado</InputLabel>
          <Select
            value={filter.status || ""}
            label="Estado"
            onChange={(e) => setFilter((f) => ({ ...f, status: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="OPEN">Abierto</MenuItem>
            <MenuItem value="REPORTED">Reportado</MenuItem>
            <MenuItem value="INVESTIGATING">En Investigación</MenuItem>
            <MenuItem value="CLOSED">Cerrado</MenuItem>
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Severidad</InputLabel>
          <Select
            value={filter.severity || ""}
            label="Severidad"
            onChange={(e) => setFilter((f) => ({ ...f, severity: e.target.value || undefined }))}
          >
            <MenuItem value="">Todas</MenuItem>
            <MenuItem value="LEVE">Leve</MenuItem>
            <MenuItem value="MODERADO">Moderado</MenuItem>
            <MenuItem value="GRAVE">Grave</MenuItem>
            <MenuItem value="FATAL">Fatal</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? `${r.employeeCode}-${r.date}`}
          mobileVisibleFields={['employeeName', 'type']}
          smExtraFields={['severity', 'status']}
        />
      </Paper>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Registro" : "Nuevo Registro de Salud Ocupacional"}</DialogTitle>
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
                <MenuItem value="ACCIDENTE">Accidente</MenuItem>
                <MenuItem value="INCIDENTE">Incidente</MenuItem>
                <MenuItem value="ENFERMEDAD">Enfermedad</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Fecha"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={form.date}
              onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>Severidad</InputLabel>
              <Select
                value={form.severity}
                label="Severidad"
                onChange={(e) => setForm((f) => ({ ...f, severity: e.target.value }))}
              >
                <MenuItem value="LEVE">Leve</MenuItem>
                <MenuItem value="MODERADO">Moderado</MenuItem>
                <MenuItem value="GRAVE">Grave</MenuItem>
                <MenuItem value="FATAL">Fatal</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Días Perdidos"
              type="number"
              fullWidth
              value={form.daysLost || ""}
              onChange={(e) => setForm((f) => ({ ...f, daysLost: Number(e.target.value) }))}
            />
            <TextField
              label="Descripción"
              fullWidth
              multiline
              rows={3}
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
            />
            <TextField
              label="Acciones Correctivas"
              fullWidth
              multiline
              rows={2}
              value={form.correctiveActions || ""}
              onChange={(e) => setForm((f) => ({ ...f, correctiveActions: e.target.value }))}
            />
            {editMode && (
              <FormControl fullWidth>
                <InputLabel>Estado</InputLabel>
                <Select
                  value={form.status || "OPEN"}
                  label="Estado"
                  onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}
                >
                  <MenuItem value="OPEN">Abierto</MenuItem>
                  <MenuItem value="REPORTED">Reportado</MenuItem>
                  <MenuItem value="INVESTIGATING">En Investigación</MenuItem>
                  <MenuItem value="CLOSED">Cerrado</MenuItem>
                </Select>
              </FormControl>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={createMutation.isPending || updateMutation.isPending}
          >
            {editMode ? "Actualizar" : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Detail Dialog */}
      <Dialog open={detailId != null} onClose={() => setDetailId(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle del Registro</DialogTitle>
        <DialogContent>
          {detail.isLoading ? (
            <CircularProgress />
          ) : (
            <Stack spacing={1.5} mt={1}>
              <Typography variant="body2"><strong>Empleado:</strong> {detail.data?.employeeName ?? detail.data?.employeeCode}</Typography>
              <Typography variant="body2"><strong>Tipo:</strong> {detail.data?.type}</Typography>
              <Typography variant="body2"><strong>Fecha:</strong> {detail.data?.date}</Typography>
              <Typography variant="body2"><strong>Severidad:</strong> {detail.data?.severity}</Typography>
              <Typography variant="body2"><strong>Días Perdidos:</strong> {detail.data?.daysLost ?? 0}</Typography>
              <Typography variant="body2"><strong>Estado:</strong> {STATUS_LABELS[detail.data?.status] || detail.data?.status}</Typography>
              <Typography variant="body2"><strong>Descripción:</strong> {detail.data?.description}</Typography>
              <Typography variant="body2"><strong>Acciones Correctivas:</strong> {detail.data?.correctiveActions || "—"}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
