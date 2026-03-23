// components/LotesPage.tsx
"use client";

import { useState } from "react";
import {
  Box,
  Button,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
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
import { useLotesList, useCreateLote } from "../hooks/useInventarioAvanzado";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatCurrency } from "@zentto/shared-api";

const LOT_STATUS_CONFIG: Record<string, { label: string; color: "success" | "error" | "warning" | "default" }> = {
  ACTIVE: { label: "Activo", color: "success" },
  EXPIRED: { label: "Expirado", color: "error" },
  QUARANTINE: { label: "Cuarentena", color: "warning" },
  DEPLETED: { label: "Agotado", color: "default" },
};

export default function LotesPage() {
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

  const { data, isLoading } = useLotesList({
    productId: filterProductId ? Number(filterProductId) : undefined,
    status: filterStatus || undefined,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: createLote, isPending: isCreating } = useCreateLote();

  const rows = (data as any)?.rows ?? [];
  const total = (data as any)?.total ?? 0;

  const getStatusChip = (status: string) => {
    const cfg = LOT_STATUS_CONFIG[status] ?? { label: status, color: "default" as const };
    return <Chip label={cfg.label} size="small" color={cfg.color} variant="outlined" />;
  };

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

      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 4 }}>
            <TextField
              label="ID Producto"
              type="number"
              value={filterProductId}
              onChange={(e) => { setFilterProductId(e.target.value); setPage(0); }}
              fullWidth
              size="small"
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <FormControl fullWidth size="small">
              <InputLabel>Estado</InputLabel>
              <Select value={filterStatus} label="Estado" onChange={(e) => { setFilterStatus(e.target.value); setPage(0); }}>
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="ACTIVE">Activo</MenuItem>
                <MenuItem value="EXPIRED">Expirado</MenuItem>
                <MenuItem value="QUARANTINE">Cuarentena</MenuItem>
                <MenuItem value="DEPLETED">Agotado</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Paper>

      {/* Tabla */}
      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Nro. Lote</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Producto ID</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha Fabricación</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha Expiración</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Cantidad Actual</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Costo Unit.</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay lotes registrados
                </TableCell>
              </TableRow>
            ) : (
              rows.map((row: any, i: number) => (
                <TableRow key={row.LotId ?? i} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{String(row.LotNumber ?? "")}</TableCell>
                  <TableCell>{row.ProductId ?? ""}</TableCell>
                  <TableCell>{String(row.ManufactureDate ?? "").slice(0, 10)}</TableCell>
                  <TableCell>{String(row.ExpiryDate ?? "").slice(0, 10)}</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 500 }}>{Number(row.CurrentQuantity ?? 0)}</TableCell>
                  <TableCell align="right">{formatCurrency(Number(row.UnitCost ?? 0))}</TableCell>
                  <TableCell>{getStatusChip(String(row.Status ?? ""))}</TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {total > 0 && (
        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(_, p) => setPage(p)}
          onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          labelRowsPerPage="Filas por página:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

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
                label="Número de Lote"
                value={formData.lotNumber}
                onChange={(e) => setFormData({ ...formData, lotNumber: e.target.value })}
                fullWidth
                size="small"
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
                size="small"
                required
              />
            </Grid>
            <Grid size={6}>
              <DatePicker
                label="Fecha Fabricación"
                value={formData.manufactureDate ? dayjs(formData.manufactureDate) : null}
                onChange={(v) => setFormData({ ...formData, manufactureDate: v ? v.format('YYYY-MM-DD') : '' })}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </Grid>
            <Grid size={6}>
              <DatePicker
                label="Fecha Expiración"
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
                size="small"
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
                size="small"
                inputProps={{ min: 0, step: "0.01" }}
              />
            </Grid>
            <Grid size={12}>
              <TextField
                label="Notas"
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                fullWidth
                size="small"
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
