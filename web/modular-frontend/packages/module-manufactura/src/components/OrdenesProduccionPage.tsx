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
  Grid,
  IconButton,
  MenuItem,
  Stack,
  Tab,
  Tabs,
  TextField,
  Toolbar,
  Typography,
  Tooltip,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
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
import OrdenDetalleDialog from "./OrdenDetalleDialog";
import MaterialConsumptionPanel from "./MaterialConsumptionPanel";
import OutputReportPanel from "./OutputReportPanel";
import RoutingPage from "./RoutingPage";

/* ─── Tab Panel helper ────────────────────────────────────── */

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ pt: 1 }}>{children}</Box> : null;
}

/* ─── Detail Panel with Tabs ──────────────────────────────── */

function OrdenDetailPanel({ row }: { row: Record<string, unknown> }) {
  const [tabIndex, setTabIndex] = useState(0);
  const workOrderId = Number(row.WorkOrderId ?? row.Id ?? 0);
  const bomId = Number(row.BOMId ?? 0);
  const status = String(row.Status ?? "DRAFT");

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
    <Box sx={{ px: 2, py: 1 }}>
      {/* Info summary */}
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3, alignItems: 'center', mb: 1 }}>
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

      {/* Tabs */}
      <Tabs
        value={tabIndex}
        onChange={(_, v) => setTabIndex(v)}
        variant="scrollable"
        scrollButtons="auto"
        allowScrollButtonsMobile
        sx={{ borderBottom: 1, borderColor: 'divider', minHeight: 36 }}
      >
        <Tab label="Detalle" sx={{ minHeight: 36, py: 0.5 }} />
        <Tab label="Consumo de Materiales" sx={{ minHeight: 36, py: 0.5 }} />
        <Tab label="Reporte de Salida" sx={{ minHeight: 36, py: 0.5 }} />
        {bomId > 0 && <Tab label="Routing" sx={{ minHeight: 36, py: 0.5 }} />}
      </Tabs>

      <TabPanel value={tabIndex} index={0}>
        <Box sx={{ py: 1 }}>
          <Grid container spacing={2}>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', display: 'block' }}>Estado</Typography>
              <Chip label={status} size="small" color={
                status === 'COMPLETED' ? 'success' : status === 'IN_PROGRESS' ? 'warning' : status === 'CANCELLED' ? 'error' : 'default'
              } sx={{ mt: 0.25 }} />
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', display: 'block' }}>Producida</Typography>
              <Typography variant="body2" fontWeight={500}>{Number(row.ProducedQuantity ?? 0).toLocaleString('es')} uds</Typography>
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', display: 'block' }}>Almacen</Typography>
              <Typography variant="body2" fontWeight={500}>{String(row.WarehouseName ?? row.WarehouseId ?? '-')}</Typography>
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'uppercase', display: 'block' }}>Notas</Typography>
              <Typography variant="body2" fontWeight={500}>{String(row.Notes ?? '-')}</Typography>
            </Grid>
          </Grid>
        </Box>
      </TabPanel>

      <TabPanel value={tabIndex} index={1}>
        {workOrderId > 0 && <MaterialConsumptionPanel workOrderId={workOrderId} />}
      </TabPanel>

      <TabPanel value={tabIndex} index={2}>
        {workOrderId > 0 && <OutputReportPanel workOrderId={workOrderId} />}
      </TabPanel>

      {bomId > 0 && (
        <TabPanel value={tabIndex} index={3}>
          <RoutingPage bomId={bomId} />
        </TabPanel>
      )}
    </Box>
  );
}

/* ─── Status Maps ──────────────────────────────────────────── */

const statusLabels: Record<string, string> = {
  DRAFT: "Borrador",
  IN_PROGRESS: "En Proceso",
  COMPLETED: "Completada",
  CANCELLED: "Cancelada",
};

/* ─── Filter Definitions ──────────────────────────────────── */

const ORDENES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "IN_PROGRESS", label: "En Proceso" },
      { value: "COMPLETED", label: "Completada" },
      { value: "CANCELLED", label: "Cancelada" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
  {
    field: "prioridad", label: "Prioridad", type: "select",
    options: [
      { value: "HIGH", label: "Alta" },
      { value: "MEDIUM", label: "Media" },
      { value: "LOW", label: "Baja" },
    ],
  },
];

/* ─── Main Component ──────────────────────────────────────── */

