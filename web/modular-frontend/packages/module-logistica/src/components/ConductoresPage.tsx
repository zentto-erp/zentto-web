"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  TextField,
  Typography,
  useMediaQuery,
  useTheme,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import {  ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import {
  useDriversList,
  useCreateDriver,
  useUpdateDriver,
  type DriverFilter,
} from "../hooks/useLogistica";
import type { ColumnDef } from "@zentto/datagrid-core";

interface DriverFormData {
  driverId?: number;
  carrierId?: number;
  driverCode: string;
  driverName: string;
  licenseNumber: string;
  licenseExpiry: string;
  phone: string;
  isActive: boolean;
}

const emptyForm = (): DriverFormData => ({
  driverCode: "",
  driverName: "",
  licenseNumber: "",
  licenseExpiry: "",
  phone: "",
  isActive: true,
});

const CONDUCTORES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "true", label: "Activo" },
      { value: "false", label: "Inactivo" },
    ],
  },
];

export default function ConductoresPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<DriverFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<DriverFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useDriversList({
    ...filter,
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createDriver = useCreateDriver();
  const updateDriver = useUpdateDriver();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "DriverCode", header: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "DriverName", header: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "CarrierName", header: "Transportista", flex: 1.2, minWidth: 140 },
    { field: "LicenseNumber", header: "Licencia", flex: 1, minWidth: 120 },
    {
      field: "LicenseExpiry",
      header: "Venc. Licencia",
      flex: 1,
      minWidth: 130,
      renderCell: (params) => {
        if (!params.value) return "-";
        const d = new Date(params.value as string);
        return d.toLocaleDateString("es");
      },
    },
    { field: "Phone", header: "Telefono", flex: 1, minWidth: 120 },
    {
      field: "IsActive",
      header: "Activo",
      width: 90,
      renderCell: (params) => (
        <Chip
          label={params.value ? "Si" : "No"}
          size="small"
          color={params.value ? "success" : "default"}
          variant="outlined"
        />
      ),
    },
    {
      field: "actions",
      header: "Acciones",
      width: 80,
      sortable: false,
      filterable: false,
      renderCell: (params) => (
        <Button
          size="small"
          startIcon={<EditIcon />}
          onClick={() => {
            setFormData({
              driverId: Number(params.row.DriverId ?? params.row.Id),
              carrierId: params.row.CarrierId ? Number(params.row.CarrierId) : undefined,
              driverCode: String(params.row.DriverCode ?? ""),
              driverName: String(params.row.DriverName ?? ""),
              licenseNumber: String(params.row.LicenseNumber ?? ""),
              licenseExpiry: params.row.LicenseExpiry
                ? String(params.row.LicenseExpiry).slice(0, 10)
                : "",
              phone: String(params.row.Phone ?? ""),
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

  const handleChange = (field: keyof DriverFormData, value: string | boolean | number) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const resetForm = () => {
    setFormData(emptyForm());
    setIsEditing(false);
  };

  const handleSubmit = () => {
    const payload: Record<string, unknown> = { ...formData };
    const mutation = isEditing ? updateDriver : createDriver;

    mutation.mutate(payload, {
      onSuccess: () => {
        setDialogOpen(false);
        resetForm();
      },
    });
  };

  // Bind data to zentto-grid web component

  useEffect(() => {

    const el = gridRef.current;

    if (!el || !registered) return;

    el.columns = columns;

    el.rows = rows;

    el.loading = isLoading;

  }, [rows, isLoading, registered, columns]);


  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{
        display: "flex",
        flexDirection: { xs: "column", sm: "row" },
        justifyContent: "space-between",
        alignItems: { xs: "stretch", sm: "center" },
        gap: 2,
        mb: 3,
      }}>
        <Typography variant="h5" fontWeight={600}>
          Conductores
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            resetForm();
            setDialogOpen(true);
          }}
          fullWidth={isMobile}
          sx={{ maxWidth: { sm: "fit-content" } }}
        >
          Nuevo Conductor
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={CONDUCTORES_FILTERS}
        values={filterValues}
        onChange={(vals) => {
          setFilterValues(vals);
          setFilter((f) => ({ ...f, isActive: vals.estado || undefined }));
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por codigo, nombre, licencia..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="logistica-conductores-list"
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
        <DialogTitle>{isEditing ? "Editar Conductor" : "Nuevo Conductor"}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Codigo"
                value={formData.driverCode}
                onChange={(e) => handleChange("driverCode", e.target.value)}
                fullWidth
                disabled={isEditing}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre"
                value={formData.driverName}
                onChange={(e) => handleChange("driverName", e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Numero de Licencia"
                value={formData.licenseNumber}
                onChange={(e) => handleChange("licenseNumber", e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Vencimiento Licencia"
                type="date"
                value={formData.licenseExpiry}
                onChange={(e) => handleChange("licenseExpiry", e.target.value)}
                fullWidth
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Telefono"
                value={formData.phone}
                onChange={(e) => handleChange("phone", e.target.value)}
                fullWidth
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={
              (isEditing ? updateDriver.isPending : createDriver.isPending) ||
              !formData.driverCode ||
              !formData.driverName
            }
          >
            {(isEditing ? updateDriver.isPending : createDriver.isPending)
              ? "Guardando..."
              : "Guardar"}
          </Button>
        </DialogActions>
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
