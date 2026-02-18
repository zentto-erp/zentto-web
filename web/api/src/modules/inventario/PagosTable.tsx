"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, TextField } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import DataGrid, { Column, Action } from "@/components/common/DataGrid";
import { DeleteDialog } from "@/components/common/Dialogs";
import { usePagosList, useDeletePago } from "@/hooks/usePagos";
import { Pago } from "@/lib/types";
import { formatCurrency, formatDate } from "@/lib/formatters";

export default function PagosTable() {
  const router = useRouter();
  const [searchTerm, setSearchTerm] = useState("");
  const [page, setPage] = useState(1);
  const [limit] = useState(10);
  
  const { data, isLoading } = usePagosList({ 
    search: searchTerm, 
    page, 
    limit 
  });
  
  const { mutate: deletePago, isPending: isDeleting } = useDeletePago();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState<Pago | null>(null);

  const columns: Column<Pago>[] = [
    { accessor: "numero", header: "Número", sortable: true, width: "100px" },
    { accessor: "fecha", header: "Fecha", width: "120px", formatFn: formatDate },
    // Nota: Usamos 'cliente' como accessor porque así está definido en el tipo Pago en index.ts,
    // aunque funcionalmente represente al beneficiario/proveedor.
    { accessor: "cliente", header: "Beneficiario", sortable: true },
    { accessor: "tipo", header: "Método", width: "120px" },
    { 
      accessor: "monto", 
      header: "Monto", 
      width: "150px",
      formatFn: (val) => formatCurrency(val as number)
    },
  ];

  const actions: Action<Pago>[] = [
    {
      id: "view",
      label: "Ver",
      onClick: (row) => router.push(`/pagos/${row.numero}`),
    },
    {
      id: "delete",
      label: "Anular",
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
        <h1>Pagos Emitidos</h1>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/pagos/new")}
        >
          Registrar Pago
        </Button>
      </Box>

      <TextField
        placeholder="Buscar pago por número o beneficiario..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        fullWidth
        size="small"
        sx={{ mb: 3 }}
      />

      <DataGrid<Pago>
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
        itemName={`Pago #${selectedItem?.numero}`}
        onConfirm={() => {
          if (selectedItem) deletePago(selectedItem.numero);
          setDeleteOpen(false);
        }}
        onCancel={() => setDeleteOpen(false)}
        isLoading={isDeleting}
      />
    </Box>
  );
}