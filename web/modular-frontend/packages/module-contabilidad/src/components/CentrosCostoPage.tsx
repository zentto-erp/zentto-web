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
  Collapse,
  Tabs,
  Tab,
  CircularProgress,
  Skeleton,
  Divider,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import AccountTreeIcon from "@mui/icons-material/AccountTree";
import SearchIcon from "@mui/icons-material/Search";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useCentrosCostoList,
  useCreateCentroCosto,
  useUpdateCentroCosto,
  useDeleteCentroCosto,
  usePnLByCostCenter,
  type CentroCosto,
  type CentroCostoInput,
} from "../hooks/useContabilidadAdvanced";
import { toDateOnly } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";

// ─── Types ───────────────────────────────────────────────────

interface CentroCostoNode extends CentroCosto {
  children: CentroCostoNode[];
}

// ─── Build Tree ──────────────────────────────────────────────

function buildCentroCostoTree(items: CentroCosto[]): CentroCostoNode[] {
  const map = new Map<string, CentroCostoNode>();
  const roots: CentroCostoNode[] = [];

  // Create nodes
  for (const item of items) {
    map.set(item.code, { ...item, children: [] });
  }

  // Build hierarchy
  for (const item of items) {
    const node = map.get(item.code)!;
    if (item.parentCode && map.has(item.parentCode)) {
      map.get(item.parentCode)!.children.push(node);
    } else {
      roots.push(node);
    }
  }

  return roots;
}

// ─── Tree Row ────────────────────────────────────────────────

function CentroCostoTreeRow({
  node,
  depth,
  expanded,
  onToggle,
  onEdit,
  onDelete,
}: {
  node: CentroCostoNode;
  depth: number;
  expanded: Set<string>;
  onToggle: (code: string) => void;
  onEdit: (item: CentroCosto) => void;
  onDelete: (code: string) => void;
}) {
  const hasChildren = node.children.length > 0;
  const isExpanded = expanded.has(node.code);

  return (
    <>
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          py: 1,
          px: 2,
          pl: 2 + depth * 3,
          "&:hover": { bgcolor: "action.hover" },
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        {hasChildren ? (
          <IconButton size="small" onClick={() => onToggle(node.code)} sx={{ mr: 1 }}>
            {isExpanded ? <ExpandMoreIcon fontSize="small" /> : <ChevronRightIcon fontSize="small" />}
          </IconButton>
        ) : (
          <Box sx={{ width: 32, mr: 1 }} />
        )}

        <Typography
          variant="body2"
          sx={{ fontFamily: "monospace", fontWeight: 600, minWidth: 100, mr: 2 }}
        >
          {node.code}
        </Typography>

        <Typography variant="body2" sx={{ flex: 1, fontWeight: depth === 0 ? 600 : 400 }}>
          {node.name}
        </Typography>

        <Chip
          label={`N${node.level}`}
          size="small"
          variant="outlined"
          sx={{ mr: 1, fontSize: "0.7rem" }}
        />

        <Chip
          label={node.active ? "Activo" : "Inactivo"}
          size="small"
          color={node.active ? "success" : "default"}
          sx={{ mr: 1, fontSize: "0.7rem" }}
        />

        <Tooltip title="Editar">
          <IconButton size="small" color="primary" onClick={() => onEdit(node)}>
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Eliminar">
          <IconButton size="small" color="error" onClick={() => onDelete(node.code)}>
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>

      {hasChildren && (
        <Collapse in={isExpanded} timeout="auto" unmountOnExit>
          {node.children.map((child) => (
            <CentroCostoTreeRow
              key={child.code}
              node={child}
              depth={depth + 1}
              expanded={expanded}
              onToggle={onToggle}
              onEdit={onEdit}
              onDelete={onDelete}
            />
          ))}
        </Collapse>
      )}
    </>
  );
}

// ─── Create/Edit Dialog ──────────────────────────────────────

function CentroCostoDialog({
  open,
  onClose,
  editItem,
  allCentros,
}: {
  open: boolean;
  onClose: () => void;
  editItem: CentroCosto | null;
  allCentros: CentroCosto[];
}) {
  const createMutation = useCreateCentroCosto();
  const updateMutation = useUpdateCentroCosto();
  const isEditing = editItem != null;

  const [form, setForm] = useState<CentroCostoInput>({
    code: editItem?.code ?? "",
    name: editItem?.name ?? "",
    parentCode: editItem?.parentCode ?? null,
  });
  const [error, setError] = useState<string | null>(null);

  // Reset form when dialog opens with new data
  React.useEffect(() => {
    if (open) {
      setForm({
        code: editItem?.code ?? "",
        name: editItem?.name ?? "",
        parentCode: editItem?.parentCode ?? null,
      });
      setError(null);
    }
  }, [open, editItem]);

  const handleSubmit = async () => {
    if (!form.code || !form.name) {
      setError("Codigo y nombre son obligatorios");
      return;
    }

    try {
      if (isEditing) {
        await updateMutation.mutateAsync(form);
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
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isEditing ? "Editar Centro de Costo" : "Crear Centro de Costo"}
      </DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2, mt: 1 }}>
            {error}
          </Alert>
        )}
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Codigo"
            value={form.code}
            onChange={(e) => setForm({ ...form, code: e.target.value })}
            disabled={isEditing}
            size="small"
            fullWidth
            placeholder="Ej: CC-001"
          />
          <TextField
            label="Nombre"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            size="small"
            fullWidth
          />
          <TextField
            select
            label="Centro Padre"
            value={form.parentCode ?? ""}
            onChange={(e) =>
              setForm({ ...form, parentCode: e.target.value || null })
            }
            size="small"
            fullWidth
          >
            <MenuItem value="">Sin padre (raiz)</MenuItem>
            {allCentros
              .filter((c) => c.code !== form.code)
              .map((c) => (
                <MenuItem key={c.code} value={c.code}>
                  {c.code} - {c.name}
                </MenuItem>
              ))}
          </TextField>
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

