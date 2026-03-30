"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
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
  Button,
} from "@mui/material";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import PeopleIcon from "@mui/icons-material/People";
import NoteIcon from "@mui/icons-material/Note";
import TaskIcon from "@mui/icons-material/Task";
import { ContextActionHeader, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useCRMGridRegistration } from "./zenttoGridPersistence";
import {
  useActivitiesList,
  useCreateActivity,
  useCompleteActivity,
  type Activity,
  type ActivityFilter,
} from "../hooks/useCRM";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";


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

const GRID_ID = "module-crm:actividades:list";

export default function ActividadesPage() {
  const [filter, setFilter] = useState<ActivityFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState(emptyActivity);
  const gridRef = useRef<any>(null);
  const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useCRMGridRegistration(gridLayoutReady);

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
      renderCell: ((value: unknown) => {
        const v = value as string;
        const cfg = typeConfig[v] ?? typeConfig.TASK;
        return (
          <Chip
            icon={cfg.icon as React.ReactElement}
            label={typeLabel[v] ?? v}
            size="small"
            color={cfg.color}
            variant="outlined"
          />
        );
      }) as unknown as ColumnDef["renderCell"],
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
      renderCell: ((value: unknown, row: GridRow) => (
        <Checkbox
          checked={!!value}
          onChange={() => {
            if (!value) {
              completeActivity.mutate(row.ActivityId as number);
            }
          }}
          disabled={!!value}
          size="small"
        />
      )) as unknown as ColumnDef["renderCell"],
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
    {
      field: "actions",
      header: "Acciones",
      type: "actions",
      width: 130,
      pin: "right",
      actions: [
        { icon: "view", label: "Ver", action: "view", color: "#6b7280" },
        { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
        { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
      ],
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

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setDialogOpen(true);
    el.addEventListener("create-click", handler);
    return () => el.removeEventListener("create-click", handler);
  }, [registered]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Actividades"
      />

      {/* DataGrid */}
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        export-filename="crm-actividades-list"
        height="calc(100vh - 200px)"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-grouping
        enable-pivot
        enable-create
        create-label="Nueva Actividad"
      ></zentto-grid>
      </Box>

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
