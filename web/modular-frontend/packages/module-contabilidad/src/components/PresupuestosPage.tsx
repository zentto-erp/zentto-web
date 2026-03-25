"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, Stack, Alert, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Chip, IconButton, Tooltip, Tabs, Tab, CircularProgress, Divider,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import VisibilityIcon from "@mui/icons-material/Visibility";
import SaveIcon from "@mui/icons-material/Save";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import {
  usePresupuestosList, usePresupuestoGet, useCreatePresupuesto, useUpdatePresupuesto,
  useDeletePresupuesto, usePresupuestoVarianza,
  type Presupuesto, type PresupuestoDetalle, type PresupuestoLinea,
  type CreatePresupuestoInput, type VarianzaRow,
} from "../hooks/useContabilidadAdvanced";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

const MONTHS = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"];
const MONTH_FIELDS = ["month01","month02","month03","month04","month05","month06","month07","month08","month09","month10","month11","month12"] as const;

// ---- Form Dialog (unchanged) ----
function PresupuestoFormDialog({ open, onClose, editItem }: { open: boolean; onClose: () => void; editItem: Presupuesto | null }) {
  const createMutation = useCreatePresupuesto();
  const updateMutation = useUpdatePresupuesto();
  const isEditing = editItem != null;
  const [form, setForm] = useState({ name: editItem?.name ?? "", fiscalYear: editItem?.fiscalYear ?? new Date().getFullYear(), costCenterCode: editItem?.costCenterCode ?? "" });
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => { if (open) { setForm({ name: editItem?.name ?? "", fiscalYear: editItem?.fiscalYear ?? new Date().getFullYear(), costCenterCode: editItem?.costCenterCode ?? "" }); setError(null); } }, [open, editItem]);

  const handleSubmit = async () => {
    if (!form.name) { setError("El nombre es obligatorio"); return; }
    try {
      const payload: CreatePresupuestoInput = { name: form.name, fiscalYear: form.fiscalYear, costCenterCode: form.costCenterCode || undefined, lines: [] };
      if (isEditing) await updateMutation.mutateAsync({ ...payload, id: editItem.id }); else await createMutation.mutateAsync(payload);
      onClose();
    } catch (err: any) { setError(err.message || "Error al guardar"); }
  };
  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{isEditing ? "Editar presupuesto" : "Crear presupuesto"}</DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2, mt: 1 }}>{error}</Alert>}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField label="Nombre" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} fullWidth />
          <TextField label="Ano fiscal" type="number" value={form.fiscalYear} onChange={(e) => setForm({ ...form, fiscalYear: Number(e.target.value) })} fullWidth />
          <TextField label="Centro de Costo (opcional)" value={form.costCenterCode} onChange={(e) => setForm({ ...form, costCenterCode: e.target.value })} fullWidth placeholder="Dejar vacio para presupuesto global" />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={isPending}>{isPending ? "Guardando..." : isEditing ? "Actualizar" : "Crear"}</Button>
      </DialogActions>
    </Dialog>
  );
}

// ---- Detail View ----
const LINE_COLUMNS: ColumnDef[] = [
  { field: "accountCode", header: "Cuenta", width: 120 },
  { field: "accountName", header: "Descripcion", width: 180 },
  ...MONTHS.map((label, idx) => ({ field: MONTH_FIELDS[idx], header: label, width: 90, type: "number" as const, currency: "VES" as const })),
  { field: "annualTotal", header: "Total anual", width: 130, type: "number" as const, currency: "VES" as const },
];

function PresupuestoDetailView({ presupuestoId, onBack }: { presupuestoId: number; onBack: () => void }) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { data, isLoading } = usePresupuestoGet(presupuestoId);
  const [tabValue, setTabValue] = useState(0);
  const detail: PresupuestoDetalle | null = data?.data ?? data ?? null;
  const lines: PresupuestoLinea[] = detail?.lines ?? [];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered || tabValue !== 0) return;
    el.columns = LINE_COLUMNS;
    el.rows = lines.map((l, i) => ({ ...l, id: i }));
    el.loading = isLoading;
    // No actionButtons needed — read-only budget line detail
  }, [lines, isLoading, registered, tabValue]);

  return (
    <Box>
      <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 3 }}>
        <Tooltip title="Volver"><IconButton onClick={onBack}><ArrowBackIcon /></IconButton></Tooltip>
        <Typography variant="h5" fontWeight={700}>{detail?.name || "Presupuesto"}</Typography>
        {detail && <Chip label={`Ano ${detail.fiscalYear}`} color="primary" variant="outlined" />}
        {detail?.costCenterCode && <Chip label={`CC: ${detail.costCenterCode}`} variant="outlined" />}
      </Stack>
      <Paper sx={{ mb: 2 }}><Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}><Tab label="Detalle" /><Tab label="Varianza" /></Tabs></Paper>
      {tabValue === 0 && (
        <Paper sx={{ borderRadius: 2 }}>
          {!registered || isLoading ? <Box p={4} display="flex" justifyContent="center"><CircularProgress /></Box>
          : lines.length === 0 ? <Box p={4} textAlign="center"><Typography color="text.secondary">No hay lineas de presupuesto.</Typography></Box>
          : <Box sx={{ height: 400 }}>
              <zentto-grid ref={gridRef} default-currency="VES" height="100%" show-totals enable-editing
                enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
            </Box>
          }
        </Paper>
      )}
      {tabValue === 1 && <VarianzaTab presupuestoId={presupuestoId} />}
    </Box>
  );
}

// ---- Varianza Tab ----
const VARIANZA_COLUMNS: ColumnDef[] = [
  { field: "accountCode", header: "Cuenta", width: 120 },
  { field: "accountName", header: "Descripcion", flex: 1, minWidth: 180 },
  { field: "budget", header: "Presupuesto", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "actual", header: "Real", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "variance", header: "Varianza", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "variancePercent", header: "% Varianza", width: 120, type: "number" },
];

