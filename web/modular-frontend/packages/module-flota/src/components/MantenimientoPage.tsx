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
import { ZenttoDataGrid, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
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

export default function MantenimientoPage() {
  const [filter, setFilter] = useState<MaintenanceFilter>({ page: 1, limit: 25 });
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

  const columns: GridColDef[] = [
    { field: "OrderNumber", headerName: "N. Orden", flex: 0.8, minWidth: 110 },
    { field: "VehiclePlate", headerName: "Placa Vehiculo", flex: 1, minWidth: 110 },
    { field: "MaintenanceCategory", headerName: "Tipo", width: 120 },
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

  const handleStatusFilter = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilter((f) => ({ ...f, status: e.target.value || undefined }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

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

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Ordenes de Mantenimiento
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => { resetForm(); setDialogOpen(true); }}>
          Nueva Orden
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
          <MenuItem value="SCHEDULED">Programado</MenuItem>
          <MenuItem value="IN_PROGRESS">En Progreso</MenuItem>
          <MenuItem value="COMPLETED">Completado</MenuItem>
          <MenuItem value="CANCELLED">Cancelado</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.MaintenanceOrderId ?? row.Id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['OrderNumber', 'VehiclePlate']}
        smExtraFields={['Status', 'ScheduledDate']}
      />

      {/* Dialog: Nueva Orden */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Orden de Mantenimiento</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Vehiculo (ID)" type="number" value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} size="small" fullWidth required />
            <TextField label="Tipo Mantenimiento (ID)" type="number" value={maintenanceTypeId} onChange={(e) => setMaintenanceTypeId(e.target.value)} size="small" fullWidth required />
            <TextField label="Kilometraje al Servicio" type="number" value={mileageAtService} onChange={(e) => setMileageAtService(e.target.value)} size="small" fullWidth required />
            <DatePicker label="Fecha Programada" value={scheduledDate ? dayjs(scheduledDate) : null} onChange={(v) => setScheduledDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
            <TextField label="Costo Estimado" type="number" value={estimatedCost} onChange={(e) => setEstimatedCost(e.target.value)} size="small" fullWidth required />
            <TextField label="Descripcion" value={description} onChange={(e) => setDescription(e.target.value)} size="small" fullWidth required multiline rows={3} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={createOrder.isPending || !vehicleId || !maintenanceTypeId || !scheduledDate || !description}
          >
            {createOrder.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Completar Orden */}
      <Dialog open={completeOpen} onClose={() => setCompleteOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Completar Mantenimiento</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Orden: {String(selectedRow?.OrderNumber ?? "")}
            </Typography>
            <TextField label="Costo Real" type="number" value={actualCost} onChange={(e) => setActualCost(e.target.value)} size="small" fullWidth required />
            <DatePicker label="Fecha Completado" value={completedDate ? dayjs(completedDate) : null} onChange={(v) => setCompletedDate(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true, required: true } }} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCompleteOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            color="success"
            onClick={handleComplete}
            disabled={completeOrder.isPending || !actualCost || !completedDate}
          >
            {completeOrder.isPending ? "Completando..." : "Completar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Detalle */}
      <Dialog open={detailOpen} onClose={() => setDetailOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle de Mantenimiento</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1} sx={{ mt: 1 }}>
              <Typography><strong>N. Orden:</strong> {String(selectedRow.OrderNumber ?? "")}</Typography>
              <Typography><strong>Vehiculo:</strong> {String(selectedRow.VehiclePlate ?? "")}</Typography>
              <Typography><strong>Tipo:</strong> {String(selectedRow.MaintenanceCategory ?? "")}</Typography>
              <Typography><strong>Descripcion:</strong> {String(selectedRow.Description ?? "")}</Typography>
              <Typography><strong>Fecha Programada:</strong> {String(selectedRow.ScheduledDate ?? "").slice(0, 10)}</Typography>
              <Typography><strong>Costo Estimado:</strong> {formatCurrency(Number(selectedRow.EstimatedCost ?? 0))}</Typography>
              <Typography><strong>Costo Real:</strong> {formatCurrency(Number(selectedRow.ActualCost ?? 0))}</Typography>
              <Typography>
                <strong>Estado:</strong>{" "}
                <Chip
                  label={statusLabels[String(selectedRow.Status)] ?? String(selectedRow.Status)}
                  size="small"
                  color={statusColors[String(selectedRow.Status)] ?? "default"}
                  variant="outlined"
                />
              </Typography>
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
