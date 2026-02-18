"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, TextField } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import DataGrid, { Column, Action } from "@/components/common/DataGrid";
import { DeleteDialog } from "@/components/common/Dialogs";
import { useProveedoresList, useDeleteProveedor } from "@/hooks/useProveedores";
import { Proveedor } from "@/lib/types";
import { formatCurrency } from "@/lib/formatters";

export default function ProveedoresTable() {
  const router = useRouter();
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  
  const { data, isLoading } = useProveedoresList({ 
    search: searchTerm, 
    page, 
    limit 
  });
  
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState<Proveedor | null>(null);

  const columns: Column<Proveedor>[] = [
    { accessor: "codigo", header: "Código", sortable: true, width: "100px" },
    { accessor: "nombre", header: "Nombre", sortable: true },
    { accessor: "rif", header: "RIF", width: "120px" },
    { accessor: "telefono", header: "Teléfono", width: "150px" },
    { accessor: "email", header: "Email" },
    { 
      accessor: "saldo", 
      header: "Saldo", 
      width: "150px",
      formatFn: (val) => formatCurrency(val as number)
    },
    { accessor: "estado", header: "Estado", width: "100px" },
  ];

  const actions: Action<Proveedor>[] = [
    {
      id: "edit",
      label: "Editar",
      onClick: (row) => router.push(`/proveedores/${row.codigo}/edit`),
    },
    {
      id: "delete",
      label: "Eliminar",
      color: "error",
      onClick: (row) => {
        setSelectedItem(row);
        setDeleteOpen(true);
      },
    },
  ];

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", mb: 3 }}>
        <h1>Proveedores</h1>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/proveedores/new")}
        >
          Nuevo Proveedor
        </Button>
      </Box>

      <TextField
        placeholder="Buscar proveedor por nombre o RIF..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        fullWidth
        size="small"
        sx={{ mb: 3 }}
      />

      <DataGrid<Proveedor>
        columns={columns}
        data={data?.items || []}
        total={data?.total || 0}
        page={page}
        pageSize={limit}
        onPageChange={setPage}
        isLoading={isLoading}
        actions={actions}
      />

      <DeleteDialog
        open={deleteOpen}
        itemName={selectedItem?.nombre || ""}
        onConfirm={() => {
          if (selectedItem) deleteProveedor(selectedItem.codigo);
          setDeleteOpen(false);
        }}
        onCancel={() => setDeleteOpen(false)}
        isLoading={isDeleting}
      />
    </Box>
  );
}