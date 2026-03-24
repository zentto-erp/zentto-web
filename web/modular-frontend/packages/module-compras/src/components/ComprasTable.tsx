"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  InputAdornment,
  Paper,
  TextField,
  Typography,
} from "@mui/material";
import { Add, Search } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  ConfirmDialog,
  DatePicker,
} from "@zentto/shared-ui";
import { useComprasList } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, formatDate } from "@zentto/shared-api";
import dayjs from "dayjs";

export default function ComprasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  function firstDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth(), 1), timeZone);
  }

  function lastDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth() + 1, 0), timeZone);
  }

  const [search, setSearch] = useState("");
  const [fechaDesde, setFechaDesde] = useState(firstDayOfCurrentMonth());
  const [fechaHasta, setFechaHasta] = useState(lastDayOfCurrentMonth());
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 50 });

  // Anular dialog
  const [anularOpen, setAnularOpen] = useState(false);
  const [anularRow, setAnularRow] = useState<Record<string, unknown> | null>(null);

  const filter = useMemo(
    () => ({
      search: search.trim() || undefined,
      fechaDesde,
      fechaHasta,
      page: paginationModel.page + 1,
      limit: paginationModel.pageSize,
    }),
    [search, fechaDesde, fechaHasta, paginationModel]
  );

  const { data, isLoading } = useComprasList(filter);

  const rows = (data?.rows ?? []) as Record<string, unknown>[];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "documentNumber", headerName: "Numero", flex: 0.8, minWidth: 110 },
    { field: "supplierName", headerName: "Proveedor", flex: 1.5, minWidth: 180,
      valueGetter: (_value: unknown, row: Record<string, unknown>) =>
        row.supplierName || row.supplierCode || "",
    },
    {
      field: "issueDate",
      headerName: "Fecha",
      flex: 1,
      minWidth: 120,
      valueFormatter: (value: unknown) =>
        value ? formatDate(String(value), { timeZone }) : "",
    },
    {
      field: "documentType",
      headerName: "Tipo",
      width: 120,
      statusColors: {
        CONTADO: "success",
        CREDITO: "warning",
      },
    },
    {
      field: "status",
      headerName: "Estado",
      width: 130,
      statusColors: {
        DRAFT: "default",
        EMITIDA: "info",
        ANULADA: "error",
        RECIBIDA: "success",
        PARCIAL: "warning",
      },
    },
    {
      field: "totalAmount",
      headerName: "Total",
      flex: 0.8,
      minWidth: 120,
      type: "number",
      currency: true,
      aggregation: "sum",
    },
    buildCrudActionsColumn<Record<string, unknown>>({
      onView: (row) =>
        router.push(`/compras/${encodeURIComponent(String(row.documentNumber))}`),
      onEdit: (row) =>
        router.push(`/compras/${encodeURIComponent(String(row.documentNumber))}/edit`),
      onDelete: (row) => {
        setAnularRow(row);
        setAnularOpen(true);
      },
    }, { headerName: "Acciones" }),
  ];

  const handleAnularConfirm = () => {
    // TODO: integrar mutacion de anulacion cuando el endpoint exista
    setAnularOpen(false);
    setAnularRow(null);
  };

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Compras
        </Typography>
        <Button variant="contained" startIcon={<Add />} onClick={() => router.push("/compras/new")}>
          Nueva Compra
        </Button>
      </Box>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: "grid", gap: 1.5, gridTemplateColumns: { xs: "1fr", md: "2fr 1fr 1fr" } }}>
          <TextField
            label="Buscar"
            placeholder="Numero, proveedor, rif"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPaginationModel((p) => ({ ...p, page: 0 }));
            }}
            size="small"
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search fontSize="small" />
                </InputAdornment>
              ),
            }}
          />
          <DatePicker
            label="Desde"
            value={fechaDesde ? dayjs(fechaDesde) : null}
            onChange={(v) => {
              setFechaDesde(v ? v.format("YYYY-MM-DD") : "");
              setPaginationModel((p) => ({ ...p, page: 0 }));
            }}
            slotProps={{ textField: { size: "small", fullWidth: true } }}
          />
          <DatePicker
            label="Hasta"
            value={fechaHasta ? dayjs(fechaHasta) : null}
            onChange={(v) => {
              setFechaHasta(v ? v.format("YYYY-MM-DD") : "");
              setPaginationModel((p) => ({ ...p, page: 0 }));
            }}
            slotProps={{ textField: { size: "small", fullWidth: true } }}
          />
        </Box>
      </Paper>

      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        getRowId={(row) => row.documentNumber ?? row.id ?? Math.random()}
        rowCount={total}
        loading={isLoading}
        paginationMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[25, 50, 100]}
        disableRowSelectionOnClick
        autoHeight
        enableClipboard
        enableHeaderFilters
        showTotals
        sx={{ bgcolor: "background.paper", borderRadius: 2 }}
        mobileVisibleFields={["documentNumber", "supplierName"]}
        smExtraFields={["totalAmount", "status"]}
      />

      <ConfirmDialog
        open={anularOpen}
        onClose={() => { setAnularOpen(false); setAnularRow(null); }}
        onConfirm={handleAnularConfirm}
        title="Anular Compra"
        message={`Estas seguro de que deseas anular la compra ${anularRow?.documentNumber ?? ""}? Esta accion no se puede deshacer.`}
        confirmLabel="Anular"
        variant="danger"
      />
    </Box>
  );
}
