"use client";

import React, { useState, useMemo, useCallback } from "react";
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
  Tabs,
  Tab,
  CircularProgress,
  Divider,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import VisibilityIcon from "@mui/icons-material/Visibility";
import SaveIcon from "@mui/icons-material/Save";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import {
  usePresupuestosList,
  usePresupuestoGet,
  useCreatePresupuesto,
  useUpdatePresupuesto,
  useDeletePresupuesto,
  usePresupuestoVarianza,
  type Presupuesto,
  type PresupuestoDetalle,
  type PresupuestoLinea,
  type CreatePresupuestoInput,
  type VarianzaRow,
} from "../hooks/useContabilidadAdvanced";

// ─── Month Labels ────────────────────────────────────────────

const MONTHS = [
  "Ene", "Feb", "Mar", "Abr", "May", "Jun",
  "Jul", "Ago", "Sep", "Oct", "Nov", "Dic",
];

const MONTH_FIELDS = [
  "month01", "month02", "month03", "month04", "month05", "month06",
  "month07", "month08", "month09", "month10", "month11", "month12",
] as const;

// ─── Budget Create/Edit Dialog ───────────────────────────────

function PresupuestoFormDialog({
  open,
  onClose,
  editItem,
}: {
  open: boolean;
  onClose: () => void;
  editItem: Presupuesto | null;
}) {
  const createMutation = useCreatePresupuesto();
  const updateMutation = useUpdatePresupuesto();
  const isEditing = editItem != null;

  const [form, setForm] = useState({
    name: editItem?.name ?? "",
    fiscalYear: editItem?.fiscalYear ?? new Date().getFullYear(),
    costCenterCode: editItem?.costCenterCode ?? "",
  });
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    if (open) {
      setForm({
        name: editItem?.name ?? "",
        fiscalYear: editItem?.fiscalYear ?? new Date().getFullYear(),
        costCenterCode: editItem?.costCenterCode ?? "",
      });
      setError(null);
    }
  }, [open, editItem]);

  const handleSubmit = async () => {
    if (!form.name) {
      setError("El nombre es obligatorio");
      return;
    }
    try {
      const payload: CreatePresupuestoInput = {
        name: form.name,
        fiscalYear: form.fiscalYear,
        costCenterCode: form.costCenterCode || undefined,
        lines: [],
      };

      if (isEditing) {
        await updateMutation.mutateAsync({ ...payload, id: editItem.id });
      } else {
        await createMutation.mutateAsync(payload);
      }
      onClose();
    } catch (err: any) {
      setError(err.message || "Error al guardar");
    }
  };

  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isEditing ? "Editar presupuesto" : "Crear presupuesto"}
      </DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2, mt: 1 }}>{error}</Alert>}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            fullWidth
            size="small"
          />
          <TextField
            label="Año fiscal"
            type="number"
            value={form.fiscalYear}
            onChange={(e) => setForm({ ...form, fiscalYear: Number(e.target.value) })}
            fullWidth
            size="small"
          />
          <TextField
            label="Centro de Costo (opcional)"
            value={form.costCenterCode}
            onChange={(e) => setForm({ ...form, costCenterCode: e.target.value })}
            fullWidth
            size="small"
            placeholder="Dejar vacio para presupuesto global"
          />
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

// ─── Budget Detail View ──────────────────────────────────────

