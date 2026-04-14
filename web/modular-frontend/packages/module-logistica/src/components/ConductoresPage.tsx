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
  useMediaQuery,
  useTheme,
} from "@mui/material";
import Grid from "@mui/material/Grid";
import {
  useDriversList,
  useCreateDriver,
  useUpdateDriver,
  type DriverFilter,
} from "../hooks/useLogistica";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { buildLogisticaGridId, useLogisticaGridId, useLogisticaGridRegistration } from "./zenttoGridPersistence";


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


const GRID_IDS = {
  gridRef: buildLogisticaGridId("conductores", "main"),
} as const;

export default function ConductoresPage() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  const [filter, setFilter] = useState<DriverFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [formData, setFormData] = useState<DriverFormData>(emptyForm());
  const [isEditing, setIsEditing] = useState(false);
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useLogisticaGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useLogisticaGridRegistration(layoutReady);

const { data, isLoading } = useDriversList({
    ...filter,
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
      renderCell: (value: unknown) => {
        if (!value) return "-";
        const d = new Date(value as string);
        return d.toLocaleDateString("es");
      },
    },
    { field: "Phone", header: "Telefono", flex: 1, minWidth: 120 },
    {
      field: "IsActive",
      header: "Activo",
      width: 90,
      type: "boolean",
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

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") {
        setFormData({
          driverId: Number(row.DriverId ?? row.Id),
          carrierId: row.CarrierId ? Number(row.CarrierId) : undefined,
          driverCode: String(row.DriverCode ?? ""),
          driverName: String(row.DriverName ?? ""),
          licenseNumber: String(row.LicenseNumber ?? ""),
          licenseExpiry: row.LicenseExpiry ? String(row.LicenseExpiry).slice(0, 10) : "",
          phone: String(row.Phone ?? ""),
          isActive: Boolean(row.IsActive),
        });
        setIsEditing(true);
        setDialogOpen(true);
      }
      if (action === "delete") { /* TODO: eliminar conductor */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => { resetForm(); setDialogOpen(true); };
    el.addEventListener("create-click", handler);
    return () => el.removeEventListener("create-click", handler);
  }, [registered]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* DataGrid */}
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          export-filename="logistica-conductores-list"
          height="calc(100vh - 200px)"
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
          enable-grouping
          enable-pivot
          enable-create
          create-label="Nuevo Conductor"
        ></zentto-grid>
      </Box>

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
