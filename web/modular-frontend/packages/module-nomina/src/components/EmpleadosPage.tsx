"use client";

import React, { useState, useEffect, useRef, useMemo } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  MenuItem, Select, FormControl, InputLabel, CircularProgress,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import NominaWizard from "./NominaWizard";
import VacacionesWizard from "./VacacionesWizard";
import LiquidacionesWizard from "./LiquidacionesWizard";
import {
  useEmpleadosList, useCreateEmpleado, useUpdateEmpleado, useDeleteEmpleado,
  type EmpleadoFilter, type EmpleadoInput,
} from "../hooks/useEmpleados";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useNominasList } from "../hooks/useNomina";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const GRUPOS = ["ADMIN", "ALMACEN", "GERENCIA", "PRODUCCION", "VENTAS"];
const NOMINAS = ["MENSUAL", "QUINCENAL", "SEMANAL"];


const emptyForm: EmpleadoInput = { CEDULA: "", NOMBRE: "", GRUPO: "", DIRECCION: "", TELEFONO: "", CARGO: "", NOMINA: "", SUELDO: 0, STATUS: "ACTIVO", SEXO: "", NACIONALIDAD: "" };

const COLUMNS: ColumnDef[] = [
  { field: "cedula", header: "Cédula", width: 130, sortable: true },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "cargo", header: "Cargo", width: 150, sortable: true },
  { field: "grupo", header: "Grupo", width: 120, sortable: true, groupable: true },
  { field: "nomina", header: "Nómina", width: 120, sortable: true, groupable: true },
  { field: "sueldo", header: "Sueldo", width: 130, type: "number", aggregation: "sum" },
  { field: "status", header: "Status", width: 110, statusColors: { Activo: "success", Inactivo: "default" } },
  {
    field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
    ],
  },
];

const HISTORIAL_COLUMNS: ColumnDef[] = [
  { field: "nomina", header: "Nómina", width: 120 },
  { field: "fechaInicio", header: "Desde", width: 110 },
  { field: "fechaHasta", header: "Hasta", width: 110 },
  { field: "totalAsignaciones", header: "Asignaciones", width: 130, type: "number" },
  { field: "totalDeducciones", header: "Deducciones", width: 130, type: "number" },
  { field: "netoAPagar", header: "Neto", width: 130, type: "number" },
  { field: "estado", header: "Estado", width: 100, statusColors: { CERRADA: "default", ABIERTA: "success" } },
];

const EMPLEADOS_GRID_ID = buildNominaGridId("empleados");
const EMPLEADOS_HISTORIAL_GRID_ID = buildNominaGridId("empleados", "historial");


