"use client";

import React, { useState } from "react";
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
  Stack,
  TextField,
  Toolbar,
  Typography,
  Tooltip,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CloseIcon from "@mui/icons-material/Close";
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
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

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
  const [departureDate, setDepartedAt] = useState("");
  const [startMileage, setStartMileage] = useState("");
  const [notes, setNotes] = useState("");

  // Form state - completar
  const [endMileage, setEndMileage] = useState("");
  const [arrivalDate, setArrivedAt] = useState("");
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

  const columns: ZenttoColDef[] = [
    { field: "TripNumber", headerName: "N. Viaje", flex: 0.8, minWidth: 100 },
    { field: "LicensePlate", headerName: "Placa Vehiculo", flex: 0.8, minWidth: 110 },
    { field: "DriverId", headerName: "Conductor", flex: 1, minWidth: 120 },
    { field: "Origin", headerName: "Origen", flex: 1, minWidth: 120 },
    { field: "Destination", headerName: "Destino", flex: 1, minWidth: 120 },
    {
      field: "DepartedAt",
      headerName: "Fecha Salida",
      flex: 0.8,
      minWidth: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "ArrivedAt",
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
      field: "DistanceKm",
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
            {(status === "PLANNED" || status === "IN_TRANSIT") && (
              <Tooltip title="Completar viaje">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => {
                    setSelectedRow(params.row);
                    setEndMileage("");
                    setArrivedAt("");
                    setFuelUsed("");
                    setCompleteOpen(true);
                  }}
                >
                  <CheckCircleIcon fontSize="small" />
                </IconButton>
              </Tooltip>
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
    setDepartedAt("");
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

  const canCreate = !createTrip.isPending && !!vehicleId && !!origin && !!destination && !!departureDate && !!startMileage;
  const canComplete = !completeTrip.isPending && !!endMileage && !!arrivalDate;

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
          Viajes
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { resetForm(); setDialogOpen(true); }}>
          Nuevo Viaje
        </Button>
      </Box>

      {/* Filter */}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={6} md={3}>
          <TextField
            select
            label="Estado"
            value={filter.status ?? ""}
            onChange={handleStatusFilter}
            fullWidth
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="PLANNED">Planificado</MenuItem>
            <MenuItem value="IN_TRANSIT">En Transito</MenuItem>
            <MenuItem value="COMPLETED">Completado</MenuItem>
          </TextField>
        </Grid>
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
        gridId="flota-viajes-list"
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
        mobileVisibleFields={['TripNumber', 'LicensePlate']}
        smExtraFields={['Status', 'DepartedAt']}
      />

      {/* Dialog: Nuevo Viaje */}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Nuevo Viaje</Typography>
              <Button autoFocus color="inherit" onClick={handleCreate} disabled={!canCreate}>
                {createTrip.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Nuevo Viaje</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <DatePicker label="Fecha Salida" value={departureDate ? dayjs(departureDate) : null} onChange={(v) => setDepartedAt(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Origen" value={origin} onChange={(e) => setOrigin(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Destino" value={destination} onChange={(e) => setDestination(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Kilometraje Inicio" type="number" value={startMileage} onChange={(e) => setStartMileage(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Notas" value={notes} onChange={(e) => setNotes(e.target.value)} fullWidth multiline rows={2} />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
            <Button variant="contained" onClick={handleCreate} disabled={!canCreate}>
              {createTrip.isPending ? "Guardando..." : "Guardar"}
            </Button>
          </DialogActions>
        )}
      </Dialog>

      {/* Dialog: Completar Viaje */}
      <Dialog
        open={completeOpen}
        onClose={() => setCompleteOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "xs"}
        fullWidth
      >
        {isMobile ? (
          <AppBar sx={{ position: 'relative' }}>
            <Toolbar>
              <IconButton edge="start" color="inherit" onClick={() => setCompleteOpen(false)} aria-label="cerrar">
                <CloseIcon />
              </IconButton>
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Completar Viaje</Typography>
              <Button autoFocus color="inherit" onClick={handleComplete} disabled={!canComplete}>
                {completeTrip.isPending ? "Completando..." : "Completar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Completar Viaje</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <Typography variant="body2" color="text.secondary">
                Viaje: {String(selectedRow?.TripNumber ?? "")} — {String(selectedRow?.Origin ?? "")} a {String(selectedRow?.Destination ?? "")}
              </Typography>
            </Grid>
            <Grid item xs={12}>
              <TextField label="Kilometraje Final" type="number" value={endMileage} onChange={(e) => setEndMileage(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12}>
              <DatePicker label="Fecha Llegada" value={arrivalDate ? dayjs(arrivalDate) : null} onChange={(v) => setArrivedAt(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Combustible Usado (L)" type="number" value={fuelUsed} onChange={(e) => setFuelUsed(e.target.value)} fullWidth />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setCompleteOpen(false)}>Cancelar</Button>
            <Button variant="contained" color="success" onClick={handleComplete} disabled={!canComplete}>
              {completeTrip.isPending ? "Completando..." : "Completar"}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Detalle de Viaje</Typography>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Detalle de Viaje</DialogTitle>
        )}
        <DialogContent>
          {selectedRow && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">N. Viaje</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.TripNumber ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Vehiculo</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.LicensePlate ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Conductor</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.DriverId ?? "--")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Origen</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Origin ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Destino</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Destination ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Fecha Salida</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.DepartedAt ?? "").slice(0, 10)}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Fecha Llegada</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.ArrivedAt ?? "--").slice(0, 10)}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Distancia</Typography>
                <Typography variant="body1" fontWeight={500}>{Number(selectedRow.DistanceKm ?? 0) > 0 ? Number(selectedRow.DistanceKm).toLocaleString("es") + " km" : "--"}</Typography>
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
