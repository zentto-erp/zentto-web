// components/AlmacenesWMSPage.tsx
"use client";

import { useState } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  CircularProgress,
  Chip,
  Typography,
  Card,
  CardContent,
  CardActionArea,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  IconButton,
  Breadcrumbs,
  Link,
  Tooltip,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AddIcon from "@mui/icons-material/Add";
import WarehouseIcon from "@mui/icons-material/Warehouse";
import LayersIcon from "@mui/icons-material/Layers";
import ViewInArIcon from "@mui/icons-material/ViewInAr";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import {
  useWarehousesList,
  useWarehouseZones,
  useWarehouseBins,
  useCreateWarehouse,
  useBinStock,
} from "../hooks/useInventarioAvanzado";

export default function AlmacenesWMSPage() {
  // Navigation state
  const [selectedWarehouse, setSelectedWarehouse] = useState<{ id: number; name: string } | null>(null);
  const [selectedZone, setSelectedZone] = useState<{ id: number; name: string } | null>(null);

  // Create dialog
  const [createOpen, setCreateOpen] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    warehouseCode: "",
    warehouseName: "",
    address: "",
    notes: "",
  });

  const { data: warehousesData, isLoading: whLoading } = useWarehousesList();
  const { data: zonesData, isLoading: zonesLoading } = useWarehouseZones(selectedWarehouse?.id);
  const { data: binsData, isLoading: binsLoading } = useWarehouseBins(selectedZone?.id);
  const { data: binStockData } = useBinStock(selectedWarehouse?.id);
  const { mutate: createWarehouse, isPending: isCreating } = useCreateWarehouse();

  const warehouses = (warehousesData as any)?.rows ?? (Array.isArray(warehousesData) ? warehousesData : []);
  const zones = (zonesData as any)?.rows ?? (Array.isArray(zonesData) ? zonesData : []);
  const bins = (binsData as any)?.rows ?? (Array.isArray(binsData) ? binsData : []);
  const binStock = (binStockData as any)?.rows ?? (Array.isArray(binStockData) ? binStockData : []);

  const handleSelectWarehouse = (wh: any) => {
    setSelectedWarehouse({ id: wh.WarehouseId, name: String(wh.WarehouseName ?? wh.WarehouseCode ?? "") });
    setSelectedZone(null);
  };

  const handleSelectZone = (zone: any) => {
    setSelectedZone({ id: zone.ZoneId, name: String(zone.ZoneName ?? zone.ZoneCode ?? "") });
  };

  const handleBackToWarehouses = () => {
    setSelectedWarehouse(null);
    setSelectedZone(null);
  };

  const handleBackToZones = () => {
    setSelectedZone(null);
  };

  const handleCreate = () => {
    setSubmitError(null);
    if (!formData.warehouseCode || !formData.warehouseName) {
      setSubmitError("Código y nombre del almacén son requeridos");
      return;
    }
    createWarehouse(
      {
        warehouseCode: formData.warehouseCode,
        warehouseName: formData.warehouseName,
        address: formData.address || undefined,
        notes: formData.notes || undefined,
      },
      {
        onSuccess: () => {
          setCreateOpen(false);
          setFormData({ warehouseCode: "", warehouseName: "", address: "", notes: "" });
        },
        onError: (err) => {
          setSubmitError(err instanceof Error ? err.message : "Error al crear almacén");
        },
      }
    );
  };

  // Get bin stock map for quick lookup
  const stockMap = new Map<number, number>();
  binStock.forEach((s: any) => {
    stockMap.set(s.BinId, Number(s.StockQty ?? 0));
  });

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" fontWeight={600}>Almacenes WMS</Typography>
        {!selectedWarehouse && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
            Nuevo Almacén
          </Button>
        )}
      </Box>

      {/* Breadcrumbs */}
      <Breadcrumbs sx={{ mb: 3 }}>
        <Link
          component="button"
          underline="hover"
          color={selectedWarehouse ? "inherit" : "text.primary"}
          onClick={handleBackToWarehouses}
          sx={{ fontWeight: selectedWarehouse ? 400 : 600 }}
        >
          Almacenes
        </Link>
        {selectedWarehouse && (
          <Link
            component="button"
            underline="hover"
            color={selectedZone ? "inherit" : "text.primary"}
            onClick={handleBackToZones}
            sx={{ fontWeight: selectedZone ? 400 : 600 }}
          >
            {selectedWarehouse.name}
          </Link>
        )}
        {selectedZone && (
          <Typography color="text.primary" fontWeight={600}>
            {selectedZone.name}
          </Typography>
        )}
      </Breadcrumbs>

      {/* Nivel 1: Almacenes */}
      {!selectedWarehouse && (
        <>
          {whLoading ? (
            <Box sx={{ textAlign: "center", py: 6 }}>
              <CircularProgress size={40} />
            </Box>
          ) : warehouses.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: "center" }}>
              <WarehouseIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
              <Typography color="text.secondary">No hay almacenes WMS registrados</Typography>
            </Paper>
          ) : (
            <Grid container spacing={2}>
              {warehouses.map((wh: any, i: number) => (
                <Grid size={{ xs: 12, sm: 6, md: 4 }} key={wh.WarehouseId ?? i}>
                  <Card variant="outlined">
                    <CardActionArea onClick={() => handleSelectWarehouse(wh)}>
                      <CardContent>
                        <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                          <WarehouseIcon color="primary" />
                          <Typography variant="h6" fontWeight={600}>
                            {String(wh.WarehouseCode ?? "")}
                          </Typography>
                        </Box>
                        <Typography variant="body1" sx={{ mb: 1 }}>
                          {String(wh.WarehouseName ?? "")}
                        </Typography>
                        {wh.Address && (
                          <Typography variant="body2" color="text.secondary">
                            {String(wh.Address)}
                          </Typography>
                        )}
                        <Box sx={{ mt: 1, display: "flex", gap: 1 }}>
                          <Chip
                            label={`${wh.ZoneCount ?? 0} zonas`}
                            size="small"
                            variant="outlined"
                            color="primary"
                          />
                          <Chip
                            label={wh.IsActive ? "Activo" : "Inactivo"}
                            size="small"
                            variant="outlined"
                            color={wh.IsActive !== false ? "success" : "default"}
                          />
                        </Box>
                      </CardContent>
                    </CardActionArea>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </>
      )}

      {/* Nivel 2: Zonas */}
      {selectedWarehouse && !selectedZone && (
        <>
          <Box sx={{ mb: 2 }}>
            <Tooltip title="Volver a almacenes">
              <IconButton onClick={handleBackToWarehouses} size="small" sx={{ mr: 1 }}>
                <ArrowBackIcon />
              </IconButton>
            </Tooltip>
            <Typography variant="subtitle1" component="span" fontWeight={600}>
              Zonas de {selectedWarehouse.name}
            </Typography>
          </Box>

          {zonesLoading ? (
            <Box sx={{ textAlign: "center", py: 6 }}>
              <CircularProgress size={40} />
            </Box>
          ) : zones.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: "center" }}>
              <LayersIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
              <Typography color="text.secondary">No hay zonas en este almacén</Typography>
            </Paper>
          ) : (
            <Grid container spacing={2}>
              {zones.map((zone: any, i: number) => (
                <Grid size={{ xs: 12, sm: 6, md: 4 }} key={zone.ZoneId ?? i}>
                  <Card variant="outlined">
                    <CardActionArea onClick={() => handleSelectZone(zone)}>
                      <CardContent>
                        <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                          <LayersIcon color="secondary" />
                          <Typography variant="h6" fontWeight={600}>
                            {String(zone.ZoneCode ?? "")}
                          </Typography>
                        </Box>
                        <Typography variant="body1" sx={{ mb: 1 }}>
                          {String(zone.ZoneName ?? "")}
                        </Typography>
                        {zone.ZoneType && (
                          <Chip
                            label={String(zone.ZoneType)}
                            size="small"
                            variant="outlined"
                            color="info"
                          />
                        )}
                        <Box sx={{ mt: 1 }}>
                          <Chip
                            label={`${zone.BinCount ?? 0} ubicaciones`}
                            size="small"
                            variant="outlined"
                          />
                        </Box>
                      </CardContent>
                    </CardActionArea>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </>
      )}

      {/* Nivel 3: Ubicaciones (Bins) */}
      {selectedZone && (
        <>
          <Box sx={{ mb: 2 }}>
            <Tooltip title="Volver a zonas">
              <IconButton onClick={handleBackToZones} size="small" sx={{ mr: 1 }}>
                <ArrowBackIcon />
              </IconButton>
            </Tooltip>
            <Typography variant="subtitle1" component="span" fontWeight={600}>
              Ubicaciones de {selectedZone.name}
            </Typography>
          </Box>

          {binsLoading ? (
            <Box sx={{ textAlign: "center", py: 6 }}>
              <CircularProgress size={40} />
            </Box>
          ) : bins.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: "center" }}>
              <ViewInArIcon sx={{ fontSize: 48, color: "text.disabled", mb: 1 }} />
              <Typography color="text.secondary">No hay ubicaciones en esta zona</Typography>
            </Paper>
          ) : (
            <Grid container spacing={2}>
              {bins.map((bin: any, i: number) => {
                const stock = stockMap.get(bin.BinId) ?? Number(bin.StockQty ?? 0);
                return (
                  <Grid size={{ xs: 6, sm: 4, md: 3 }} key={bin.BinId ?? i}>
                    <Card variant="outlined" sx={{ borderColor: stock > 0 ? "success.light" : "grey.300" }}>
                      <CardContent sx={{ textAlign: "center", py: 2 }}>
                        <ViewInArIcon sx={{ fontSize: 32, color: stock > 0 ? "success.main" : "text.disabled", mb: 0.5 }} />
                        <Typography variant="subtitle2" fontWeight={600}>
                          {String(bin.BinCode ?? "")}
                        </Typography>
                        {bin.BinName && (
                          <Typography variant="caption" color="text.secondary" display="block">
                            {String(bin.BinName)}
                          </Typography>
                        )}
                        <Chip
                          label={`Stock: ${stock}`}
                          size="small"
                          color={stock > 0 ? "success" : "default"}
                          variant="outlined"
                          sx={{ mt: 1 }}
                        />
                        {bin.MaxCapacity && (
                          <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 0.5 }}>
                            Cap. máx: {bin.MaxCapacity}
                          </Typography>
                        )}
                      </CardContent>
                    </Card>
                  </Grid>
                );
              })}
            </Grid>
          )}
        </>
      )}

      {/* Dialog Crear Almacén */}
      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Almacén WMS</DialogTitle>
        <DialogContent>
          {submitError && (
            <Alert severity="error" sx={{ mb: 2, mt: 1 }} onClose={() => setSubmitError(null)}>
              {submitError}
            </Alert>
          )}
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid size={6}>
              <TextField
                label="Código"
                value={formData.warehouseCode}
                onChange={(e) => setFormData({ ...formData, warehouseCode: e.target.value })}
                fullWidth
                required
              />
            </Grid>
            <Grid size={6}>
              <TextField
                label="Nombre"
                value={formData.warehouseName}
                onChange={(e) => setFormData({ ...formData, warehouseName: e.target.value })}
                fullWidth
                required
              />
            </Grid>
            <Grid size={12}>
              <TextField
                label="Dirección"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
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
            {isCreating ? "Guardando..." : "Crear Almacén"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
