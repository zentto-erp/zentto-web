// components/modules/facturas/FacturasTable.tsx
"use client";

import { useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Chip,
  Divider,
  Stack,
  Typography,
  CircularProgress,
} from "@mui/material";
import {
  Add as AddIcon,
  Receipt as ReceiptIcon,
} from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  ConfirmDialog,
  ZenttoFilterPanel,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import {
  useFacturasList,
  useDeleteFactura,
  useDetalleFactura,
} from "../../hooks/useFacturas";
import { useTimezone } from "../../hooks/useTimezone";
import { toDateOnly } from "@zentto/shared-api";
import { GridSidebar } from "../../components/GridSidebar";
import { buildPivotConfig, buildGroupingConfig, type LabConfig } from "../../components/LabConfigurator";

// ============ Master-detail estilo AG Grid ============
const detailColumns: ZenttoColDef[] = [
  { field: "codigo", headerName: "Codigo", width: 120 },
  { field: "descripcion", headerName: "Descripcion", flex: 1, minWidth: 200 },
  { field: "cantidad", headerName: "Cant.", width: 70, type: "number" },
  { field: "precio", headerName: "Precio", width: 110, type: "number", currency: true },
  { field: "descuento", headerName: "Desc.", width: 90, type: "number", currency: true },
  { field: "total", headerName: "Total", width: 120, type: "number", currency: true, aggregation: "sum" },
];

const STATUS_COLOR: Record<string, "success" | "error" | "info" | "warning" | "default"> = {
  Pagada: "success", Emitida: "info", Anulada: "error", Pendiente: "warning",
};

function FacturaDetailPanel({ row }: { row: any }) {
  const numeroFactura = row.numeroFactura;
  const { data: detalle, isLoading } = useDetalleFactura(numeroFactura);
  const rawRows = Array.isArray(detalle) ? detalle : [];

  const lines = useMemo(
    () =>
      rawRows.map((line: any, idx: number) => {
        const qty = Number(line.CANTIDAD ?? line.Quantity ?? 0);
        const price = Number(line.PRECIO ?? line.UnitPrice ?? 0);
        const discount = Number(line.DESCUENTO ?? line.DiscountAmount ?? 0);
        return {
          id: idx,
          codigo: line.COD_SERV ?? line.ItemCode ?? "",
          descripcion: line.DESCRIPCION ?? line.Description ?? "",
          cantidad: qty,
          precio: price,
          descuento: discount,
          total: Number(line.TOTAL ?? line.LineTotal ?? qty * price - discount),
        };
      }),
    [rawRows]
  );

  const fmt = (v: number) => new Intl.NumberFormat("es-VE", { minimumFractionDigits: 2 }).format(v);

  return (
    <Box sx={{ bgcolor: "#fafafa", borderBottom: "2px solid #e0e0e0" }}>
      {/* ── Header resumen (estilo AG Grid) ── */}
      <Stack
        direction="row"
        alignItems="center"
        spacing={2}
        sx={{ px: 3, py: 1.5, bgcolor: "#f5f5f5", borderBottom: "1px solid #eee" }}
      >
        <ReceiptIcon color="action" />
        <Box>
          <Typography variant="subtitle2" fontWeight={700}>{numeroFactura}</Typography>
          <Typography variant="caption" color="text.secondary">
            {row.nombreCliente || "Sin cliente"}
          </Typography>
        </Box>
        <Chip
          label={row.estado || "—"}
          size="small"
          color={STATUS_COLOR[row.estado] || "default"}
          variant="filled"
        />
        <Typography variant="body2" color="text.secondary">{row.fecha ? new Date(row.fecha).toLocaleDateString("es-VE") : ""}</Typography>
        <Box sx={{ flex: 1 }} />
        <Box sx={{ textAlign: "right" }}>
          <Typography variant="caption" color="text.secondary">Total</Typography>
          <Typography variant="subtitle2" fontWeight={700}>{fmt(Number(row.totalFactura || 0))} VES</Typography>
        </Box>
        <Typography variant="caption" color="text.secondary">
          {lines.length} item{lines.length !== 1 ? "s" : ""}
        </Typography>
      </Stack>

      {/* ── Tabla de lineas ── */}
      {isLoading ? (
        <Box sx={{ p: 2, display: "flex", justifyContent: "center" }}>
          <CircularProgress size={20} />
        </Box>
      ) : lines.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ p: 2, pl: 3 }}>
          Sin renglones
        </Typography>
      ) : (
        <Box sx={{ px: 2, pb: 1 }}>
          <ZenttoDataGrid
            gridId={`detail-${numeroFactura}`}
            columns={detailColumns}
            rows={lines}
            density="compact"
            showTotals
            hideToolbar
            disableRowSelectionOnClick
            hideFooter
            sx={{
              border: "none",
              "& .MuiDataGrid-columnHeaders": { bgcolor: "#f0f0f0", fontSize: "0.75rem" },
              "& .MuiDataGrid-cell": { fontSize: "0.8rem" },
            }}
          />
        </Box>
      )}
    </Box>
  );
}

