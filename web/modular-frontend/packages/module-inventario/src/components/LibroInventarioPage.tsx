// components/LibroInventarioPage.tsx
"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import {
  Box,
  Button,
  Paper,
  CircularProgress,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import DownloadIcon from "@mui/icons-material/Download";
import { useLibroInventario } from "../hooks/useInventario";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";
import type { ColumnDef } from "@zentto/datagrid-core";

const GRID_ID = "module-inventario:libro:list";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 120, sortable: true },
  { field: "articulo", header: "Articulo", flex: 1, minWidth: 200, sortable: true },
  { field: "unidad", header: "Unidad", width: 80 },
  { field: "stockInicial", header: "Stock Inicial", width: 110, type: "number", aggregation: "sum" },
  { field: "entradas", header: "Entradas", width: 100, type: "number", aggregation: "sum" },
  { field: "salidas", header: "Salidas", width: 100, type: "number", aggregation: "sum" },
  { field: "stockFinal", header: "Stock Final", width: 110, type: "number", aggregation: "sum" },
  { field: "costoUnit", header: "Costo Unit.", width: 120, type: "number", currency: "VES", aggregation: "avg" },
  { field: "valorTotal", header: "Valor Total", width: 130, type: "number", currency: "VES", aggregation: "sum" },
];

export default function LibroInventarioPage() {
  const gridRef = useRef<any>(null);
  const { timeZone } = useTimezone();
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return toDateOnly(d, timeZone);
  });
  const [fechaHasta, setFechaHasta] = useState(() => toDateOnly(new Date(), timeZone));
  const [filter, setFilter] = useState<{ fechaDesde: string; fechaHasta: string } | undefined>(undefined);

  const { ready } = useGridLayoutSync(GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  const { data, isLoading } = useLibroInventario(filter);
  const rows = (data?.rows ?? []) as Record<string, unknown>[];

  const handleGenerar = () => {
    setFilter({ fechaDesde, fechaHasta });
  };

  const gridRows = useMemo(() => rows.map((r, i) => {
    const stockFinal = Number(r.StockFinal ?? 0);
    const costoUnit = Number(r.CostoUnitario ?? 0);
    return {
      id: i,
      codigo: String(r.CODIGO ?? ""),
      articulo: String(r.DescripcionCompleta ?? r.DESCRIPCION ?? ""),
      unidad: String(r.Unidad ?? ""),
      stockInicial: Number(r.StockInicial ?? 0),
      entradas: Number(r.Entradas ?? 0),
      salidas: Number(r.Salidas ?? 0),
      stockFinal,
      costoUnit,
      valorTotal: stockFinal * costoUnit,
    };
  }), [rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, isLoading, registered]);

  const handleExportCsv = () => {
    if (rows.length === 0) return;
    const headers = ["Codigo", "Articulo", "Unidad", "Stock Inicial", "Entradas", "Salidas", "Stock Final", "Costo Unit.", "Valor Total"];
    const csvRows = rows.map((r) => [
      r.CODIGO, r.DescripcionCompleta ?? r.DESCRIPCION, r.Unidad ?? "",
      r.StockInicial, r.Entradas, r.Salidas, r.StockFinal, r.CostoUnitario,
      (Number(r.StockFinal ?? 0) * Number(r.CostoUnitario ?? 0)).toFixed(2),
    ].join(","));
    const csv = [headers.join(","), ...csvRows].join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `libro-inventario-${fechaDesde}-${fechaHasta}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 4 }}>
            <DatePicker
              label="Desde"
              value={fechaDesde ? dayjs(fechaDesde) : null}
              onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <DatePicker
              label="Hasta"
              value={fechaHasta ? dayjs(fechaHasta) : null}
              onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button variant="contained" onClick={handleGenerar} disabled={isLoading} startIcon={isLoading ? <CircularProgress size={18} /> : <MenuBookIcon />}>
                Generar
              </Button>
              {rows.length > 0 && (
                <Button variant="outlined" onClick={handleExportCsv} startIcon={<DownloadIcon />}>
                  CSV
                </Button>
              )}
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Resultado */}
      {!filter && (
        <Alert severity="info">Seleccione un rango de fechas y presione "Generar" para ver el libro de inventario.</Alert>
      )}

      {filter && isLoading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      )}

      {filter && !isLoading && rows.length === 0 && (
        <Alert severity="warning">No hay datos para el rango seleccionado.</Alert>
      )}

      {rows.length > 0 && (
        <zentto-grid
          ref={gridRef}
          grid-id={GRID_ID}
          height="calc(100vh - 320px)"
          default-currency="VES"
          export-filename={`libro-inventario-${fechaDesde}-${fechaHasta}`}
          show-totals
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
        />
      )}
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
