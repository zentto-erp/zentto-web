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
  Switch,
  FormControlLabel,
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import {
  useWorkCentersList,
  useUpsertWorkCenter,
  type WorkCenterFilter,
} from "../hooks/useManufactura";

interface WorkCenterFormData {
  workCenterId?: number | null;
  workCenterCode: string;
  workCenterName: string;
  costPerHour: number;
  capacity: number;
  isActive: boolean;
}

const emptyForm = (): WorkCenterFormData => ({
  workCenterId: null,
  workCenterCode: "",
  workCenterName: "",
  costPerHour: 0,
  capacity: 1,
  isActive: true,
});

export default function CentrosTrabajoPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<WorkCenterFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const [search, setSearch] = useState("");

  const { data, isLoading } = useWorkCentersList({
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const upsertWorkCenter = useUpsertWorkCenter();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "WorkCenterCode", headerName: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "WorkCenterName", headerName: "Nombre", flex: 1.5, minWidth: 180 },
    {
      field: "CostPerHour",
      headerName: "Costo/Hora",
      width: 120,
      currency: true,
      aggregation: "sum",
    },
    {
      field: "Capacity",
      headerName: "Capacidad",
      width: 110,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "IsActive",
      headerName: "Activo",
      width: 90,
      statusColors: {
        true: "success",
        false: "default",
      },
      valueFormatter: (value: unknown) => value ? "Si" : "No",
    },
    {
      field: "actions",
      headerName: "Acciones",
      width: 80,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Button
          size="small"
          startIcon={<EditIcon />}
          onClick={() => {
            setFormData({
              workCenterId: Number(params.row.WorkCenterId ?? params.row.Id),
              workCenterCode: String(params.row.WorkCenterCode ?? ""),
              workCenterName: String(params.row.WorkCenterName ?? ""),
              costPerHour: Number(params.row.CostPerHour ?? 0),
              capacity: Number(params.row.Capacity ?? 1),
              isActive: Boolean(params.row.IsActive),
            });
            setIsEditing(true);
            setDialogOpen(true);
          }}
        >
          Editar
        </Button>
      ),
    },
  ];

  const handleChange = (field: keyof WorkCenterFormData, value: string | number | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const resetForm = () => {
    setFormData(emptyForm());
    setIsEditing(false);
  };

  const handleSubmit = () => {
    upsertWorkCenter.mutate(
      { ...formData },
      {
        onSuccess: () => {
          setDialogOpen(false);
          resetForm();
        },
      }
    );
  };

  const dialogTitle = isEditing ? "Editar Centro de Trabajo" : "Nuevo Centro de Trabajo";

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
          Centros de Trabajo
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            resetForm();
            setDialogOpen(true);
          }}
          fullWidth={isMobile}
        >
          Nuevo Centro
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por codigo, nombre..."
        value={search}
        onChange={(e) => {
          setSearch(e.target.value);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        fullWidth
        sx={{ mb: 2 }}
      />

      {/* DataGrid */}
      <ZenttoDataGrid
        gridId="manufactura-centros-trabajo-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.WorkCenterId ?? row.Id ?? row.WorkCenterCode ?? Math.random()}
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
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={["WorkCenterName", "IsActive"]}
        smExtraFields={["CostPerHour", "Capacity"]}
      />

      {/* Dialog: Crear/Editar */}
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
                disabled={
                  upsertWorkCenter.isPending ||
                  !formData.workCenterCode ||
                  !formData.workCenterName
                }
              >
                {upsertWorkCenter.isPending ? "Guardando..." : "Guardar"}
              </Button>
            </Toolbar>
          </AppBar>
        ) : (
          <DialogTitle>{dialogTitle}</DialogTitle>
        )}
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Codigo"
                value={formData.workCenterCode}
                onChange={(e) => handleChange("workCenterCode", e.target.value)}
                fullWidth
                disabled={isEditing}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre"
                value={formData.workCenterName}
                onChange={(e) => handleChange("workCenterName", e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Costo por Hora"
                value={formData.costPerHour}
                onChange={(e) => handleChange("costPerHour", Number(e.target.value))}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Capacidad"
                value={formData.capacity}
                onChange={(e) => handleChange("capacity", Number(e.target.value))}
                type="number"
                fullWidth
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.isActive}
                    onChange={(e) => handleChange("isActive", e.target.checked)}
                  />
                }
                label="Activo"
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
                upsertWorkCenter.isPending ||
                !formData.workCenterCode ||
                !formData.workCenterName
              }
            >
              {upsertWorkCenter.isPending ? "Guardando..." : "Guardar"}
            </Button>
          </DialogActions>
        )}
      </Dialog>
    </Box>
  );
}
