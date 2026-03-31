"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  AppBar,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import {  DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useFlotaGridRegistration } from "./zenttoGridPersistence";
import {
  useFuelLogsList,
  useCreateFuelLog,
  type FuelFilter,
} from "../hooks/useFlota";
import type { ColumnDef } from "@zentto/datagrid-core";


const GRID_ID = "module-flota:combustible:list";

export default function CombustiblePage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [filter, setFilter] = useState<FuelFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);

  // Form state
  const [vehicleId, setVehicleId] = useState("");
  const [logDate, setLogDate] = useState("");
  const [mileage, setMileage] = useState("");
  const [fuelType, setFuelType] = useState("");
  const [liters, setLiters] = useState("");
  const [pricePerLiter, setPricePerLiter] = useState("");
  const [totalCost, setTotalCost] = useState("");
  const [stationName, setStationName] = useState("");
  const [notes, setNotes] = useState("");
  const gridRef = useRef<any>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { gridReady, registered } = useFlotaGridRegistration(layoutReady);

  const { data, isLoading } = useFuelLogsList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createFuelLog = useCreateFuelLog();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    {
      field: "FuelDate",
      header: "Fecha",
      flex: 1,
      minWidth: 110,
      renderCell: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    { field: "LicensePlate", header: "Placa Vehiculo", flex: 1, minWidth: 110 },
    { field: "FuelType", header: "Tipo Combustible", flex: 1, minWidth: 120 },
    {
      field: "Quantity",
      header: "Litros",
      width: 90,
      renderCell: (value: unknown) => Number(value ?? 0).toFixed(2),
    },
    {
      field: "TotalCost",
      header: "Costo",
      width: 110,
      renderCell: (value: unknown) => formatCurrency(Number(value ?? 0)),
    },
    {
      field: "OdometerReading",
      header: "Kilometraje",
      width: 110,
      renderCell: (value: unknown) => Number(value ?? 0).toLocaleString("es") + " km",
    },
    { field: "StationName", header: "Estacion", flex: 1, minWidth: 130 },
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
    setVehicleId("");
    setLogDate("");
    setMileage("");
    setFuelType("");
    setLiters("");
    setPricePerLiter("");
    setTotalCost("");
    setStationName("");
    setNotes("");
  };

  const handleSubmit = () => {
    createFuelLog.mutate(
      {
        vehicleId: Number(vehicleId),
        logDate,
        mileage: Number(mileage),
        fuelType,
        liters: Number(liters),
        pricePerLiter: Number(pricePerLiter),
        totalCost: Number(totalCost),
        stationName: stationName || undefined,
        notes: notes || undefined,
      },
      {
        onSuccess: () => {
          setDialogOpen(false);
          resetForm();
        },
      }
    );
  };

  const canSubmit = !createFuelLog.isPending && !!vehicleId && !!logDate && !!fuelType && !!liters && !!totalCost;

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
      if (action === "view") { /* TODO: ver detalle */ }
      if (action === "edit") { /* TODO: editar registro */ }
      if (action === "delete") { /* TODO: eliminar registro */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setDialogOpen(true);
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
          Control de Combustible
        </Typography>
      </Box>

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        export-filename="flota-combustible-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
        enable-create
        create-label="Nuevo Combustible"
      ></zentto-grid>

      {/* Dialog: Registrar Carga */}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Registrar Carga de Combustible</Typography>
              <Button autoFocus color="inherit" onClick={handleSubmit} disabled={!canSubmit}>
                {createFuelLog.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Registrar Carga de Combustible</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <DatePicker label="Fecha" value={logDate ? dayjs(logDate) : null} onChange={(v) => setLogDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Kilometraje" type="number" value={mileage} onChange={(e) => setMileage(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Tipo Combustible" value={fuelType} onChange={(e) => setFuelType(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField label="Litros" type="number" value={liters} onChange={(e) => setLiters(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField label="Precio/Litro" type="number" value={pricePerLiter} onChange={(e) => setPricePerLiter(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField label="Costo Total" type="number" value={totalCost} onChange={(e) => setTotalCost(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Estacion" value={stationName} onChange={(e) => setStationName(e.target.value)} fullWidth />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
            <Button variant="contained" onClick={handleSubmit} disabled={!canSubmit}>
              {createFuelLog.isPending ? "Guardando..." : "Guardar"}
            </Button>
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
