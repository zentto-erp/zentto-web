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
  Switch,
  FormControlLabel,
  TextField,
  Toolbar,
  Typography,
  useMediaQuery,
  useTheme,
  CircularProgress,
} from "@mui/material";
import {  ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import {
  useWorkCentersList,
  useUpsertWorkCenter,
  type WorkCenterFilter,
} from "../hooks/useManufactura";
import type { ColumnDef } from "@zentto/datagrid-core";


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

const CENTROS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "true", label: "Activo" },
      { value: "false", label: "Inactivo" },
    ],
  },
];

export default function CentrosTrabajoPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<WorkCenterFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useWorkCentersList({
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const upsertWorkCenter = useUpsertWorkCenter();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "WorkCenterCode", header: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "WorkCenterName", header: "Nombre", flex: 1.5, minWidth: 180 },
    {
      field: "CostPerHour",
      header: "Costo/Hora",
      width: 120,
      currency: true,
      aggregation: "sum",
    },
    {
      field: "Capacity",
      header: "Capacidad",
      width: 110,
      type: "number",
      aggregation: "sum",
    },
    {
      field: "IsActive",
      header: "Activo",
      width: 90,
      statusColors: {
        true: "success",
        false: "default",
      },
      valueFormatter: (value: unknown) => value ? "Si" : "No",
    },
    {
      field: "actions",
      header: "Acciones",
      type: "actions",
      width: 100,
      pin: "right",
      actions: [
        { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
        { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
      ],
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
      if (action === "edit") {
        setFormData({
          workCenterId: Number(row.WorkCenterId ?? row.Id),
          workCenterCode: String(row.WorkCenterCode ?? ""),
          workCenterName: String(row.WorkCenterName ?? ""),
          costPerHour: Number(row.CostPerHour ?? 0),
          capacity: Number(row.Capacity ?? 1),
          isActive: Boolean(row.IsActive),
        });
        setIsEditing(true);
        setDialogOpen(true);
      }
      if (action === "delete") { /* TODO: eliminar centro de trabajo */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

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

      {/* Filter */}
      <ZenttoFilterPanel
        filters={CENTROS_FILTERS}
        values={filterValues}
        onChange={(vals) => {
          setFilterValues(vals);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por codigo, nombre..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="manufactura-centros-trabajo-list"
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
