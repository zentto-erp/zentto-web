"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import {
  useLeadsList,
  usePipelinesList,
  usePipelineStages,
  useCreateLead,
  useUpdateLead,
  type Lead,
  type LeadFilter,
} from "../hooks/useCRM";
import type { ColumnDef } from "@zentto/datagrid-core";

const priorityColor: Record<string, "error" | "warning" | "info" | "default"> = {
  HIGH: "error",
  MEDIUM: "warning",
  LOW: "info",
};

const statusColor: Record<string, "success" | "error" | "info" | "default"> = {
  OPEN: "info",
  WON: "success",
  LOST: "error",
};

const statusLabel: Record<string, string> = {
  OPEN: "Abierto",
  WON: "Ganado",
  LOST: "Perdido",
};

const emptyLead = {
  contactName: "",
  companyName: "",
  email: "",
  phone: "",
  estimatedValue: "",
  priority: "MEDIUM",
  source: "",
  notes: "",
  pipelineId: "" as number | string,
  stageId: "" as number | string,
};

const LEADS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "OPEN", label: "Abierto" },
      { value: "WON", label: "Ganado" },
      { value: "LOST", label: "Perdido" },
    ],
  },
  {
    field: "prioridad", label: "Prioridad", type: "select",
    options: [
      { value: "HIGH", label: "Alta" },
      { value: "MEDIUM", label: "Media" },
      { value: "LOW", label: "Baja" },
    ],
  },
];

