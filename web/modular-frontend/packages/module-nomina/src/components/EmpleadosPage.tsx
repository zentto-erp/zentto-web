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
  Tooltip,
  CircularProgress,
  Menu,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import HistoryIcon from "@mui/icons-material/History";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import BeachAccessIcon from "@mui/icons-material/BeachAccess";
import ExitToAppIcon from "@mui/icons-material/ExitToApp";
import MoreVertIcon from "@mui/icons-material/MoreVert";
import NominaWizard from "./NominaWizard";
import VacacionesWizard from "./VacacionesWizard";
import LiquidacionesWizard from "./LiquidacionesWizard";
import {
  useEmpleadosList,
  useCreateEmpleado,
  useUpdateEmpleado,
  useDeleteEmpleado,
  type EmpleadoFilter,
  type EmpleadoInput,
} from "../hooks/useEmpleados";
import { formatCurrency } from "@zentto/shared-api";
import { useNominasList } from "../hooks/useNomina";

const GRUPOS = ["ADMIN", "ALMACEN", "GERENCIA", "PRODUCCION", "VENTAS"];
const NOMINAS = ["MENSUAL", "QUINCENAL", "SEMANAL"];

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
  const [historialCedula, setHistorialCedula] = useState<string | null>(null);
  const [historialNombre, setHistorialNombre] = useState<string>("");
  const [nominaCedula, setNominaCedula] = useState<string | null>(null);
  const [nominaNombre, setNominaNombre] = useState<string>("");
  const [vacCedula, setVacCedula] = useState<string | null>(null);
  const [vacNombre, setVacNombre] = useState<string>("");
  const [liqCedula, setLiqCedula] = useState<string | null>(null);
  const [liqNombre, setLiqNombre] = useState<string>("");

  const { data, isLoading } = useEmpleadosList(filter);
  const historial = useNominasList(
    historialCedula ? { cedula: historialCedula, limit: 50 } : { limit: 0 }
  );
  const createMut = useCreateEmpleado();
  const updateMut = useUpdateEmpleado();
  const deleteMut = useDeleteEmpleado();

  const rows = data?.data ?? data?.rows ?? data?.items ?? [];
  const totalCount = data?.totalCount ?? data?.total ?? rows.length;

  const norm = (row: any, ...keys: string[]) => {
    for (const k of keys) if (row[k] !== undefined && row[k] !== null) return row[k];
    return "";
  };

  // Sub-componente para acciones por fila con menú contextual
  const RowActions = ({ row }: { row: any }) => {
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const ced = norm(row, "CEDULA", "cedula", "EmployeeCode");
    const nombre = norm(row, "NOMBRE", "nombre", "EmployeeName");
    return (
      <>
        <Tooltip title="Editar">
          <IconButton size="small" onClick={() => handleEdit(row)}>
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Acciones">
          <IconButton size="small" onClick={(e) => setAnchorEl(e.currentTarget)}>
            <MoreVertIcon fontSize="small" />
          </IconButton>
        </Tooltip>
        <Menu anchorEl={anchorEl} open={!!anchorEl} onClose={() => setAnchorEl(null)}>
          <MenuItem onClick={() => { setAnchorEl(null); setNominaCedula(ced); setNominaNombre(nombre); }}>
            <PlayArrowIcon fontSize="small" sx={{ mr: 1, color: "success.main" }} /> Procesar Nómina
          </MenuItem>
          <MenuItem onClick={() => { setAnchorEl(null); setVacCedula(ced); setVacNombre(nombre); }}>
            <BeachAccessIcon fontSize="small" sx={{ mr: 1, color: "info.main" }} /> Procesar Vacaciones
          </MenuItem>
          <MenuItem onClick={() => { setAnchorEl(null); setLiqCedula(ced); setLiqNombre(nombre); }}>
            <ExitToAppIcon fontSize="small" sx={{ mr: 1, color: "warning.main" }} /> Calcular Liquidación
          </MenuItem>
          <MenuItem onClick={() => { setAnchorEl(null); setHistorialCedula(ced); setHistorialNombre(nombre); }}>
            <HistoryIcon fontSize="small" sx={{ mr: 1, color: "primary.main" }} /> Historial de Nómina
          </MenuItem>
          <MenuItem onClick={() => { setAnchorEl(null); setDeleteTarget(ced); }} sx={{ color: "error.main" }}>
            <DeleteIcon fontSize="small" sx={{ mr: 1 }} /> Eliminar
          </MenuItem>
        </Menu>
      </>
    );
  };

  const columns: ZenttoColDef[] = [
    { field: "cedula", headerName: "Cédula", width: 130, valueGetter: (_v, row) => norm(row, "CEDULA", "cedula", "EmployeeCode") },
    { field: "nombre", headerName: "Nombre", flex: 1, minWidth: 200, valueGetter: (_v, row) => norm(row, "NOMBRE", "nombre", "EmployeeName") },
    { field: "cargo", headerName: "Cargo", width: 150, valueGetter: (_v, row) => norm(row, "CARGO", "cargo", "Position") },
    { field: "grupo", headerName: "Grupo", width: 120, valueGetter: (_v, row) => norm(row, "GRUPO", "grupo", "Department") },
    { field: "nomina", headerName: "Nómina", width: 120, valueGetter: (_v, row) => norm(row, "NOMINA", "nomina", "PayrollCode") },
    {
      field: "sueldo", headerName: "Sueldo", width: 130, type: "number",
      valueGetter: (_v, row) => Number(norm(row, "SUELDO", "sueldo", "Salary")) || 0,
      renderCell: (p) => formatCurrency(p.value ?? 0),
      currency: true,
      aggregation: 'sum',
    },
    {
      field: "status", headerName: "Status", width: 110,
      valueGetter: (_v, row) => norm(row, "STATUS", "status", "IsActive"),
      renderCell: (p) => {
        const v = String(p.value || "").toUpperCase();
        const active = v === "ACTIVO" || v === "A" || v === "1" || v === "TRUE";
        return <Chip label={active ? "Activo" : "Inactivo"} color={active ? "success" : "default"} size="small" />;
      },
      statusColors: { 'Activo': 'success', 'Inactivo': 'default' },
    },
    {
      field: "acciones", headerName: "", width: 120, sortable: false,
      renderCell: (p) => <RowActions row={p.row} />,
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
         
          value={filter.search || ""}
          onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
        />
        <FormControl sx={{ minWidth: 130 }}>
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
        <FormControl sx={{ minWidth: 130 }}>
          <InputLabel>Grupo</InputLabel>
          <Select
            value={filter.grupo || ""}
            label="Grupo"
            onChange={(e) => setFilter((f) => ({ ...f, grupo: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            {GRUPOS.map((g) => (
              <MenuItem key={g} value={g}>{g}</MenuItem>
            ))}
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <ZenttoDataGrid
            gridId="nomina-empleados-list"
          rows={rows}
          columns={columns}
          loading={isLoading}
          enableHeaderFilters
          paginationMode="server"
          rowCount={totalCount}
          paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 50 }}
          onPaginationModelChange={(m) => setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))}
          pageSizeOptions={[25, 50, 100]}
          disableRowSelectionOnClick
          getRowId={(r) => r.CEDULA ?? r.cedula ?? r.EmployeeCode ?? Math.random()}
          showTotals
          totalsLabel="Total"
          enableGrouping
          enableClipboard
          mobileVisibleFields={['cedula', 'nombre']}
          smExtraFields={['cargo', 'grupo']}
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
              <FormControl fullWidth>
                <InputLabel>Grupo / Depto.</InputLabel>
                <Select
                  value={form.GRUPO || ""}
                  label="Grupo / Depto."
                  onChange={(e) => setForm((f) => ({ ...f, GRUPO: e.target.value }))}
                >
                  <MenuItem value="">—</MenuItem>
                  {GRUPOS.map((g) => (
                    <MenuItem key={g} value={g}>{g}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Stack>
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth>
                <InputLabel>Nómina</InputLabel>
                <Select
                  value={form.NOMINA || ""}
                  label="Nómina"
                  onChange={(e) => setForm((f) => ({ ...f, NOMINA: e.target.value }))}
                >
                  <MenuItem value="">—</MenuItem>
                  {NOMINAS.map((n) => (
                    <MenuItem key={n} value={n}>{n}</MenuItem>
                  ))}
                </Select>
              </FormControl>
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

      {/* Procesar Vacaciones */}
      <Dialog
        open={vacCedula != null}
        onClose={() => setVacCedula(null)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>Procesar Vacaciones — {vacNombre} ({vacCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {vacCedula && (
            <VacacionesWizard
              initialCedula={vacCedula}
              onClose={() => setVacCedula(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Calcular Liquidación */}
      <Dialog
        open={liqCedula != null}
        onClose={() => setLiqCedula(null)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>Calcular Liquidación — {liqNombre} ({liqCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {liqCedula && (
            <LiquidacionesWizard
              initialCedula={liqCedula}
              onClose={() => setLiqCedula(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Procesar Nómina Individual */}
      <Dialog
        open={nominaCedula != null}
        onClose={() => setNominaCedula(null)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>Procesar Nómina — {nominaNombre} ({nominaCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {nominaCedula && (
            <NominaWizard
              initialCedula={nominaCedula}
              onClose={() => setNominaCedula(null)}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Historial de Nómina */}
      <Dialog
        open={historialCedula != null}
        onClose={() => setHistorialCedula(null)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Historial de Nómina — {historialNombre} ({historialCedula})</DialogTitle>
        <DialogContent>
          {historial.isLoading ? (
            <Box sx={{ textAlign: "center", py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (() => {
            const hRows = historial.data?.data ?? historial.data?.rows ?? [];
            if (hRows.length === 0) {
              return <Typography color="text.secondary" sx={{ py: 2 }}>No se encontraron registros de nómina para este empleado.</Typography>;
            }
            return (
              <ZenttoDataGrid
                rows={hRows}
                columns={[
                  { field: "nomina", headerName: "Nómina", width: 120 },
                  { field: "fechaInicio", headerName: "Desde", width: 110 },
                  { field: "fechaHasta", headerName: "Hasta", width: 110 },
                  { field: "totalAsignaciones", headerName: "Asignaciones", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
                  { field: "totalDeducciones", headerName: "Deducciones", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
                  { field: "netoAPagar", headerName: "Neto", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0) },
                  {
                    field: "estado", headerName: "Estado", width: 100,
                    renderCell: (p) => (
                      <Chip label={p.value || "ABIERTA"} size="small" color={p.value === "CERRADA" ? "default" : "success"} />
                    ),
                  },
                ]}
                autoHeight
                disableRowSelectionOnClick
                getRowId={(r) => `${r.nomina}-${r.fechaInicio ?? Math.random()}`}
                pageSizeOptions={[10, 25]}
                initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
                hideToolbar
                mobileDetailDrawer={false}
                density="compact"
                mobileVisibleFields={['nomina', 'netoAPagar']}
                smExtraFields={['fechaInicio', 'estado']}
              />
            );
          })()}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHistorialCedula(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
