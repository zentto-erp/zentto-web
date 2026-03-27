"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  AppBar,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import CloseIcon from "@mui/icons-material/Close";
import {
  useVehiclesList,
  useCreateVehicle,
  useUpdateVehicle,
  type VehicleFilter,
} from "../hooks/useFlota";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";


function VehiculoDetailPanel({ row }: { row: Record<string, unknown> }) {
  const fields = [
    { label: 'VIN / Chasis', value: row.VinNumber },
    { label: 'Color', value: row.Color },
    { label: 'Combustible', value: row.FuelType },
    { label: 'Kilometraje', value: row.CurrentOdometer != null ? `${Number(row.CurrentOdometer).toLocaleString('es')} km` : null },
    { label: 'Conductor asignado', value: row.DefaultDriverId },
    { label: 'Notas', value: row.Notes },
  ].filter(f => f.value != null && f.value !== '');

  return (
    <Box sx={{ px: 3, py: 2, display: 'flex', flexWrap: 'wrap', gap: 3 }}>
      {fields.map(f => (
        <Box key={f.label} sx={{ minWidth: 150 }}>
          <Typography variant="caption" color="text.secondary"
            sx={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block' }}>
            {f.label}
          </Typography>
          <Typography variant="body2" fontWeight={500} sx={{ mt: 0.25 }}>
            {String(f.value)}
          </Typography>
        </Box>
      ))}
    </Box>
  );
}

const statusColors: Record<string, "success" | "warning" | "default"> = {
  ACTIVE: "success",
  MAINTENANCE: "warning",
  INACTIVE: "default",
};

const statusLabels: Record<string, string> = {
  ACTIVE: "Activo",
  MAINTENANCE: "Mantenimiento",
  INACTIVE: "Inactivo",
};

const GRID_ID = "module-flota:vehiculos:list";

export default function VehiculosPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [filter, setFilter] = useState<VehicleFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);
  const [editMode, setEditMode] = useState(false);

  // Form state
  const [vehiclePlate, setLicensePlate] = useState("");
  const [brand, setBrand] = useState("");
  const [model, setModel] = useState("");
  const [year, setYear] = useState("");
  const [vehicleType, setVehicleType] = useState("");
  const [fuelType, setFuelType] = useState("");
  const [currentMileage, setCurrentOdometer] = useState("");
  const [color, setColor] = useState("");
  const [vin, setVin] = useState("");
  const [notes, setNotes] = useState("");
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);

  useEffect(() => {
    if (!layoutReady) return;
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, [layoutReady]);

  const { data, isLoading } = useVehiclesList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createVehicle = useCreateVehicle();
  const updateVehicle = useUpdateVehicle();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "LicensePlate", header: "Placa", flex: 0.8, minWidth: 100 },
    { field: "Brand", header: "Marca", flex: 1, minWidth: 100 },
    { field: "Model", header: "Modelo", flex: 1, minWidth: 100 },
    { field: "Year", header: "Ano", width: 70 },
    {
      field: "VehicleType",
      header: "Tipo",
      width: 120,
      renderCell: (params) => (
        <Chip label={String(params.value ?? "")} size="small" variant="outlined" />
      ),
    },
    {
      field: "Status",
      header: "Estado",
      width: 130,
      renderCell: (params) => {
        const status = String(params.value ?? "ACTIVE");
        return (
          <Chip
            label={statusLabels[status] ?? status}
            size="small"
            color={statusColors[status] ?? "default"}
            variant="outlined"
          />
        );
      },
    },
    { field: "DefaultDriverId", header: "Conductor", flex: 1, minWidth: 120 },
    {
      field: "CurrentOdometer",
      header: "Kilometraje",
      width: 110,
      valueFormatter: (value: unknown) => {
        const n = Number(value ?? 0);
        return n.toLocaleString("es") + " km";
      },
    },
    {
      field: "actions",
      header: "Acciones",
      type: "actions",
      width: 130,
      pin: "right",
      actions: [
        { icon: "view", label: "Ver", action: "view", color: "#6b7280" },
        { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
        { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
      ],
    },
  ];

  const resetForm = () => {
    setLicensePlate("");
    setBrand("");
    setModel("");
    setYear("");
    setVehicleType("");
    setFuelType("");
    setCurrentOdometer("");
    setColor("");
    setVin("");
    setNotes("");
    setEditMode(false);
    setSelectedRow(null);
  };

  const openEditDialog = (row: Record<string, unknown>) => {
    setSelectedRow(row);
    setLicensePlate(String(row.LicensePlate ?? ""));
    setBrand(String(row.Brand ?? ""));
    setModel(String(row.Model ?? ""));
    setYear(String(row.Year ?? ""));
    setVehicleType(String(row.VehicleType ?? ""));
    setFuelType(String(row.FuelType ?? ""));
    setCurrentOdometer(String(row.CurrentOdometer ?? ""));
    setColor(String(row.Color ?? ""));
    setVin(String(row.VinNumber ?? ""));
    setNotes(String(row.Notes ?? ""));
    setEditMode(true);
    setDialogOpen(true);
  };

  const handleSubmit = () => {
    const payload: Record<string, unknown> = {
      vehiclePlate,
      brand,
      model,
      year: Number(year),
      vehicleType,
      fuelType,
      currentMileage: Number(currentMileage),
      color: color || undefined,
      vin: vin || undefined,
      notes: notes || undefined,
    };

    if (editMode && selectedRow) {
      payload.vehicleId = Number(selectedRow.VehicleId ?? selectedRow.Id);
      updateVehicle.mutate(payload, {
        onSuccess: () => {
          setDialogOpen(false);
          resetForm();
        },
      });
    } else {
      createVehicle.mutate(payload, {
        onSuccess: () => {
          setDialogOpen(false);
          resetForm();
        },
      });
    }
  };

  const isPending = createVehicle.isPending || updateVehicle.isPending;

  const dialogTitle = editMode ? "Editar Vehiculo" : "Nuevo Vehiculo";

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") { setSelectedRow(row); setDetailOpen(true); }
      if (action === "edit") openEditDialog(row);
      if (action === "delete") { /* TODO: eliminar vehiculo */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => { resetForm(); setDialogOpen(true); };
    el.addEventListener("create-click", handler);
    return () => el.removeEventListener("create-click", handler);
  }, [registered]);

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{
        display: "flex",
        flexDirection: { xs: 'column', sm: 'row' },
        justifyContent: "space-between",
        alignItems: { xs: 'stretch', sm: 'center' },
        gap: 2, mb: 3,
      }}>
        <Typography variant="h5" fontWeight={600}>
          Vehiculos
        </Typography>
      </Box>

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        export-filename="flota-vehiculos-list"
        height="calc(100vh - 200px)"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-grouping
        enable-pivot
        enable-create
        create-label="Nuevo Vehiculo"
      ></zentto-grid>

      {/* Dialog: Crear/Editar Vehiculo */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "md"}
        fullWidth
      >
        {isMobile ? (
          <AppBar sx={{ position: 'relative' }}>
            <Toolbar>
              <IconButton edge="start" color="inherit" onClick={() => setDialogOpen(false)} aria-label="cerrar">
                <CloseIcon />
              </IconButton>
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">{dialogTitle}</Typography>
              <Button
                autoFocus
                color="inherit"
                onClick={handleSubmit}
                disabled={isPending || !vehiclePlate || !brand || !model || !year || !vehicleType || !fuelType}
              >
                {isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>{dialogTitle}</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField label="Placa" value={vehiclePlate} onChange={(e) => setLicensePlate(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Marca" value={brand} onChange={(e) => setBrand(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Modelo" value={model} onChange={(e) => setModel(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Ano" type="number" value={year} onChange={(e) => setYear(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Color" value={color} onChange={(e) => setColor(e.target.value)} fullWidth />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                select
                label="Tipo Vehiculo"
                value={vehicleType}
                onChange={(e) => setVehicleType(e.target.value)}
                fullWidth
                required
              >
                <MenuItem value="SEDAN">Sedan</MenuItem>
                <MenuItem value="SUV">SUV</MenuItem>
                <MenuItem value="PICKUP">Pickup</MenuItem>
                <MenuItem value="VAN">Van</MenuItem>
                <MenuItem value="TRUCK">Camion</MenuItem>
                <MenuItem value="MOTORCYCLE">Moto</MenuItem>
                <MenuItem value="OTHER">Otro</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                select
                label="Tipo Combustible"
                value={fuelType}
                onChange={(e) => setFuelType(e.target.value)}
                fullWidth
                required
              >
                <MenuItem value="GASOLINE">Gasolina</MenuItem>
                <MenuItem value="DIESEL">Diesel</MenuItem>
                <MenuItem value="ELECTRIC">Electrico</MenuItem>
                <MenuItem value="HYBRID">Hibrido</MenuItem>
                <MenuItem value="GAS">Gas</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Kilometraje Actual" type="number" value={currentMileage} onChange={(e) => setCurrentOdometer(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="VIN" value={vin} onChange={(e) => setVin(e.target.value)} fullWidth />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
            <Button
              variant="contained"
              onClick={handleSubmit}
              disabled={isPending || !vehiclePlate || !brand || !model || !year || !vehicleType || !fuelType}
            >
              {isPending ? "Guardando..." : "Guardar"}
            </Button>
          </DialogActions>
        )}
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "sm"}
        fullWidth
      >
        {isMobile ? (
          <AppBar sx={{ position: 'relative' }}>
            <Toolbar>
              <IconButton edge="start" color="inherit" onClick={() => setDetailOpen(false)} aria-label="cerrar">
                <CloseIcon />
              </IconButton>
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Detalle de Vehiculo</Typography>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Detalle de Vehiculo</DialogTitle>
        )}
        <DialogContent>
          {selectedRow && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Placa</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.LicensePlate ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Marca</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Brand ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Modelo</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Model ?? "")}</Typography>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" color="text.secondary">Ano</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Year ?? "")}</Typography>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" color="text.secondary">Tipo</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.VehicleType ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Combustible</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.FuelType ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Kilometraje</Typography>
                <Typography variant="body1" fontWeight={500}>{Number(selectedRow.CurrentOdometer ?? 0).toLocaleString("es")} km</Typography>
              </Grid>
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" color="text.secondary">Color</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Color ?? "--")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">VIN</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.VinNumber ?? "--")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Conductor</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.DefaultDriverId ?? "--")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Estado</Typography>
                <Box sx={{ mt: 0.5 }}>
                  <Chip
                    label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                    size="small"
                    color={statusColors[String(selectedRow.Status)] ?? "default"}
                    variant="outlined"
                  />
                </Box>
              </Grid>
              <Grid item xs={12}>
                <Typography variant="caption" color="text.secondary">Notas</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Notes ?? "--")}</Typography>
              </Grid>
            </Grid>
          )}
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
          </DialogActions>
        )}
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