export default function LeadsPage() {
  const [filter, setFilter] = useState<LeadFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyLead);
  const [searchText, setSearchText] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useLeadsList(filter);
  const { data: pipelinesData } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];

  const selectedPipelineId = typeof form.pipelineId === "number" ? form.pipelineId : undefined;
  const { data: stagesData } = usePipelineStages(selectedPipelineId);
  const stages = stagesData?.data ?? stagesData?.rows ?? stagesData ?? [];

  const createLead = useCreateLead();
  const updateLead = useUpdateLead();

  const rows = data?.data ?? data?.rows ?? [];
  const totalCount = data?.totalCount ?? data?.TotalCount ?? rows.length;

  const columns: ColumnDef[] = [
    { field: "LeadCode", header: "Código", width: 110 },
    { field: "ContactName", header: "Contacto", flex: 1, minWidth: 160 },
    { field: "CompanyName", header: "Empresa", width: 160 },
    { field: "Email", header: "Email", width: 180 },
    { field: "Phone", header: "Teléfono", width: 130 },
    { field: "StageName", header: "Etapa", width: 130 },
    {
      field: "EstimatedValue",
      header: "Valor Est.",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "Priority",
      header: "Prioridad",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value === "HIGH" ? "Alta" : p.value === "MEDIUM" ? "Media" : "Baja"}
          size="small"
          color={priorityColor[p.value] ?? "default"}
        />
      ),
    },
    {
      field: "Status",
      header: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={statusLabel[p.value] ?? p.value}
          size="small"
          color={statusColor[p.value] ?? "default"}
        />
      ),
    },
    { field: "Source", header: "Origen", width: 110 },
    { field: "AssignedToName", header: "Asignado a", width: 140 },
  ];

  const handleOpenNew = () => {
    setEditId(null);
    setForm({ ...emptyLead, pipelineId: pipelines[0]?.PipelineId ?? "" });
    setDialogOpen(true);
  };

  const handleEdit = (lead: Lead) => {
    setEditId(lead.LeadId);
    setForm({
      contactName: lead.ContactName,
      companyName: lead.CompanyName ?? "",
      email: lead.Email ?? "",
      phone: lead.Phone ?? "",
      estimatedValue: String(lead.EstimatedValue ?? ""),
      priority: lead.Priority,
      source: lead.Source ?? "",
      notes: lead.Notes ?? "",
      pipelineId: lead.PipelineId,
      stageId: lead.StageId,
    });
    setDialogOpen(true);
  };

  const handleSave = () => {
    const payload = {
      ...form,
      estimatedValue: Number(form.estimatedValue) || 0,
      pipelineId: Number(form.pipelineId),
      stageId: Number(form.stageId),
    };

    if (editId) {
      updateLead.mutate({ id: editId, ...payload }, { onSuccess: () => setDialogOpen(false) });
    } else {
      createLead.mutate(payload, { onSuccess: () => setDialogOpen(false) });
    }
  };

  // Bind data to zentto-grid web component

  useEffect(() => {

    const el = gridRef.current;

    if (!el || !registered) return;

    el.columns = columns;

    el.rows = rows;

    el.loading = isLoading;

  }, [rows, isLoading, registered, columns]);


  return (
    <Box>
      <ContextActionHeader
        title="Leads"
        actions={
          <Button variant="contained" startIcon={<AddIcon />} onClick={handleOpenNew}>
            Nuevo Lead
          </Button>
        }
      />

      {/* Filtros */}
      <Box sx={{ mb: 2 }}>
        <ZenttoFilterPanel
          filters={LEADS_FILTERS}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              status: vals.estado || undefined,
              priority: vals.prioridad || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Nombre, empresa, email..."
          searchValue={searchText}
          onSearchChange={(v) => {
            setSearchText(v);
            setFilter((f) => ({ ...f, search: v || undefined, page: 1 }));
          }}
        />
      </Box>

      {/* DataGrid */}
      <Paper sx={{ borderRadius: 2 }}>
        <zentto-grid
        ref={gridRef}
        export-filename="crm-leads-list"
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

      {/* Dialog Crear/Editar */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editId ? "Editar Lead" : "Nuevo Lead"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Nombre de contacto"
              fullWidth
              required
              value={form.contactName}
              onChange={(e) => setForm({ ...form, contactName: e.target.value })}
            />
            <TextField
              label="Empresa"
              fullWidth
              value={form.companyName}
              onChange={(e) => setForm({ ...form, companyName: e.target.value })}
            />
            <Stack direction="row" spacing={2}>
              <TextField
                label="Email"
                fullWidth
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
              />
              <TextField
                label="Teléfono"
                fullWidth
                value={form.phone}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
              />
            </Stack>
            <Stack direction="row" spacing={2}>
              <FormControl fullWidth>
                <InputLabel>Pipeline</InputLabel>
                <Select
                  value={form.pipelineId}
                  label="Pipeline"
                  onChange={(e) => setForm({ ...form, pipelineId: Number(e.target.value), stageId: "" })}
                >
                  {pipelines.map((p: any) => (
                    <MenuItem key={p.PipelineId} value={p.PipelineId}>{p.Name}</MenuItem>
                  ))}
                </Select>
              </FormControl>
              <FormControl fullWidth>
                <InputLabel>Etapa</InputLabel>
                <Select
                  value={form.stageId}
                  label="Etapa"
                  onChange={(e) => setForm({ ...form, stageId: Number(e.target.value) })}
                >
                  {stages.map((s: any) => (
                    <MenuItem key={s.StageId} value={s.StageId}>{s.Name}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField
                label="Valor estimado"
                fullWidth
                type="number"
                value={form.estimatedValue}
                onChange={(e) => setForm({ ...form, estimatedValue: e.target.value })}
              />
              <FormControl fullWidth>
                <InputLabel>Prioridad</InputLabel>
                <Select
                  value={form.priority}
                  label="Prioridad"
                  onChange={(e) => setForm({ ...form, priority: e.target.value })}
                >
                  <MenuItem value="HIGH">Alta</MenuItem>
                  <MenuItem value="MEDIUM">Media</MenuItem>
                  <MenuItem value="LOW">Baja</MenuItem>
                </Select>
              </FormControl>
            </Stack>
            <TextField
              label="Origen"
              fullWidth
              value={form.source}
              onChange={(e) => setForm({ ...form, source: e.target.value })}
            />
            <TextField
              label="Notas"
              fullWidth
              multiline
              rows={2}
              value={form.notes}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={!form.contactName.trim() || createLead.isPending || updateLead.isPending}
          >
            {createLead.isPending || updateLead.isPending ? "Guardando..." : editId ? "Guardar" : "Crear"}
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
