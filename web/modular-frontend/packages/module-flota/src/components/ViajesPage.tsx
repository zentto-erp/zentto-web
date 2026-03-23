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
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import {
  useTripsList,
  useCreateTrip,
  useCompleteTrip,
  type TripFilter,
} from "../hooks/useFlota";

const statusColors: Record<string, "info" | "warning" | "success" | "default"> = {
  PLANNED: "info",
  IN_TRANSIT: "warning",
  COMPLETED: "success",
};

const statusLabels: Record<string, string> = {
  PLANNED: "Planificado",
  IN_TRANSIT: "En Transito",
  COMPLETED: "Completado",
};

export default function ViajesPage() {
  const [filter, setFilter] = useState<TripFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [completeOpen, setCompleteOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);

  // Form state - crear
  const [vehicleId, setVehicleId] = useState("");
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [departureDate, setDepartureDate] = useState("");
  const [startMileage, setStartMileage] = useState("");
  const [notes, setNotes] = useState("");

  // Form state - completar
  const [endMileage, setEndMileage] = useState("");
  const [arrivalDate, setArrivalDate] = useState("");
  const [fuelUsed, setFuelUsed] = useState("");

  const { data, isLoading } = useTripsList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createTrip = useCreateTrip();
  const completeTrip = useCompleteTrip();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "TripNumber", headerName: "N. Viaje", flex: 0.8, minWidth: 100 },
    { field: "VehiclePlate", headerName: "Placa Vehiculo", flex: 0.8, minWidth: 110 },
    { field: "DriverName", headerName: "Conductor", flex: 1, minWidth: 120 },
    { field: "Origin", headerName: "Origen", flex: 1, minWidth: 120 },
    { field: "Destination", headerName: "Destino", flex: 1, minWidth: 120 },
    {
      field: "DepartureDate",
      headerName: "Fecha Salida",
      flex: 0.8,
      minWidth: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "ArrivalDate",
      headerName: "Fecha Llegada",
      flex: 0.8,
      minWidth: 110,
      valueFormatter: (value: unknown) => {
        const v = String(value ?? "");
        return v ? v.slice(0, 10) : "--";
      },
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      renderCell: (params) => {
        const status = String(params.value ?? "PLANNED");
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
    {
      field: "Distance",
      headerName: "Distancia",
      width: 100,
      valueFormatter: (value: unknown) => {
        const n = Number(value ?? 0);
        return n > 0 ? n.toLocaleString("es") + " km" : "--";
      },
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 100,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        return (
          <Stack direction="row" spacing={0.5}>
            <IconButton
              size="small"
              title="Ver detalle"
              onClick={() => {
                setSelectedRow(params.row);
                setDetailOpen(true);
              }}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
            {(status === "PLANNED" || status === "IN_TRANSIT") && (
              <IconButton
                size="small"
                title="Completar"
                color="success"
                onClick={() => {
                  setSelectedRow(params.row);
                  setEndMileage("");
                  setArrivalDate("");
                  setFuelUsed("");
                  setCompleteOpen(true);
                }}
              >
                <CheckCircleIcon fontSize="small" />
              </IconButton>
            )}
          </Stack>
        );
      },
    },
  ];

  const handleStatusFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, status: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const resetForm = () => {
    setVehicleId("");
    setOrigin("");
    setDestination("");
    setDepartureDate("");
    setStartMileage("");
    setNotes("");
  };

  const handleCreate = () => {
    createTrip.mutate(
      {
        vehicleId: Number(vehicleId),
        origin,
        destination,
        departureDate,
        startMileage: Number(startMileage),
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

  const handleComplete = () => {
    const id = Number(selectedRow?.TripId ?? selectedRow?.Id);
    if (!id) return;
    completeTrip.mutate(
      {
        id,
        endMileage: Number(endMileage),
        arrivalDate,
        fuelUsed: fuelUsed ? Number(fuelUsed) : undefined,
      },
      {
        onSuccess: () => {
          setCompleteOpen(false);
          setSelectedRow(null);
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Viajes
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { resetForm(); setDialogOpen(true); }}>
          Nuevo Viaje
        </Button>
      </Box>

      {/* Filter */}
      <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
        <TextField
          select
          label="Estado"
          value={filter.status ?? ""}
          onChange={handleStatusFilter}
          size="small"
          sx={{ minWidth: 160 }}
        >
          <MenuItem value="">Todos</MenuItem>
          <MenuItem value="PLANNED">Planificado</MenuItem>
          <MenuItem value="IN_TRANSIT">En Transito</MenuItem>
          <MenuItem value="COMPLETED">Completado</MenuItem>
        </TextField>
        <TextField
          label="Desde"
          type="date"
          value={filter.fechaDesde ?? ""}
          onChange={(e) => setFilter((f) => ({ ...f, fechaDesde: e.target.value || undefined }))}
          size="small"
          InputLabelProps={{ shrink: true }}
          sx={{ minWidth: 150 }}
        />
        <TextField
          label="Hasta"
          type="date"
          value={filter.fechaHasta ?? ""}
          onChange={(e) => setFilter((f) => ({ ...f, fechaHasta: e.target.value || undefined }))}
          size="small"
          InputLabelProps={{ shrink: true }}
          sx={{ minWidth: 150 }}
        />
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.TripId ?? row.Id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['TripNumber', 'VehiclePlate']}
        smExtraFields={['Status', 'DepartureDate']}
      />

      {/* Dialog: Nuevo Viaje */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Viaje</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} size="small" fullWidth required />
            <Stack direction="row" spacing={2}>
              <TextField label="Origen" value={origin} onChange={(e) => setOrigin(e.target.value)} size="small" fullWidth required />
              <TextField label="Destino" value={destination} onChange={(e) => setDestination(e.target.value)} size="small" fullWidth required />
            </Stack>
            <TextField label="Fecha Salida" type="date" value={departureDate} onChange={(e) => setDepartureDate(e.target.value)} size="small" fullWidth required InputLabelProps={{ shrink: true }} />
            <TextField label="Kilometraje Inicio" type="number" value={startMileage} onChange={(e) => setStartMileage(e.target.value)} size="small" fullWidth required />
            <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} size="small" fullWidth multiline rows={2} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={createTrip.isPending || !vehicleId || !origin || !destination || !departureDate || !startMileage}
          >
            {createTrip.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Completar Viaje */}
      <Dialog open={completeOpen} onClose={() => setCompleteOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Completar Viaje</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Viaje: {String(selectedRow?.TripNumber ?? "")} — {String(selectedRow?.Origin ?? "")} a {String(selectedRow?.Destination ?? "")}
            </Typography>
            <TextField label="Kilometraje Final" type="number" value={endMileage} onChange={(e) => setEndMileage(e.target.value)} size="small" fullWidth required />
            <TextField label="Fecha Llegada" type="date" value={arrivalDate} onChange={(e) => setArrivalDate(e.target.value)} size="small" fullWidth required InputLabelProps={{ shrink: true }} />
            <TextField label="Combustible Usado (L)" type="number" value={fuelUsed} onChange={(e) => setFuelUsed(e.target.value)} size="small" fullWidth />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCompleteOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            color="success"
            onClick={handleComplete}
            disabled={completeTrip.isPending || !endMileage || !arrivalDate}
          >
            {completeTrip.isPending ? "Completando..." : "Completar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Viaje</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>N. Viaje:</strong> {String(selectedRow.TripNumber ?? "")}</Typography>
              <Typography><strong>Vehiculo:</strong> {String(selectedRow.VehiclePlate ?? "")}</Typography>
              <Typography><strong>Conductor:</strong> {String(selectedRow.DriverName ?? "--")}</Typography>
              <Typography><strong>Origen:</strong> {String(selectedRow.Origin ?? "")}</Typography>
              <Typography><strong>Destino:</strong> {String(selectedRow.Destination ?? "")}</Typography>
              <Typography><strong>Fecha Salida:</strong> {String(selectedRow.DepartureDate ?? "").slice(0, 10)}</Typography>
              <Typography><strong>Fecha Llegada:</strong> {String(selectedRow.ArrivalDate ?? "--").slice(0, 10)}</Typography>
              <Typography><strong>Distancia:</strong> {Number(selectedRow.Distance ?? 0) > 0 ? Number(selectedRow.Distance).toLocaleString("es") + " km" : "--"}</Typography>
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
