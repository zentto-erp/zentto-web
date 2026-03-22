"use client";

import React, { useState } from "react";
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
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useLeadsList,
  usePipelinesList,
  usePipelineStages,
  useCreateLead,
  useUpdateLead,
  type Lead,
  type LeadFilter,
} from "../hooks/useCRM";

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

export default function LeadsPage() {
  const [filter, setFilter] = useState<LeadFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyLead);
  const [searchText, setSearchText] = useState("");

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

  const columns: GridColDef[] = [
    { field: "LeadCode", headerName: "Código", width: 110 },
    { field: "ContactName", headerName: "Contacto", flex: 1, minWidth: 160 },
    { field: "CompanyName", headerName: "Empresa", width: 160 },
    { field: "Email", headerName: "Email", width: 180 },
    { field: "Phone", headerName: "Teléfono", width: 130 },
    { field: "StageName", headerName: "Etapa", width: 130 },
    {
      field: "EstimatedValue",
      headerName: "Valor Est.",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "Priority",
      headerName: "Prioridad",
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
      headerName: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={statusLabel[p.value] ?? p.value}
          size="small"
          color={statusColor[p.value] ?? "default"}
        />
      ),
    },
    { field: "Source", headerName: "Origen", width: 110 },
    { field: "AssignedToName", headerName: "Asignado a", width: 140 },
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

  const handleSearch = () => {
    setFilter({ ...filter, search: searchText || undefined, page: 1 });
  };

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
      <Paper sx={{ p: 2, mb: 2, borderRadius: 2 }}>
        <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap">
          <TextField
            size="small"
            label="Buscar"
            placeholder="Nombre, empresa, email..."
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSearch()}
            sx={{ minWidth: 240 }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Pipeline</InputLabel>
            <Select
              value={filter.pipelineId ?? ""}
              label="Pipeline"
              onChange={(e) => setFilter({ ...filter, pipelineId: e.target.value ? Number(e.target.value) : undefined, page: 1 })}
            >
              <MenuItem value="">Todos</MenuItem>
              {pipelines.map((p: any) => (
                <MenuItem key={p.PipelineId} value={p.PipelineId}>{p.Name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filter.status ?? ""}
              label="Estado"
              onChange={(e) => setFilter({ ...filter, status: e.target.value || undefined, page: 1 })}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="OPEN">Abierto</MenuItem>
              <MenuItem value="WON">Ganado</MenuItem>
              <MenuItem value="LOST">Perdido</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Prioridad</InputLabel>
            <Select
              value={filter.priority ?? ""}
              label="Prioridad"
              onChange={(e) => setFilter({ ...filter, priority: e.target.value || undefined, page: 1 })}
            >
              <MenuItem value="">Todas</MenuItem>
              <MenuItem value="HIGH">Alta</MenuItem>
              <MenuItem value="MEDIUM">Media</MenuItem>
              <MenuItem value="LOW">Baja</MenuItem>
            </Select>
          </FormControl>
          <Button variant="outlined" size="small" onClick={handleSearch}>
            Filtrar
          </Button>
        </Stack>
      </Paper>

      {/* DataGrid */}
      <Paper sx={{ borderRadius: 2 }}>
        <DataGrid
          rows={rows}
          columns={columns}
          getRowId={(r) => r.LeadId}
          loading={isLoading}
          paginationMode="server"
          rowCount={totalCount}
          pageSizeOptions={[10, 25, 50]}
          paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
          onPaginationModelChange={(m) => setFilter({ ...filter, page: m.page + 1, limit: m.pageSize })}
          onRowClick={(p) => handleEdit(p.row as Lead)}
          autoHeight
          disableRowSelectionOnClick
          sx={{ border: "none" }}
        />
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
