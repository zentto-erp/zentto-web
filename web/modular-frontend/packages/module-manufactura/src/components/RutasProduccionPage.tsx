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
  Stack,
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
  useBOMList,
  useRoutingList,
  useUpsertRouting,
  useWorkCentersList,
  type RoutingRow,
} from "../hooks/useManufactura";

interface RoutingFormData {
  routingId: number | null;
  operationNumber: string;
  operationName: string;
  workCenterId: string;
  setupTime: string;
  runTime: string;
  description: string;
}

const emptyForm = (): RoutingFormData => ({
  routingId: null,
  operationNumber: "",
  operationName: "",
  workCenterId: "",
  setupTime: "0",
  runTime: "0",
  description: "",
});

export default function RutasProduccionPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [selectedBomId, setSelectedBomId] = useState<number | undefined>();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<RoutingFormData>(emptyForm());

  // Data queries
  const { data: bomData, isLoading: bomLoading } = useBOMList({ limit: 500 });
  const { data: routingRows, isLoading: routingLoading } = useRoutingList(selectedBomId);
  const { data: wcData } = useWorkCentersList({ limit: 500 });
  const upsertRouting = useUpsertRouting(selectedBomId);

  const boms = (bomData?.rows ?? []) as Record<string, unknown>[];
  const workCenters = (wcData?.rows ?? []) as Record<string, unknown>[];
  const rows = (routingRows ?? []) as RoutingRow[];

  const columns: ZenttoColDef[] = [
    {
      field: "OperationNumber",
      headerName: "N. Operacion",
      width: 120,
      type: "number",
    },
    {
      field: "OperationName",
      headerName: "Nombre",
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
    },
    {
      field: "RunTime",
      headerName: "Ejecucion (min)",
      width: 130,
      type: "number",
    },
    {
      field: "Description",
      headerName: "Descripcion",
      flex: 1,
      minWidth: 150,
      renderCell: (params) => String(params.value ?? ""),
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

  const handleEdit = (row: RoutingRow) => {
    setForm({
      routingId: row.RoutingId,
      operationNumber: String(row.OperationNumber),
      operationName: row.OperationName,
      workCenterId: String(row.WorkCenterId),
      setupTime: String(row.SetupTime ?? 0),
      runTime: String(row.RunTime ?? 0),
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
          Rutas de Produccion
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleNew}
          disabled={!selectedBomId}
          fullWidth={isMobile}
        >
          Nueva Operacion
        </Button>
      </Box>

      {/* BOM Selector */}
      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid item xs={12} sm={8} md={6}>
          <TextField
            select
            label="Seleccionar BOM"
            value={selectedBomId ?? ""}
            onChange={(e) => {
              const val = e.target.value;
              setSelectedBomId(val ? Number(val) : undefined);
            }}
            fullWidth
            disabled={bomLoading}
            helperText={
              !selectedBomId
                ? "Seleccione una BOM para ver sus operaciones de ruta"
                : undefined
            }
          >
            <MenuItem value="">-- Seleccionar --</MenuItem>
            {boms.map((b) => (
              <MenuItem
                key={String(b.BOMId ?? b.Id)}
                value={String(b.BOMId ?? b.Id)}
              >
                {String(b.BOMCode ?? "")} - {String(b.BOMName ?? "")}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
      </Grid>

      {/* Grid */}
      {selectedBomId ? (
        <ZenttoDataGrid
        gridId="manufactura-rutas-produccion-list"
          rows={rows}
          columns={columns}
          enableHeaderFilters
          getRowId={(row) =>
            row.RoutingId ?? row.Id ?? row.OperationNumber ?? Math.random()
          }
          loading={routingLoading}
          disableRowSelectionOnClick
          autoHeight
          pageSizeOptions={[10, 25, 50]}
          sx={{ bgcolor: "background.paper", borderRadius: 2 }}
          mobileVisibleFields={["OperationName", "WorkCenterName"]}
          smExtraFields={["OperationNumber", "RunTime"]}
        />
      ) : (
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            minHeight: 200,
            bgcolor: "#f8f9fa",
            borderRadius: 2,
          }}
        >
          <Typography variant="body1" color="text.secondary">
            Seleccione una BOM para visualizar y gestionar sus rutas de
            produccion
          </Typography>
        </Box>
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
                label="N. Operacion"
                value={form.operationNumber}
                onChange={(e) =>
                  setForm((f) => ({ ...f, operationNumber: e.target.value }))
                }
                type="number"
                fullWidth
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre de la Operacion"
                value={form.operationName}
                onChange={(e) =>
                  setForm((f) => ({ ...f, operationName: e.target.value }))
                }
                fullWidth
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                select
                label="Centro de Trabajo"
                value={form.workCenterId}
                onChange={(e) =>
                  setForm((f) => ({ ...f, workCenterId: e.target.value }))
                }
                fullWidth
                required
              >
                <MenuItem value="">-- Seleccionar --</MenuItem>
                {workCenters.map((wc) => (
                  <MenuItem
                    key={String(wc.WorkCenterId ?? wc.Id)}
                    value={String(wc.WorkCenterId ?? wc.Id)}
                  >
                    {String(wc.WorkCenterCode ?? "")} -{" "}
                    {String(wc.WorkCenterName ?? "")}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Tiempo Setup (min)"
                value={form.setupTime}
                onChange={(e) =>
                  setForm((f) => ({ ...f, setupTime: e.target.value }))
                }
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Tiempo Ejecucion (min)"
                value={form.runTime}
                onChange={(e) =>
                  setForm((f) => ({ ...f, runTime: e.target.value }))
                }
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                label="Descripcion"
                value={form.description}
                onChange={(e) =>
                  setForm((f) => ({ ...f, description: e.target.value }))
                }
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
