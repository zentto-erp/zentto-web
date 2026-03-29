"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  MenuItem, Select, FormControl, InputLabel, CircularProgress,
} from "@mui/material";
import { DatePicker } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import { useGridLayoutSync } from "@zentto/shared-api";
import {
  useOccHealthList, useCreateOccHealth, useUpdateOccHealth, useOccHealthDetail,
  type OccHealthFilter, type OccHealthInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const STATUS_LABELS: Record<string, string> = { OPEN: "Abierto", REPORTED: "Reportado", INVESTIGATING: "En Investigación", CLOSED: "Cerrado" };

const emptyForm: OccHealthInput = { employeeCode: "", type: "", date: "", severity: "LEVE", daysLost: 0, description: "", status: "OPEN", correctiveActions: "" };

const COLUMNS: ColumnDef[] = [
  { field: "OccurrenceDate", header: "Fecha", width: 110 },
  { field: "RecordType", header: "Tipo", width: 140, statusColors: { ACCIDENTE: "error", INCIDENTE: "warning", ENFERMEDAD: "info" }, statusVariant: "outlined" },
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "Severity", header: "Severidad", width: 120, statusColors: { LEVE: "success", MODERADO: "warning", GRAVE: "error", FATAL: "error" } },
  { field: "DaysLost", header: "Días Perdidos", width: 120, type: "number" },
  { field: "Status", header: "Estado", width: 140, statusColors: { OPEN: "warning", REPORTED: "info", INVESTIGATING: "info", CLOSED: "default" } },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
    ],
  },
];

const GRID_ID = buildNominaGridId("salud-ocupacional");



export default function SaludOcupacionalPage() {
  const gridRef = useRef<any>(null);
  const [filter, setFilter] = useState<OccHealthFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailId, setDetailId] = useState<number | null>(null);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState<OccHealthInput>({ ...emptyForm });

  const { data, isLoading } = useOccHealthList(filter);
  const createMutation = useCreateOccHealth();
  const updateMutation = useUpdateOccHealth();
  const detail = useOccHealthDetail(detailId);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useNominaGridRegistration(layoutReady);

  const rows = data?.data ?? data?.rows ?? [];
  useNominaGridId(gridRef, GRID_ID);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.OccupationalHealthId ?? `${r.EmployeeCode}-${r.OccurrenceDate}`;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setDetailId(row.OccupationalHealthId);
      if (action === "edit") {
        setForm({ id: row.OccupationalHealthId, employeeCode: row.EmployeeCode ?? "", type: row.RecordType ?? "", date: row.OccurrenceDate ?? "", severity: row.Severity ?? "LEVE", daysLost: row.DaysLost ?? 0, description: row.Description ?? "", status: row.Status ?? "OPEN", correctiveActions: row.CorrectiveAction ?? "" });
        setEditMode(true); setDialogOpen(true);
      }
    };
    el.addEventListener("action-click", handler);
    const createHandler = () => handleOpenCreate();
    el.addEventListener("create-click", createHandler);
    return () => { el.removeEventListener("action-click", handler); el.removeEventListener("create-click", createHandler); };
  }, [registered, rows]);

  const handleSave = async () => {
    if (editMode && form.id) await updateMutation.mutateAsync(form);
    else await createMutation.mutateAsync(form);
    setDialogOpen(false); setEditMode(false); setForm({ ...emptyForm });
  };

  const handleOpenCreate = () => { setEditMode(false); setForm({ ...emptyForm }); setDialogOpen(true); };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>Salud Ocupacional</Typography>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot enable-create create-label="Nuevo Registro" />
      </Box>

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Registro" : "Nuevo Registro de Salud Ocupacional"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={form.employeeCode} onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel>
              <Select value={form.type} label="Tipo" onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <MenuItem value="ACCIDENTE">Accidente</MenuItem><MenuItem value="INCIDENTE">Incidente</MenuItem><MenuItem value="ENFERMEDAD">Enfermedad</MenuItem>
              </Select>
            </FormControl>
            <DatePicker label="Fecha" value={form.date ? dayjs(form.date) : null} onChange={(v) => setForm((f) => ({ ...f, date: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <FormControl fullWidth><InputLabel>Severidad</InputLabel>
              <Select value={form.severity} label="Severidad" onChange={(e) => setForm((f) => ({ ...f, severity: e.target.value }))}>
                <MenuItem value="LEVE">Leve</MenuItem><MenuItem value="MODERADO">Moderado</MenuItem>
                <MenuItem value="GRAVE">Grave</MenuItem><MenuItem value="FATAL">Fatal</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Días Perdidos" type="number" fullWidth value={form.daysLost || ""} onChange={(e) => setForm((f) => ({ ...f, daysLost: Number(e.target.value) }))} />
            <TextField label="Descripción" fullWidth multiline rows={3} value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
            <TextField label="Acciones Correctivas" fullWidth multiline rows={2} value={form.correctiveActions || ""} onChange={(e) => setForm((f) => ({ ...f, correctiveActions: e.target.value }))} />
            {editMode && (
              <FormControl fullWidth><InputLabel>Estado</InputLabel>
                <Select value={form.status || "OPEN"} label="Estado" onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}>
                  <MenuItem value="OPEN">Abierto</MenuItem><MenuItem value="REPORTED">Reportado</MenuItem>
                  <MenuItem value="INVESTIGATING">En Investigación</MenuItem><MenuItem value="CLOSED">Cerrado</MenuItem>
                </Select>
              </FormControl>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={createMutation.isPending || updateMutation.isPending}>{editMode ? "Actualizar" : "Guardar"}</Button>
        </DialogActions>
      </Dialog>

      {/* Detail Dialog */}
      <Dialog open={detailId != null} onClose={() => setDetailId(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle del Registro</DialogTitle>
        <DialogContent>
          {detail.isLoading ? <CircularProgress /> : (
            <Stack spacing={1.5} mt={1}>
              <Typography variant="body2"><strong>Empleado:</strong> {detail.data?.EmployeeName ?? detail.data?.EmployeeCode}</Typography>
              <Typography variant="body2"><strong>Tipo:</strong> {detail.data?.RecordType}</Typography>
              <Typography variant="body2"><strong>Fecha:</strong> {detail.data?.OccurrenceDate}</Typography>
              <Typography variant="body2"><strong>Severidad:</strong> {detail.data?.Severity}</Typography>
              <Typography variant="body2"><strong>Días Perdidos:</strong> {detail.data?.DaysLost ?? 0}</Typography>
              <Typography variant="body2"><strong>Estado:</strong> {STATUS_LABELS[detail.data?.Status] || detail.data?.Status}</Typography>
              <Typography variant="body2"><strong>Descripción:</strong> {detail.data?.Description}</Typography>
              <Typography variant="body2"><strong>Acciones Correctivas:</strong> {detail.data?.CorrectiveAction || "—"}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions><Button onClick={() => setDetailId(null)}>Cerrar</Button></DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
