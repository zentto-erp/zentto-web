"use client";

import React, { useState, useMemo } from "react";
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
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
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

// ─── Frequency Labels ────────────────────────────────────────

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

// ─── Template Form Dialog ────────────────────────────────────

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
    setForm({
      ...form,
      lines: [...form.lines, { accountCode: "", description: "", debit: 0, credit: 0 }],
    });
  };

  const handleRemoveLine = (idx: number) => {
    setForm({
      ...form,
      lines: form.lines.filter((_, i) => i !== idx),
    });
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
    if (form.lines.length === 0) {
      setError("Debe tener al menos una linea");
      return;
    }
    if (!isBalanced) {
      setError("El asiento debe estar balanceado (Debe = Haber)");
      return;
    }

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
      <DialogTitle>
        {isEditing ? "Editar asiento recurrente" : "Crear asiento recurrente"}
      </DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2, mt: 1 }}>{error}</Alert>}

        <Stack spacing={2} sx={{ mt: 1 }}>
          {/* Header Fields */}
          <Stack direction="row" spacing={2}>
            <TextField
              label="Nombre"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              fullWidth
              size="small"
            />
            <TextField
              select
              label="Frecuencia"
              value={form.frequency}
              onChange={(e) => setForm({ ...form, frequency: e.target.value })}
              size="small"
              sx={{ minWidth: 160 }}
            >
              {FREQUENCY_OPTIONS.map((opt) => (
                <MenuItem key={opt.value} value={opt.value}>
                  {opt.label}
                </MenuItem>
              ))}
            </TextField>
          </Stack>

          <Stack direction="row" spacing={2}>
            <TextField
              label="Concepto"
              value={form.concept}
              onChange={(e) => setForm({ ...form, concept: e.target.value })}
              fullWidth
              size="small"
            />
            <TextField
              label="Próxima ejecución"
              type="date"
              value={form.nextExecution}
              onChange={(e) => setForm({ ...form, nextExecution: e.target.value })}
              size="small"
              InputLabelProps={{ shrink: true }}
              sx={{ minWidth: 180 }}
            />
          </Stack>

          <FormControlLabel
            control={
              <Switch
                checked={form.active ?? true}
                onChange={(e) => setForm({ ...form, active: e.target.checked })}
              />
            }
            label="Activo"
          />

          <Divider />

          {/* Lines */}
          <Typography variant="subtitle2" fontWeight={600}>
            Lineas del Asiento
          </Typography>

          {form.lines.map((line, idx) => (
            <Stack key={idx} direction="row" spacing={1} alignItems="center">
              <TextField
                label="Cuenta"
                value={line.accountCode}
                onChange={(e) => handleLineChange(idx, "accountCode", e.target.value)}
                size="small"
                sx={{ width: 140 }}
              />
              <TextField
                label="Descripcion"
                value={line.description || ""}
                onChange={(e) => handleLineChange(idx, "description", e.target.value)}
                size="small"
                sx={{ flex: 1 }}
              />
              <TextField
                label="Debe"
                type="number"
                value={line.debit || ""}
                onChange={(e) => handleLineChange(idx, "debit", Number(e.target.value) || 0)}
                size="small"
                sx={{ width: 120 }}
              />
              <TextField
                label="Haber"
                type="number"
                value={line.credit || ""}
                onChange={(e) => handleLineChange(idx, "credit", Number(e.target.value) || 0)}
                size="small"
                sx={{ width: 120 }}
              />
              <IconButton
                size="small"
                color="error"
                onClick={() => handleRemoveLine(idx)}
                disabled={form.lines.length <= 1}
              >
                <DeleteOutlineIcon fontSize="small" />
              </IconButton>
            </Stack>
          ))}

          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Button size="small" startIcon={<AddIcon />} onClick={handleAddLine}>
              Agregar Linea
            </Button>
            <Stack direction="row" spacing={2}>
              <Typography variant="body2">
                Debe: <strong>{formatCurrency(totalDebit)}</strong>
              </Typography>
              <Typography variant="body2">
                Haber: <strong>{formatCurrency(totalCredit)}</strong>
              </Typography>
              <Chip
                label={isBalanced ? "Balanceado" : "Desbalanceado"}
                size="small"
                color={isBalanced ? "success" : "error"}
              />
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

// ─── Main Component ──────────────────────────────────────────

