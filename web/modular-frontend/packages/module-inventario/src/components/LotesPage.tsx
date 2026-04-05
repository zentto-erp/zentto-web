// components/LotesPage.tsx
"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  CircularProgress,
  Typography,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AddIcon from "@mui/icons-material/Add";
import { useLotesList, useCreateLote } from "../hooks/useInventarioAvanzado";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";

const GRID_ID = "module-inventario:lotes:list";

const COLUMNS: ColumnDef[] = [
  { field: "lotNumber", header: "Nro. Lote", width: 140, sortable: true },
  { field: "productId", header: "Producto ID", width: 110, sortable: true },
  { field: "manufactureDate", header: "Fecha Fabricacion", width: 130, type: "date" },
  { field: "expiryDate", header: "Fecha Expiracion", width: 130, type: "date" },
  { field: "currentQuantity", header: "Cantidad Actual", width: 120, type: "number", aggregation: "sum" },
  { field: "unitCost", header: "Costo Unit.", width: 120, type: "number", currency: "VES", aggregation: "avg" },
  {
    field: "status", header: "Estado", width: 110,
    statusColors: { ACTIVE: "success", EXPIRED: "error", QUARANTINE: "warning", DEPLETED: "default" },
    statusVariant: "outlined",
  },
];

export default function LotesPage() {
  const gridRef = useRef<any>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [filterProductId, setFilterProductId] = useState<string>("");
  const [filterStatus, setFilterStatus] = useState<string>("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  // Form state
  const [formData, setFormData] = useState({
    lotNumber: "",
    productId: "",
    manufactureDate: "",
    expiryDate: "",
    initialQuantity: "",
    unitCost: "",
    notes: "",
  });

  const { ready } = useGridLayoutSync(GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  const { data, isLoading } = useLotesList({
    productId: filterProductId ? Number(filterProductId) : undefined,
    status: filterStatus || undefined,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: createLote, isPending: isCreating } = useCreateLote();

  const rows = (data as any)?.rows ?? [];
  const total = (data as any)?.total ?? 0;

  const gridRows = useMemo(() => rows.map((row: any, i: number) => ({
    id: row.LotId ?? i,
    lotNumber: String(row.LotNumber ?? ""),
    productId: row.ProductId ?? "",
    manufactureDate: String(row.ManufactureDate ?? "").slice(0, 10),
    expiryDate: String(row.ExpiryDate ?? "").slice(0, 10),
    currentQuantity: Number(row.CurrentQuantity ?? 0),
    unitCost: Number(row.UnitCost ?? 0),
    status: String(row.Status ?? ""),
  })), [rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, isLoading, registered]);

  const handleCreate = () => {
    setSubmitError(null);
    if (!formData.lotNumber || !formData.productId) {
      setSubmitError("Numero de lote y producto son requeridos");
      return;
    }
    createLote(
      {
        lotNumber: formData.lotNumber,
        productId: Number(formData.productId),
        manufactureDate: formData.manufactureDate || undefined,
        expiryDate: formData.expiryDate || undefined,
        initialQuantity: formData.initialQuantity ? Number(formData.initialQuantity) : undefined,
        unitCost: formData.unitCost ? Number(formData.unitCost) : undefined,
        notes: formData.notes || undefined,
      },
      {
        onSuccess: () => {
          setDialogOpen(false);
          setFormData({ lotNumber: "", productId: "", manufactureDate: "", expiryDate: "", initialQuantity: "", unitCost: "", notes: "" });
        },
        onError: (err) => {
          setSubmitError(err instanceof Error ? err.message : "Error al crear lote");
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Lotes</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Nuevo Lote
        </Button>
      </Box>

      {/* Grid */}
      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="calc(100vh - 200px)"
        default-currency="VES"
        export-filename="lotes"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      />

      {/* Dialog Crear Lote */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Lote</DialogTitle>
        <DialogContent>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2, mt: 1 }} onClose={() => setSubmitError(null)}>
              {submitError}
            </Alert>
          )}
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={6}>
              <TextField
                label="Numero de Lote"
                value={formData.lotNumber}
                onChange={(e) => setFormData({ ...formData, lotNumber: e.target.value })}
                fullWidth
                required
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="ID Producto"
                type="number"
                value={formData.productId}
                onChange={(e) => setFormData({ ...formData, productId: e.target.value })}
                fullWidth
                required
              />
            </Grid>
            <Grid size={6}>
              <DatePicker
                label="Fecha Fabricacion"
                value={formData.manufactureDate ? dayjs(formData.manufactureDate) : null}
                onChange={(v) => setFormData({ ...formData, manufactureDate: v ? v.format('YYYY-MM-DD') : '' })}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </Grid>
            <Grid size={6}>
              <DatePicker
                label="Fecha Expiracion"
                value={formData.expiryDate ? dayjs(formData.expiryDate) : null}
                onChange={(v) => setFormData({ ...formData, expiryDate: v ? v.format('YYYY-MM-DD') : '' })}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="Cantidad Inicial"
                type="number"
                value={formData.initialQuantity}
                onChange={(e) => setFormData({ ...formData, initialQuantity: e.target.value })}
                fullWidth
                inputProps={{ min: 0 }}
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="Costo Unitario"
                type="number"
                value={formData.unitCost}
                onChange={(e) => setFormData({ ...formData, unitCost: e.target.value })}
                fullWidth
                inputProps={{ min: 0, step: "0.01" }}
              />
            </Grid>
            <Grid size={12}>
              <TextField
                label="Notas"
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                fullWidth
                multiline
                rows={2}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)} disabled={isCreating}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={isCreating}
            startIcon={isCreating ? <CircularProgress size={20} /> : null}
          >
            {isCreating ? "Guardando..." : "Crear Lote"}
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
