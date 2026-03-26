"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  MenuItem, Select, FormControl, InputLabel,
} from "@mui/material";
import { DatePicker } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import {
  useMedOrderList, useCreateMedOrder, useApproveMedOrder,
  type MedOrderFilter, type MedOrderInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

const COLUMNS: ColumnDef[] = [
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "OrderType", header: "Tipo", width: 140, statusColors: { CONSULTA: "info", FARMACIA: "info", LABORATORIO: "info", EMERGENCIA: "error" }, statusVariant: "outlined" },
  { field: "OrderDate", header: "Fecha", width: 110 },
  { field: "Diagnosis", header: "Diagnóstico", width: 200 },
  { field: "EstimatedCost", header: "Costo", width: 120, type: "number", aggregation: "sum" },
  { field: "Status", header: "Estado", width: 120, statusColors: { APROBADO: "success", RECHAZADO: "error", PENDIENTE: "warning" } },
];


const SVG_APPROVE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>';
const SVG_REJECT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>';

export default function OrdenesMedicasPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<MedOrderFilter>({ page: 1, limit: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<MedOrderInput>({ employeeCode: "", type: "", date: "", diagnosis: "", cost: 0, description: "" });

  const { data, isLoading } = useMedOrderList(filter);
  const createMutation = useCreateMedOrder();
  const approveMutation = useApproveMedOrder();

  const rows = data?.data ?? data?.rows ?? [];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.MedicalOrderId ?? `${r.EmployeeCode}-${r.OrderDate}-${r.OrderType}`;
    el.actionButtons = [
      { icon: SVG_APPROVE, label: "Aprobar", action: "approve", color: "#2e7d32" },
      { icon: SVG_REJECT, label: "Rechazar", action: "reject", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (row.Status !== "PENDIENTE") return;
      if (action === "approve") approveMutation.mutate({ orderId: row.MedicalOrderId, approved: true });
      if (action === "reject") approveMutation.mutate({ orderId: row.MedicalOrderId, approved: false });
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  const handleSave = async () => {
    await createMutation.mutateAsync(form);
    setDialogOpen(false);
    setForm({ employeeCode: "", type: "", date: "", diagnosis: "", cost: 0, description: "" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Órdenes Médicas</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>Nueva Orden</Button>
      </Stack>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
      </Box>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Orden Médica</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={form.employeeCode} onChange={(code) => setForm((f) => ({ ...f, employeeCode: code }))} />
            <FormControl fullWidth><InputLabel>Tipo</InputLabel>
              <Select value={form.type} label="Tipo" onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}>
                <MenuItem value="CONSULTA">Consulta</MenuItem><MenuItem value="FARMACIA">Farmacia</MenuItem>
                <MenuItem value="LABORATORIO">Laboratorio</MenuItem><MenuItem value="EMERGENCIA">Emergencia</MenuItem>
              </Select>
            </FormControl>
            <DatePicker label="Fecha" value={form.date ? dayjs(form.date) : null} onChange={(v) => setForm((f) => ({ ...f, date: v ? v.format('YYYY-MM-DD') : '' }))} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            <TextField label="Diagnóstico" fullWidth value={form.diagnosis || ""} onChange={(e) => setForm((f) => ({ ...f, diagnosis: e.target.value }))} />
            <TextField label="Costo" type="number" fullWidth value={form.cost || ""} onChange={(e) => setForm((f) => ({ ...f, cost: Number(e.target.value) }))} />
            <TextField label="Descripción" fullWidth multiline rows={2} value={form.description || ""} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={createMutation.isPending}>Guardar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
