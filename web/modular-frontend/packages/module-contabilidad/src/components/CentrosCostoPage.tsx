"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, Stack, Alert, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, MenuItem, Chip, IconButton, Tooltip, Collapse, Tabs, Tab,
  CircularProgress, Skeleton,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import PivotTableChartIcon from "@mui/icons-material/PivotTableChart";
import TableChartIcon from "@mui/icons-material/TableChart";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import {
  useCentrosCostoList, useCreateCentroCosto, useUpdateCentroCosto, useDeleteCentroCosto,
  usePnLByCostCenter, type CentroCosto, type CentroCostoInput,
} from "../hooks/useContabilidadAdvanced";

// ---- Types & Tree building (unchanged) ----
interface CentroCostoNode extends CentroCosto { children: CentroCostoNode[]; }

function buildCentroCostoTree(items: CentroCosto[]): CentroCostoNode[] {
  const map = new Map<string, CentroCostoNode>();
  const roots: CentroCostoNode[] = [];
  for (const item of items) map.set(item.code, { ...item, children: [] });
  for (const item of items) {
    const node = map.get(item.code)!;
    if (item.parentCode && map.has(item.parentCode)) map.get(item.parentCode)!.children.push(node);
    else roots.push(node);
  }
  return roots;
}

// ---- Tree Row (unchanged) ----
function CentroCostoTreeRow({ node, depth, expanded, onToggle, onEdit, onDelete }: {
  node: CentroCostoNode; depth: number; expanded: Set<string>;
  onToggle: (code: string) => void; onEdit: (item: CentroCosto) => void; onDelete: (code: string) => void;
}) {
  const hasChildren = node.children.length > 0;
  const isExpanded = expanded.has(node.code);
  return (
    <>
      <Box sx={{ display: "flex", alignItems: "center", py: 1, px: 2, pl: 2 + depth * 3,
        "&:hover": { bgcolor: "action.hover" }, borderBottom: "1px solid", borderColor: "divider" }}>
        {hasChildren ? (
          <Tooltip title={isExpanded ? "Colapsar" : "Expandir"}>
            <IconButton size="small" onClick={() => onToggle(node.code)} sx={{ mr: 1 }}>
              {isExpanded ? <ExpandMoreIcon fontSize="small" /> : <ChevronRightIcon fontSize="small" />}
            </IconButton>
          </Tooltip>
        ) : <Box sx={{ width: 32, mr: 1 }} />}
        <Typography variant="body2" sx={{ fontFamily: "monospace", fontWeight: 600, minWidth: 100, mr: 2 }}>{node.code}</Typography>
        <Typography variant="body2" sx={{ flex: 1, fontWeight: depth === 0 ? 600 : 400 }}>{node.name}</Typography>
        <Chip label={`N${node.level}`} size="small" variant="outlined" sx={{ mr: 1, fontSize: "0.7rem" }} />
        <Chip label={node.active ? "Activo" : "Inactivo"} size="small" color={node.active ? "success" : "default"} sx={{ mr: 1, fontSize: "0.7rem" }} />
        <Tooltip title="Editar"><IconButton size="small" color="primary" onClick={() => onEdit(node)}><EditIcon fontSize="small" /></IconButton></Tooltip>
        <Tooltip title="Eliminar"><IconButton size="small" color="error" onClick={() => onDelete(node.code)}><DeleteIcon fontSize="small" /></IconButton></Tooltip>
      </Box>
      {hasChildren && (
        <Collapse in={isExpanded} timeout="auto" unmountOnExit>
          {node.children.map((child) => (
            <CentroCostoTreeRow key={child.code} node={child} depth={depth + 1} expanded={expanded}
              onToggle={onToggle} onEdit={onEdit} onDelete={onDelete} />
          ))}
        </Collapse>
      )}
    </>
  );
}

