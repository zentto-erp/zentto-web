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
  Switch,
  FormControlLabel,
  TextField,
  Typography,
} from "@mui/material";
import { DataGrid, GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
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
      type: "number",
      valueFormatter: (value: unknown) => {
        const n = Number(value ?? 0);
        return n.toFixed(2);
      },
    },
    {
      field: "Capacity",
      headerName: "Capacidad",
      width: 110,
      type: "number",
    },
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

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
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
        rows={rows}
        columns={columns}
        getRowId={(row) => row.WorkCenterId ?? row.Id ?? row.WorkCenterCode ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={['WorkCenterName', 'IsActive']}
        smExtraFields={['CostPerHour', 'Capacity']}
      />

      {/* Dialog: Crear/Editar */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{isEditing ? "Editar Centro de Trabajo" : "Nuevo Centro de Trabajo"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Codigo"
              value={formData.workCenterCode}
              onChange={(e) => handleChange("workCenterCode", e.target.value)}
              fullWidth
              disabled={isEditing}
            />
            <TextField
              label="Nombre"
              value={formData.workCenterName}
              onChange={(e) => handleChange("workCenterName", e.target.value)}
              fullWidth
            />
            <TextField
              label="Costo por Hora"
              value={formData.costPerHour}
              onChange={(e) => handleChange("costPerHour", Number(e.target.value))}
              type="number"
              fullWidth
            />
            <TextField
              label="Capacidad"
              value={formData.capacity}
              onChange={(e) => handleChange("capacity", Number(e.target.value))}
              type="number"
              fullWidth
            />
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => handleChange("isActive", e.target.checked)}
                />
              }
              label="Activo"
            />
          </Stack>
        </DialogContent>
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
      </Dialog>
    </Box>
  );
}