export default function AsientosRecurrentesPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<RecurrenteTemplate | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const { data: listData, isLoading } = useRecurrentesList();
  const { data: dueData } = useDueRecurrentes();
  const executeMutation = useExecuteRecurrente();
  const deleteMutation = useDeleteRecurrente();

  const templates: RecurrenteTemplate[] = useMemo(
    () => listData?.data ?? listData?.rows ?? [],
    [listData]
  );

  const dueTemplates: RecurrenteTemplate[] = useMemo(
    () => dueData?.data ?? dueData?.rows ?? [],
    [dueData]
  );
  const dueCount = dueTemplates.length;

  const handleExecute = async (id: number) => {
    setError(null);
    setSuccessMsg(null);
    try {
      await executeMutation.mutateAsync(id);
      setSuccessMsg("Asiento recurrente ejecutado correctamente");
    } catch (err: any) {
      setError(err.message || "Error al ejecutar");
    }
  };

  const handleExecuteAllDue = async () => {
    setError(null);
    setSuccessMsg(null);
    try {
      for (const t of dueTemplates) {
        await executeMutation.mutateAsync(t.id);
      }
      setSuccessMsg(`${dueTemplates.length} asientos recurrentes ejecutados`);
    } catch (err: any) {
      setError(err.message || "Error al ejecutar asientos vencidos");
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteMutation.mutateAsync(id);
      setDeleteConfirm(null);
    } catch (err: any) {
      setError(err.message || "Error al eliminar");
    }
  };

  const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 60 },
    { field: "name", headerName: "Nombre", flex: 1, minWidth: 200 },
    {
      field: "frequency",
      headerName: "Frecuencia",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={FREQUENCY_LABELS[p.value] || p.value}
          size="small"
          variant="outlined"
          color="primary"
        />
      ),
    },
    { field: "concept", headerName: "Concepto", width: 200 },
    {
      field: "nextExecution",
      headerName: "Próxima ejecución",
      width: 150,
      renderCell: (p) => {
        const isOverdue = p.value && new Date(p.value) <= new Date();
        return (
          <Typography
            variant="body2"
            fontWeight={isOverdue ? 700 : 400}
            sx={{ color: isOverdue ? "error.main" : "text.primary" }}
          >
            {p.value || "--"}
            {isOverdue && " (vencido)"}
          </Typography>
        );
      },
    },
    {
      field: "timesExecuted",
      headerName: "Ejecutado",
      width: 100,
      type: "number",
      renderCell: (p) => (
        <Chip label={`${p.value ?? 0}x`} size="small" />
      ),
    },
    {
      field: "active",
      headerName: "Activo",
      width: 80,
      renderCell: (p) => (
        <Chip
          label={p.value ? "Si" : "No"}
          size="small"
          color={p.value ? "success" : "default"}
        />
      ),
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 180,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ejecutar">
            <IconButton
              size="small"
              color="success"
              onClick={() => handleExecute(p.row.id)}
              disabled={executeMutation.isPending}
            >
              <PlayArrowIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Editar">
            <IconButton
              size="small"
              color="primary"
              onClick={() => {
                setEditItem(p.row);
                setDialogOpen(true);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Eliminar">
            <IconButton
              size="small"
              color="error"
              onClick={() => setDeleteConfirm(p.row.id)}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Stack direction="row" alignItems="center" spacing={2}>
          <Typography variant="h5" fontWeight={700}>
            Asientos Recurrentes
          </Typography>
          {dueCount > 0 && (
            <Badge badgeContent={dueCount} color="error">
              <Chip
                icon={<ScheduleIcon />}
                label="Vencidos"
                color="warning"
                variant="outlined"
              />
            </Badge>
          )}
        </Stack>
        <Stack direction="row" spacing={2}>
          {dueCount > 0 && (
            <Button
              variant="outlined"
              color="warning"
              startIcon={
                executeMutation.isPending ? (
                  <CircularProgress size={18} />
                ) : (
                  <PlaylistPlayIcon />
                )
              }
              onClick={handleExecuteAllDue}
              disabled={executeMutation.isPending}
            >
              Ejecutar Todos Vencidos ({dueCount})
            </Button>
          )}
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => {
              setEditItem(null);
              setDialogOpen(true);
            }}
          >
            Crear Plantilla
          </Button>
        </Stack>
      </Stack>

      {/* Messages */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}
      {successMsg && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMsg(null)}>
          {successMsg}
        </Alert>
      )}

      {/* Grid */}
      <Paper sx={{ borderRadius: 2 }}>
        <ZenttoDataGrid
          rows={templates}
          columns={columns}
          getRowId={(r) => r.RecurringEntryId}
          loading={isLoading}
          autoHeight
          disableRowSelectionOnClick
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
          pageSizeOptions={[10, 25]}
          sx={{ border: 0 }}
          mobileVisibleFields={['name', 'nextExecution']}
          smExtraFields={['frequency', 'active']}
        />
      </Paper>

      {/* Form Dialog */}
      <RecurrenteFormDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          setEditItem(null);
        }}
        editItem={editItem}
      />

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)}>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de eliminar esta plantilla recurrente? Esta accion no se puede deshacer.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={() => deleteConfirm != null && handleDelete(deleteConfirm)}
            disabled={deleteMutation.isPending}
          >
            {deleteMutation.isPending ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
