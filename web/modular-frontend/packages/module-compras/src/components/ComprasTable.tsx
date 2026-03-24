"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Typography,
} from "@mui/material";
import { Add } from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  ConfirmDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import { useComprasList } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, formatDate } from "@zentto/shared-api";

const COMPRAS_FILTERS: FilterFieldDef[] = [
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "DRAFT", label: "Borrador" },
      { value: "EMITIDA", label: "Emitida" },
      { value: "RECIBIDA", label: "Recibida" },
      { value: "PARCIAL", label: "Parcial" },
      { value: "ANULADA", label: "Anulada" },
    ],
  },
  {
    field: "tipo",
    label: "Tipo",
    type: "select",
    options: [
      { value: "CONTADO", label: "Contado" },
      { value: "CREDITO", label: "Credito" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
  { field: "proveedor", label: "Proveedor", type: "text", placeholder: "Nombre del proveedor..." },
];

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
  const [filterValues, setFilterValues] = useState<Record<string, string>>({
    from: firstDayOfCurrentMonth(),
    to: lastDayOfCurrentMonth(),
  });
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 50 });

  // Anular dialog
  const [anularOpen, setAnularOpen] = useState(false);
  const [anularRow, setAnularRow] = useState<Record<string, unknown> | null>(null);

  const filter = useMemo(
    () => ({
      search: search.trim() || undefined,
      fechaDesde: filterValues.from || undefined,
      fechaHasta: filterValues.to || undefined,
      estado: filterValues.estado || undefined,
      tipo: filterValues.tipo || undefined,
      proveedor: filterValues.proveedor?.trim() || undefined,
      page: paginationModel.page + 1,
      limit: paginationModel.pageSize,
    }),
    [search, filterValues, paginationModel]
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

      <ZenttoFilterPanel
        filters={COMPRAS_FILTERS}
        values={filterValues}
        onChange={(v) => {
          setFilterValues(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        searchPlaceholder="Buscar por numero, proveedor, rif..."
        searchValue={search}
        onSearchChange={(v) => {
          setSearch(v);
          setPaginationModel((p) => ({ ...p, page: 0 }));
        }}
        defaultOpen
      />

      <ZenttoDataGrid
        gridId="compras-compras-list"
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
