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
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useFlotaGridRegistration } from "./zenttoGridPersistence";
import {
  useMaintenanceOrdersList,
  useCreateMaintenanceOrder,
  useCompleteMaintenanceOrder,
  useCancelMaintenanceOrder,
  type MaintenanceFilter,
} from "../hooks/useFlota";
import type { ColumnDef } from "@zentto/datagrid-core";


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

const GRID_ID = "module-flota:mantenimiento:list";

export default function MantenimientoPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

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
  const gridRef = useRef<any>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { gridReady, registered } = useFlotaGridRegistration(layoutReady);

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

  const columns: ColumnDef[] = [
    { field: "OrderNumber", header: "N. Orden", flex: 0.8, minWidth: 110 },
    { field: "LicensePlate", header: "Placa Vehiculo", flex: 1, minWidth: 110 },
    { field: "MaintenanceType", header: "Tipo", width: 120 },
    { field: "Description", header: "Descripcion", flex: 1.5, minWidth: 160 },
    {
      field: "ScheduledDate",
      header: "Fecha Programada",
      flex: 1,
      minWidth: 130,
      renderCell: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "Status",
      header: "Estado",
      width: 130,
      statusColors: {
        SCHEDULED: "info",
        IN_PROGRESS: "warning",
        COMPLETED: "success",
        CANCELLED: "error",
      },
    },
    {
      field: "EstimatedCost",
      header: "Costo Est.",
      width: 110,
      renderCell: (value: unknown) => formatCurrency(Number(value ?? 0)),
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
        { icon: "delete", label: "Cancelar", action: "delete", color: "#dc2626" },
      ],
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
      if (action === "edit") {
        setSelectedRow(row);
        setActualCost(String(row.EstimatedCost ?? ""));
        setCompletedDate("");
        setCompleteOpen(true);
      }
      if (action === "delete") {
        const id = Number(row.MaintenanceOrderId ?? row.Id);
        if (id) cancelOrder.mutate(id);
      }
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
          Ordenes de Mantenimiento
        </Typography>
      </Box>

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        export-filename="flota-mantenimiento-list"
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
        create-label="Nueva Orden"
      ></zentto-grid>

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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
