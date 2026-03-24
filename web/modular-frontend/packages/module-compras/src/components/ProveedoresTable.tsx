// components/ProveedoresTable.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Typography,
} from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  DeleteDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import { useProveedoresList, useDeleteProveedor } from "../hooks/useProveedores";
import { Proveedor, ProveedorFilter } from "@zentto/shared-api/types";

const PROVEEDORES_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "Activo", label: "Activo" },
      { value: "Inactivo", label: "Inactivo" },
    ],
  },
];

export default function ProveedoresTable() {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedProveedor, setSelectedProveedor] = useState<Proveedor | null>(null);

  // Queries
  const { data, isLoading } = useProveedoresList({
    search,
    estado: filterValues.estado || undefined,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  } as ProveedorFilter);
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();

  const rows = (data?.items ?? []) as unknown as Record<string, unknown>[];
  const total = data?.total ?? 0;

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

      {/* Filters */}
      <ZenttoFilterPanel
        filters={PROVEEDORES_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por nombre o RIF..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
      />

      {/* DataGrid */}
      <ZenttoDataGrid
        gridId="compras-proveedores-list"
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
