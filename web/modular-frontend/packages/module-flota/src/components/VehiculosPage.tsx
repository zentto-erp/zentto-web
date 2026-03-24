"use client";

import React, { useState } from "react";
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  MenuItem,
  Stack,
  TextField,
  Typography,
  Tooltip,
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import VisibilityIcon from "@mui/icons-material/Visibility";
import {
  useVehiclesList,
  useCreateVehicle,
  useUpdateVehicle,
  type VehicleFilter,
} from "../hooks/useFlota";

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

export default function VehiculosPage() {
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

  const { data, isLoading } = useVehiclesList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createVehicle = useCreateVehicle();
  const updateVehicle = useUpdateVehicle();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "LicensePlate", headerName: "Placa", flex: 0.8, minWidth: 100 },
    { field: "Brand", headerName: "Marca", flex: 1, minWidth: 100 },
    { field: "Model", headerName: "Modelo", flex: 1, minWidth: 100 },
    { field: "Year", headerName: "Ano", width: 70 },
    {
      field: "VehicleType",
      headerName: "Tipo",
      width: 120,
      renderCell: (params) => (
        <Chip label={String(params.value ?? "")} size="small" variant="outlined" />
      ),
    },
    {
      field: "Status",
      headerName: "Estado",
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
    { field: "DefaultDriverId", headerName: "Conductor", flex: 1, minWidth: 120 },
    {
      field: "CurrentOdometer",
      headerName: "Kilometraje",
      width: 110,
      valueFormatter: (value: unknown) => {
        const n = Number(value ?? 0);
        return n.toLocaleString("es") + " km";
      },
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 100,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ver detalle">
            <IconButton
              size="small"
              onClick={() => {
                setSelectedRow(params.row);
                setDetailOpen(true);
              }}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="Editar vehículo">
            <IconButton
              size="small"
              onClick={() => openEditDialog(params.row)}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
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

  const handleStatusFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, status: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const handleSearchFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, search: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const isPending = createVehicle.isPending || updateVehicle.isPending;

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Vehiculos
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            resetForm();
            setDialogOpen(true);
          }}
        >
          Nuevo Vehiculo
        </Button>
      </Box>

      {/* Filters */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          select
          label="Estado"
          value={filter.status ?? ""}
          onChange={handleStatusFilter}
         
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">Todos</MenuItem>
          <MenuItem value="ACTIVE">Activo</MenuItem>
          <MenuItem value="MAINTENANCE">Mantenimiento</MenuItem>
          <MenuItem value="INACTIVE">Inactivo</MenuItem>
        </TextField>
        <TextField
          label="Buscar"
          value={filter.search ?? ""}
          onChange={handleSearchFilter}
         
          placeholder="Placa, marca, modelo..."
          sx={{ minWidth: 220 }}
        />
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.VehicleId ?? row.Id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['LicensePlate', 'Brand']}
        smExtraFields={['VehicleType', 'Status']}
        getDetailContent={(row: any) => <VehiculoDetailPanel row={row} />}
        detailPanelHeight={120}
      />

      {/* Dialog: Crear/Editar Vehiculo */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editMode ? "Editar Vehiculo" : "Nuevo Vehiculo"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Placa" value={vehiclePlate} onChange={(e) => setLicensePlate(e.target.value)} fullWidth required />
            <Stack direction="row" spacing={2}>
              <TextField label="Marca" value={brand} onChange={(e) => setBrand(e.target.value)} fullWidth required />
              <TextField label="Modelo" value={model} onChange={(e) => setModel(e.target.value)} fullWidth required />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="Ano" type="number" value={year} onChange={(e) => setYear(e.target.value)} fullWidth required />
              <TextField label="Color" value={color} onChange={(e) => setColor(e.target.value)} fullWidth />
            </Stack>
            <Stack direction="row" spacing={2}>
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
            </Stack>
            <TextField label="Kilometraje Actual" type="number" value={currentMileage} onChange={(e) => setCurrentOdometer(e.target.value)} fullWidth required />
            <TextField label="VIN" value={vin} onChange={(e) => setVin(e.target.value)} fullWidth />
            <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} />
          </Stack>
        </DialogContent>
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
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Vehiculo</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>Placa:</strong> {String(selectedRow.LicensePlate ?? "")}</Typography>
              <Typography><strong>Marca:</strong> {String(selectedRow.Brand ?? "")}</Typography>
              <Typography><strong>Modelo:</strong> {String(selectedRow.Model ?? "")}</Typography>
              <Typography><strong>Ano:</strong> {String(selectedRow.Year ?? "")}</Typography>
              <Typography><strong>Tipo:</strong> {String(selectedRow.VehicleType ?? "")}</Typography>
              <Typography><strong>Combustible:</strong> {String(selectedRow.FuelType ?? "")}</Typography>
              <Typography><strong>Kilometraje:</strong> {Number(selectedRow.CurrentOdometer ?? 0).toLocaleString("es")} km</Typography>
              <Typography><strong>Color:</strong> {String(selectedRow.Color ?? "--")}</Typography>
              <Typography><strong>VIN:</strong> {String(selectedRow.VinNumber ?? "--")}</Typography>
              <Typography><strong>Conductor:</strong> {String(selectedRow.DefaultDriverId ?? "--")}</Typography>
              <Typography>
                <strong>Estado:</strong>{" "}
                <Chip
                  label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                  size="small"
                  color={statusColors[String(selectedRow.Status)] ?? "default"}
                  variant="outlined"
                />
              </Typography>
              <Typography><strong>Notas:</strong> {String(selectedRow.Notes ?? "--")}</Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
