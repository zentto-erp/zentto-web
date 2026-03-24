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
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency } from "@zentto/shared-api";
import {
  useMaintenanceOrdersList,
  useCreateMaintenanceOrder,
  useCompleteMaintenanceOrder,
  useCancelMaintenanceOrder,
  type MaintenanceFilter,
} from "../hooks/useFlota";

const statusColors: Record<string, "info" | "warning" | "success" | "error" | "default"> = {
  SCHEDULED: "info",
  IN_PROGRESS: "warning",
  COMPLETED: "success",
  CANCELLED: "error",
};

const statusLabels: Record<string, string> = {
  SCHEDULED: "Programado",
  IN_PROGRESS: "En Progreso",
  COMPLETED: "Completado",
  CANCELLED: "Cancelado",
};

const MANTENIMIENTO_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "SCHEDULED", label: "Programado" },
      { value: "IN_PROGRESS", label: "En Progreso" },
      { value: "COMPLETED", label: "Completado" },
      { value: "CANCELLED", label: "Cancelado" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

export default function MantenimientoPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [filter, setFilter] = useState<MaintenanceFilter>({ page: 1, limit: 25 });
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [completeOpen, setCompleteOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<Record<string, unknown> | null>(null);

  // Form state - crear
  const [vehicleId, setVehicleId] = useState("");
  const [maintenanceTypeId, setMaintenanceTypeId] = useState("");
  const [mileageAtService, setMileageAtService] = useState("");
  const [scheduledDate, setScheduledDate] = useState("");
  const [estimatedCost, setEstimatedCost] = useState("");
  const [description, setDescription] = useState("");

  // Form state - completar
  const [actualCost, setActualCost] = useState("");
  const [completedDate, setCompletedDate] = useState("");

  const { data, isLoading } = useMaintenanceOrdersList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createOrder = useCreateMaintenanceOrder();
  const completeOrder = useCompleteMaintenanceOrder();
  const cancelOrder = useCancelMaintenanceOrder();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "OrderNumber", headerName: "N. Orden", flex: 0.8, minWidth: 110 },
    { field: "LicensePlate", headerName: "Placa Vehiculo", flex: 1, minWidth: 110 },
    { field: "MaintenanceType", headerName: "Tipo", width: 120 },
    { field: "Description", headerName: "Descripcion", flex: 1.5, minWidth: 160 },
    {
      field: "ScheduledDate",
      headerName: "Fecha Programada",
      flex: 1,
      minWidth: 130,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
      renderCell: (params) => {
        const status = String(params.value ?? "SCHEDULED");
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
      field: "EstimatedCost",
      headerName: "Costo Est.",
      width: 110,
      valueFormatter: (value: unknown) => formatCurrency(Number(value ?? 0)),
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 140,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.MaintenanceOrderId ?? params.row.Id);
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
            {(status === "SCHEDULED" || status === "IN_PROGRESS") && (
              <>
                <Tooltip title="Completar">
                  <IconButton
                    size="small"
                    color="success"
                    onClick={() => {
                      setSelectedRow(params.row);
                      setActualCost(String(params.row.EstimatedCost ?? ""));
                      setCompletedDate("");
                      setCompleteOpen(true);
                    }}
                  >
                    <CheckCircleIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Cancelar">
                  <IconButton
                    size="small"
                    color="error"
                    onClick={() => {
                      if (id) cancelOrder.mutate(id);
                    }}
                  >
                    <CancelIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </>
            )}
          </Stack>
        );
      },
    },
  ];

  const resetForm = () => {
    setVehicleId("");
    setMaintenanceTypeId("");
    setMileageAtService("");
    setScheduledDate("");
    setEstimatedCost("");
    setDescription("");
  };

  const handleCreate = () => {
    createOrder.mutate(
      {
        vehicleId: Number(vehicleId),
        maintenanceTypeId: Number(maintenanceTypeId),
        mileageAtService: Number(mileageAtService),
        scheduledDate,
        estimatedCost: Number(estimatedCost),
        description,
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
    const id = Number(selectedRow?.MaintenanceOrderId ?? selectedRow?.Id);
    if (!id) return;
    completeOrder.mutate(
      { id, actualCost: Number(actualCost), completedDate },
      {
        onSuccess: () => {
          setCompleteOpen(false);
          setSelectedRow(null);
        },
      }
    );
  };

  const canCreate = !createOrder.isPending && !!vehicleId && !!maintenanceTypeId && !!scheduledDate && !!description;
  const canComplete = !completeOrder.isPending && !!actualCost && !!completedDate;

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
          Ordenes de Mantenimiento
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { resetForm(); setDialogOpen(true); }}>
          Nueva Orden
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={MANTENIMIENTO_FILTERS}
        values={filterValues}
        onChange={(vals) => {
          setFilterValues(vals);
          setFilter((f) => ({
            ...f,
            status: vals.estado || undefined,
            fechaDesde: vals.from || undefined,
            fechaHasta: vals.to || undefined,
          }));
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar ordenes de mantenimiento..."
        searchValue=""
        onSearchChange={() => {}}
      />

      {/* DataGrid */}
      <ZenttoDataGrid
        gridId="flota-mantenimiento-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.MaintenanceOrderId ?? row.Id ?? Math.random()}
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
        mobileVisibleFields={['OrderNumber', 'LicensePlate']}
        smExtraFields={['Status', 'ScheduledDate']}
      />

      {/* Dialog: Nueva Orden */}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Nueva Orden de Mantenimiento</Typography>
              <Button autoFocus color="inherit" onClick={handleCreate} disabled={!canCreate}>
                {createOrder.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Nueva Orden de Mantenimiento</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Tipo Mantenimiento (ID)" type="number" value={maintenanceTypeId} onChange={(e) => setMaintenanceTypeId(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Kilometraje al Servicio" type="number" value={mileageAtService} onChange={(e) => setMileageAtService(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12} sm={6}>
              <DatePicker label="Fecha Programada" value={scheduledDate ? dayjs(scheduledDate) : null} onChange={(v) => setScheduledDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField label="Costo Estimado" type="number" value={estimatedCost} onChange={(e) => setEstimatedCost(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12}>
              <TextField label="Descripcion" value={description} onChange={(e) => setDescription(e.target.value)} fullWidth required multiline rows={3} />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
            <Button variant="contained" onClick={handleCreate} disabled={!canCreate}>
              {createOrder.isPending ? "Guardando..." : "Guardar"}
            </Button>
          </DialogActions>
        )}
      </Dialog>

      {/* Dialog: Completar Orden */}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Completar Mantenimiento</Typography>
              <Button autoFocus color="inherit" onClick={handleComplete} disabled={!canComplete}>
                {completeOrder.isPending ? "Completando..." : "Completar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Completar Mantenimiento</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <Typography variant="body2" color="text.secondary">
                Orden: {String(selectedRow?.OrderNumber ?? "")}
              </Typography>
            </Grid>
            <Grid item xs={12}>
              <TextField label="Costo Real" type="number" value={actualCost} onChange={(e) => setActualCost(e.target.value)} fullWidth required />
            </Grid>
            <Grid item xs={12}>
              <DatePicker label="Fecha Completado" value={completedDate ? dayjs(completedDate) : null} onChange={(v) => setCompletedDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
          <DialogActions>
            <Button onClick={() => setCompleteOpen(false)}>Cancelar</Button>
            <Button variant="contained" color="success" onClick={handleComplete} disabled={!canComplete}>
              {completeOrder.isPending ? "Completando..." : "Completar"}
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
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">Detalle de Mantenimiento</Typography>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Detalle de Mantenimiento</DialogTitle>
        )}
        <DialogContent>
          {selectedRow && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">N. Orden</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.OrderNumber ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Vehiculo</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.LicensePlate ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Tipo</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.MaintenanceType ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Fecha Programada</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.ScheduledDate ?? "").slice(0, 10)}</Typography>
              </Grid>
              <Grid item xs={12}>
                <Typography variant="caption" color="text.secondary">Descripcion</Typography>
                <Typography variant="body1" fontWeight={500}>{String(selectedRow.Description ?? "")}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Costo Estimado</Typography>
                <Typography variant="body1" fontWeight={500}>{formatCurrency(Number(selectedRow.EstimatedCost ?? 0))}</Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="caption" color="text.secondary">Costo Real</Typography>
                <Typography variant="body1" fontWeight={500}>{formatCurrency(Number(selectedRow.ActualCost ?? 0))}</Typography>
              </Grid>
              <Grid item xs={12}>
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
