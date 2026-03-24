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
  MenuItem,
  Collapse,
  Paper,
  Badge,
  Stack,
  CircularProgress,
} from "@mui/material";
import {
  Add as AddIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
} from "@mui/icons-material";
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  ConfirmDialog,
} from "@zentto/shared-ui";
import {
  useFacturasList,
  useDeleteFactura,
  useDetalleFactura,
} from "../../../hooks/useFacturas";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";
import { debounce } from "lodash";

// ============ Componente selector reutilizable ============
function FilterSelect({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (val: string) => void;
}) {
  return (
    <TextField
      select
      label={label}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      size="small"
      sx={{ minWidth: 140, flex: 1 }}
    >
      <MenuItem value="">
        <em>Todos</em>
      </MenuItem>
      {options.map((o) => (
        <MenuItem key={o.value} value={o.value}>
          {o.label}
        </MenuItem>
      ))}
    </TextField>
  );
}

// ============ Master-detail: renglones de factura ============
const detailColumns: ZenttoColDef[] = [
  { field: "lineNumber", headerName: "#", width: 50 },
  { field: "codigo", headerName: "Codigo", width: 130 },
  { field: "descripcion", headerName: "Descripcion", flex: 1, minWidth: 200 },
  { field: "cantidad", headerName: "Cantidad", width: 100, type: "number" },
  { field: "precio", headerName: "Precio", width: 120, type: "number", currency: true },
  { field: "descuento", headerName: "Descuento", width: 110, type: "number", currency: true },
  { field: "total", headerName: "Total", width: 120, type: "number", currency: true, aggregation: "sum" },
];

