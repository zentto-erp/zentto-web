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
  Divider,
  Grid,
  IconButton,
  Stack,
  Tab,
  Tabs,
  TextField,
  Toolbar,
  Typography,
  Alert,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import AddIcon from "@mui/icons-material/Add";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import {
  useWorkOrderDetail,
  useConsumeMaterial,
  useReportOutput,
  useStartWorkOrder,
  useCompleteWorkOrder,
  useCancelWorkOrder,
  type ConsumeMaterialPayload,
  type ReportOutputPayload,
} from "../hooks/useManufactura";

// ── Status helpers ──────────────────────────────────────────────

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

const priorityColors: Record<string, "error" | "warning" | "info" | "default"> = {
  HIGH: "error",
  MEDIUM: "warning",
  LOW: "info",
};

const priorityLabels: Record<string, string> = {
  HIGH: "Alta",
  MEDIUM: "Media",
  LOW: "Baja",
};

// ── Mini dialogs ────────────────────────────────────────────────

interface ConsumeMaterialDialogProps {
  open: boolean;
  onClose: () => void;
  workOrderId: number;
}

function ConsumeMaterialDialog({ open, onClose, workOrderId }: ConsumeMaterialDialogProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [productId, setProductId] = useState("");
  const [quantity, setQuantity] = useState("");
  const [unitCost, setUnitCost] = useState("");
  const [lotNumber, setLotNumber] = useState("");
  const [warehouseId, setWarehouseId] = useState("");
  const [error, setError] = useState("");

  const consumeMaterial = useConsumeMaterial(workOrderId);

  const reset = () => {
    setProductId("");
    setQuantity("");
    setUnitCost("");
    setLotNumber("");
    setWarehouseId("");
    setError("");
  };

  const handleSubmit = () => {
    if (!productId || !quantity) {
      setError("Producto y cantidad son requeridos");
      return;
    }
    const payload: ConsumeMaterialPayload = {
      productId: Number(productId),
      quantity: Number(quantity),
      lotNumber: lotNumber || null,
      warehouseId: warehouseId ? Number(warehouseId) : null,
    };
    consumeMaterial.mutate(payload, {
      onSuccess: (res: any) => {
        if (res?.success === false) {
          setError(res.message || "Error al consumir material");
          return;
        }
        reset();
        onClose();
      },
      onError: (err: any) => setError(String(err?.message ?? err)),
    });
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      fullScreen={isMobile}
      maxWidth={isMobile ? undefined : "xs"}
      fullWidth
    >
      {isMobile ? (
        <AppBar sx={{ position: "relative" }}>
          <Toolbar>
            <IconButton edge="start" color="inherit" onClick={handleClose}>
              <CloseIcon />
            </IconButton>
            <Typography sx={{ ml: 2, flex: 1 }} variant="h6">
              Consumir Material
            </Typography>
            <Button
              color="inherit"
              onClick={handleSubmit}
              disabled={consumeMaterial.isPending || !productId || !quantity}
            >
              {consumeMaterial.isPending ? "Guardando..." : "Consumir"}
            </Button>
          </Toolbar>
        </AppBar>
      ) : (
        <DialogTitle>Consumir Material</DialogTitle>
      )}
      <DialogContent>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          {error && (
            <Grid item xs={12}>
              <Alert severity="error">{error}</Alert>
            </Grid>
          )}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Producto (ID)"
              value={productId}
              onChange={(e) => setProductId(e.target.value)}
              type="number"
              fullWidth
              size="small"
              required
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Cantidad"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              type="number"
              fullWidth
              size="small"
              required
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Costo Unitario"
              value={unitCost}
              onChange={(e) => setUnitCost(e.target.value)}
              type="number"
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Lote (opcional)"
              value={lotNumber}
              onChange={(e) => setLotNumber(e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12}>
            <TextField
              label="Almacen (ID, opcional)"
              value={warehouseId}
              onChange={(e) => setWarehouseId(e.target.value)}
              type="number"
              fullWidth
              size="small"
            />
          </Grid>
        </Grid>
      </DialogContent>
      {!isMobile && (
        <DialogActions>
          <Button onClick={handleClose}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={consumeMaterial.isPending || !productId || !quantity}
          >
            {consumeMaterial.isPending ? "Guardando..." : "Consumir"}
          </Button>
        </DialogActions>
      )}
    </Dialog>
  );
}

interface ReportOutputDialogProps {
  open: boolean;
  onClose: () => void;
  workOrderId: number;
}

function ReportOutputDialog({ open, onClose, workOrderId }: ReportOutputDialogProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [quantity, setQuantity] = useState("");
  const [warehouseId, setWarehouseId] = useState("");
  const [lotNumber, setLotNumber] = useState("");
  const [error, setError] = useState("");

  const reportOutput = useReportOutput(workOrderId);

  const reset = () => {
    setQuantity("");
    setWarehouseId("");
    setLotNumber("");
    setError("");
  };

  const handleSubmit = () => {
    if (!quantity) {
      setError("Cantidad es requerida");
      return;
    }
    const payload: ReportOutputPayload = {
      quantity: Number(quantity),
      lotNumber: lotNumber || null,
      warehouseId: warehouseId ? Number(warehouseId) : null,
    };
    reportOutput.mutate(payload, {
      onSuccess: (res: any) => {
        if (res?.success === false) {
          setError(res.message || "Error al reportar salida");
          return;
        }
        reset();
        onClose();
      },
      onError: (err: any) => setError(String(err?.message ?? err)),
    });
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      fullScreen={isMobile}
      maxWidth={isMobile ? undefined : "xs"}
      fullWidth
    >
      {isMobile ? (
        <AppBar sx={{ position: "relative" }}>
          <Toolbar>
            <IconButton edge="start" color="inherit" onClick={handleClose}>
              <CloseIcon />
            </IconButton>
            <Typography sx={{ ml: 2, flex: 1 }} variant="h6">
              Reportar Salida de Produccion
            </Typography>
            <Button
              color="inherit"
              onClick={handleSubmit}
              disabled={reportOutput.isPending || !quantity}
            >
              {reportOutput.isPending ? "Guardando..." : "Reportar"}
            </Button>
          </Toolbar>
        </AppBar>
      ) : (
        <DialogTitle>Reportar Salida de Produccion</DialogTitle>
      )}
      <DialogContent>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          {error && (
            <Grid item xs={12}>
              <Alert severity="error">{error}</Alert>
            </Grid>
          )}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Cantidad"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
              type="number"
              fullWidth
              size="small"
              required
            />
          </Grid>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Almacen (ID, opcional)"
              value={warehouseId}
              onChange={(e) => setWarehouseId(e.target.value)}
              type="number"
              fullWidth
              size="small"
            />
          </Grid>
          <Grid item xs={12}>
            <TextField
              label="Lote (opcional)"
              value={lotNumber}
              onChange={(e) => setLotNumber(e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
        </Grid>
      </DialogContent>
      {!isMobile && (
        <DialogActions>
          <Button onClick={handleClose}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={reportOutput.isPending || !quantity}
          >
            {reportOutput.isPending ? "Guardando..." : "Reportar"}
          </Button>
        </DialogActions>
      )}
    </Dialog>
  );
}

// ── Tab Panel ───────────────────────────────────────────────────

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ pt: 2 }}>{children}</Box> : null;
}

