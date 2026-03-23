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
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import {
  useWorkOrdersList,
  useCreateWorkOrder,
  useStartWorkOrder,
  useCompleteWorkOrder,
  useCancelWorkOrder,
  type WorkOrderFilter,
} from "../hooks/useManufactura";

function OrdenDetailPanel({ row }: { row: Record<string, unknown> }) {
  const priorityColor: Record<string, 'error' | 'warning' | 'success'> = {
    HIGH: 'error', MEDIUM: 'warning', LOW: 'success',
  };

  const fields = [
    { label: 'Producto', value: row.ProductName },
    { label: 'BOM', value: row.BOMCode },
    { label: 'Cantidad planificada', value: row.PlannedQuantity != null ? `${row.PlannedQuantity} uds` : null },
    { label: 'Inicio planificado', value: row.PlannedStart ? String(row.PlannedStart).slice(0, 10) : null },
    { label: 'Fin planificado', value: row.PlannedEnd ? String(row.PlannedEnd).slice(0, 10) : null },
  ].filter(f => f.value != null && f.value !== '');

  return (
    <Box sx={{ px: 3, py: 2, display: 'flex', flexWrap: 'wrap', gap: 3, alignItems: 'center' }}>
      {fields.map(f => (
        <Box key={f.label} sx={{ minWidth: 130 }}>
          <Typography variant="caption" color="text.secondary"
            sx={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block' }}>
            {f.label}
          </Typography>
          <Typography variant="body2" fontWeight={500} sx={{ mt: 0.25 }}>
            {String(f.value)}
          </Typography>
        </Box>
      ))}
      <Box>
        <Typography variant="caption" color="text.secondary"
          sx={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.06em', display: 'block' }}>
          Prioridad
        </Typography>
        <Chip
          size="small"
          label={String(row.Priority ?? '')}
          color={priorityColor[String(row.Priority ?? '')] ?? 'default'}
          sx={{ mt: 0.25 }}
        />
      </Box>
    </Box>
  );
}

const statusColors: Record<string, "default" | "info" | "success" | "error" | "warning"> = {
  DRAFT: "default",
  IN_PROGRESS: "info",
  COMPLETED: "success",
  CANCELLED: "error",
};

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  IN_PROGRESS: "En Proceso",
  COMPLETED: "Completada",
  CANCELLED: "Cancelada",
};

export default function OrdenesProduccionPage() {
  const [filter, setFilter] = useState<WorkOrderFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);

  // Form state
  const [bomId, setBomId] = useState("");
  const [productId, setProductId] = useState("");
  const [plannedQuantity, setPlannedQuantity] = useState("");
  const [plannedStart, setPlannedStart] = useState("");
  const [plannedEnd, setPlannedEnd] = useState("");
  const [priority, setPriority] = useState("MEDIUM");
  const [notes, setNotes] = useState("");

  const { data, isLoading } = useWorkOrdersList({
    ...filter,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createOrder = useCreateWorkOrder();
  const startOrder = useStartWorkOrder();
  const completeOrder = useCompleteWorkOrder();
  const cancelOrder = useCancelWorkOrder();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "WorkOrderNumber", headerName: "N. Orden", flex: 0.8, minWidth: 120 },
    { field: "ProductName", headerName: "Producto", flex: 1.5, minWidth: 180 },
    { field: "BOMCode", headerName: "BOM", flex: 0.8, minWidth: 100 },
    {
      field: "PlannedQuantity",
      headerName: "Cantidad",
      width: 100,
      type: "number",
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
      renderCell: (params) => {
        const status = String(params.value ?? "DRAFT");
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
      field: "Priority",
      headerName: "Prioridad",
      width: 100,
      renderCell: (params) => {
        const p = String(params.value ?? "MEDIUM");
        const colors: Record<string, "default" | "error" | "warning" | "info"> = {
          HIGH: "error",
          MEDIUM: "warning",
          LOW: "info",
        };
        return <Chip label={p} size="small" color={colors[p] ?? "default"} variant="outlined" />;
      },
    },
    {
      field: "PlannedStart",
      headerName: "Inicio",
      width: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "PlannedEnd",
      headerName: "Fin",
      width: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 140,
      sortable: false,
      filterable: false,
      renderCell: (params) => {
        const status = String(params.row.Status ?? "");
        const id = Number(params.row.WorkOrderId ?? params.row.Id);
        return (
          <Stack direction="row" spacing={0.5}>
            {status === "DRAFT" && (
              <Tooltip title="Iniciar orden">
                <IconButton
                  size="small"
                  color="info"
                  onClick={() => id && startOrder.mutate(id)}
                >
                  <PlayArrowIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            {status === "IN_PROGRESS" && (
              <Tooltip title="Completar orden">
                <IconButton
                  size="small"
                  color="success"
                  onClick={() => id && completeOrder.mutate(id)}
                >
                  <CheckCircleIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
            {(status === "DRAFT" || status === "IN_PROGRESS") && (
              <Tooltip title="Cancelar orden">
                <IconButton
                  size="small"
                  color="error"
                  onClick={() => id && cancelOrder.mutate(id)}
                >
                  <CancelIcon fontSize="small" />
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
    setBomId("");
    setProductId("");
    setPlannedQuantity("");
    setPlannedStart("");
    setPlannedEnd("");
    setPriority("MEDIUM");
    setNotes("");
  };

  const handleSubmit = () => {
    createOrder.mutate(
      {
        bomId: Number(bomId),
        productId: Number(productId),
        plannedQuantity: Number(plannedQuantity),
        plannedStart,
        plannedEnd,
        priority,
        notes: notes || null,
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
          Ordenes de Produccion
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
          <MenuItem value="DRAFT">Borrador</MenuItem>
          <MenuItem value="IN_PROGRESS">En Proceso</MenuItem>
          <MenuItem value="COMPLETED">Completada</MenuItem>
          <MenuItem value="CANCELLED">Cancelada</MenuItem>
        </TextField>
      </Stack>

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.WorkOrderId ?? row.Id ?? row.WorkOrderNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['WorkOrderNumber', 'Status']}
        smExtraFields={['ProductName', 'PlannedStart']}
        getDetailContent={(row: any) => <OrdenDetailPanel row={row} />}
        detailPanelHeight={110}
      />

      {/* Dialog: Crear Orden */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Orden de Produccion</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="BOM (ID)"
              value={bomId}
              onChange={(e) => setBomId(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <TextField
              label="Producto (ID)"
              value={productId}
              onChange={(e) => setProductId(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <TextField
              label="Cantidad Planificada"
              value={plannedQuantity}
              onChange={(e) => setPlannedQuantity(e.target.value)}
              size="small"
              type="number"
              fullWidth
            />
            <DatePicker
              label="Fecha Inicio"
              value={plannedStart ? dayjs(plannedStart) : null}
              onChange={(v) => setPlannedStart(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <DatePicker
              label="Fecha Fin"
              value={plannedEnd ? dayjs(plannedEnd) : null}
              onChange={(v) => setPlannedEnd(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <TextField
              select
              label="Prioridad"
              value={priority}
              onChange={(e) => setPriority(e.target.value)}
              size="small"
              fullWidth
            >
              <MenuItem value="LOW">Baja</MenuItem>
              <MenuItem value="MEDIUM">Media</MenuItem>
              <MenuItem value="HIGH">Alta</MenuItem>
            </TextField>
            <TextField
              label="Notas"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              size="small"
              fullWidth
              multiline
              rows={2}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={
              createOrder.isPending || !bomId || !productId || !plannedQuantity || !plannedStart || !plannedEnd
            }
          >
            {createOrder.isPending ? "Guardando..." : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
