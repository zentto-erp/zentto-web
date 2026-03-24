// components/modules/abonos/AbonosaTable.tsx
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
import { useAbonosList, useDeleteAbono } from "../../../hooks/useAbonos";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";
import { debounce } from "lodash";

export default function AbonosTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAbono, setSelectedAbono] = useState<string | null>(null);

  const { data: abonos, isLoading } = useAbonosList({
    search,
    page: page + 1,
    limit: pageSize,
  });

  const { mutate: deleteAbono, isPending: isDeleting } = useDeleteAbono();

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

  const handleDeleteClick = (numero: string) => {
    setSelectedAbono(numero);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedAbono) {
      deleteAbono(selectedAbono, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedAbono(null);
        },
        onError: (err) => {
          console.error("Error eliminando:", err);
        },
      });
    }
  };

  const columns = useMemo<ZenttoColDef[]>(
    () => [
      {
        field: "numeroAbono",
        headerName: "Numero Abono",
        width: 140,
        sortable: true,
      },
      {
        field: "nombreCliente",
        headerName: "Cliente",
        flex: 1,
        minWidth: 180,
        sortable: true,
      },
      {
        field: "numeroFactura",
        headerName: "Factura",
        width: 140,
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
        field: "monto",
        headerName: "Monto",
        width: 140,
        type: "number",
        currency: true,
        aggregation: "sum",
      },
      buildCrudActionsColumn({
        onView: (row) => router.push(`/abonos/${row.numeroAbono}`),
        onDelete: (row) => handleDeleteClick(row.numeroAbono),
      }),
    ],
    [timeZone, router]
  );

  const rows = useMemo(
    () =>
      (abonos?.data || []).map((a: any, idx: number) => ({
        id: a.numeroAbono || idx,
        ...a,
      })),
    [abonos?.data]
  );

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={600}>
          Abonos
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/abonos/new")}
        >
          Nuevo Abono
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por numero, cliente o factura..."
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
          rowCount={abonos?.total ?? 0}
          serverRowCount={abonos?.total ?? 0}
          paginationModel={{ page, pageSize }}
          onPaginationModelChange={(model) => {
            setPage(model.page);
            setPageSize(model.pageSize);
          }}
          pageSizeOptions={[5, 10, 25, 50]}
          density="comfortable"
          exportFilename="abonos"
          gridId="abonos-table"
          sx={{ height: "100%" }}
        />
      </Box>

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        title="Eliminar Abono"
        message={`Esta seguro de que desea eliminar el abono ${selectedAbono || ""}?`}
        confirmLabel={isDeleting ? "Eliminando..." : "Eliminar"}
        variant="danger"
        onConfirm={handleConfirmDelete}
        onClose={() => {
          setDeleteDialogOpen(false);
          setSelectedAbono(null);
        }}
        loading={isDeleting}
      />
    </Box>
  );
}