// ── Main Component ──────────────────────────────────────────────

export interface OrdenDetalleDialogProps {
  open: boolean;
  onClose: () => void;
  workOrderId: number | null;
}

export default function OrdenDetalleDialog({ open, onClose, workOrderId }: OrdenDetalleDialogProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [tabIndex, setTabIndex] = useState(0);
  const [consumeOpen, setConsumeOpen] = useState(false);
  const [outputOpen, setOutputOpen] = useState(false);

  const { data: detail, isLoading } = useWorkOrderDetail(workOrderId ?? undefined);
  const startOrder = useStartWorkOrder();
  const completeOrder = useCompleteWorkOrder();
  const cancelOrder = useCancelWorkOrder();

  if (!workOrderId) return null;

  const order = (detail ?? {}) as Record<string, unknown>;
  const status = String(order.Status ?? "DRAFT");
  const priority = String(order.Priority ?? "MEDIUM");
  const canModify = status === "DRAFT" || status === "IN_PROGRESS";

  // Materials consumed — from detail response (may be embedded or empty)
  const materials = (Array.isArray(order.Materials) ? order.Materials : []) as Record<string, unknown>[];
  const outputs = (Array.isArray(order.Outputs) ? order.Outputs : []) as Record<string, unknown>[];

  // ── Columns: Materials ──────────────────────────────────────

  const materialColumns: ZenttoColDef[] = [
    { field: "ProductCode", headerName: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "ProductName", headerName: "Descripcion", flex: 1.5, minWidth: 160 },
    {
      field: "PlannedQuantity",
      headerName: "Cant. Planificada",
      width: 130,
      type: "number",
    },
    {
      field: "ConsumedQuantity",
      headerName: "Cant. Consumida",
      width: 130,
      type: "number",
    },
    {
      field: "UnitCost",
      headerName: "Costo Unit.",
      width: 110,
      type: "number",
      valueFormatter: (value: unknown) => {
        const n = Number(value ?? 0);
        return n.toFixed(2);
      },
    },
  ];

  // ── Columns: Outputs ────────────────────────────────────────

  const outputColumns: ZenttoColDef[] = [
    { field: "ProductCode", headerName: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "ProductName", headerName: "Producto", flex: 1.2, minWidth: 140 },
    {
      field: "Quantity",
      headerName: "Cantidad",
      width: 110,
      type: "number",
    },
    { field: "WarehouseName", headerName: "Almacen", flex: 1, minWidth: 120 },
    { field: "LotNumber", headerName: "Lote", flex: 0.8, minWidth: 100 },
    {
      field: "CreatedAt",
      headerName: "Fecha",
      width: 110,
      valueFormatter: (value: unknown) => String(value ?? "").slice(0, 10),
    },
  ];

  // ── Action handlers ─────────────────────────────────────────

  const handleStart = () => startOrder.mutate(workOrderId);
  const handleComplete = () => completeOrder.mutate(workOrderId);
  const handleCancel = () => cancelOrder.mutate(workOrderId);

  const infoFields = [
    { label: "Producto", value: order.ProductName },
    { label: "BOM", value: order.BOMCode },
    { label: "Cantidad Planificada", value: order.PlannedQuantity != null ? `${order.PlannedQuantity} uds` : "-" },
    { label: "Inicio Planificado", value: order.PlannedStart ? String(order.PlannedStart).slice(0, 10) : "-" },
    { label: "Fin Planificado", value: order.PlannedEnd ? String(order.PlannedEnd).slice(0, 10) : "-" },
    { label: "Almacen", value: order.WarehouseName ?? order.WarehouseId ?? "-" },
    { label: "Notas", value: order.Notes || "-" },
  ];

  return (
    <>
      <Dialog
        open={open}
        onClose={onClose}
        fullScreen
        PaperProps={{
          sx: isMobile
            ? {}
            : { maxWidth: 1100, maxHeight: "95vh", m: "auto", borderRadius: 2 },
        }}
      >
        {/* Header */}
        <DialogTitle sx={{ display: "flex", alignItems: "center", gap: 2, pr: 6 }}>
          <Box sx={{ flex: 1 }}>
            <Typography variant="h6" fontWeight={600}>
              {isLoading ? "Cargando..." : `Orden ${order.WorkOrderNumber ?? ""}`}
            </Typography>
            {!isLoading && (
              <Stack direction="row" spacing={1} sx={{ mt: 0.5 }} flexWrap="wrap">
                <Chip
                  label={statusLabels[status] ?? status}
                  size="small"
                  color={statusColors[status] ?? "default"}
                />
                <Chip
                  label={priorityLabels[priority] ?? priority}
                  size="small"
                  color={priorityColors[priority] ?? "default"}
                  variant="outlined"
                />
              </Stack>
            )}
          </Box>
          <IconButton onClick={onClose} sx={{ position: "absolute", right: 8, top: 8 }}>
            <CloseIcon />
          </IconButton>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ p: 0 }}>
          {/* Info general (responsive grid) */}
          {!isLoading && (
            <Box sx={{ px: 3, py: 2, bgcolor: "grey.50" }}>
              <Grid container spacing={2}>
                {infoFields.map((f) => (
                  <Grid item xs={6} sm={4} md={3} key={f.label}>
                    <Typography
                      variant="caption"
                      color="text.secondary"
                      sx={{ fontSize: "0.68rem", textTransform: "uppercase", letterSpacing: "0.06em", display: "block" }}
                    >
                      {f.label}
                    </Typography>
                    <Typography variant="body2" fontWeight={500} sx={{ mt: 0.25 }}>
                      {String(f.value ?? "-")}
                    </Typography>
                  </Grid>
                ))}
              </Grid>
            </Box>
          )}

          <Divider />

          {/* Tabs */}
          <Box sx={{ px: { xs: 1, sm: 3 } }}>
            <Tabs
              value={tabIndex}
              onChange={(_, v) => setTabIndex(v)}
              variant={isMobile ? "scrollable" : "standard"}
              scrollButtons={isMobile ? "auto" : false}
              allowScrollButtonsMobile
              sx={{ borderBottom: 1, borderColor: "divider" }}
            >
              <Tab label="Materiales Consumidos" />
              <Tab label="Produccion Reportada" />
            </Tabs>

            {/* Tab: Materiales */}
            <TabPanel value={tabIndex} index={0}>
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "flex-end",
                  mb: 1,
                }}
              >
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => setConsumeOpen(true)}
                  disabled={!canModify}
                  fullWidth={isMobile}
                >
                  Consumir Material
                </Button>
              </Box>
              <ZenttoDataGrid
                rows={materials}
                columns={materialColumns}
                getRowId={(row) => row.MaterialConsumptionId ?? row.ProductId ?? Math.random()}
                autoHeight
                disableRowSelectionOnClick
                hideFooter={materials.length <= 10}
                pageSizeOptions={[10, 25]}
                sx={{ bgcolor: "background.paper", borderRadius: 1 }}
                mobileVisibleFields={["ProductCode", "ConsumedQuantity"]}
                smExtraFields={["ProductName"]}
              />
              {materials.length === 0 && !isLoading && (
                <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
                  No hay materiales consumidos aun.
                </Typography>
              )}
            </TabPanel>

            {/* Tab: Produccion */}
            <TabPanel value={tabIndex} index={1}>
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "flex-end",
                  mb: 1,
                }}
              >
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => setOutputOpen(true)}
                  disabled={!canModify}
                  fullWidth={isMobile}
                >
                  Reportar Salida
                </Button>
              </Box>
              <ZenttoDataGrid
                rows={outputs}
                columns={outputColumns}
                getRowId={(row) => row.OutputId ?? row.ProductId ?? Math.random()}
                autoHeight
                disableRowSelectionOnClick
                hideFooter={outputs.length <= 10}
                pageSizeOptions={[10, 25]}
                sx={{ bgcolor: "background.paper", borderRadius: 1 }}
                mobileVisibleFields={["ProductCode", "Quantity"]}
                smExtraFields={["WarehouseName"]}
              />
              {outputs.length === 0 && !isLoading && (
                <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
                  No hay produccion reportada aun.
                </Typography>
              )}
            </TabPanel>
          </Box>
        </DialogContent>

        <Divider />

        {/* Footer actions */}
        <DialogActions
          sx={{
            px: 3,
            py: 2,
            justifyContent: "space-between",
            flexDirection: { xs: "column", sm: "row" },
            gap: 1,
          }}
        >
          <Stack
            direction={{ xs: "column", sm: "row" }}
            spacing={1}
            sx={{ width: { xs: "100%", sm: "auto" } }}
          >
            {status === "DRAFT" && (
              <Button
                variant="contained"
                color="info"
                startIcon={<PlayArrowIcon />}
                onClick={handleStart}
                disabled={startOrder.isPending}
                fullWidth={isMobile}
              >
                {startOrder.isPending ? "Iniciando..." : "Iniciar Orden"}
              </Button>
            )}
            {status === "IN_PROGRESS" && (
              <Button
                variant="contained"
                color="success"
                startIcon={<CheckCircleIcon />}
                onClick={handleComplete}
                disabled={completeOrder.isPending}
                fullWidth={isMobile}
              >
                {completeOrder.isPending ? "Completando..." : "Completar Orden"}
              </Button>
            )}
            {canModify && (
              <Button
                variant="outlined"
                color="error"
                startIcon={<CancelIcon />}
                onClick={handleCancel}
                disabled={cancelOrder.isPending}
                fullWidth={isMobile}
              >
                {cancelOrder.isPending ? "Cancelando..." : "Cancelar Orden"}
              </Button>
            )}
          </Stack>
          <Button onClick={onClose} fullWidth={isMobile}>
            Cerrar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Sub-dialogs */}
      <ConsumeMaterialDialog
        open={consumeOpen}
        onClose={() => setConsumeOpen(false)}
        workOrderId={workOrderId}
      />
      <ReportOutputDialog
        open={outputOpen}
        onClose={() => setOutputOpen(false)}
        workOrderId={workOrderId}
      />
    </>
  );
}
