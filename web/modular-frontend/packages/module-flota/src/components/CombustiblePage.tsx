"use client";

import React, { useState } from "react";
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import {
  useFuelLogsList,
  useCreateFuelLog,
  type FuelFilter,
} from "../hooks/useFlota";

export default function CombustiblePage() {
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

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Control de Combustible
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setDialogOpen(true)}>
          Registrar Carga
        </Button>
      </Box>

      {/* Filters */}
      <FormGrid spacing={2} sx={{ mb: 2 }}>
        <FormField xs={12} sm={6} md={3}>
          <DatePicker
            label="Desde"
            value={filter.fechaDesde ? dayjs(filter.fechaDesde) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaDesde: v ? v.format('YYYY-MM-DD') : undefined }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </FormField>
        <FormField xs={12} sm={6} md={3}>
          <DatePicker
            label="Hasta"
            value={filter.fechaHasta ? dayjs(filter.fechaHasta) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaHasta: v ? v.format('YYYY-MM-DD') : undefined }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </FormField>
      </FormGrid>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.FuelLogId ?? row.Id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
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
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Registrar Carga de Combustible</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} fullWidth required />
            <DatePicker label="Fecha" value={logDate ? dayjs(logDate) : null} onChange={(v) => setLogDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            <TextField label="Kilometraje" type="number" value={mileage} onChange={(e) => setMileage(e.target.value)} fullWidth required />
            <TextField label="Tipo Combustible" value={fuelType} onChange={(e) => setFuelType(e.target.value)} fullWidth required />
            <FormGrid spacing={2}>
              <FormField xs={12} sm={4}>
                <TextField label="Litros" type="number" value={liters} onChange={(e) => setLiters(e.target.value)} fullWidth required />
              </FormField>
              <FormField xs={12} sm={4}>
                <TextField label="Precio/Litro" type="number" value={pricePerLiter} onChange={(e) => setPricePerLiter(e.target.value)} fullWidth required />
              </FormField>
              <FormField xs={12} sm={4}>
                <TextField label="Costo Total" type="number" value={totalCost} onChange={(e) => setTotalCost(e.target.value)} fullWidth required />
              </FormField>
            </FormGrid>
            <TextField label="Estacion" value={stationName} onChange={(e) => setStationName(e.target.value)} fullWidth />
            <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={createFuelLog.isPending || !vehicleId || !logDate || !fuelType || !liters || !totalCost}
          >
            {createFuelLog.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
