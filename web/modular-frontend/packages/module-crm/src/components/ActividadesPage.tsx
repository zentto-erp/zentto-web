"use client";

import React, { useState } from "react";
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
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import PeopleIcon from "@mui/icons-material/People";
import NoteIcon from "@mui/icons-material/Note";
import TaskIcon from "@mui/icons-material/Task";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import {
  useActivitiesList,
  useCreateActivity,
  useCompleteActivity,
  type Activity,
  type ActivityFilter,
} from "../hooks/useCRM";

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

  const { data, isLoading } = useActivitiesList(filter);
  const createActivity = useCreateActivity();
  const completeActivity = useCompleteActivity();

  const rows: Activity[] = data?.data ?? data?.rows ?? [];
  const totalCount = data?.totalCount ?? data?.TotalCount ?? rows.length;

  const columns: ZenttoColDef[] = [
    {
      field: "Subject",
      headerName: "Asunto",
      flex: 1,
      minWidth: 200,
    },
    {
      field: "ActivityType",
      headerName: "Tipo",
      width: 130,
      renderCell: (p) => {
        const cfg = typeConfig[p.value] ?? typeConfig.TASK;
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
      headerName: "Fecha límite",
      width: 140,
    },
    {
      field: "IsCompleted",
      headerName: "Completada",
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
      headerName: "Asignado a",
      width: 150,
    },
    {
      field: "LeadCode",
      headerName: "Lead",
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
        <ZenttoDataGrid
        gridId="crm-actividades-list"
          rows={rows}
          columns={columns}
          getRowId={(r) => r.ActivityId}
          loading={isLoading}
          enableHeaderFilters
          paginationMode="server"
          rowCount={totalCount}
          pageSizeOptions={[10, 25, 50]}
          paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
          onPaginationModelChange={(m) => setFilter({ ...filter, page: m.page + 1, limit: m.pageSize })}
          autoHeight
          disableRowSelectionOnClick
          sx={{ border: "none" }}
          mobileVisibleFields={['Subject', 'ActivityType']}
          smExtraFields={['DueDate', 'IsCompleted']}
        />
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