export default function EmpleadosPage() {
  const gridRef = useRef<any>(null);
  const histGridRef = useRef<any>(null);
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
  const historial = useNominasList(historialCedula ? { cedula: historialCedula, limit: 50 } : { limit: 0 });
  const createMut = useCreateEmpleado();
  const updateMut = useUpdateEmpleado();
  const deleteMut = useDeleteEmpleado();
  const { ready: empleadosLayoutReady } = useGridLayoutSync(EMPLEADOS_GRID_ID);
  const { ready: historialLayoutReady } = useGridLayoutSync(EMPLEADOS_HISTORIAL_GRID_ID);
  const { registered } = useNominaGridRegistration(empleadosLayoutReady && historialLayoutReady);

  const rows = data?.data ?? data?.rows ?? data?.items ?? [];
  const totalCount = data?.totalCount ?? data?.total ?? rows.length;
  useNominaGridId(gridRef, EMPLEADOS_GRID_ID);
  useNominaGridId(histGridRef, EMPLEADOS_HISTORIAL_GRID_ID);

  const norm = (row: any, ...keys: string[]) => { for (const k of keys) if (row[k] !== undefined && row[k] !== null) return row[k]; return ""; };

  // Map rows for the grid
  const gridRows = useMemo(() => rows.map((row: any) => {
    const v = String(norm(row, "STATUS", "status", "IsActive") || "").toUpperCase();
    const active = v === "ACTIVO" || v === "A" || v === "1" || v === "TRUE";
    return {
      ...row,
      cedula: norm(row, "CEDULA", "cedula", "EmployeeCode"),
      nombre: norm(row, "NOMBRE", "nombre", "EmployeeName"),
      cargo: norm(row, "CARGO", "cargo", "Position"),
      grupo: norm(row, "GRUPO", "grupo", "Department"),
      nomina: norm(row, "NOMINA", "nomina", "PayrollCode"),
      sueldo: Number(norm(row, "SUELDO", "sueldo", "Salary")) || 0,
      status: active ? "Activo" : "Inactivo",
    };
  }), [rows]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = gridRows; el.loading = isLoading;
    el.getRowId = (r: any) => r.CEDULA ?? r.cedula ?? r.EmployeeCode ?? Math.random();
  }, [gridRows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row);
    };
    el.addEventListener("action-click", handler);
    const createHandler = () => handleNew();
    el.addEventListener("create-click", createHandler);
    return () => { el.removeEventListener("action-click", handler); el.removeEventListener("create-click", createHandler); };
  }, [registered, gridRows]);

  // Historial grid
  useEffect(() => {
    const el = histGridRef.current; if (!el || !registered || !historialCedula) return;
    const hRows = historial.data?.data ?? historial.data?.rows ?? [];
    el.columns = HISTORIAL_COLUMNS; el.rows = hRows; el.loading = historial.isLoading;
    el.getRowId = (r: any) => `${r.nomina}-${r.fechaInicio ?? Math.random()}`;
  }, [historial.data, historial.isLoading, registered, historialCedula]);

  const handleEdit = (row: any) => {
    const ced = norm(row, "CEDULA", "cedula", "EmployeeCode");
    setEditCedula(ced);
    setForm({
      CEDULA: ced, NOMBRE: norm(row, "NOMBRE", "nombre", "EmployeeName"),
      GRUPO: norm(row, "GRUPO", "grupo", "Department"), DIRECCION: norm(row, "DIRECCION", "direccion", "Address"),
      TELEFONO: norm(row, "TELEFONO", "telefono", "Phone"), CARGO: norm(row, "CARGO", "cargo", "Position"),
      NOMINA: norm(row, "NOMINA", "nomina", "PayrollCode"), SUELDO: Number(norm(row, "SUELDO", "sueldo", "Salary")) || 0,
      STATUS: norm(row, "STATUS", "status") || "ACTIVO", SEXO: norm(row, "SEXO", "sexo", "Gender"),
      NACIONALIDAD: norm(row, "NACIONALIDAD", "nacionalidad", "Nationality"),
    });
    setFormOpen(true);
  };

  const handleNew = () => { setEditCedula(null); setForm({ ...emptyForm }); setFormOpen(true); };

  const handleSave = async () => {
    if (editCedula) { const { CEDULA, ...rest } = form; await updateMut.mutateAsync({ cedula: editCedula, data: rest }); }
    else await createMut.mutateAsync(form);
    setFormOpen(false);
  };

  const handleDelete = async () => { if (!deleteTarget) return; await deleteMut.mutateAsync(deleteTarget); setDeleteTarget(null); };

  const saving = createMut.isPending || updateMut.isPending;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>Empleados</Typography>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot enable-create create-label="Nuevo Empleado" />
      </Box>

      {/* Create / Edit Dialog */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editCedula ? "Editar Empleado" : "Nuevo Empleado"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Cédula" fullWidth value={form.CEDULA} onChange={(e) => setForm((f) => ({ ...f, CEDULA: e.target.value }))} disabled={!!editCedula} />
            <TextField label="Nombre Completo" fullWidth value={form.NOMBRE} onChange={(e) => setForm((f) => ({ ...f, NOMBRE: e.target.value }))} />
            <Stack direction="row" spacing={2}>
              <TextField label="Cargo" fullWidth value={form.CARGO || ""} onChange={(e) => setForm((f) => ({ ...f, CARGO: e.target.value }))} />
              <FormControl fullWidth><InputLabel>Grupo / Depto.</InputLabel>
                <Select value={form.GRUPO || ""} label="Grupo / Depto." onChange={(e) => setForm((f) => ({ ...f, GRUPO: e.target.value }))}>
                  <MenuItem value="">—</MenuItem>{GRUPOS.map((g) => <MenuItem key={g} value={g}>{g}</MenuItem>)}
                </Select>
              </FormControl>
            </Stack>
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth><InputLabel>Nómina</InputLabel>
                <Select value={form.NOMINA || ""} label="Nómina" onChange={(e) => setForm((f) => ({ ...f, NOMINA: e.target.value }))}>
                  <MenuItem value="">—</MenuItem>{NOMINAS.map((n) => <MenuItem key={n} value={n}>{n}</MenuItem>)}
                </Select>
              </FormControl>
              <TextField label="Sueldo" type="number" fullWidth value={form.SUELDO || ""} onChange={(e) => setForm((f) => ({ ...f, SUELDO: Number(e.target.value) || 0 }))} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="Teléfono" fullWidth value={form.TELEFONO || ""} onChange={(e) => setForm((f) => ({ ...f, TELEFONO: e.target.value }))} />
              <FormControl fullWidth><InputLabel>Status</InputLabel>
                <Select value={form.STATUS || "ACTIVO"} label="Status" onChange={(e) => setForm((f) => ({ ...f, STATUS: e.target.value }))}>
                  <MenuItem value="ACTIVO">Activo</MenuItem><MenuItem value="INACTIVO">Inactivo</MenuItem>
                </Select>
              </FormControl>
            </Stack>
            <TextField label="Dirección" fullWidth value={form.DIRECCION || ""} onChange={(e) => setForm((f) => ({ ...f, DIRECCION: e.target.value }))} />
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth><InputLabel>Sexo</InputLabel>
                <Select value={form.SEXO || ""} label="Sexo" onChange={(e) => setForm((f) => ({ ...f, SEXO: e.target.value }))}>
                  <MenuItem value="">—</MenuItem><MenuItem value="M">Masculino</MenuItem><MenuItem value="F">Femenino</MenuItem>
                </Select>
              </FormControl>
              <TextField label="Nacionalidad" fullWidth value={form.NACIONALIDAD || ""} onChange={(e) => setForm((f) => ({ ...f, NACIONALIDAD: e.target.value }))} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving || !form.CEDULA || !form.NOMBRE}>{editCedula ? "Actualizar" : "Guardar"}</Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar Eliminación</DialogTitle>
        <DialogContent><Typography>¿Está seguro de eliminar al empleado <strong>{deleteTarget}</strong>?</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={deleteMut.isPending}>Eliminar</Button>
        </DialogActions>
      </Dialog>

      {/* Procesar Vacaciones */}
      <Dialog open={vacCedula != null} onClose={() => setVacCedula(null)} maxWidth="lg" fullWidth>
        <DialogTitle>Procesar Vacaciones — {vacNombre} ({vacCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {vacCedula && <VacacionesWizard initialCedula={vacCedula} onClose={() => setVacCedula(null)} />}
        </DialogContent>
      </Dialog>

      {/* Calcular Liquidación */}
      <Dialog open={liqCedula != null} onClose={() => setLiqCedula(null)} maxWidth="lg" fullWidth>
        <DialogTitle>Calcular Liquidación — {liqNombre} ({liqCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {liqCedula && <LiquidacionesWizard initialCedula={liqCedula} onClose={() => setLiqCedula(null)} />}
        </DialogContent>
      </Dialog>

      {/* Procesar Nómina Individual */}
      <Dialog open={nominaCedula != null} onClose={() => setNominaCedula(null)} maxWidth="lg" fullWidth>
        <DialogTitle>Procesar Nómina — {nominaNombre} ({nominaCedula})</DialogTitle>
        <DialogContent sx={{ p: 0, minHeight: 500 }}>
          {nominaCedula && <NominaWizard initialCedula={nominaCedula} onClose={() => setNominaCedula(null)} />}
        </DialogContent>
      </Dialog>

      {/* Historial de Nómina */}
      <Dialog open={historialCedula != null} onClose={() => setHistorialCedula(null)} maxWidth="md" fullWidth>
        <DialogTitle>Historial de Nómina — {historialNombre} ({historialCedula})</DialogTitle>
        <DialogContent>
          {historial.isLoading ? (
            <Box sx={{ textAlign: "center", py: 4 }}><CircularProgress /></Box>
          ) : (() => {
            const hRows = historial.data?.data ?? historial.data?.rows ?? [];
            if (hRows.length === 0) return <Typography color="text.secondary" sx={{ py: 2 }}>No se encontraron registros de nómina para este empleado.</Typography>;
            return (
              <Box sx={{ height: 400 }}>
                <zentto-grid ref={histGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
              </Box>
            );
          })()}
        </DialogContent>
        <DialogActions><Button onClick={() => setHistorialCedula(null)}>Cerrar</Button></DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