function FacturaDetailPanel({ numeroFactura }: { numeroFactura: string }) {
  const { data: detalle, isLoading } = useDetalleFactura(numeroFactura);
  const rawRows = Array.isArray(detalle) ? detalle : [];

  const rows = useMemo(
    () =>
      rawRows.map((line: any, idx: number) => {
        const qty = Number(line.CANTIDAD ?? line.Quantity ?? 0);
        const price = Number(line.PRECIO ?? line.UnitPrice ?? 0);
        const discount = Number(line.DESCUENTO ?? line.DiscountAmount ?? 0);
        return {
          id: idx,
          lineNumber: idx + 1,
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

  if (isLoading) {
    return (
      <Box sx={{ p: 2, display: "flex", justifyContent: "center" }}>
        <CircularProgress size={24} />
      </Box>
    );
  }

  if (rows.length === 0) {
    return (
      <Box sx={{ p: 2 }}>
        <Typography variant="body2" color="text.secondary">
          Sin renglones de detalle
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 1.5, pl: 6 }}>
      <Typography variant="subtitle2" sx={{ mb: 1 }}>
        Detalle de {numeroFactura}
      </Typography>
      <ZenttoDataGrid
        gridId={`factura-detail-${numeroFactura}`}
        columns={detailColumns}
        rows={rows}
        density="compact"
        showTotals
        hideToolbar
        disableRowSelectionOnClick
        hideFooter
        sx={{ maxHeight: 300 }}
      />
    </Box>
  );
}

// ============ Opciones de estado ============
const ESTADO_OPTIONS = [
  { value: "Emitida", label: "Emitida" },
  { value: "Pagada", label: "Pagada" },
  { value: "Anulada", label: "Anulada" },
];

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [anularOpen, setAnularOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);

  // ========== Filtros ==========
  const [showFilters, setShowFilters] = useState(false);
  const [searchInput, setSearchInput] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [filterEstado, setFilterEstado] = useState("");
  const [filterCliente, setFilterCliente] = useState("");
  const [debouncedCliente, setDebouncedCliente] = useState("");
  const [filterFrom, setFilterFrom] = useState("");
  const [filterTo, setFilterTo] = useState("");

  // Debounced search
  const debouncedSetSearch = useCallback(
    debounce((value: string) => {
      setDebouncedSearch(value);
      setPage(0);
    }, 400),
    []
  );

  const debouncedSetCliente = useCallback(
    debounce((value: string) => {
      setDebouncedCliente(value);
      setPage(0);
    }, 400),
    []
  );

  // Contar filtros activos
  const activeFilterCount = useMemo(() => {
    let c = 0;
    if (debouncedSearch) c++;
    if (filterEstado) c++;
    if (debouncedCliente) c++;
    if (filterFrom) c++;
    if (filterTo) c++;
    return c;
  }, [debouncedSearch, filterEstado, debouncedCliente, filterFrom, filterTo]);

  const clearFilters = () => {
    setSearchInput("");
    setDebouncedSearch("");
    setFilterEstado("");
    setFilterCliente("");
    setDebouncedCliente("");
    setFilterFrom("");
    setFilterTo("");
    setPage(0);
  };

  const { data: facturas, isLoading } = useFacturasList({
    search: debouncedSearch || undefined,
    page: page + 1,
    limit: pageSize,
    estado: filterEstado || undefined,
    cliente: debouncedCliente || undefined,
    from: filterFrom || undefined,
    to: filterTo || undefined,
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
      {
        field: "numeroFactura",
        headerName: "Numero",
        width: 150,
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
          Emitida: "info",
          Anulada: "error",
          Cancelada: "default",
        },
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
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 2,
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

      {/* Search bar + Filter toggle */}
      <Box sx={{ display: "flex", gap: 1, mb: 1.5, alignItems: "center" }}>
        <TextField
          placeholder="Buscar por numero, cliente o referencia..."
          value={searchInput}
          onChange={(e) => {
            setSearchInput(e.target.value);
            debouncedSetSearch(e.target.value);
          }}
          fullWidth
          size="small"
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon fontSize="small" />
              </InputAdornment>
            ),
          }}
        />
        <Badge badgeContent={activeFilterCount} color="primary">
          <Button
            variant={showFilters ? "contained" : "outlined"}
            startIcon={<FilterIcon />}
            onClick={() => setShowFilters(!showFilters)}
            sx={{ whiteSpace: "nowrap" }}
          >
            Filtros
          </Button>
        </Badge>
        {activeFilterCount > 0 && (
          <Button
            size="small"
            startIcon={<ClearIcon />}
            onClick={clearFilters}
            color="error"
          >
            Limpiar ({activeFilterCount})
          </Button>
        )}
      </Box>

      {/* Panel de Filtros */}
      <Collapse in={showFilters}>
        <Paper variant="outlined" sx={{ p: 1.5, mb: 1.5 }}>
          <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap>
            {/* Cliente */}
            <TextField
              label="Cliente"
              value={filterCliente}
              onChange={(e) => {
                setFilterCliente(e.target.value);
                debouncedSetCliente(e.target.value);
              }}
              size="small"
              sx={{ minWidth: 200, flex: 1 }}
              placeholder="Nombre o codigo..."
            />
            {/* Estado */}
            <FilterSelect
              label="Estado"
              value={filterEstado}
              options={ESTADO_OPTIONS}
              onChange={(val) => {
                setFilterEstado(val);
                setPage(0);
              }}
            />
            {/* Fecha desde */}
            <TextField
              label="Fecha desde"
              type="date"
              value={filterFrom}
              onChange={(e) => {
                setFilterFrom(e.target.value);
                setPage(0);
              }}
              size="small"
              sx={{ minWidth: 155 }}
              InputLabelProps={{ shrink: true }}
            />
            {/* Fecha hasta */}
            <TextField
              label="Fecha hasta"
              type="date"
              value={filterTo}
              onChange={(e) => {
                setFilterTo(e.target.value);
                setPage(0);
              }}
              size="small"
              sx={{ minWidth: 155 }}
              InputLabelProps={{ shrink: true }}
            />
          </Stack>
        </Paper>
      </Collapse>

      {/* ZenttoDataGrid con master-detail */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        <ZenttoDataGrid
          gridId="facturas-table"
          columns={columns}
          rows={rows}
          loading={isLoading}
          enableClipboard
          showTotals
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
          exportFilename="facturas"
          hideQuickFilter
          getDetailContent={(row) => (
            <FacturaDetailPanel numeroFactura={row.numeroFactura} />
          )}
          detailPanelHeight="auto"
          mobileVisibleFields={["numeroFactura", "nombreCliente", "totalFactura"]}
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
