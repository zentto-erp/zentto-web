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
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import {
  useCarriersList,
  useCreateCarrier,
  useUpdateCarrier,
  type CarrierFilter,
} from "../hooks/useLogistica";

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

export default function TransportistasPage() {
  const [filter, setFilter] = useState<CarrierFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<CarrierFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const [search, setSearch] = useState("");

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

  const columns: ZenttoColDef[] = [
    { field: "CarrierCode", headerName: "Codigo", flex: 0.8, minWidth: 100 },
    { field: "CarrierName", headerName: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "FiscalId", headerName: "RIF / NIF", flex: 1, minWidth: 120 },
    { field: "ContactName", headerName: "Contacto", flex: 1.2, minWidth: 140 },
    { field: "Phone", headerName: "Telefono", flex: 1, minWidth: 120 },
    {
      field: "IsActive",
      headerName: "Activo",
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

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
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
        >
          Nuevo Transportista
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por codigo, nombre, RIF..."
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
        rows={rows}
        columns={columns}
        getRowId={(row) => row.CarrierId ?? row.Id ?? row.CarrierCode ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['CarrierCode', 'CarrierName']}
        smExtraFields={['IsActive', 'Phone']}
      />

      {/* Dialog: Crear/Editar */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{isEditing ? "Editar Transportista" : "Nuevo Transportista"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Codigo"
              value={formData.carrierCode}
              onChange={(e) => handleChange("carrierCode", e.target.value)}
              fullWidth
              disabled={isEditing}
            />
            <TextField
              label="Nombre"
              value={formData.carrierName}
              onChange={(e) => handleChange("carrierName", e.target.value)}
              fullWidth
            />
            <TextField
              label="RIF / NIF"
              value={formData.fiscalId}
              onChange={(e) => handleChange("fiscalId", e.target.value)}
              fullWidth
            />
            <TextField
              label="Contacto"
              value={formData.contactName}
              onChange={(e) => handleChange("contactName", e.target.value)}
              fullWidth
            />
            <TextField
              label="Telefono"
              value={formData.phone}
              onChange={(e) => handleChange("phone", e.target.value)}
              fullWidth
            />
          </Stack>
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
