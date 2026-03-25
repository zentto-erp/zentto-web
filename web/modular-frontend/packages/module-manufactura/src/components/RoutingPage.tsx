"use client";

import React, { useState, useEffect, useRef } from "react";
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
  CircularProgress,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import {
  useRoutingList,
  useUpsertRouting,
  useWorkCentersList,
  type RoutingRow,
} from "../hooks/useManufactura";
import type { ColumnDef } from "@zentto/datagrid-core";

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

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
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data: routingRows, isLoading } = useRoutingList(bomId);
  const { data: wcData } = useWorkCentersList({ limit: 500 });
  const upsertRouting = useUpsertRouting(bomId);

  const workCenters = (wcData?.rows ?? []) as Record<string, unknown>[];
  const rows = (routingRows ?? []) as RoutingRow[];

  /* ─── Columns ──────────────────────────────────────────── */

  const columns: ColumnDef[] = [
    {
      field: "OperationNumber",
      header: "Secuencia",
      width: 100,
      type: "number",
    },
    {
      field: "OperationName",
      header: "Operacion",
      flex: 1.2,
      minWidth: 160,
    },
    {
      field: "WorkCenterName",
      header: "Centro de Trabajo",
      flex: 1,
      minWidth: 150,
    },
    {
      field: "SetupTime",
      header: "Setup (min)",
      width: 120,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "RunTime",
      header: "Ejecucion (min)",
      width: 130,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "CostPerOperation",
      header: "Costo Operacion",
      width: 140,
      currency: true,
    },
    {
      field: "actions",
      header: "Acciones",
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

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
    el.actionButtons = [
      { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
      { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#dc2626" },
    ];
  }, [rows, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") handleEdit(row as RoutingRow);
      if (action === "delete") { /* TODO: eliminar operacion */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

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
      <zentto-grid
        ref={gridRef}
        export-filename="manufactura-routing-list"
        height="400px"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
