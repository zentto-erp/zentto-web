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
  IconButton,
  Tooltip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
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
    { field: "EmployeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    {
      field: "OrderType",
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
    { field: "OrderDate", headerName: "Fecha", width: 110 },
    { field: "Diagnosis", headerName: "Diagnóstico", width: 200 },
    { field: "EstimatedCost", headerName: "Costo", width: 120, renderCell: (p) => formatCurrency(p.value ?? 0) },
    {
      field: "Status",
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
        p.row.Status === "PENDIENTE" ? (
          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Aprobar orden">
              <IconButton
                size="small"
                color="success"
                onClick={() => approveMutation.mutate({ orderId: p.row.MedicalOrderId, approved: true })}
              >
                <CheckCircleIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title="Rechazar orden">
              <IconButton
                size="small"
                color="error"
                onClick={() => approveMutation.mutate({ orderId: p.row.MedicalOrderId, approved: false })}
              >
                <CancelIcon fontSize="small" />
              </IconButton>
            </Tooltip>
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

      <FormGrid spacing={2} sx={{ mb: 2 }}>
        <FormField xs={12} sm={4}>
          <TextField
            label="Buscar"
           
            fullWidth
            value={filter.search || ""}
            onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
          />
        </FormField>
        <FormField xs={12} sm={4}>
          <FormControl fullWidth>
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
        </FormField>
        <FormField xs={12} sm={4}>
          <FormControl fullWidth>
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
        </FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.MedicalOrderId ?? `${r.EmployeeCode}-${r.OrderDate}-${r.OrderType}`}
          mobileVisibleFields={['EmployeeName', 'OrderType']}
          smExtraFields={['Status', 'OrderDate']}
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
            <DatePicker
              label="Fecha"
              value={form.date ? dayjs(form.date) : null}
              onChange={(v) => setForm((f) => ({ ...f, date: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
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
