"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Chip,
  IconButton,
  Tooltip,
  Badge,
  CircularProgress,
  Divider,
  Switch,
  FormControlLabel,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import PlaylistPlayIcon from "@mui/icons-material/PlaylistPlay";
import ScheduleIcon from "@mui/icons-material/Schedule";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import { formatCurrency } from "@zentto/shared-api";
import {
  useRecurrentesList,
  useCreateRecurrente,
  useUpdateRecurrente,
  useDeleteRecurrente,
  useExecuteRecurrente,
  useDueRecurrentes,
  type RecurrenteTemplate,
  type RecurrenteLinea,
  type CreateRecurrenteInput,
} from "../hooks/useContabilidadAdvanced";

const FREQUENCY_LABELS: Record<string, string> = {
  DAILY: "Diario",
  WEEKLY: "Semanal",
  MONTHLY: "Mensual",
  QUARTERLY: "Trimestral",
  YEARLY: "Anual",
};

const FREQUENCY_OPTIONS = [
  { value: "DAILY", label: "Diario" },
  { value: "WEEKLY", label: "Semanal" },
  { value: "MONTHLY", label: "Mensual" },
  { value: "QUARTERLY", label: "Trimestral" },
  { value: "YEARLY", label: "Anual" },
];

// ---- Template Form Dialog (unchanged business logic) ----

function RecurrenteFormDialog({
  open,
  onClose,
  editItem,
}: {
  open: boolean;
  onClose: () => void;
  editItem: RecurrenteTemplate | null;
}) {
  const createMutation = useCreateRecurrente();
  const updateMutation = useUpdateRecurrente();
  const isEditing = editItem != null;

  const [form, setForm] = useState<CreateRecurrenteInput>({
    name: editItem?.name ?? "",
    frequency: editItem?.frequency ?? "MONTHLY",
    nextExecution: editItem?.nextExecution ?? "",
    concept: editItem?.concept ?? "",
    active: editItem?.active ?? true,
    lines: editItem?.lines?.map((l) => ({
      accountCode: l.accountCode,
      description: l.description,
      debit: l.debit,
      credit: l.credit,
    })) ?? [{ accountCode: "", description: "", debit: 0, credit: 0 }],
  });
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    if (open) {
      setForm({
        name: editItem?.name ?? "",
        frequency: editItem?.frequency ?? "MONTHLY",
        nextExecution: editItem?.nextExecution ?? "",
        concept: editItem?.concept ?? "",
        active: editItem?.active ?? true,
        lines: editItem?.lines?.map((l) => ({
          accountCode: l.accountCode,
          description: l.description,
          debit: l.debit,
          credit: l.credit,
        })) ?? [{ accountCode: "", description: "", debit: 0, credit: 0 }],
      });
      setError(null);
    }
  }, [open, editItem]);

  const handleAddLine = () => {
    setForm({ ...form, lines: [...form.lines, { accountCode: "", description: "", debit: 0, credit: 0 }] });
  };

  const handleRemoveLine = (idx: number) => {
    setForm({ ...form, lines: form.lines.filter((_, i) => i !== idx) });
  };

  const handleLineChange = (idx: number, field: string, value: string | number) => {
    const next = [...form.lines];
    next[idx] = { ...next[idx], [field]: value };
    setForm({ ...form, lines: next });
  };

  const totalDebit = form.lines.reduce((s, l) => s + (l.debit || 0), 0);
  const totalCredit = form.lines.reduce((s, l) => s + (l.credit || 0), 0);
  const isBalanced = Math.abs(totalDebit - totalCredit) < 0.01;

  const handleSubmit = async () => {
    if (!form.name || !form.concept || !form.nextExecution) {
      setError("Nombre, concepto y proxima ejecucion son obligatorios");
      return;
    }
    if (form.lines.length === 0) { setError("Debe tener al menos una linea"); return; }
    if (!isBalanced) { setError("El asiento debe estar balanceado (Debe = Haber)"); return; }
    try {
      if (isEditing) {
        await updateMutation.mutateAsync({ ...form, id: editItem.id });
      } else {
        await createMutation.mutateAsync(form);
      }
      onClose();
    } catch (err: any) {
      setError(err.message || "Error al guardar");
    }
  };

  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>{isEditing ? "Editar asiento recurrente" : "Crear asiento recurrente"}</DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2, mt: 1 }}>{error}</Alert>}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Stack direction="row" spacing={2}>
            <TextField label="Nombre" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} fullWidth />
            <TextField select label="Frecuencia" value={form.frequency} onChange={(e) => setForm({ ...form, frequency: e.target.value })} sx={{ minWidth: 160 }}>
              {FREQUENCY_OPTIONS.map((opt) => (<MenuItem key={opt.value} value={opt.value}>{opt.label}</MenuItem>))}
            </TextField>
          </Stack>
          <Stack direction="row" spacing={2}>
            <TextField label="Concepto" value={form.concept} onChange={(e) => setForm({ ...form, concept: e.target.value })} fullWidth />
            <DatePicker label="Proxima ejecucion" value={form.nextExecution ? dayjs(form.nextExecution) : null} onChange={(v) => setForm({ ...form, nextExecution: v ? v.format('YYYY-MM-DD') : '' })} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
          </Stack>
          <FormControlLabel control={<Switch checked={form.active ?? true} onChange={(e) => setForm({ ...form, active: e.target.checked })} />} label="Activo" />
          <Divider />
          <Typography variant="subtitle2" fontWeight={600}>Lineas del Asiento</Typography>
          {form.lines.map((line, idx) => (
            <Stack key={idx} direction="row" spacing={1} alignItems="center">
              <TextField label="Cuenta" value={line.accountCode} onChange={(e) => handleLineChange(idx, "accountCode", e.target.value)} sx={{ width: 140 }} />
              <TextField label="Descripcion" value={line.description || ""} onChange={(e) => handleLineChange(idx, "description", e.target.value)} sx={{ flex: 1 }} />
              <TextField label="Debe" type="number" value={line.debit || ""} onChange={(e) => handleLineChange(idx, "debit", Number(e.target.value) || 0)} sx={{ width: 120 }} />
              <TextField label="Haber" type="number" value={line.credit || ""} onChange={(e) => handleLineChange(idx, "credit", Number(e.target.value) || 0)} sx={{ width: 120 }} />
              <Tooltip title="Eliminar linea">
                <span>
                  <IconButton size="small" color="error" onClick={() => handleRemoveLine(idx)} disabled={form.lines.length <= 1}>
                    <DeleteOutlineIcon fontSize="small" />
                  </IconButton>
                </span>
              </Tooltip>
            </Stack>
          ))}
          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Button size="small" startIcon={<AddIcon />} onClick={handleAddLine}>Agregar Linea</Button>
            <Stack direction="row" spacing={2}>
              <Typography variant="body2">Debe: <strong>{formatCurrency(totalDebit)}</strong></Typography>
              <Typography variant="body2">Haber: <strong>{formatCurrency(totalCredit)}</strong></Typography>
              <Chip label={isBalanced ? "Balanceado" : "Desbalanceado"} size="small" color={isBalanced ? "success" : "error"} />
            </Stack>
          </Stack>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={isPending}>
          {isPending ? "Guardando..." : isEditing ? "Actualizar" : "Crear"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}


