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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  Chip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import {
  useEmpleadosList,
  useCreateEmpleado,
  useUpdateEmpleado,
  useDeleteEmpleado,
  type EmpleadoFilter,
  type EmpleadoInput,
} from "../hooks/useEmpleados";
import { formatCurrency } from "@datqbox/shared-api";

const emptyForm: EmpleadoInput = {
  CEDULA: "",
  NOMBRE: "",
  GRUPO: "",
  DIRECCION: "",
  TELEFONO: "",
  CARGO: "",
  NOMINA: "",
  SUELDO: 0,
  STATUS: "ACTIVO",
  SEXO: "",
  NACIONALIDAD: "",
};

export default function EmpleadosPage() {
  const [filter, setFilter] = useState<EmpleadoFilter>({ page: 1, limit: 50 });
  const [formOpen, setFormOpen] = useState(false);
  const [editCedula, setEditCedula] = useState<string | null>(null);
  const [form, setForm] = useState<EmpleadoInput>({ ...emptyForm });
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);

  const { data, isLoading } = useEmpleadosList(filter);
  const createMut = useCreateEmpleado();
  const updateMut = useUpdateEmpleado();
  const deleteMut = useDeleteEmpleado();

  const rows = data?.data ?? data?.rows ?? data?.items ?? [];
  const totalCount = data?.totalCount ?? data?.total ?? rows.length;

  const norm = (row: any, ...keys: string[]) => {
    for (const k of keys) if (row[k] !== undefined && row[k] !== null) return row[k];
    return "";
  };

  const columns: GridColDef[] = [
    { field: "cedula", headerName: "Cédula", width: 130, valueGetter: (_v, row) => norm(row, "CEDULA", "cedula", "EmployeeCode") },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200, valueGetter: (_v, row) => norm(row, "NOMBRE", "nombre", "EmployeeName") },
    { field: "cargo", headerName: "Cargo", width: 150, valueGetter: (_v, row) => norm(row, "CARGO", "cargo", "Position") },
    { field: "grupo", headerName: "Grupo", width: 120, valueGetter: (_v, row) => norm(row, "GRUPO", "grupo", "Department") },
    { field: "nomina", headerName: "Nómina", width: 120, valueGetter: (_v, row) => norm(row, "NOMINA", "nomina", "PayrollCode") },
    {
      field: "sueldo", headerName: "Sueldo", width: 130, type: "number",
      valueGetter: (_v, row) => Number(norm(row, "SUELDO", "sueldo", "Salary")) || 0,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "status", headerName: "Status", width: 110,
      valueGetter: (_v, row) => norm(row, "STATUS", "status", "IsActive"),
      renderCell: (p) => {
        const v = String(p.value || "").toUpperCase();
        const active = v === "ACTIVO" || v === "A" || v === "1" || v === "TRUE";
        return <Chip label={active ? "Activo" : "Inactivo"} color={active ? "success" : "default"} size="small" />;
      },
    },
    {
      field: "acciones", headerName: "", width: 100, sortable: false,
      renderCell: (p) => {
        const ced = norm(p.row, "CEDULA", "cedula", "EmployeeCode");
        return (
          <>
            <IconButton size="small" onClick={() => handleEdit(p.row)}>
              <EditIcon fontSize="small" />
            </IconButton>
            <IconButton size="small" color="error" onClick={() => setDeleteTarget(ced)}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </>
        );
      },
    },
  ];

  const handleEdit = (row: any) => {
    const ced = norm(row, "CEDULA", "cedula", "EmployeeCode");
    setEditCedula(ced);
    setForm({
      CEDULA: ced,
      NOMBRE: norm(row, "NOMBRE", "nombre", "EmployeeName"),
      GRUPO: norm(row, "GRUPO", "grupo", "Department"),
      DIRECCION: norm(row, "DIRECCION", "direccion", "Address"),
      TELEFONO: norm(row, "TELEFONO", "telefono", "Phone"),
      CARGO: norm(row, "CARGO", "cargo", "Position"),
      NOMINA: norm(row, "NOMINA", "nomina", "PayrollCode"),
      SUELDO: Number(norm(row, "SUELDO", "sueldo", "Salary")) || 0,
      STATUS: norm(row, "STATUS", "status") || "ACTIVO",
      SEXO: norm(row, "SEXO", "sexo", "Gender"),
      NACIONALIDAD: norm(row, "NACIONALIDAD", "nacionalidad", "Nationality"),
    });
    setFormOpen(true);
  };

  const handleNew = () => {
    setEditCedula(null);
    setForm({ ...emptyForm });
    setFormOpen(true);
  };

  const handleSave = async () => {
    if (editCedula) {
      const { CEDULA, ...rest } = form;
      await updateMut.mutateAsync({ cedula: editCedula, data: rest });
    } else {
      await createMut.mutateAsync(form);
    }
    setFormOpen(false);
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    await deleteMut.mutateAsync(deleteTarget);
    setDeleteTarget(null);
  };

  const saving = createMut.isPending || updateMut.isPending;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6" fontWeight={600}>Empleados</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
          Nuevo Empleado
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar"
          size="small"
          value={filter.search || ""}
          onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
        />
        <FormControl size="small" sx={{ minWidth: 130 }}>
          <InputLabel>Status</InputLabel>
          <Select
            value={filter.status || ""}
            label="Status"
            onChange={(e) => setFilter((f) => ({ ...f, status: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="ACTIVO">Activo</MenuItem>
            <MenuItem value="INACTIVO">Inactivo</MenuItem>
          </Select>
        </FormControl>
        <TextField
          label="Grupo"
          size="small"
          value={filter.grupo || ""}
          onChange={(e) => setFilter((f) => ({ ...f, grupo: e.target.value || undefined }))}
        />
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          paginationMode="server"
          rowCount={totalCount}
          paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 50 }}
          onPaginationModelChange={(m) => setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))}
          pageSizeOptions={[25, 50, 100]}
          disableRowSelectionOnClick
          getRowId={(r) => r.CEDULA ?? r.cedula ?? r.EmployeeCode ?? Math.random()}
        />
      </Paper>

      {/* Create / Edit Dialog */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editCedula ? "Editar Empleado" : "Nuevo Empleado"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Cédula"
              fullWidth
              value={form.CEDULA}
              onChange={(e) => setForm((f) => ({ ...f, CEDULA: e.target.value }))}
              disabled={!!editCedula}
            />
            <TextField
              label="Nombre Completo"
              fullWidth
              value={form.NOMBRE}
              onChange={(e) => setForm((f) => ({ ...f, NOMBRE: e.target.value }))}
            />
            <Stack direction="row" spacing={2}>
              <TextField
                label="Cargo"
                fullWidth
                value={form.CARGO || ""}
                onChange={(e) => setForm((f) => ({ ...f, CARGO: e.target.value }))}
              />
              <TextField
                label="Grupo / Depto."
                fullWidth
                value={form.GRUPO || ""}
                onChange={(e) => setForm((f) => ({ ...f, GRUPO: e.target.value }))}
              />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Nómina"
                fullWidth
                value={form.NOMINA || ""}
                onChange={(e) => setForm((f) => ({ ...f, NOMINA: e.target.value }))}
              />
              <TextField
                label="Sueldo"
                type="number"
                fullWidth
                value={form.SUELDO || ""}
                onChange={(e) => setForm((f) => ({ ...f, SUELDO: Number(e.target.value) || 0 }))}
              />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Teléfono"
                fullWidth
                value={form.TELEFONO || ""}
                onChange={(e) => setForm((f) => ({ ...f, TELEFONO: e.target.value }))}
              />
              <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select
                  value={form.STATUS || "ACTIVO"}
                  label="Status"
                  onChange={(e) => setForm((f) => ({ ...f, STATUS: e.target.value }))}
                >
                  <MenuItem value="ACTIVO">Activo</MenuItem>
                  <MenuItem value="INACTIVO">Inactivo</MenuItem>
                </Select>
              </FormControl>
            </Stack>
            <TextField
              label="Dirección"
              fullWidth
              value={form.DIRECCION || ""}
              onChange={(e) => setForm((f) => ({ ...f, DIRECCION: e.target.value }))}
            />
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth>
                <InputLabel>Sexo</InputLabel>
                <Select
                  value={form.SEXO || ""}
                  label="Sexo"
                  onChange={(e) => setForm((f) => ({ ...f, SEXO: e.target.value }))}
                >
                  <MenuItem value="">—</MenuItem>
                  <MenuItem value="M">Masculino</MenuItem>
                  <MenuItem value="F">Femenino</MenuItem>
                </Select>
              </FormControl>
              <TextField
                label="Nacionalidad"
                fullWidth
                value={form.NACIONALIDAD || ""}
                onChange={(e) => setForm((f) => ({ ...f, NACIONALIDAD: e.target.value }))}
              />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving || !form.CEDULA || !form.NOMBRE}>
            {editCedula ? "Actualizar" : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar Eliminación</DialogTitle>
        <DialogContent>
          <Typography>¿Está seguro de eliminar al empleado <strong>{deleteTarget}</strong>?</Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={deleteMut.isPending}>
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