function PresupuestoDetailView({
  presupuestoId,
  onBack,
}: {
  presupuestoId: number;
  onBack: () => void;
}) {
  const { data, isLoading } = usePresupuestoGet(presupuestoId);
  const [tabValue, setTabValue] = useState(0);

  const detail: PresupuestoDetalle | null = data?.data ?? data ?? null;
  const lines: PresupuestoLinea[] = detail?.lines ?? [];

  // Editable lines state
  const [editLines, setEditLines] = useState<PresupuestoLinea[]>([]);
  const [isDirty, setIsDirty] = useState(false);

  React.useEffect(() => {
    if (lines.length > 0) {
      setEditLines(lines);
      setIsDirty(false);
    }
  }, [lines]);

  const updateMutation = useUpdatePresupuesto();

  const handleCellEdit = (rowIdx: number, field: string, value: number) => {
    setEditLines((prev) => {
      const next = [...prev];
      next[rowIdx] = { ...next[rowIdx], [field]: value };
      // Recalc annual total
      let total = 0;
      for (const mf of MONTH_FIELDS) {
        total += next[rowIdx][mf] ?? 0;
      }
      next[rowIdx].annualTotal = total;
      return next;
    });
    setIsDirty(true);
  };

  const handleSave = async () => {
    if (!detail) return;
    try {
      await updateMutation.mutateAsync({
        id: presupuestoId,
        name: detail.name,
        fiscalYear: detail.fiscalYear,
        costCenterCode: detail.costCenterCode,
        lines: editLines.map((l) => ({
          accountCode: l.accountCode,
          month01: l.month01,
          month02: l.month02,
          month03: l.month03,
          month04: l.month04,
          month05: l.month05,
          month06: l.month06,
          month07: l.month07,
          month08: l.month08,
          month09: l.month09,
          month10: l.month10,
          month11: l.month11,
          month12: l.month12,
        })),
      });
      setIsDirty(false);
    } catch {
      // Error handled by mutation
    }
  };

  // Budget lines columns
  const lineColumns: GridColDef[] = [
    { field: "accountCode", headerName: "Cuenta", width: 120, cellClassName: () => "monospace-cell" },
    { field: "accountName", headerName: "Descripcion", width: 180 },
    ...MONTHS.map((label, idx) => ({
      field: MONTH_FIELDS[idx],
      headerName: label,
      width: 90,
      type: "number" as const,
      editable: true,
      renderCell: (p: any) => formatCurrency(p.value ?? 0),
    })),
    {
      field: "annualTotal",
      headerName: "Total anual",
      width: 130,
      type: "number" as const,
      renderCell: (p: any) => (
        <Typography variant="body2" fontWeight={700}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
  ];

  return (
    <Box>
      <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 3 }}>
        <IconButton onClick={onBack}>
          <ArrowBackIcon />
        </IconButton>
        <Typography variant="h5" fontWeight={700}>
          {detail?.name || "Presupuesto"}
        </Typography>
        {detail && (
          <Chip label={`Año ${detail.fiscalYear}`} color="primary" variant="outlined" />
        )}
        {detail?.costCenterCode && (
          <Chip label={`CC: ${detail.costCenterCode}`} variant="outlined" />
        )}
        <Box sx={{ flex: 1 }} />
        {isDirty && (
          <Button
            variant="contained"
            startIcon={updateMutation.isPending ? <CircularProgress size={18} /> : <SaveIcon />}
            onClick={handleSave}
            disabled={updateMutation.isPending}
          >
            Guardar cambios
          </Button>
        )}
      </Stack>

      <Paper sx={{ mb: 2 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
          <Tab label="Detalle" />
          <Tab label="Varianza" />
        </Tabs>
      </Paper>

      {tabValue === 0 && (
        <Paper sx={{ borderRadius: 2 }}>
          {isLoading ? (
            <Box p={4} display="flex" justifyContent="center">
              <CircularProgress />
            </Box>
          ) : editLines.length === 0 ? (
            <Box p={4} textAlign="center">
              <Typography color="text.secondary">
                No hay lineas de presupuesto. Agregue cuentas para comenzar.
              </Typography>
            </Box>
          ) : (
            <DataGrid
              rows={editLines.map((l, i) => ({ ...l, _id: i }))}
              columns={lineColumns}
              getRowId={(r) => r._id}
              autoHeight
              disableRowSelectionOnClick
              processRowUpdate={(newRow, oldRow) => {
                const idx = newRow._id;
                for (const mf of MONTH_FIELDS) {
                  if (newRow[mf] !== oldRow[mf]) {
                    handleCellEdit(idx, mf, Number(newRow[mf]) || 0);
                  }
                }
                return newRow;
              }}
              sx={{
                "& .monospace-cell": { fontFamily: "monospace" },
              }}
            />
          )}
        </Paper>
      )}

      {tabValue === 1 && <VarianzaTab presupuestoId={presupuestoId} />}
    </Box>
  );
}

// ─── Variance Tab ────────────────────────────────────────────

function VarianzaTab({ presupuestoId }: { presupuestoId: number }) {
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);

  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);

  const { data, isLoading, error } = usePresupuestoVarianza(
    presupuestoId,
    fechaDesde,
    fechaHasta,
  );

  const rows: VarianzaRow[] = useMemo(() => {
    const items = data?.data ?? data?.rows ?? [];
    return items.map((r: any, i: number) => ({ ...r, _id: i }));
  }, [data]);

  const columns: GridColDef[] = [
    { field: "accountCode", headerName: "Cuenta", width: 120, cellClassName: () => "monospace-cell" },
    { field: "accountName", headerName: "Descripcion", flex: 1, minWidth: 180 },
    {
      field: "budget",
      headerName: "Presupuesto",
      width: 140,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "actual",
      headerName: "Real",
      width: 140,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "variance",
      headerName: "Varianza",
      width: 140,
      type: "number",
      renderCell: (p) => (
        <Typography
          variant="body2"
          fontWeight={600}
          sx={{ color: (p.value ?? 0) >= 0 ? "success.main" : "error.main" }}
        >
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "variancePercent",
      headerName: "% Varianza",
      width: 120,
      type: "number",
      renderCell: (p) => {
        const val = p.value ?? 0;
        return (
          <Chip
            label={`${val >= 0 ? "+" : ""}${val.toFixed(1)}%`}
            size="small"
            color={val >= 0 ? "success" : "error"}
            sx={{ fontWeight: 600 }}
          />
        );
      },
    },
  ];

  // Simple bar comparison
  const maxVal = Math.max(...rows.map((r) => Math.max(r.budget, r.actual)), 1);

  return (
    <Box>
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
        <TextField
          label="Desde"
          type="date"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={fechaDesde}
          onChange={(e) => setFechaDesde(e.target.value)}
        />
        <TextField
          label="Hasta"
          type="date"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={fechaHasta}
          onChange={(e) => setFechaHasta(e.target.value)}
        />
      </Stack>

      {isLoading ? (
        <Box display="flex" justifyContent="center" p={4}>
          <CircularProgress />
        </Box>
      ) : error ? (
        <Alert severity="error">Error al cargar datos de varianza</Alert>
      ) : rows.length === 0 ? (
        <Alert severity="info">No hay datos de varianza para este periodo</Alert>
      ) : (
        <>
          {/* Bar Chart Comparison */}
          <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Presupuesto vs Real por Cuenta
            </Typography>
            <Box sx={{ maxHeight: 300, overflow: "auto" }}>
              {rows.slice(0, 10).map((row, i) => (
                <Box key={i} sx={{ mb: 1.5 }}>
                  <Typography variant="caption" color="text.secondary">
                    {row.accountCode} - {row.accountName}
                  </Typography>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <Box sx={{ flex: 1 }}>
                      <Box
                        sx={{
                          height: 12,
                          width: `${Math.min((row.budget / maxVal) * 100, 100)}%`,
                          bgcolor: "#2196f3",
                          borderRadius: 1,
                          mb: 0.3,
                          transition: "width 0.5s ease",
                        }}
                      />
                      <Box
                        sx={{
                          height: 12,
                          width: `${Math.min((row.actual / maxVal) * 100, 100)}%`,
                          bgcolor: row.variance >= 0 ? "#4caf50" : "#f44336",
                          borderRadius: 1,
                          transition: "width 0.5s ease",
                        }}
                      />
                    </Box>
                    <Typography variant="caption" sx={{ minWidth: 60, textAlign: "right" }}>
                      {row.variancePercent >= 0 ? "+" : ""}{row.variancePercent.toFixed(1)}%
                    </Typography>
                  </Stack>
                </Box>
              ))}
            </Box>
            <Stack direction="row" spacing={2} sx={{ mt: 1 }}>
              <Stack direction="row" alignItems="center" spacing={0.5}>
                <Box sx={{ width: 12, height: 12, bgcolor: "#2196f3", borderRadius: 1 }} />
                <Typography variant="caption">Presupuesto</Typography>
              </Stack>
              <Stack direction="row" alignItems="center" spacing={0.5}>
                <Box sx={{ width: 12, height: 12, bgcolor: "#4caf50", borderRadius: 1 }} />
                <Typography variant="caption">Real (bajo presupuesto)</Typography>
              </Stack>
              <Stack direction="row" alignItems="center" spacing={0.5}>
                <Box sx={{ width: 12, height: 12, bgcolor: "#f44336", borderRadius: 1 }} />
                <Typography variant="caption">Real (sobre presupuesto)</Typography>
              </Stack>
            </Stack>
          </Paper>

          {/* Data Table */}
          <Paper sx={{ borderRadius: 2 }}>
            <DataGrid
              rows={rows}
              columns={columns}
              getRowId={(r) => r._id}
              autoHeight
              disableRowSelectionOnClick
              sx={{ "& .monospace-cell": { fontFamily: "monospace" } }}
            />
          </Paper>
        </>
      )}
    </Box>
  );
}

// ─── Main Component ──────────────────────────────────────────

export default function PresupuestosPage() {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<Presupuesto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);
  const [fiscalYear, setFiscalYear] = useState<number>(new Date().getFullYear());
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = usePresupuestosList(fiscalYear);
  const deleteMutation = useDeletePresupuesto();

  const presupuestos: Presupuesto[] = useMemo(
    () => (data?.data ?? data?.rows ?? []).map((r: any) => ({
      ...r,
      id: r.BudgetId ?? r.id ?? r.budgetId,
    })),
    [data]
  );

  // If a budget is selected, show detail view
  if (selectedId != null) {
    return (
      <PresupuestoDetailView
        presupuestoId={selectedId}
        onBack={() => setSelectedId(null)}
      />
    );
  }

  const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "name", headerName: "Nombre", flex: 1, minWidth: 200 },
    { field: "fiscalYear", headerName: "Año", width: 80 },
    {
      field: "costCenterCode",
      headerName: "Centro costo",
      width: 140,
      renderCell: (p) => p.value || <Typography variant="body2" color="text.secondary">Global</Typography>,
    },
    {
      field: "status",
      headerName: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value || "DRAFT"}
          size="small"
          color={
            p.value === "APPROVED"
              ? "success"
              : p.value === "CLOSED"
                ? "error"
                : "default"
          }
        />
      ),
    },
    {
      field: "total",
      headerName: "Total",
      width: 140,
      type: "number",
      renderCell: (p) => (
        <Typography variant="body2" fontWeight={600}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 150,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ver detalle">
            <IconButton size="small" color="primary" onClick={() => setSelectedId(p.row.id)}>
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Editar">
            <IconButton
              size="small"
              color="info"
              onClick={() => {
                setEditItem(p.row);
                setDialogOpen(true);
              }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Eliminar">
            <IconButton size="small" color="error" onClick={() => setDeleteConfirm(p.row.id)}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const handleDelete = async (id: number) => {
    try {
      await deleteMutation.mutateAsync(id);
      setDeleteConfirm(null);
    } catch (err: any) {
      setError(err.message || "Error al eliminar");
    }
  };

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          Presupuestos
        </Typography>
        <Stack direction="row" spacing={2} alignItems="center">
          <TextField
            select
            label="Año fiscal"
            value={fiscalYear}
            onChange={(e) => setFiscalYear(Number(e.target.value))}
            size="small"
            sx={{ minWidth: 120 }}
          >
            {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map((y) => (
              <MenuItem key={y} value={y}>
                {y}
              </MenuItem>
            ))}
          </TextField>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => {
              setEditItem(null);
              setDialogOpen(true);
            }}
          >
            Crear Presupuesto
          </Button>
        </Stack>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Paper sx={{ borderRadius: 2 }}>
        <DataGrid
          rows={presupuestos}
          columns={columns}
          getRowId={(r) => r.BudgetId ?? r.id ?? r._id}
          loading={isLoading}
          autoHeight
          disableRowSelectionOnClick
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
          pageSizeOptions={[10, 25]}
          sx={{ border: 0 }}
        />
      </Paper>

      {/* Form Dialog */}
      <PresupuestoFormDialog
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
            Esta seguro de eliminar este presupuesto? Esta accion no se puede deshacer.
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
