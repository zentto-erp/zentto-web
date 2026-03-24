"use client";

import React, { useState } from "react";
import {
  AppBar,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Stack,
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency } from "@zentto/shared-api";
import {
  useFuelLogsList,
  useCreateFuelLog,
  type FuelFilter,
} from "../hooks/useFlota";

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

  const { data, isLoading } = useFuelLogsList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createFuelLog = useCreateFuelLog();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    {
      field: "FuelDate",
      headerName: "Fecha",
      flex: 1,
      minWidth: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    { field: "LicensePlate", headerName: "Placa Vehiculo", flex: 1, minWidth: 110 },
    { field: "FuelType", headerName: "Tipo Combustible", flex: 1, minWidth: 120 },
    {
      field: "Quantity",
      headerName: "Litros",
      width: 90,
      valueFormatter: (value: unknown) => Number(value ?? 0).toFixed(2),
    },
    {
      field: "TotalCost",
      headerName: "Costo",
      width: 110,
      valueFormatter: (value: unknown) => formatCurrency(Number(value ?? 0)),
    },
    {
      field: "OdometerReading",
      headerName: "Kilometraje",
      width: 110,
      valueFormatter: (value: unknown) => Number(value ?? 0).toLocaleString("es") + " km",
    },
    { field: "StationName", headerName: "Estacion", flex: 1, minWidth: 130 },
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
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Registrar Carga
        </Button>
      </Box>

      {/* Filters */}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={6} md={3}>
          <DatePicker
            label="Desde"
            value={filter.fechaDesde ? dayjs(filter.fechaDesde) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaDesde: v ? v.format('YYYY-MM-DD') : undefined }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <DatePicker
            label="Hasta"
            value={filter.fechaHasta ? dayjs(filter.fechaHasta) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaHasta: v ? v.format('YYYY-MM-DD') : undefined }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Grid>
      </Grid>

      {/* DataGrid */}
      <ZenttoDataGrid
        gridId="flota-combustible-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.FuelLogId ?? row.Id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        enableHeaderFilters
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['LicensePlate', 'FuelDate']}
        smExtraFields={['TotalCost', 'Quantity']}
      />

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
