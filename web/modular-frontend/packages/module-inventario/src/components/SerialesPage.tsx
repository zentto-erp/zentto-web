// components/SerialesPage.tsx
"use client";

import { useState, useCallback } from "react";
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
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  IconButton,
  Tooltip,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SearchIcon from "@mui/icons-material/Search";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import {
  useSerialsList,
  useSerialByNumber,
  useCreateSerial,
  useUpdateSerialStatus,
} from "../hooks/useInventarioAvanzado";
import { debounce } from "lodash";

const SERIAL_STATUS_CONFIG: Record<string, { label: string; color: "success" | "error" | "warning" | "info" | "default" }> = {
  AVAILABLE: { label: "Disponible", color: "success" },
  SOLD: { label: "Vendido", color: "info" },
  RESERVED: { label: "Reservado", color: "warning" },
  DAMAGED: { label: "Dañado", color: "error" },
  RETURNED: { label: "Devuelto", color: "default" },
  IN_WARRANTY: { label: "En Garantía", color: "warning" },
};

export default function SerialesPage() {
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

  const debouncedSearch = useCallback(
    debounce((value: string) => { setSearch(value); setPage(0); }, 500),
    []
  );

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

  const handleViewDetail = (serialNumber: string) => {
    setDetailSerial(serialNumber);
    setDetailOpen(true);
  };

  const handleOpenStatusChange = (serialNumber: string, currentStatus: string) => {
    setStatusSerial(serialNumber);
    setNewStatus(currentStatus);
    setStatusDialogOpen(true);
  };

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
      setSubmitError("Número de serie y producto son requeridos");
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

      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 4 }}>
            <TextField
              placeholder="Buscar serial, producto..."
              onChange={(e) => debouncedSearch(e.target.value)}
              fullWidth
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon fontSize="small" />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <FormControl fullWidth>
              <InputLabel>Estado</InputLabel>
              <Select value={filterStatus} label="Estado" onChange={(e) => { setFilterStatus(e.target.value); setPage(0); }}>
                <MenuItem value="">Todos</MenuItem>
                <MenuItem value="AVAILABLE">Disponible</MenuItem>
                <MenuItem value="SOLD">Vendido</MenuItem>
                <MenuItem value="RESERVED">Reservado</MenuItem>
                <MenuItem value="DAMAGED">Dañado</MenuItem>
                <MenuItem value="RETURNED">Devuelto</MenuItem>
                <MenuItem value="IN_WARRANTY">En Garantía</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <TextField
              label="ID Almacén"
              type="number"
              value={filterWarehouseId}
              onChange={(e) => { setFilterWarehouseId(e.target.value); setPage(0); }}
              fullWidth
            />
          </Grid>
        </Grid>
      </Paper>

      {/* Tabla */}
      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Serial</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Producto ID</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Almacén</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Lote</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Doc. Compra</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Doc. Venta</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Venc. Garantía</TableCell>
              <TableCell align="center" sx={{ fontWeight: 600 }}>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay seriales registrados
                </TableCell>
              </TableRow>
            ) : (
              rows.map((row: any, i: number) => {
                const serial = String(row.SerialNumber ?? "");
                const status = String(row.Status ?? "");
                return (
                  <TableRow key={row.SerialId ?? i} hover>
                    <TableCell sx={{ fontWeight: 500 }}>{serial}</TableCell>
                    <TableCell>{row.ProductId ?? ""}</TableCell>
                    <TableCell>{getStatusChip(status)}</TableCell>
                    <TableCell>{row.WarehouseId ?? ""}</TableCell>
                    <TableCell>{String(row.LotNumber ?? "")}</TableCell>
                    <TableCell>{String(row.PurchaseDoc ?? "")}</TableCell>
                    <TableCell>{String(row.SalesDoc ?? "")}</TableCell>
                    <TableCell>{String(row.WarrantyExpiry ?? "").slice(0, 10)}</TableCell>
                    <TableCell align="center">
                      <Tooltip title="Ver detalle">
                        <IconButton size="small" onClick={() => handleViewDetail(serial)}>
                          <VisibilityIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Cambiar estado">
                        <IconButton size="small" onClick={() => handleOpenStatusChange(serial, status)}>
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                );
              })
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
                  <Typography variant="caption" color="text.secondary">Número de Serie</Typography>
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
                  <Typography variant="caption" color="text.secondary">Almacén</Typography>
                  <Typography variant="body1">{detail.WarehouseId ?? ""}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Lote</Typography>
                  <Typography variant="body1">{String(detail.LotNumber ?? "-")}</Typography>
                </Grid>
                <Grid size={6}>
                  <Typography variant="caption" color="text.secondary">Garantía hasta</Typography>
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
            <Typography color="text.secondary" sx={{ py: 2 }}>No se encontró el serial</Typography>
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
              <MenuItem value="DAMAGED">Dañado</MenuItem>
              <MenuItem value="RETURNED">Devuelto</MenuItem>
              <MenuItem value="IN_WARRANTY">En Garantía</MenuItem>
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
                label="Número de Serie"
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
                label="Número de Lote"
                value={formData.lotNumber}
                onChange={(e) => setFormData({ ...formData, lotNumber: e.target.value })}
                fullWidth
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="ID Almacén"
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
