// components/modules/facturas/FacturasTable.tsx
"use client";

import { useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  InputAdornment,
  Typography,
} from "@mui/material";
import { Add as AddIcon, Search as SearchIcon } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  ConfirmDialog,
} from "@zentto/shared-ui";
import { useFacturasList, useDeleteFactura } from "../../../hooks/useFacturas";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";
import { debounce } from "lodash";

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState("");
  const [anularOpen, setAnularOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);

  const { data: facturas, isLoading } = useFacturasList({
    search,
    page: page + 1,
    limit: pageSize,
  });

  const { mutate: deleteFactura, isPending: isDeleting } = useDeleteFactura();

  // Debounced search
  const debouncedSearch = useCallback(
    debounce((value: string) => {
      setSearch(value);
      setPage(0);
    }, 500),
    []
  );

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    debouncedSearch(e.target.value);
  };

  const handleAnularClick = (numero: string) => {
    setSelectedFactura(numero);
    setAnularOpen(true);
  };

  const handleConfirmAnular = () => {
    if (selectedFactura) {
      deleteFactura(selectedFactura, {
        onSuccess: () => {
          setAnularOpen(false);
          setSelectedFactura(null);
        },
        onError: (err) => {
          console.error("Error anulando:", err);
        },
      });
    }
  };

  const columns = useMemo<ZenttoColDef[]>(
    () => [
      {
        field: "numeroFactura",
        headerName: "Numero",
        width: 130,
        sortable: true,
      },
      {
        field: "nombreCliente",
        headerName: "Cliente",
        flex: 1,
        minWidth: 180,
        sortable: true,
        mobileHide: true,
      },
      {
        field: "fecha",
        headerName: "Fecha",
        width: 120,
        sortable: true,
        valueFormatter: (value: string) =>
          value ? toDateOnly(value, timeZone) : "",
      },
      {
        field: "tipoDoc",
        headerName: "Tipo",
        width: 110,
        tabletHide: true,
        statusColors: {
          FACT: "primary",
          PRESUP: "info",
          PEDIDO: "warning",
        },
        statusVariant: "outlined",
      },
      {
        field: "totalFactura",
        headerName: "Total",
        width: 140,
        type: "number",
        currency: true,
        aggregation: "sum",
      },
      {
        field: "estado",
        headerName: "Estado",
        width: 120,
        statusColors: {
          Pagada: "success",
          Pendiente: "warning",
          Anulada: "error",
          Cancelada: "default",
        },
        statusVariant: "outlined",
      },
      buildCrudActionsColumn({
        onView: (row) =>
          router.push(`/facturas/${row.numeroFactura}`),
        onDelete: (row) => handleAnularClick(row.numeroFactura),
      }),
    ],
    [timeZone, router]
  );

  const rows = useMemo(
    () =>
      (facturas?.data || []).map((f: any, idx: number) => ({
        id: f.numeroFactura || idx,
        ...f,
      })),
    [facturas?.data]
  );

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Header */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={600}>
          Facturas
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/facturas/new")}
          size="large"
        >
          Nueva Factura
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por numero, cliente o referencia..."
        defaultValue=""
        onChange={handleSearchChange}
        fullWidth
        sx={{ mb: 2 }}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon fontSize="small" />
            </InputAdornment>
          ),
        }}
      />

      {/* ZenttoDataGrid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        <ZenttoDataGrid
          columns={columns}
          rows={rows}
          loading={isLoading}
          enableClipboard
          enableHeaderFilters
          showTotals
          paginationMode="server"
          rowCount={facturas?.total ?? 0}
          serverRowCount={facturas?.total ?? 0}
          paginationModel={{ page, pageSize }}
          onPaginationModelChange={(model) => {
            setPage(model.page);
            setPageSize(model.pageSize);
          }}
          pageSizeOptions={[5, 10, 25, 50]}
          density="comfortable"
          exportFilename="facturas"
          gridId="facturas-table"
          sx={{ height: "100%" }}
        />
      </Box>

      {/* Anular Confirmation Dialog */}
      <ConfirmDialog
        open={anularOpen}
        title="Anular Factura"
        message={`Esta seguro de que desea anular la factura ${selectedFactura || ""}? Esta accion no puede deshacerse.`}
        confirmLabel={isDeleting ? "Anulando..." : "Anular"}
        variant="danger"
        onConfirm={handleConfirmAnular}
        onClose={() => {
          setAnularOpen(false);
          setSelectedFactura(null);
        }}
        loading={isDeleting}
      />
    </Box>
  );
}
