// components/MovimientosTable.tsx
"use client";

import { useState, useCallback, useEffect, useRef } from "react";
import {
  Box, TextField, Paper, InputAdornment, Typography, IconButton, Alert, Tooltip,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SearchIcon from "@mui/icons-material/Search";
import ClearIcon from "@mui/icons-material/Clear";
import { useMovimientosList, useInventarioList } from "../hooks/useInventario";
import type { ColumnDef } from "@zentto/datagrid-core";
import { formatCurrency, toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

const ART_COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Código", width: 110, sortable: true },
  { field: "descripcion", header: "Artículo", flex: 1, sortable: true },
  { field: "stock", header: "Stock", width: 80, type: "number" },
];

const MOV_COLUMNS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 100 },
  { field: "codigo", header: "Código", width: 110, sortable: true },
  { field: "articulo", header: "Artículo", flex: 1, minWidth: 140, sortable: true },
  { field: "tipo", header: "Tipo", width: 100, statusColors: { ENTRADA: "success", SALIDA: "error", AJUSTE: "info", TRASLADO: "warning" }, statusVariant: "outlined" },
  { field: "cantidad", header: "Cantidad", width: 90, type: "number", aggregation: "sum" },
  { field: "costoUnit", header: "Costo Unit.", width: 120, type: "number", currency: "VES", aggregation: "avg" },
  { field: "total", header: "Total", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  { field: "almacen", header: "Almacén", width: 130 },
  { field: "referencia", header: "Referencia", width: 130 },
  { field: "notas", header: "Notas", flex: 1, minWidth: 150 },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 80,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view", color: "#6b7280" },
    ],
  },
];

const DETAIL_RENDERER = (row: any) => `
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr 1fr;gap:12px;padding:8px 16px;background:#fafafa">
    ${row._lote ? `<div><strong>Lote / Serie</strong><br/>${row._lote}</div>` : ''}
    ${row._usuario ? `<div><strong>Registrado por</strong><br/>${row._usuario}</div>` : ''}
    ${row._fechaCreacion ? `<div><strong>Fecha registro</strong><br/>${row._fechaCreacion}</div>` : ''}
    <div><strong>Almacén</strong><br/>${row.almacen || '—'}</div>
    <div><strong>Notas</strong><br/>${row.notas || '—'}</div>
  </div>
`;

const ARTICULOS_GRID_ID = "module-inventario:movimientos:articulos";
const MOVIMIENTOS_GRID_ID = "module-inventario:movimientos:list";

export default function MovimientosTable() {
  const artGridRef = useRef<any>(null);
  const movGridRef = useRef<any>(null);
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [search, setSearch] = useState("");
  const [movementType, setMovementType] = useState("");
  const [fechaDesde, setFechaDesde] = useState(() => { const d = new Date(); d.setDate(1); return toDateOnly(d, timeZone); });
  const [fechaHasta, setFechaHasta] = useState(() => toDateOnly(new Date(), timeZone));

  const [artSearch, setArtSearch] = useState("");
  const [selectedProductCode, setSelectedProductCode] = useState("");
  const { data: inventario, isLoading: artLoading } = useInventarioList({ search: artSearch, limit: 100 });
  const artRows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const debouncedArtSearch = useCallback(debounce((value: string) => setArtSearch(value), 400), []);
  const { ready: articulosLayoutReady } = useGridLayoutSync(ARTICULOS_GRID_ID);
  const { ready: movimientosLayoutReady } = useGridLayoutSync(MOVIMIENTOS_GRID_ID);
  const layoutReady = articulosLayoutReady && movimientosLayoutReady;
  const { gridReady, registered } = useInventarioGridRegistration(layoutReady);

  const { data: movimientos, isLoading } = useMovimientosList({
    search: search || undefined, productCode: selectedProductCode || undefined,
    movementType: movementType || undefined, fechaDesde, fechaHasta, page: page + 1, limit: rowsPerPage,
  });

  const rows = (movimientos?.rows ?? []) as Record<string, unknown>[];
  const total = movimientos?.total ?? 0;

  const artGridRows = artRows.map((item, i) => ({
    id: i, codigo: String(item.CODIGO ?? item.ProductCode ?? ""),
    descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
    stock: Number(item.EXISTENCIA ?? item.Stock ?? 0),
  }));

  const movGridRows = rows.map((m, i) => {
    const whFrom = String(m.WarehouseFrom ?? ""); const whTo = String(m.WarehouseTo ?? "");
    return {
      id: i, fecha: String(m.MovementDate ?? "").slice(0, 10), codigo: String(m.ProductCode ?? ""),
      articulo: String(m.ProductName ?? ""), tipo: String(m.MovementType ?? ""),
      cantidad: Number(m.Quantity ?? 0), costoUnit: Number(m.UnitCost ?? 0), total: Number(m.TotalCost ?? 0),
      almacen: whFrom && whTo ? `${whFrom} → ${whTo}` : whFrom || whTo || "",
      referencia: String(m.DocumentRef ?? ""), notas: String(m.Notes ?? ""),
      _lote: String(m.BatchNumber ?? ""), _usuario: String(m.CreatedBy ?? ""),
      _fechaCreacion: String(m.CreatedAt ?? "").slice(0, 19).replace("T", " "),
    };
  });

  useEffect(() => {
    const el = artGridRef.current; if (!el || !registered) return;
    el.columns = ART_COLUMNS; el.rows = artGridRows; el.loading = artLoading;
    el.getRowId = (r: any) => r.id;
  }, [artGridRows, artLoading, registered]);

  useEffect(() => {
    const el = artGridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => { if (e.detail?.row?.codigo) { setSelectedProductCode(String(e.detail.row.codigo)); setPage(0); } };
    el.addEventListener("row-click", handler);
    return () => el.removeEventListener("row-click", handler);
  }, [registered]);

  useEffect(() => {
    const el = movGridRef.current; if (!el || !registered) return;
    el.columns = MOV_COLUMNS; el.rows = movGridRows; el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
    el.detailRenderer = DETAIL_RENDERER;
  }, [movGridRows, isLoading, registered]);

  useEffect(() => {
    const el = movGridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") { /* TODO: ver detalle movimiento */ }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, movGridRows]);

  return (
    <Box sx={{ p: 2 }}>
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Artículos</Typography>
            <TextField placeholder="Buscar artículos..." onChange={(e) => debouncedArtSearch(e.target.value)} fullWidth sx={{ mb: 2 }}
              InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
            />
            <zentto-grid ref={artGridRef} grid-id={ARTICULOS_GRID_ID} height="350px" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, md: 8 }}>
          {selectedProductCode && (
            <Alert severity="info" sx={{ mb: 2 }}
              action={<Tooltip title="Limpiar filtro"><IconButton size="small" onClick={() => { setSelectedProductCode(""); setPage(0); }}><ClearIcon fontSize="small" /></IconButton></Tooltip>}
            >
              Filtrando movimientos de: <strong>{selectedProductCode}</strong>
            </Alert>
          )}

          <zentto-grid ref={movGridRef} grid-id={MOVIMIENTOS_GRID_ID} height="500px" default-currency="VES" export-filename="movimientos-inventario" show-totals
            enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-master-detail enable-configurator
          />
        </Grid>
      </Grid>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
