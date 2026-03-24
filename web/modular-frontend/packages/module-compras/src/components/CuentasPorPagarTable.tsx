// components/CuentasPorPagarTable.tsx
"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  InputAdornment,
  TextField,
  Typography,
} from "@mui/material";
import { Add as AddIcon, Search as SearchIcon } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  DeleteDialog,
} from "@zentto/shared-ui";
import { useCuentasPorPagarList, useDeleteCuentaPorPagar } from "../hooks/useCuentasPorPagar";
import { formatCurrency, formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

export default function CuentasPorPagarTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 25 });
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCuenta, setSelectedCuenta] = useState<Record<string, unknown> | null>(null);

  const { data: cuentas, isLoading } = useCuentasPorPagarList({
    search,
    page: paginationModel.page + 1,
    limit: paginationModel.pageSize,
  });

  const { mutate: deleteCuenta, isPending: isDeleting } = useDeleteCuentaPorPagar();

  const debouncedSearch = useCallback(
    debounce((value: string) => {
      setSearch(value);
      setPaginationModel((p) => ({ ...p, page: 0 }));
    }, 500),
    []
  );

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    debouncedSearch(e.target.value);
  };

  const handleDeleteClick = (row: Record<string, unknown>) => {
    setSelectedCuenta(row);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedCuenta) {
      deleteCuenta(String(selectedCuenta.id), {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedCuenta(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
        },
      });
    }
  };

  const rows = (cuentas?.data ?? []) as Record<string, unknown>[];
  const total = cuentas?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "nombreProveedor", headerName: "Proveedor", flex: 1.5, minWidth: 180 },
    { field: "numeroReferencia", headerName: "Num Ref", flex: 0.8, minWidth: 110 },
    {
      field: "fechaCreacion",
      headerName: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) =>
        value ? formatDate(String(value), { timeZone }) : "",
    },
    {
      field: "fechaVencimiento",
      headerName: "Vencimiento",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) =>
        value ? formatDate(String(value), { timeZone }) : "",
    },
    {
      field: "montoTotal",
      headerName: "Monto",
      flex: 0.8,
      minWidth: 120,
      type: "number",
      currency: true,
    },
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
      field: "diasVencidos",
      headerName: "Dias Vencidos",
      width: 130,
      type: "number",
      renderCell: (params) => {
        const row = params.row as Record<string, unknown>;
        const vencimiento = row.fechaVencimiento ? new Date(String(row.fechaVencimiento)) : null;
        const estado = String(row.estado ?? "");
        if (!vencimiento || estado === "Pagada") return "-";
        const hoy = new Date();
        const diff = Math.floor((hoy.getTime() - vencimiento.getTime()) / (1000 * 60 * 60 * 24));
        if (diff <= 0) return "-";
        return (
          <Typography variant="body2" sx={{ color: "error.main", fontWeight: 600 }}>
            {diff}
          </Typography>
        );
      },
    },
    {
      field: "estado",
      headerName: "Estado",
      width: 130,
      statusColors: {
        Pagada: "success",
        Pendiente: "warning",
        Vencida: "error",
        Parcial: "info",
      },
    },
    buildCrudActionsColumn<Record<string, unknown>>({
      onView: (row) => router.push(`/cuentas-por-pagar/${row.id}`),
      onDelete: (row) => handleDeleteClick(row),
    }),
  ];

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Cuentas por Pagar
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/cuentas-por-pagar/new")}
        >
          Nueva Cuenta
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por proveedor, numero o referencia..."
        defaultValue=""
        onChange={handleSearchChange}
        fullWidth
        size="small"
        sx={{ mb: 2 }}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon fontSize="small" />
            </InputAdornment>
          ),
        }}
      />

      <ZenttoDataGrid
        gridId="compras-cuentas-por-pagar-list"
        rows={rows}
        columns={columns}
        getRowId={(row) => row.id ?? row.numeroReferencia ?? Math.random()}
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
        mobileVisibleFields={["nombreProveedor", "saldo"]}
        smExtraFields={["estado", "fechaVencimiento"]}
      />

      <DeleteDialog
        open={deleteDialogOpen}
        onClose={() => { setDeleteDialogOpen(false); setSelectedCuenta(null); }}
        onConfirm={handleConfirmDelete}
        itemName={selectedCuenta ? `la cuenta ${selectedCuenta.numeroReferencia ?? ""}` : "esta cuenta por pagar"}
        loading={isDeleting}
      />
    </Box>
  );
}
