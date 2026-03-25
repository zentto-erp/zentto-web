"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Button,
  Chip,
  Checkbox,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import PeopleIcon from "@mui/icons-material/People";
import NoteIcon from "@mui/icons-material/Note";
import TaskIcon from "@mui/icons-material/Task";
import { ContextActionHeader, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import {
  useActivitiesList,
  useCreateActivity,
  useCompleteActivity,
  type Activity,
  type ActivityFilter,
} from "../hooks/useCRM";
import type { ColumnDef } from "@zentto/datagrid-core";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

const typeConfig: Record<string, { icon: React.ReactNode; color: "primary" | "secondary" | "success" | "warning" | "info" }> = {
  CALL: { icon: <PhoneIcon sx={{ fontSize: 14 }} />, color: "primary" },
  EMAIL: { icon: <EmailIcon sx={{ fontSize: 14 }} />, color: "info" },
  MEETING: { icon: <PeopleIcon sx={{ fontSize: 14 }} />, color: "success" },
  NOTE: { icon: <NoteIcon sx={{ fontSize: 14 }} />, color: "warning" },
  TASK: { icon: <TaskIcon sx={{ fontSize: 14 }} />, color: "secondary" },
};

const typeLabel: Record<string, string> = {
  CALL: "Llamada",
  EMAIL: "Correo",
  MEETING: "Reunión",
  NOTE: "Nota",
  TASK: "Tarea",
};

const emptyActivity = {
  leadId: "" as number | string,
  activityType: "CALL",
  subject: "",
  description: "",
  dueDate: "",
};

const ACTIVIDADES_FILTERS: FilterFieldDef[] = [
  {
    field: "tipo", label: "Tipo", type: "select",
    options: [
      { value: "CALL", label: "Llamada" },
      { value: "EMAIL", label: "Correo" },
      { value: "MEETING", label: "Reunion" },
      { value: "NOTE", label: "Nota" },
      { value: "TASK", label: "Tarea" },
    ],
  },
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "false", label: "Pendientes" },
      { value: "true", label: "Completadas" },
    ],
  },
];

export default function ActividadesPage() {
  const [filter, setFilter] = useState<ActivityFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState(emptyActivity);
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useActivitiesList(filter);
  const createActivity = useCreateActivity();
  const completeActivity = useCompleteActivity();

  const rows: Activity[] = data?.data ?? data?.rows ?? [];
  const totalCount = data?.totalCount ?? data?.TotalCount ?? rows.length;

  const columns: ColumnDef[] = [
    {
      field: "Subject",
      header: "Asunto",
      flex: 1,
      minWidth: 200,
    },
    {
      field: "ActivityType",
      header: "Tipo",
      width: 130,
      renderCell: (p) => {
        const cfg = typeConfig[p.value] ?? typeConfig.TASK;
        // Bind data to zentto-grid web component
        return (
          <Chip
            icon={cfg.icon as React.ReactElement}
            label={typeLabel[p.value] ?? p.value}
            size="small"
            color={cfg.color}
            variant="outlined"
          />
        );
      },
    },
    {
      field: "DueDate",
      header: "Fecha límite",
      width: 140,
    },
    {
      field: "IsCompleted",
      header: "Completada",
      width: 110,
      renderCell: (p) => (
        <Checkbox
          checked={!!p.value}
          onChange={() => {
            if (!p.value) {
              completeActivity.mutate(p.row.ActivityId);
            }
          }}
          disabled={!!p.value}
          size="small"
        />
      ),
    },
    {
      field: "AssignedToName",
      header: "Asignado a",
      width: 150,
    },
    {
      field: "LeadCode",
      header: "Lead",
      width: 120,
    },
  ];

  const handleCreate = () => {
    createActivity.mutate(
      {
        ...form,
        leadId: form.leadId ? Number(form.leadId) : undefined,
      },
      {
        onSuccess: () => {
          setDialogOpen(false);
          setForm(emptyActivity);
        },
      }
    );
  };

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
    el.actionButtons = [
      { icon: SVG_VIEW, label: "Ver", action: "view", color: "#6b7280" },
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") { /* TODO: ver detalle */ }
      if (action === "edit") { setDialogOpen(true); }
      if (action === "delete") { /* TODO: eliminar */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box>
      <ContextActionHeader
        title="Actividades"
        actions={
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
            Nueva Actividad
          </Button>
        }
      />

      {/* Filtros */}
      <Box sx={{ mb: 2 }}>
        <ZenttoFilterPanel
          filters={ACTIVIDADES_FILTERS}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              type: vals.tipo || undefined,
              isCompleted: vals.estado === "" || !vals.estado ? undefined : vals.estado === "true",
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar actividades..."
          searchValue=""
          onSearchChange={() => {}}
        />
      </Box>

      {/* DataGrid */}
      <Paper sx={{ borderRadius: 2 }}>
        <zentto-grid
        ref={gridRef}
        export-filename="crm-actividades-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>
      </Paper>

      {/* Dialog Crear */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Actividad</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <FormControl fullWidth>
              <InputLabel>Tipo de actividad</InputLabel>
              <Select
                value={form.activityType}
                label="Tipo de actividad"
                onChange={(e) => setForm({ ...form, activityType: e.target.value })}
              >
                <MenuItem value="CALL">Llamada</MenuItem>
                <MenuItem value="EMAIL">Correo</MenuItem>
                <MenuItem value="MEETING">Reunión</MenuItem>
                <MenuItem value="NOTE">Nota</MenuItem>
                <MenuItem value="TASK">Tarea</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Asunto"
              fullWidth
              required
              value={form.subject}
              onChange={(e) => setForm({ ...form, subject: e.target.value })}
            />
            <TextField
              label="Descripción"
              fullWidth
              multiline
              rows={3}
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
            <DatePicker
              label="Fecha límite"
              value={form.dueDate ? dayjs(form.dueDate) : null}
              onChange={(v) => setForm({ ...form, dueDate: v ? v.format('YYYY-MM-DD') : '' })}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <TextField
              label="Lead ID (opcional)"
              fullWidth
              type="number"
              value={form.leadId}
              onChange={(e) => setForm({ ...form, leadId: e.target.value ? Number(e.target.value) : "" })}
              helperText="Dejar vacío si no está asociado a un lead"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={!form.subject.trim() || createActivity.isPending}
          >
            {createActivity.isPending ? "Creando..." : "Crear"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
