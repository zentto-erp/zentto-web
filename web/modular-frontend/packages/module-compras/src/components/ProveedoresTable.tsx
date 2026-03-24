// components/ProveedoresTable.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  Typography,
} from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  DeleteDialog,
} from "@zentto/shared-ui";
import { useProveedoresList, useDeleteProveedor } from "../hooks/useProveedores";
import { Proveedor, ProveedorFilter } from "@zentto/shared-api/types";

export default function ProveedoresTable() {
  const router = useRouter();
  const [filter, setFilter] = useState<ProveedorFilter>({ page: 1, limit: 25 });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [searchTerm, setSearchTerm] = useState("");
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedProveedor, setSelectedProveedor] = useState<Proveedor | null>(null);

  // Queries
  const { data, isLoading } = useProveedoresList({
    ...filter,
    search: searchTerm,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();

  const rows = (data?.items ?? []) as unknown as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  const handleDeleteClick = (row: Record<string, unknown>) => {
    setSelectedProveedor(row as unknown as Proveedor);
    setDeleteOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (selectedProveedor) {
      deleteProveedor(selectedProveedor.codigo, {
        onSuccess: () => {
          setDeleteOpen(false);
          setSelectedProveedor(null);
        },
      });
    }
  };

  const columns: ZenttoColDef[] = [
    { field: "codigo", headerName: "Codigo", flex: 0.7, minWidth: 100 },
    { field: "nombre", headerName: "Nombre", flex: 1.5, minWidth: 180 },
    { field: "rif", headerName: "RIF", flex: 1, minWidth: 120 },
    { field: "email", headerName: "Email", flex: 1.2, minWidth: 160 },
    { field: "telefono", headerName: "Telefono", flex: 0.9, minWidth: 120 },
    {
      field: "saldo",
      headerName: "Saldo",
      flex: 0.8,
      minWidth: 120,
      type: "number",
      currency: true,
      aggregation: "sum",
    },
    {
      field: "estado",
      headerName: "Estado",
      width: 120,
      statusColors: {
        Activo: "success",
        ACTIVE: "success",
        Inactivo: "error",
        INACTIVE: "error",
      },
    },
    buildCrudActionsColumn<Record<string, unknown>>({
      onView: (row) => router.push(`/proveedores/${row.codigo}`),
      onEdit: (row) => router.push(`/proveedores/${row.codigo}/edit`),
      onDelete: (row) => handleDeleteClick(row),
    }),
  ];

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Gestion de Proveedores
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/proveedores/new")}
        >
          Nuevo Proveedor
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por nombre o RIF..."
        value={searchTerm}
        onChange={handleSearch}
        fullWidth
        size="small"
        variant="outlined"
        sx={{ mb: 2 }}
      />

      {/* DataGrid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.codigo ?? row.id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        enableClipboard
        enableHeaderFilters
        showTotals
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={["codigo", "nombre"]}
        smExtraFields={["rif", "estado"]}
      />

      {/* Delete Dialog */}
      <DeleteDialog
        open={deleteOpen}
        onClose={() => { setDeleteOpen(false); setSelectedProveedor(null); }}
        onConfirm={handleDeleteConfirm}
        itemName={selectedProveedor ? `el proveedor ${selectedProveedor.nombre}` : "este proveedor"}
        loading={isDeleting}
      />
    </Box>
  );
}
