// components/SerialesPage.tsx
"use client";

import { useState, useCallback, useEffect, useRef, useMemo } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  CircularProgress,
  Chip,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AddIcon from "@mui/icons-material/Add";
import {
  useSerialsList,
  useSerialByNumber,
  useCreateSerial,
  useUpdateSerialStatus,
} from "../hooks/useInventarioAvanzado";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";

const GRID_ID = "module-inventario:seriales:list";

const SERIAL_STATUS_CONFIG: Record<string, { label: string; color: "success" | "error" | "warning" | "info" | "default" }> = {
  AVAILABLE: { label: "Disponible", color: "success" },
  SOLD: { label: "Vendido", color: "info" },
  RESERVED: { label: "Reservado", color: "warning" },
  DAMAGED: { label: "Danado", color: "error" },
  RETURNED: { label: "Devuelto", color: "default" },
  IN_WARRANTY: { label: "En Garantia", color: "warning" },
};

const COLUMNS: ColumnDef[] = [
  { field: "serial", header: "Serial", width: 160, sortable: true },
  { field: "productId", header: "Producto ID", width: 110, sortable: true },
  {
    field: "status", header: "Estado", width: 120,
    statusColors: { AVAILABLE: "success", SOLD: "info", RESERVED: "warning", DAMAGED: "error", RETURNED: "default", IN_WARRANTY: "warning" },
    statusVariant: "outlined",
  },
  { field: "warehouseId", header: "Almacen", width: 100 },
  { field: "lotNumber", header: "Lote", width: 120 },
  { field: "purchaseDoc", header: "Doc. Compra", width: 130 },
  { field: "salesDoc", header: "Doc. Venta", width: 130 },
  { field: "warrantyExpiry", header: "Venc. Garantia", width: 120, type: "date" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view", color: "#6b7280" },
      { icon: "edit", label: "Cambiar estado", action: "changeStatus", color: "#1976d2" },
    ],
  },
];