// ---- Main Component ----

const COLUMNS: ColumnDef[] = [
  { field: "id", header: "ID", width: 60, sortable: true },
  { field: "name", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "frequency", header: "Frecuencia", width: 120, sortable: true, groupable: true },
  { field: "concept", header: "Concepto", width: 200, sortable: true },
  { field: "nextExecution", header: "Proxima ejecucion", width: 150, type: "date", sortable: true },
  { field: "timesExecuted", header: "Ejecutado", width: 100, type: "number" },
  { field: "active", header: "Activo", width: 80, statusColors: { true: "success", false: "default" } },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 130,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  },
];

export default function AsientosRecurrentesPage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<RecurrenteTemplate | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const { data: listData, isLoading } = useRecurrentesList();
  const { data: dueData } = useDueRecurrentes();
  const executeMutation = useExecuteRecurrente();
  const deleteMutation = useDeleteRecurrente();

  const templates: RecurrenteTemplate[] = useMemo(() => listData?.data ?? listData?.rows ?? [], [listData]);
  const dueTemplates: RecurrenteTemplate[] = useMemo(() => dueData?.data ?? dueData?.rows ?? [], [dueData]);
  const dueCount = dueTemplates.length;

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = templates.map((r: any) => ({ ...r, id: r.RecurringEntryId ?? r.id, active: r.active ? "true" : "false" }));
    el.loading = isLoading;
  }, [templates, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      const template = templates.find((t: any) => (t.RecurringEntryId ?? t.id) === row.id);
      if (action === 'view' && template) { setEditItem(template); setDialogOpen(true); }
      if (action === 'edit' && template) { setEditItem(template); setDialogOpen(true); }
      if (action === 'delete') setDeleteConfirm(row.id);
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, templates]);

  const handleExecute = async (id: number) => {
    setError(null); setSuccessMsg(null);
    try {
      await executeMutation.mutateAsync(id);
      setSuccessMsg("Asiento recurrente ejecutado correctamente");
    } catch (err: any) { setError(err.message || "Error al ejecutar"); }
  };

  const handleExecuteAllDue = async () => {
    setError(null); setSuccessMsg(null);
    try {
      for (const t of dueTemplates) { await executeMutation.mutateAsync(t.id); }
      setSuccessMsg(`${dueTemplates.length} asientos recurrentes ejecutados`);
    } catch (err: any) { setError(err.message || "Error al ejecutar asientos vencidos"); }
  };

  const handleDelete = async (id: number) => {
    try { await deleteMutation.mutateAsync(id); setDeleteConfirm(null); }
    catch (err: any) { setError(err.message || "Error al eliminar"); }
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Stack direction="row" alignItems="center" spacing={2}>
          <Typography variant="h5" fontWeight={700}>Asientos Recurrentes</Typography>
          {dueCount > 0 && (
            <Badge badgeContent={dueCount} color="error">
              <Chip icon={<ScheduleIcon />} label="Vencidos" color="warning" variant="outlined" />
            </Badge>
          )}
        </Stack>
        <Stack direction="row" spacing={2}>
          {dueCount > 0 && (
            <Button variant="outlined" color="warning" startIcon={executeMutation.isPending ? <CircularProgress size={18} /> : <PlaylistPlayIcon />}
              onClick={handleExecuteAllDue} disabled={executeMutation.isPending}>
              Ejecutar Todos Vencidos ({dueCount})
            </Button>
          )}
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => { setEditItem(null); setDialogOpen(true); }}>
            Crear Plantilla
          </Button>
        </Stack>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}
      {successMsg && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMsg(null)}>{successMsg}</Alert>}

      <Paper sx={{ borderRadius: 2 }}>
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="asientos-recurrentes"
          height="calc(100vh - 300px)"
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

      <RecurrenteFormDialog open={dialogOpen} onClose={() => { setDialogOpen(false); setEditItem(null); }} editItem={editItem} />

      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)}>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent>
          <Typography>Esta seguro de eliminar esta plantilla recurrente? Esta accion no se puede deshacer.</Typography>
        </DialogContent>
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
