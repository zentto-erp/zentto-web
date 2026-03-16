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
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import IconButton from "@mui/material/IconButton";
import { formatCurrency } from "@zentto/shared-api";
import {
  useMedOrderList,
  useCreateMedOrder,
  useApproveMedOrder,
  type MedOrderFilter,
  type MedOrderInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

export default function OrdenesMedicasPage() {
  const [filter, setFilter] = useState<MedOrderFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<MedOrderInput>({
    employeeCode: "",
    type: "",
    date: "",
    diagnosis: "",
    cost: 0,
    description: "",
  });

  const { data, isLoading } = useMedOrderList(filter);
  const createMutation = useCreateMedOrder();
  const approveMutation = useApproveMedOrder();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    {
      field: "type",
      headerName: "Tipo",
      width: 140,
      renderCell: (p) => (
        <Chip
          label={
            p.value === "CONSULTA" ? "Consulta" :
            p.value === "FARMACIA" ? "Farmacia" :
            p.value === "LABORATORIO" ? "Laboratorio" :
            p.value === "EMERGENCIA" ? "Emergencia" : p.value
          }
          size="small"
          variant="outlined"
          color={
            p.value === "EMERGENCIA" ? "error" :
            p.value === "LABORATORIO" ? "info" : "primary"
          }
        />
      ),
    },
    { field: "date", headerName: "Fecha", width: 110 },
    { field: "diagnosis", headerName: "Diagnóstico", width: 200 },
    { field: "cost", headerName: "Costo", width: 120, renderCell: (p) => formatCurrency(p.value ?? 0) },
    {
      field: "status",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={
            p.value === "APROBADO" ? "Aprobado" :
            p.value === "RECHAZADO" ? "Rechazado" : "Pendiente"
          }
          size="small"
          color={
            p.value === "APROBADO" ? "success" :
            p.value === "RECHAZADO" ? "error" : "warning"
          }
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) =>
        p.row.status === "PENDIENTE" ? (
          <Stack direction="row" spacing={0.5}>
            <IconButton
              size="small"
              color="success"
              title="Aprobar"
              onClick={() => approveMutation.mutate({ orderId: p.row.id, approved: true })}
            >
              <CheckCircleIcon fontSize="small" />
            </IconButton>
            <IconButton
              size="small"
              color="error"
              title="Rechazar"
              onClick={() => approveMutation.mutate({ orderId: p.row.id, approved: false })}
            >
              <CancelIcon fontSize="small" />
            </IconButton>
          </Stack>
        ) : null,
    },
  ];

  const handleSave = async () => {
    await createMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ employeeCode: "", type: "", date: "", diagnosis: "", cost: 0, description: "" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Órdenes Médicas</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nueva Orden
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
            <MenuItem value="CONSULTA">Consulta</MenuItem>
            <MenuItem value="FARMACIA">Farmacia</MenuItem>
            <MenuItem value="LABORATORIO">Laboratorio</MenuItem>
            <MenuItem value="EMERGENCIA">Emergencia</MenuItem>
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
            <MenuItem value="PENDIENTE">Pendiente</MenuItem>
            <MenuItem value="APROBADO">Aprobado</MenuItem>
            <MenuItem value="RECHAZADO">Rechazado</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? `${r.employeeCode}-${r.date}-${r.type}`}
        />
      </Paper>

      {/* Create Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Orden Médica</DialogTitle>
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
                <MenuItem value="CONSULTA">Consulta</MenuItem>
                <MenuItem value="FARMACIA">Farmacia</MenuItem>
                <MenuItem value="LABORATORIO">Laboratorio</MenuItem>
                <MenuItem value="EMERGENCIA">Emergencia</MenuItem>
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
            <TextField
              label="Diagnóstico"
              fullWidth
              value={form.diagnosis || ""}
              onChange={(e) => setForm((f) => ({ ...f, diagnosis: e.target.value }))}
            />
            <TextField
              label="Costo"
              type="number"
              fullWidth
              value={form.cost || ""}
              onChange={(e) => setForm((f) => ({ ...f, cost: Number(e.target.value) }))}
            />
            <TextField
              label="Descripción"
              fullWidth
              multiline
              rows={2}
              value={form.description || ""}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={createMutation.isPending}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