export default function OrdenesProduccionPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<WorkOrderFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [detailOrderId, setDetailOrderId] = useState<number | null>(null);

  // Form state
  const [bomId, setBomId] = useState("");
  const [productId, setProductId] = useState("");
  const [plannedQuantity, setPlannedQuantity] = useState("");
  const [plannedStart, setPlannedStart] = useState("");
  const [plannedEnd, setPlannedEnd] = useState("");
  const [priority, setPriority] = useState("MEDIUM");
  const [notes, setNotes] = useState("");

  const handleFilterChange = (vals: Record<string, string>) => {
    setFilterValues(vals);
    setFilter((f) => ({
      ...f,
      status: vals.estado || undefined,
      priority: vals.prioridad || undefined,
      fechaDesde: vals.from || undefined,
      fechaHasta: vals.to || undefined,
    }));
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const { data, isLoading } = useWorkOrdersList({
    ...filter,
    search: search || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createOrder = useCreateWorkOrder();
  const startOrder = useStartWorkOrder();
  const completeOrder = useCompleteWorkOrder();
  const cancelOrder = useCancelWorkOrder();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "WorkOrderNumber", headerName: "N. Orden", flex: 0.8, minWidth: 120 },
    { field: "ProductName", headerName: "Producto", flex: 1.5, minWidth: 180 },
    { field: "BOMCode", headerName: "BOM", flex: 0.8, minWidth: 100 },
    {
      field: "PlannedQuantity",
      headerName: "Cantidad",
      width: 100,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
      statusColors: {
        DRAFT: "default",
        IN_PROGRESS: "warning",
        COMPLETED: "success",
        CANCELLED: "error",
      },
    },
    {
      field: "Priority",
      headerName: "Prioridad",
      width: 100,
      statusColors: {
        HIGH: "error",
        MEDIUM: "warning",
        LOW: "info",
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
                  onClick={(e) => { e.stopPropagation(); id && startOrder.mutate(id); }}
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
                  onClick={(e) => { e.stopPropagation(); id && completeOrder.mutate(id); }}
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
                  onClick={(e) => { e.stopPropagation(); id && cancelOrder.mutate(id); }}
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
      <Box
        sx={{
          display: "flex",
          flexDirection: { xs: "column", sm: "row" },
          justifyContent: "space-between",
          alignItems: { xs: "stretch", sm: "center" },
          gap: 2,
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={600}>
          Ordenes de Produccion
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => { resetForm(); setDialogOpen(true); }}
          fullWidth={isMobile}
        >
          Nueva Orden
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={ORDENES_FILTERS}
        values={filterValues}
        onChange={handleFilterChange}
        searchPlaceholder="Buscar ordenes..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid con master-detail */}
      <ZenttoDataGrid
        gridId="manufactura-ordenes-produccion-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.WorkOrderId ?? row.Id ?? row.WorkOrderNumber ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        enableHeaderFilters
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        enableClipboard
        enableGrouping
        onRowClick={(params) => {
          const id = Number(params.row.WorkOrderId ?? params.row.Id);
          if (id) setDetailOrderId(id);
        }}
        sx={{ bgcolor: "background.paper", borderRadius: 2, "& .MuiDataGrid-row": { cursor: "pointer" } }}
        mobileVisibleFields={["WorkOrderNumber", "Status"]}
        smExtraFields={["ProductName", "PlannedStart"]}
        getDetailContent={(row: any) => <OrdenDetailPanel row={row} />}
        detailPanelHeight="auto"
      />

      {/* Dialog: Detalle de Orden */}
      <OrdenDetalleDialog
        open={detailOrderId !== null}
        onClose={() => setDetailOrderId(null)}
        workOrderId={detailOrderId}
      />

      {/* Dialog: Crear Orden */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        fullScreen={isMobile}
        maxWidth={isMobile ? undefined : "sm"}
        fullWidth
      >
        {isMobile ? (
          <AppBar sx={{ position: "relative" }}>
            <Toolbar>
              <IconButton edge="start" color="inherit" onClick={() => setDialogOpen(false)}>
                <CloseIcon />
              </IconButton>
              <Typography sx={{ ml: 2, flex: 1 }} variant="h6">
                Nueva Orden de Produccion
              </Typography>
              <Button
                color="inherit"
                onClick={handleSubmit}
                disabled={
                  createOrder.isPending || !bomId || !productId || !plannedQuantity || !plannedStart || !plannedEnd
                }
              >
                {createOrder.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>Nueva Orden de Produccion</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="BOM (ID)"
                value={bomId}
                onChange={(e) => setBomId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Producto (ID)"
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Cantidad Planificada"
                value={plannedQuantity}
                onChange={(e) => setPlannedQuantity(e.target.value)}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                select
                label="Prioridad"
                value={priority}
                onChange={(e) => setPriority(e.target.value)}
                fullWidth
              >
                <MenuItem value="LOW">Baja</MenuItem>
                <MenuItem value="MEDIUM">Media</MenuItem>
                <MenuItem value="HIGH">Alta</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6}>
              <DatePicker
                label="Fecha Inicio"
                value={plannedStart ? dayjs(plannedStart) : null}
                onChange={(v) => setPlannedStart(v ? v.format('YYYY-MM-DD') : '')}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <DatePicker
                label="Fecha Fin"
                value={plannedEnd ? dayjs(plannedEnd) : null}
                onChange={(v) => setPlannedEnd(v ? v.format('YYYY-MM-DD') : '')}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                label="Notas"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                fullWidth
                multiline
                rows={2}
              />
            </Grid>
          </Grid>
        </DialogContent>
        {!isMobile && (
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
        )}
      </Dialog>
    </Box>
  );
}