export default function SerialesPage() {
  const gridRef = useRef<any>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("");
  const [filterWarehouseId, setFilterWarehouseId] = useState("");

  // Detail dialog
  const [detailSerial, setDetailSerial] = useState<string | undefined>(undefined);
  const [detailOpen, setDetailOpen] = useState(false);

  // Status change dialog
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [statusSerial, setStatusSerial] = useState("");
  const [newStatus, setNewStatus] = useState("");

  // Create dialog
  const [createOpen, setCreateOpen] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    serialNumber: "",
    productId: "",
    lotNumber: "",
    warehouseId: "",
    notes: "",
  });

  const { ready } = useGridLayoutSync(GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  const { data, isLoading } = useSerialsList({
    search: search || undefined,
    status: filterStatus || undefined,
    warehouseId: filterWarehouseId ? Number(filterWarehouseId) : undefined,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { data: serialDetail, isLoading: detailLoading } = useSerialByNumber(detailSerial);
  const { mutate: createSerial, isPending: isCreating } = useCreateSerial();
  const { mutate: updateStatus, isPending: isUpdatingStatus } = useUpdateSerialStatus();

  const rows = (data as any)?.rows ?? [];
  const total = (data as any)?.total ?? 0;

  const getStatusChip = (status: string) => {
    const cfg = SERIAL_STATUS_CONFIG[status] ?? { label: status, color: "default" as const };
    return <Chip label={cfg.label} size="small" color={cfg.color} variant="outlined" />;
  };

  const gridRows = useMemo(() => rows.map((row: any, i: number) => ({
    id: row.SerialId ?? i,
    serial: String(row.SerialNumber ?? ""),
    productId: row.ProductId ?? "",
    status: String(row.Status ?? ""),
    warehouseId: row.WarehouseId ?? "",
    lotNumber: String(row.LotNumber ?? ""),
    purchaseDoc: String(row.PurchaseDoc ?? ""),
    salesDoc: String(row.SalesDoc ?? ""),
    warrantyExpiry: String(row.WarrantyExpiry ?? "").slice(0, 10),
  })), [rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view" && row?.serial) {
        setDetailSerial(row.serial);
        setDetailOpen(true);
      }
      if (action === "changeStatus" && row?.serial) {
        setStatusSerial(row.serial);
        setNewStatus(row.status);
        setStatusDialogOpen(true);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, gridRows]);

  const handleStatusChange = () => {
    if (!statusSerial || !newStatus) return;
    updateStatus(
      { serialNumber: statusSerial, status: newStatus },
      {
        onSuccess: () => setStatusDialogOpen(false),
        onError: (err) => setSubmitError(err instanceof Error ? err.message : "Error al actualizar estado"),
      }
    );
  };

  const handleCreate = () => {
    setSubmitError(null);
    if (!formData.serialNumber || !formData.productId) {
      setSubmitError("Numero de serie y producto son requeridos");
      return;
    }
    createSerial(
      {
        serialNumber: formData.serialNumber,
        productId: Number(formData.productId),
        lotNumber: formData.lotNumber || undefined,
        warehouseId: formData.warehouseId ? Number(formData.warehouseId) : undefined,
        notes: formData.notes || undefined,
      },
      {
        onSuccess: () => {
          setCreateOpen(false);
          setFormData({ serialNumber: "", productId: "", lotNumber: "", warehouseId: "", notes: "" });
        },
        onError: (err) => {
          setSubmitError(err instanceof Error ? err.message : "Error al crear serial");
        },
      }
    );
  };

  const detail = serialDetail as any;

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Seriales</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
          Nuevo Serial
        </Button>
      </Box>

      {/* Grid */}
      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="calc(100vh - 200px)"
        export-filename="seriales"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      />

      {/* Dialog Detalle Serial */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle del Serial</DialogTitle>
        <DialogContent>
          {detailLoading ? (
            <Box sx={{ textAlign: "center", py: 4 }}>
              <CircularProgress size={32} />
            </Box>
          ) : detail ? (
            <Box sx={{ mt: 1 }}>
              <Grid container spacing={2}>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Numero de Serie</Typography>
                  <Typography variant="body1" fontWeight={600}>{String(detail.SerialNumber ?? "")}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Estado</Typography>
                  <Box sx={{ mt: 0.5 }}>{getStatusChip(String(detail.Status ?? ""))}</Box>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Producto ID</Typography>
                  <Typography variant="body1">{detail.ProductId ?? ""}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Almacen</Typography>
                  <Typography variant="body1">{detail.WarehouseId ?? ""}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Lote</Typography>
                  <Typography variant="body1">{String(detail.LotNumber ?? "-")}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Garantia hasta</Typography>
                  <Typography variant="body1">{String(detail.WarrantyExpiry ?? "-").slice(0, 10)}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Doc. Compra</Typography>
                  <Typography variant="body1">{String(detail.PurchaseDoc ?? "-")}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Doc. Venta</Typography>
                  <Typography variant="body1">{String(detail.SalesDoc ?? "-")}</Typography>
                </Grid>
              </Grid>
            </Box>
          ) : (
            <Typography color="text.secondary" sx={{ py: 2 }}>No se encontro el serial</Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog Cambiar Estado */}
      <Dialog open={statusDialogOpen} onClose={() => setStatusDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Cambiar Estado del Serial</DialogTitle>
        <DialogContent>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2, mt: 1 }} onClose={() => setSubmitError(null)}>
              {submitError}
            </Alert>
          )}
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1, mb: 2 }}>
            Serial: <strong>{statusSerial}</strong>
          </Typography>
          <FormControl fullWidth>
            <InputLabel>Nuevo Estado</InputLabel>
            <Select value={newStatus} label="Nuevo Estado" onChange={(e) => setNewStatus(e.target.value)}>
              <MenuItem value="AVAILABLE">Disponible</MenuItem>
              <MenuItem value="SOLD">Vendido</MenuItem>
              <MenuItem value="RESERVED">Reservado</MenuItem>
              <MenuItem value="DAMAGED">Danado</MenuItem>
              <MenuItem value="RETURNED">Devuelto</MenuItem>
              <MenuItem value="IN_WARRANTY">En Garantia</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setStatusDialogOpen(false)} disabled={isUpdatingStatus}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleStatusChange}
            disabled={isUpdatingStatus}
            startIcon={isUpdatingStatus ? <CircularProgress size={20} /> : null}
          >
            {isUpdatingStatus ? "Guardando..." : "Actualizar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog Crear Serial */}
      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Serial</DialogTitle>
        <DialogContent>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2, mt: 1 }} onClose={() => setSubmitError(null)}>
              {submitError}
            </Alert>
          )}
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={6}>
              <TextField
                label="Numero de Serie"
                value={formData.serialNumber}
                onChange={(e) => setFormData({ ...formData, serialNumber: e.target.value })}
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
              <TextField
                label="Numero de Lote"
                value={formData.lotNumber}
                onChange={(e) => setFormData({ ...formData, lotNumber: e.target.value })}
                fullWidth
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="ID Almacen"
                type="number"
                value={formData.warehouseId}
                onChange={(e) => setFormData({ ...formData, warehouseId: e.target.value })}
                fullWidth
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
          <Button onClick={() => setCreateOpen(false)} disabled={isCreating}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={isCreating}
            startIcon={isCreating ? <CircularProgress size={20} /> : null}
          >
            {isCreating ? "Guardando..." : "Crear Serial"}
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
