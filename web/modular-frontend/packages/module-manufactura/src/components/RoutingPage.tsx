"use client";

import React, { useState } from "react";
import {
  AppBar,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  IconButton,
  MenuItem,
  TextField,
  Toolbar,
  Typography,
  Alert,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import {
  useRoutingList,
  useUpsertRouting,
  useWorkCentersList,
  type RoutingRow,
} from "../hooks/useManufactura";

/* ─── Types ──────────────────────────────────────────────── */

interface RoutingFormData {
  routingId: number | null;
  operationNumber: string;
  operationName: string;
  workCenterId: string;
  setupTime: string;
  runTime: string;
  costPerOperation: string;
  description: string;
}

const emptyForm = (): RoutingFormData => ({
  routingId: null,
  operationNumber: "",
  operationName: "",
  workCenterId: "",
  setupTime: "0",
  runTime: "0",
  costPerOperation: "0",
  description: "",
});

/* ─── Props ──────────────────────────────────────────────── */

interface RoutingPageProps {
  bomId: number;
}

/* ─── Component ──────────────────────────────────────────── */

export default function RoutingPage({ bomId }: RoutingPageProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<RoutingFormData>(emptyForm());

  const { data: routingRows, isLoading } = useRoutingList(bomId);
  const { data: wcData } = useWorkCentersList({ limit: 500 });
  const upsertRouting = useUpsertRouting(bomId);

  const workCenters = (wcData?.rows ?? []) as Record<string, unknown>[];
  const rows = (routingRows ?? []) as RoutingRow[];

  /* ─── Columns ──────────────────────────────────────────── */

  const columns: ZenttoColDef[] = [
    {
      field: "OperationNumber",
      headerName: "Secuencia",
      width: 100,
      type: "number",
    },
    {
      field: "OperationName",
      headerName: "Operacion",
      flex: 1.2,
      minWidth: 160,
    },
    {
      field: "WorkCenterName",
      headerName: "Centro de Trabajo",
      flex: 1,
      minWidth: 150,
    },
    {
      field: "SetupTime",
      headerName: "Setup (min)",
      width: 120,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "RunTime",
      headerName: "Ejecucion (min)",
      width: 130,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "CostPerOperation",
      headerName: "Costo Operacion",
      width: 140,
      currency: true,
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 90,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Button
          size="small"
          startIcon={<EditIcon />}
          onClick={() => handleEdit(params.row as RoutingRow)}
        >
          Editar
        </Button>
      ),
    },
  ];

  /* ─── Handlers ─────────────────────────────────────────── */

  const handleEdit = (row: RoutingRow) => {
    setForm({
      routingId: row.RoutingId,
      operationNumber: String(row.OperationNumber),
      operationName: row.OperationName,
      workCenterId: String(row.WorkCenterId),
      setupTime: String(row.SetupTime ?? 0),
      runTime: String(row.RunTime ?? 0),
      costPerOperation: String((row as unknown as Record<string, unknown>).CostPerOperation ?? 0),
      description: row.Description ?? "",
    });
    setDialogOpen(true);
  };

  const handleNew = () => {
    setForm(emptyForm());
    setDialogOpen(true);
  };

  const handleSubmit = () => {
    upsertRouting.mutate(
      {
        routingId: form.routingId,
        operationNumber: Number(form.operationNumber),
        operationName: form.operationName,
        workCenterId: Number(form.workCenterId),
        setupTime: Number(form.setupTime),
        runTime: Number(form.runTime),
        costPerOperation: Number(form.costPerOperation),
        description: form.description || null,
      },
      {
        onSuccess: (result: any) => {
          if (result?.success !== false) {
            setDialogOpen(false);
            setForm(emptyForm());
          }
        },
      },
    );
  };

  const isFormValid =
    form.operationNumber && form.operationName && form.workCenterId;

  const dialogTitle = form.routingId ? "Editar Operacion" : "Nueva Operacion";

  return (
    <Box sx={{ p: 1 }}>
      {/* Header */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 2,
        }}
      >
        <Typography variant="subtitle1" fontWeight={600}>
          Operaciones / Ruta de Produccion
        </Typography>
        <Button
          variant="outlined"
          size="small"
          startIcon={<AddIcon />}
          onClick={handleNew}
        >
          Nueva Operacion
        </Button>
      </Box>

      {/* Grid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.RoutingId ?? row.Id ?? row.OperationNumber ?? Math.random()}
        loading={isLoading}
        disableRowSelectionOnClick
        autoHeight
        hideFooter={rows.length <= 10}
        pageSizeOptions={[10, 25]}
        enableClipboard
        sx={{ bgcolor: "background.paper", borderRadius: 1 }}
        mobileVisibleFields={["OperationName", "WorkCenterName"]}
        smExtraFields={["OperationNumber", "RunTime"]}
      />
      {rows.length === 0 && !isLoading && (
        <Typography variant="body2" color="text.secondary" sx={{ textAlign: "center", py: 3 }}>
          No hay operaciones definidas para esta BOM.
        </Typography>
      )}

      {/* Dialog: Crear/Editar Operacion */}
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
                {dialogTitle}
              </Typography>
              <Button
                color="inherit"
                onClick={handleSubmit}
                disabled={upsertRouting.isPending || !isFormValid}
              >
                {upsertRouting.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>{dialogTitle}</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            {upsertRouting.isError && (
              <Grid item xs={12}>
                <Alert severity="error">
                  Error al guardar la operacion. Intente nuevamente.
                </Alert>
              </Grid>
            )}
            <Grid item xs={12} sm={6}>
              <TextField
                label="Secuencia (N. Operacion)"
                value={form.operationNumber}
                onChange={(e) => setForm((f) => ({ ...f, operationNumber: e.target.value }))}
                type="number"
                fullWidth
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre de la Operacion"
                value={form.operationName}
                onChange={(e) => setForm((f) => ({ ...f, operationName: e.target.value }))}
                fullWidth
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                select
                label="Centro de Trabajo"
                value={form.workCenterId}
                onChange={(e) => setForm((f) => ({ ...f, workCenterId: e.target.value }))}
                fullWidth
                required
              >
                <MenuItem value="">-- Seleccionar --</MenuItem>
                {workCenters.map((wc) => (
                  <MenuItem
                    key={String(wc.WorkCenterId ?? wc.Id)}
                    value={String(wc.WorkCenterId ?? wc.Id)}
                  >
                    {String(wc.WorkCenterCode ?? "")} - {String(wc.WorkCenterName ?? "")}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                label="Tiempo Setup (min)"
                value={form.setupTime}
                onChange={(e) => setForm((f) => ({ ...f, setupTime: e.target.value }))}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                label="Tiempo Ejecucion (min)"
                value={form.runTime}
                onChange={(e) => setForm((f) => ({ ...f, runTime: e.target.value }))}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                label="Costo Operacion"
                value={form.costPerOperation}
                onChange={(e) => setForm((f) => ({ ...f, costPerOperation: e.target.value }))}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                label="Descripcion"
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                multiline
                rows={3}
                fullWidth
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
              disabled={upsertRouting.isPending || !isFormValid}
            >
              {upsertRouting.isPending ? "Guardando..." : "Guardar"}
            </Button>
          </DialogActions>
        )}
      </Dialog>
    </Box>
  );
}