function VarianzaTab({ presupuestoId }: { presupuestoId: number }) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const { data, isLoading, error } = usePresupuestoVarianza(presupuestoId, fechaDesde, fechaHasta);
  const rows: VarianzaRow[] = useMemo(() => { const items = data?.data ?? data?.rows ?? []; return items.map((r: any, i: number) => ({ ...r, id: i })); }, [data]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = VARIANZA_COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    // No actionButtons needed — read-only variance report
  }, [rows, isLoading, registered]);

  return (
    <Box>
      <FormGrid spacing={2} sx={{ mb: 2 }} alignItems="center">
        <FormField xs={12} sm={6} md={4}>
          <DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
        </FormField>
        <FormField xs={12} sm={6} md={4}>
          <DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
        </FormField>
      </FormGrid>
      {isLoading ? <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
      : error ? <Alert severity="error">Error al cargar datos de varianza</Alert>
      : rows.length === 0 ? <Alert severity="info">No hay datos de varianza para este periodo</Alert>
      : (
        <Paper sx={{ borderRadius: 2 }}>
          {registered ? (
            <Box sx={{ height: 400 }}>
              <zentto-grid ref={gridRef} default-currency="VES" height="100%" show-totals
                enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
            </Box>
          ) : <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>}
        </Paper>
      )}
    </Box>
  );
}

// ---- Main Component ----
const PRESUPUESTOS_FILTERS: FilterFieldDef[] = [
  { field: "fiscalYear", label: "Ano fiscal", type: "select", options: Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map((y) => ({ value: String(y), label: String(y) })) },
  { field: "status", label: "Estado", type: "select", options: [{ value: "DRAFT", label: "Borrador" }, { value: "APPROVED", label: "Aprobado" }, { value: "CLOSED", label: "Cerrado" }] },
];

const MAIN_COLUMNS: ColumnDef[] = [
  { field: "id", header: "ID", width: 70 },
  { field: "name", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "fiscalYear", header: "Ano", width: 80, sortable: true },
  { field: "costCenterCode", header: "Centro costo", width: 140 },
  { field: "status", header: "Estado", width: 110, statusColors: { APPROVED: "success", CLOSED: "error", DRAFT: "default" }, statusVariant: "outlined" },
  { field: "total", header: "Total", width: 140, type: "number", currency: "VES", aggregation: "sum" },
];

export default function PresupuestosPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<Presupuesto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [fiscalYear, setFiscalYear] = useState<number>(new Date().getFullYear());
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = usePresupuestosList(fiscalYear);
  const deleteMutation = useDeletePresupuesto();

  const presupuestos: Presupuesto[] = useMemo(() => (data?.data ?? data?.rows ?? []).map((r: any) => ({ ...r, id: r.BudgetId ?? r.id ?? r.budgetId })), [data]);

  const filteredPresupuestos = useMemo(() => {
    let result = presupuestos;
    if (filterValues.status) result = result.filter((r: any) => (r.status || "DRAFT") === filterValues.status);
    if (search) { const s = search.toLowerCase(); result = result.filter((r: any) => (r.name || "").toLowerCase().includes(s)); }
    return result;
  }, [presupuestos, filterValues, search]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered || selectedId != null) return;
    el.columns = MAIN_COLUMNS;
    el.rows = filteredPresupuestos.map((r: any) => ({ ...r, id: r.BudgetId ?? r.id ?? r._id }));
    el.loading = isLoading;
    el.actionButtons = [
      { icon: SVG_VIEW, label: 'Ver', action: 'view' },
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: SVG_DELETE, label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ];
  }, [filteredPresupuestos, isLoading, registered, selectedId]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      const id = row.BudgetId ?? row.id;
      if (action === 'view') setSelectedId(id);
      if (action === 'edit') {
        const pres = presupuestos.find((p: any) => (p.BudgetId ?? p.id) === id);
        if (pres) { setEditItem(pres); setDialogOpen(true); }
      }
      if (action === 'delete') setDeleteConfirm(id);
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, presupuestos]);

  if (selectedId != null) return <PresupuestoDetailView presupuestoId={selectedId} onBack={() => setSelectedId(null)} />;

  const handleDelete = async (id: number) => {
    try { await deleteMutation.mutateAsync(id); setDeleteConfirm(null); } catch (err: any) { setError(err.message || "Error al eliminar"); }
  };

  if (!registered) return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Presupuestos</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { setEditItem(null); setDialogOpen(true); }}>Crear Presupuesto</Button>
      </Stack>
      <ZenttoFilterPanel filters={PRESUPUESTOS_FILTERS} values={filterValues}
        onChange={(vals) => { setFilterValues(vals); if (vals.fiscalYear) setFiscalYear(Number(vals.fiscalYear)); }}
        searchPlaceholder="Buscar presupuesto..." searchValue={search} onSearchChange={setSearch} />
      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}
      <Paper sx={{ borderRadius: 2 }}>
        <zentto-grid ref={gridRef} default-currency="VES" export-filename="presupuestos" height="calc(100vh - 300px)"
          enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
      </Paper>
      <PresupuestoFormDialog open={dialogOpen} onClose={() => { setDialogOpen(false); setEditItem(null); }} editItem={editItem} />
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)}>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent><Typography>Esta seguro de eliminar este presupuesto? Esta accion no se puede deshacer.</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={() => deleteConfirm != null && handleDelete(deleteConfirm)} disabled={deleteMutation.isPending}>
            {deleteMutation.isPending ? "Eliminando..." : "Eliminar"}
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
