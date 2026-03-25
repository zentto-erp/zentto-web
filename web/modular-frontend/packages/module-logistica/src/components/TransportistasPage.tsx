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
  useCarriersList,
  useCreateCarrier,
  useUpdateCarrier,
  type CarrierFilter,
} from "../hooks/useLogistica";
import type { ColumnDef } from "@zentto/datagrid-core";

interface CarrierFormData {
  id?: number;
  carrierCode: string;
  carrierName: string;
  fiscalId: string;
  contactName: string;
  phone: string;
  isActive: boolean;
}

const emptyForm = (): CarrierFormData => ({
  carrierCode: "",
  carrierName: "",
  fiscalId: "",
  contactName: "",
  phone: "",
  isActive: true,
});

const TRANSPORTISTAS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado", label: "Estado", type: "select",
    options: [
      { value: "true", label: "Activo" },
      { value: "false", label: "Inactivo" },
    ],
  },
];

export default function TransportistasPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<CarrierFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<CarrierFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useCarriersList({
    ...filter,
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const createCarrier = useCreateCarrier();
  const updateCarrier = useUpdateCarrier();

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "CarrierCode", header: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "CarrierName", header: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "FiscalId", header: "RIF / NIF", flex: 1, minWidth: 120 },
    { field: "ContactName", header: "Contacto", flex: 1.2, minWidth: 140 },
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
              id: Number(params.row.CarrierId ?? params.row.Id),
              carrierCode: String(params.row.CarrierCode ?? ""),
              carrierName: String(params.row.CarrierName ?? ""),
              fiscalId: String(params.row.FiscalId ?? ""),
              contactName: String(params.row.ContactName ?? ""),
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

  const handleChange = (field: keyof CarrierFormData, value: string | boolean) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const resetForm = () => {
    setFormData(emptyForm());
    setIsEditing(false);
  };

  const handleSubmit = () => {
    const payload: Record<string, unknown> = { ...formData };
    const mutation = isEditing ? updateCarrier : createCarrier;

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
          Transportistas
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
          Nuevo Transportista
        </Button>
      </Box>

      {/* Filter */}
      <ZenttoFilterPanel
        filters={TRANSPORTISTAS_FILTERS}
        values={filterValues}
        onChange={(vals) => {
          setFilterValues(vals);
          setFilter((f) => ({ ...f, isActive: vals.estado || undefined }));
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por codigo, nombre, RIF..."
        searchValue={search}
        onSearchChange={(v) => { setSearch(v); setPaginationModel((p) => ({ ...p, page: 0 })); }}
      />

      {/* DataGrid */}
      <zentto-grid
        ref={gridRef}
        export-filename="logistica-transportistas-list"
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
        <DialogTitle>{isEditing ? "Editar Transportista" : "Nuevo Transportista"}</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Codigo"
                value={formData.carrierCode}
                onChange={(e) => handleChange("carrierCode", e.target.value)}
                fullWidth
                disabled={isEditing}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Nombre"
                value={formData.carrierName}
                onChange={(e) => handleChange("carrierName", e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="RIF / NIF"
                value={formData.fiscalId}
                onChange={(e) => handleChange("fiscalId", e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                label="Contacto"
                value={formData.contactName}
                onChange={(e) => handleChange("contactName", e.target.value)}
                fullWidth
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
              (isEditing ? updateCarrier.isPending : createCarrier.isPending) ||
              !formData.carrierCode ||
              !formData.carrierName
            }
          >
            {(isEditing ? updateCarrier.isPending : createCarrier.isPending)
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