// ─── P&L By Cost Center Tab ──────────────────────────────────

function PnLByCostCenterTab() {
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);

  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [run, setRun] = useState(false);

  const { data, isLoading, error } = usePnLByCostCenter(fechaDesde, fechaHasta, run);

  const rows = useMemo(() => {
    const items = data?.data ?? data?.rows ?? [];
    return items.map((r: any, i: number) => ({ ...r, _id: i }));
  }, [data]);

  const columns: GridColDef[] = [
    { field: "costCenterCode", headerName: "Centro Costo", width: 140 },
    { field: "costCenterName", headerName: "Nombre", flex: 1, minWidth: 180 },
    {
      field: "ingresos",
      headerName: "Ingresos",
      width: 140,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "gastos",
      headerName: "Gastos",
      width: 140,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "resultado",
      headerName: "Resultado",
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
  ];

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
        <Button variant="contained" onClick={() => setRun(true)}>
          Generar
        </Button>
      </Stack>

      {!run ? (
        <Alert severity="info">Seleccione fechas y presione &quot;Generar&quot;</Alert>
      ) : isLoading ? (
        <Box display="flex" justifyContent="center" p={4}>
          <CircularProgress />
        </Box>
      ) : error ? (
        <Alert severity="error">Error al generar reporte</Alert>
      ) : (
        <DataGrid
          rows={rows}
          columns={columns}
          getRowId={(r) => r._id}
          autoHeight
          disableRowSelectionOnClick
        />
      )}
    </Box>
  );
}

// ─── Main Component ──────────────────────────────────────────

export default function CentrosCostoPage() {
  const [search, setSearch] = useState("");
  const [tabValue, setTabValue] = useState(0);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editItem, setEditItem] = useState<CentroCosto | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = useCentrosCostoList(search || undefined);
  const deleteMutation = useDeleteCentroCosto();

  const centros: CentroCosto[] = useMemo(
    () => data?.data ?? data?.rows ?? [],
    [data]
  );

  const tree = useMemo(() => buildCentroCostoTree(centros), [centros]);

  const handleToggle = (code: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      next.has(code) ? next.delete(code) : next.add(code);
      return next;
    });
  };

  const handleEdit = (item: CentroCosto) => {
    setEditItem(item);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setEditItem(null);
    setDialogOpen(true);
  };

  const handleDelete = async (code: string) => {
    try {
      await deleteMutation.mutateAsync(code);
      setDeleteConfirm(null);
    } catch (err: any) {
      setError(err.message || "Error al eliminar");
    }
  };

  return (
    <Box>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          Centros de Costo
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreate}>
          Crear Centro
        </Button>
      </Stack>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Paper sx={{ mb: 2 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)}>
          <Tab label="Gestion" icon={<AccountTreeIcon />} iconPosition="start" />
          <Tab label="P&L por Centro" />
        </Tabs>
      </Paper>

      {tabValue === 0 && (
        <>
          {/* Search */}
          <TextField
            placeholder="Buscar por codigo o nombre..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            size="small"
            sx={{ mb: 2, maxWidth: 400 }}
            fullWidth
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: "text.secondary" }} />,
            }}
          />

          {/* Tree */}
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            {/* Header */}
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                py: 1,
                px: 2,
                bgcolor: "grey.100",
                borderBottom: "2px solid",
                borderColor: "divider",
              }}
            >
              <Box sx={{ width: 32, mr: 1 }} />
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 100, mr: 2 }}>
                CODIGO
              </Typography>
              <Typography variant="caption" fontWeight={700} sx={{ flex: 1 }}>
                NOMBRE
              </Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 50, mr: 1 }}>
                NIVEL
              </Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 70, mr: 1 }}>
                ESTADO
              </Typography>
              <Typography variant="caption" fontWeight={700} sx={{ minWidth: 72 }}>
                ACCIONES
              </Typography>
            </Box>

            {isLoading ? (
              <Box sx={{ p: 2 }}>
                {Array.from({ length: 5 }).map((_, i) => (
                  <Skeleton key={i} height={44} sx={{ mb: 0.5 }} />
                ))}
              </Box>
            ) : tree.length === 0 ? (
              <Box sx={{ p: 4, textAlign: "center" }}>
                <Typography color="text.secondary">
                  No hay centros de costo. Cree el primero con el boton &quot;Crear Centro&quot;.
                </Typography>
              </Box>
            ) : (
              tree.map((node) => (
                <CentroCostoTreeRow
                  key={node.code}
                  node={node}
                  depth={0}
                  expanded={expanded}
                  onToggle={handleToggle}
                  onEdit={handleEdit}
                  onDelete={(code) => setDeleteConfirm(code)}
                />
              ))
            )}
          </Paper>
        </>
      )}

      {tabValue === 1 && <PnLByCostCenterTab />}

      {/* Create/Edit Dialog */}
      <CentroCostoDialog
        open={dialogOpen}
        onClose={() => {
          setDialogOpen(false);
          setEditItem(null);
        }}
        editItem={editItem}
        allCentros={centros}
      />

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)}>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de eliminar el centro de costo &quot;{deleteConfirm}&quot;? Esta accion no se puede deshacer.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
            disabled={deleteMutation.isPending}
          >
            {deleteMutation.isPending ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