// ---- Create/Edit Dialog (unchanged) ----
function CentroCostoDialog({ open, onClose, editItem, allCentros }: {
  open: boolean; onClose: () => void; editItem: CentroCosto | null; allCentros: CentroCosto[];
}) {
  const createMutation = useCreateCentroCosto();
  const updateMutation = useUpdateCentroCosto();
  const isEditing = editItem != null;
  const [form, setForm] = useState<CentroCostoInput>({ code: editItem?.code ?? "", name: editItem?.name ?? "", parentCode: editItem?.parentCode ?? null });
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    if (open) { setForm({ code: editItem?.code ?? "", name: editItem?.name ?? "", parentCode: editItem?.parentCode ?? null }); setError(null); }
  }, [open, editItem]);

  const handleSubmit = async () => {
    if (!form.code || !form.name) { setError("Codigo y nombre son obligatorios"); return; }
    try {
      if (isEditing) await updateMutation.mutateAsync(form); else await createMutation.mutateAsync(form);
      onClose();
    } catch (err: any) { setError(err.message || "Error al guardar"); }
  };
  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{isEditing ? "Editar centro de costo" : "Crear centro de costo"}</DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2, mt: 1 }}>{error}</Alert>}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField label="Codigo" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} disabled={isEditing} fullWidth placeholder="Ej: CC-001" />
          <TextField label="Nombre" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} fullWidth />
          <TextField select label="Centro padre" value={form.parentCode ?? ""} onChange={(e) => setForm({ ...form, parentCode: e.target.value || null })} fullWidth>
            <MenuItem value="">Sin padre (raiz)</MenuItem>
            {allCentros.filter((c) => c.code !== form.code).map((c) => (<MenuItem key={c.code} value={c.code}>{c.code} - {c.name}</MenuItem>))}
          </TextField>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={isPending}>{isPending ? "Guardando..." : isEditing ? "Actualizar" : "Crear"}</Button>
      </DialogActions>
    </Dialog>
  );
}

// ---- P&L By Cost Center Tab ----
const PNL_COLUMNS: ColumnDef[] = [
  { field: "costCenterCode", header: "Centro", width: 130, sortable: true },
  { field: "costCenterName", header: "Nombre", flex: 1, minWidth: 180, sortable: true },
  { field: "ingresos", header: "Ingresos", width: 150, type: "number", currency: "VES", aggregation: "sum" },
  { field: "gastos", header: "Gastos", width: 150, type: "number", currency: "VES", aggregation: "sum" },
  { field: "resultado", header: "Resultado", width: 150, type: "number", currency: "VES", aggregation: "sum" },
];

function PnLByCostCenterTab() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [run, setRun] = useState(false);
  const { data, isLoading, error } = usePnLByCostCenter(fechaDesde, fechaHasta, run);

  const rows = useMemo(() => {
    const items = data?.data ?? data?.rows ?? [];
    return items.map((r: any, i: number) => ({ ...r, id: i }));
  }, [data]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = PNL_COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    // No actionButtons needed — read-only P&L report grid
  }, [rows, isLoading, registered]);

  const filters = (
    <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
      <DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
      <DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
      <Button variant="contained" onClick={() => setRun(true)}>Generar</Button>
    </Stack>
  );

  if (!run) return <>{filters}<Alert severity="info">Seleccione fechas y presione &quot;Generar&quot;</Alert></>;
  if (!registered || isLoading) return <>{filters}<Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box></>;
  if (error) return <>{filters}<Alert severity="error">Error al generar reporte</Alert></>;

  return (
    <Box>
      {filters}
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="pnl-centros-costo"
        height="calc(100vh - 400px)"
        show-totals
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>
    </Box>
  );
}

// ---- Pivot Tab ----
const PIVOT_COLUMNS: ColumnDef[] = [
  { field: "nombre", header: "Centro de Costo", flex: 1, minWidth: 180, sortable: true },
  { field: "metrica", header: "Metrica", width: 120, sortable: true, groupable: true },
  { field: "monto", header: "Monto", width: 160, type: "number", currency: "VES", aggregation: "sum" },
];

function PivotTab() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [run, setRun] = useState(false);
  const { data, isLoading, error } = usePnLByCostCenter(fechaDesde, fechaHasta, run);

  const pivotRows = useMemo(() => {
    const items: any[] = data?.data ?? data?.rows ?? [];
    const result: any[] = [];
    items.forEach((r, i) => {
      result.push({ id: `${i}_ing`, centro: r.costCenterCode, nombre: r.costCenterName, metrica: "Ingresos", monto: r.ingresos ?? 0 });
      result.push({ id: `${i}_gas`, centro: r.costCenterCode, nombre: r.costCenterName, metrica: "Gastos", monto: r.gastos ?? 0 });
      result.push({ id: `${i}_res`, centro: r.costCenterCode, nombre: r.costCenterName, metrica: "Resultado", monto: r.resultado ?? 0 });
    });
    return result;
  }, [data]);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = PIVOT_COLUMNS;
    el.rows = pivotRows;
    el.loading = isLoading;
    // No actionButtons needed — read-only pivot report grid
  }, [pivotRows, isLoading, registered]);

  const filters = (
    <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
      <DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
      <DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
      <Button variant="contained" onClick={() => setRun(true)}>Generar</Button>
    </Stack>
  );

  if (!run) return <>{filters}<Alert severity="info">Seleccione fechas y presione &quot;Generar&quot;</Alert></>;
  if (!registered || isLoading) return <>{filters}<Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box></>;
  if (error) return <>{filters}<Alert severity="error">Error al generar reporte</Alert></>;

  return (
    <Box>
      {filters}
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="pivot-centros-costo"
        height="calc(100vh - 400px)"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>
    </Box>
  );
}