// ============ Definicion de filtros ============
const FACTURA_FILTERS: FilterFieldDef[] = [
  {
    field: "cliente",
    label: "Cliente",
    type: "text",
    placeholder: "Nombre o codigo...",
  },
  {
    field: "estado",
    label: "Estado",
    type: "select",
    options: [
      { value: "Emitida", label: "Emitida" },
      { value: "Pagada", label: "Pagada" },
      { value: "Anulada", label: "Anulada" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [anularOpen, setAnularOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);

  // Configurador lab
  const [labConfig, setLabConfig] = useState<LabConfig>({
    pivotEnabled: true, pivotRowField: "nombreCliente", pivotColField: "estado",
    pivotValueField: "totalFactura", pivotAgg: "sum", pivotGrandTotals: true, pivotRowTotals: true,
    groupingEnabled: true, groupField: "estado", groupSubtotals: true, groupSort: "asc",
    headerFilters: true, showTotals: true, clipboard: true, columnGroups: true, pinning: true,
    pinnedLeft: ["numeroFactura"], pinnedRight: ["actions"],
  });

  const FACTURA_FIELDS = [
    { value: "nombreCliente", label: "Cliente" },
    { value: "estado", label: "Estado" },
    { value: "tipoDoc", label: "Tipo" },
    { value: "fecha", label: "Fecha" },
    { value: "numeroFactura", label: "Numero" },
  ];
  const FACTURA_NUMERIC = [{ value: "totalFactura", label: "Total" }];

  // Filtros (manejados por ZenttoFilterPanel)
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});

  const handleFilterChange = (vals: Record<string, string>) => {
    setFilterValues(vals);
    setPage(0);
  };

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setPage(0);
  };

  const { data: facturas, isLoading } = useFacturasList({
    search: search || undefined,
    page: page + 1,
    limit: pageSize,
    estado: filterValues.estado || undefined,
    cliente: filterValues.cliente || undefined,
    from: filterValues.from || undefined,
    to: filterValues.to || undefined,
  });

  const { mutate: deleteFactura, isPending: isDeleting } = useDeleteFactura();

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
      { field: "numeroFactura", headerName: "Numero", width: 150, sortable: true },
      { field: "nombreCliente", headerName: "Cliente", flex: 1, minWidth: 180, sortable: true, mobileHide: true },
      {
        field: "fecha", headerName: "Fecha", width: 120, sortable: true,
        valueFormatter: (value: string) => value ? toDateOnly(value, timeZone) : "",
      },
      {
        field: "tipoDoc", headerName: "Tipo", width: 110, tabletHide: true,
        statusColors: { FACT: "primary", PRESUP: "info", PEDIDO: "warning" },
        statusVariant: "outlined",
      },
      { field: "totalFactura", headerName: "Total", width: 140, type: "number", currency: true, aggregation: "sum" },
      {
        field: "estado", headerName: "Estado", width: 120,
        statusColors: { Pagada: "success", Pendiente: "warning", Emitida: "info", Anulada: "error", Cancelada: "default" },
        statusVariant: "outlined",
      },
      buildCrudActionsColumn({
        onView: (row) => router.push(`/facturas/${row.numeroFactura}`),
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
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" fontWeight={600}>
          Facturas
        </Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/facturas/new")}>
          Nueva Factura
        </Button>
      </Box>

      {/* Filtros reutilizables */}
      <ZenttoFilterPanel
        filters={FACTURA_FILTERS}
        values={filterValues}
        onChange={handleFilterChange}
        searchPlaceholder="Buscar por numero, cliente o referencia..."
        searchValue={search}
        onSearchChange={handleSearchChange}
      />

      {/* Grid + Sidebar integrado estilo AG Grid */}
      <GridSidebar config={labConfig} onChange={setLabConfig} fields={FACTURA_FIELDS} numericFields={FACTURA_NUMERIC}>
        <ZenttoDataGrid
          gridId="lab-facturas"
          columns={columns}
          rows={rows}
          loading={isLoading}
          paginationMode="server"
          rowCount={facturas?.total ?? 0}
          serverRowCount={facturas?.total ?? 0}
          paginationModel={{ page, pageSize }}
          onPaginationModelChange={(model) => {
            setPage(model.page);
            setPageSize(model.pageSize);
          }}
          pageSizeOptions={[10, 25, 50, 100]}
          density="comfortable"
          // ─── Funciones controladas por el configurador ──────
          enableClipboard={labConfig.clipboard}
          enableHeaderFilters={labConfig.headerFilters}
          showTotals={labConfig.showTotals}
          totalsLabel="Totales"
          defaultCurrency="VES"
          enableGrouping={labConfig.groupingEnabled}
          rowGroupingConfig={buildGroupingConfig(labConfig)}
          enablePivot={labConfig.pivotEnabled}
          pivotConfig={buildPivotConfig(labConfig, FACTURA_FIELDS)}
          columnGroups={labConfig.columnGroups ? [
            { groupId: "documento", headerName: "Documento", children: ["numeroFactura", "tipoDoc", "estado"] },
            { groupId: "comercial", headerName: "Comercial", children: ["nombreCliente", "totalFactura"] },
            { groupId: "fechas", headerName: "Fechas", children: ["fecha"] },
          ] : undefined}
          pinnedColumns={labConfig.pinning ? { left: ["numeroFactura"], right: ["actions"] } : undefined}
          // Master-Detail
          getDetailContent={(row) => (
            <FacturaDetailPanel row={row} />
          )}
          detailPanelHeight="auto"
          // Nuevas features
          enableContextMenu
          enableFind
          enableStatusBar
          // Export
          exportFilename="lab-facturas"
          hideQuickFilter
          mobileVisibleFields={["numeroFactura", "nombreCliente", "totalFactura"]}
          sx={{ height: "100%" }}
        />
      </GridSidebar>

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