// ---- Main Component ----
const CENTROS_COSTO_FILTERS: FilterFieldDef[] = [
  { field: "estado", label: "Estado", type: "select", options: [
    { value: "active", label: "Activo" }, { value: "inactive", label: "Inactivo" },
  ]},
];

export default function CentrosCostoPage() {
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [tabValue, setTabValue] = useState(0);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<CentroCosto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = useCentrosCostoList(search || undefined);
  const deleteMutation = useDeleteCentroCosto();
  const centros: CentroCosto[] = useMemo(() => data?.data ?? data?.rows ?? [], [data]);
  const tree = useMemo(() => buildCentroCostoTree(centros), [centros]);

  const handleToggle = (code: string) => { setExpanded((prev) => { const next = new Set(prev); next.has(code) ? next.delete(code) : next.add(code); return next; }); };
  const handleEdit = (item: CentroCosto) => { setEditItem(item); setDialogOpen(true); };
  const handleCreate = () => { setEditItem(null); setDialogOpen(true); };
  const handleDelete = async (code: string) => {
    try { await deleteMutation.mutateAsync(code); setDeleteConfirm(null); }
    catch (err: any) { setError(err.message || "Error al eliminar"); }
  };

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Centros de Costo</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreate}>Crear Centro</Button>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}

      <Paper sx={{ mb: 2 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
          <Tab label="Gestion" icon={<AccountTreeIcon />} iconPosition="start" />
          <Tab label="P&L por Centro" icon={<TableChartIcon />} iconPosition="start" />
          <Tab label="Pivot" icon={<PivotTableChartIcon />} iconPosition="start" />
        </Tabs>
      </Paper>

      {tabValue === 0 && (
        <>
          <ZenttoFilterPanel filters={CENTROS_COSTO_FILTERS} values={filterValues} onChange={setFilterValues}
            searchPlaceholder="Buscar por codigo o nombre..." searchValue={search} onSearchChange={setSearch} />
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ display: "flex", alignItems: "center", py: 1, px: 2, bgcolor: "grey.100", borderBottom: "2px solid", borderColor: "divider" }}>
              <Box sx={{ width: 32, mr: 1 }} />
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 100, mr: 2 }}>CODIGO</Typography>
              <Typography variant="caption" fontWeight={700} sx={{ flex: 1 }}>NOMBRE</Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 50, mr: 1 }}>NIVEL</Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 70, mr: 1 }}>ESTADO</Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 72 }}>ACCIONES</Typography>
            </Box>
            {isLoading ? (
              <Box sx={{ p: 2 }}>{Array.from({ length: 5 }).map((_, i) => (<Skeleton key={i} height={44} sx={{ mb: 0.5 }} />))}</Box>
            ) : tree.length === 0 ? (
              <Box sx={{ p: 4, textAlign: "center" }}><Typography color="text.secondary">No hay centros de costo. Cree el primero con el boton &quot;Crear Centro&quot;.</Typography></Box>
            ) : tree.map((node) => (
              <CentroCostoTreeRow key={node.code} node={node} depth={0} expanded={expanded}
                onToggle={handleToggle} onEdit={handleEdit} onDelete={(code) => setDeleteConfirm(code)} />
            ))}
          </Paper>
        </>
      )}

      {tabValue === 1 && <PnLByCostCenterTab />}
      {tabValue === 2 && <PivotTab />}

      <CentroCostoDialog open={dialogOpen} onClose={() => { setDialogOpen(false); setEditItem(null); }} editItem={editItem} allCentros={centros} />

      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)}>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent><Typography>Esta seguro de eliminar el centro de costo &quot;{deleteConfirm}&quot;? Esta accion no se puede deshacer.</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={() => deleteConfirm && handleDelete(deleteConfirm)} disabled={deleteMutation.isPending}>
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
