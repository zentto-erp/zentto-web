// components/MovimientosTable.tsx
"use client";

import { useState, useCallback } from "react";
import {
  Box,
  TextField,
  Paper,
  Chip,
  InputAdornment,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Alert,
  Stack,
  Tooltip,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SearchIcon from "@mui/icons-material/Search";
import ClearIcon from "@mui/icons-material/Clear";
import { useMovimientosList, useInventarioList } from "../hooks/useInventario";
import { DatePicker, ZenttoDataGrid } from "@zentto/shared-ui";
import type { ZenttoColDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

export default function MovimientosTable() {
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [search, setSearch] = useState("");
  const [movementType, setMovementType] = useState("");
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return toDateOnly(d, timeZone);
  });
  const [fechaHasta, setFechaHasta] = useState(() => toDateOnly(new Date(), timeZone));

  // Article browser
  const [artSearch, setArtSearch] = useState("");
  const [selectedProductCode, setSelectedProductCode] = useState("");
  const { data: inventario, isLoading: artLoading } = useInventarioList({ search: artSearch, limit: 100 });
  const artRows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const debouncedArtSearch = useCallback(
    debounce((value: string) => setArtSearch(value), 400),
    []
  );

  // Movements query
  const { data: movimientos, isLoading } = useMovimientosList({
    search: search || undefined,
    productCode: selectedProductCode || undefined,
    movementType: movementType || undefined,
    fechaDesde,
    fechaHasta,
    page: page + 1,
    limit: rowsPerPage,
  });

  const rows = (movimientos?.rows ?? []) as Record<string, unknown>[];
  const total = movimientos?.total ?? 0;

  const debouncedSearch = useCallback(
    debounce((value: string) => { setSearch(value); setPage(0); }, 500),
    []
  );

  const getTypeColor = (type: string): "success" | "error" | "info" | "warning" | "default" => {
    switch (type) {
      case "ENTRADA": return "success";
      case "SALIDA": return "error";
      case "AJUSTE": return "info";
      case "TRASLADO": return "warning";
      default: return "default";
    }
  };

  // ─── Columnas: Panel izquierdo (Artículos) ──────────────────────────
  const artColumns: ZenttoColDef[] = [
    { field: "codigo", headerName: "Código", width: 110 },
    { field: "descripcion", headerName: "Artículo", flex: 1 },
    {
      field: "stock", headerName: "Stock", width: 80, type: "number",
      renderCell: (p) => (
        <Chip
          label={p.value as number}
          size="small"
          color={(p.value as number) > 0 ? "success" : "error"}
          variant="outlined"
        />
      ),
    },
  ];

  const artGridRows = artRows.map((item, i) => ({
    id: i,
    codigo: String(item.CODIGO ?? item.ProductCode ?? ""),
    descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
    stock: Number(item.EXISTENCIA ?? item.Stock ?? 0),
  }));

  // ─── Columnas: Movimientos ───────────────────────────────────────────
  const movColumns: ZenttoColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "codigo", headerName: "Código", width: 110 },
    { field: "articulo", headerName: "Artículo", flex: 1, minWidth: 140 },
    {
      field: "tipo", headerName: "Tipo", width: 100,
      renderCell: (p) => (
        <Chip label={p.value as string} size="small" color={getTypeColor(p.value as string)} variant="outlined" />
      ),
    },
    { field: "cantidad", headerName: "Cantidad", width: 90, type: "number", aggregation: "sum" },
    { field: "costoUnit", headerName: "Costo Unit.", width: 120, type: "number", currency: "VES", aggregation: "avg" },
    { field: "total", headerName: "Total", width: 120, type: "number", currency: "VES", aggregation: "sum" },
    { field: "almacen", headerName: "Almacén", width: 130 },
    { field: "referencia", headerName: "Referencia", width: 130 },
    { field: "notas", headerName: "Notas", flex: 1, minWidth: 150 },
  ];

  const movGridRows = rows.map((m, i) => {
    const whFrom = String(m.WarehouseFrom ?? "");
    const whTo = String(m.WarehouseTo ?? "");
    return {
      id: i,
      fecha: String(m.MovementDate ?? "").slice(0, 10),
      codigo: String(m.ProductCode ?? ""),
      articulo: String(m.ProductName ?? ""),
      tipo: String(m.MovementType ?? ""),
      cantidad: Number(m.Quantity ?? 0),
      costoUnit: Number(m.UnitCost ?? 0),
      total: Number(m.TotalCost ?? 0),
      almacen: whFrom && whTo ? `${whFrom} → ${whTo}` : whFrom || whTo || "",
      referencia: String(m.DocumentRef ?? ""),
      notas: String(m.Notes ?? ""),
      // Extra para master-detail
      _lote: String(m.BatchNumber ?? ""),
      _usuario: String(m.CreatedBy ?? ""),
      _fechaCreacion: String(m.CreatedAt ?? "").slice(0, 19).replace("T", " "),
    };
  });

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
        Movimientos de Inventario
      </Typography>

      <Grid container spacing={3}>
        {/* ── Panel izquierdo: Artículos ── */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Artículos
            </Typography>
            <TextField
              placeholder="Buscar artículos..."
              onChange={(e) => debouncedArtSearch(e.target.value)}
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
            <ZenttoDataGrid
              gridId="inventario-articulos-browser"
              rows={artGridRows}
              columns={artColumns}
              loading={artLoading}
              hideToolbar
              autoHeight
              hideFooter
              onRowClick={(p) => {
                setSelectedProductCode(String(p.row.codigo));
                setPage(0);
              }}
              getRowClassName={(p) =>
                String(p.row.codigo) === selectedProductCode ? "Mui-selected" : ""
              }
              sx={{ cursor: "pointer" }}
              localeText={{ noRowsLabel: "Escriba para buscar artículos..." }}
            />
          </Paper>
        </Grid>

        {/* ── Panel derecho: Movimientos ── */}
        <Grid size={{ xs: 12, md: 8 }}>
          {selectedProductCode && (
            <Alert
              severity="info"
              sx={{ mb: 2 }}
              action={
                <Tooltip title="Limpiar filtro">
                  <IconButton size="small" onClick={() => { setSelectedProductCode(""); setPage(0); }}>
                    <ClearIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              }
            >
              Filtrando movimientos de: <strong>{selectedProductCode}</strong>
            </Alert>
          )}

          {/* Filtros */}
          <Paper sx={{ p: 2, mb: 2 }}>
            <Grid container spacing={2} alignItems="center">
              <Grid size={{ xs: 12, sm: 4 }}>
                <TextField
                  placeholder="Buscar por referencia, notas..."
                  onChange={(e) => debouncedSearch(e.target.value)}
                  fullWidth
                  InputProps={{
                    startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment>,
                  }}
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 2 }}>
                <FormControl fullWidth>
                  <InputLabel>Tipo</InputLabel>
                  <Select value={movementType} label="Tipo" onChange={(e) => { setMovementType(e.target.value); setPage(0); }}>
                    <MenuItem value="">Todos</MenuItem>
                    <MenuItem value="ENTRADA">Entrada</MenuItem>
                    <MenuItem value="SALIDA">Salida</MenuItem>
                    <MenuItem value="AJUSTE">Ajuste</MenuItem>
                    <MenuItem value="TRASLADO">Traslado</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid size={{ xs: 12, sm: 3 }}>
                <DatePicker
                  label="Desde"
                  value={fechaDesde ? dayjs(fechaDesde) : null}
                  onChange={(v) => { setFechaDesde(v ? v.format("YYYY-MM-DD") : ""); setPage(0); }}
                  slotProps={{ textField: { size: "small", fullWidth: true } }}
                />
              </Grid>
              <Grid size={{ xs: 12, sm: 3 }}>
                <DatePicker
                  label="Hasta"
                  value={fechaHasta ? dayjs(fechaHasta) : null}
                  onChange={(v) => { setFechaHasta(v ? v.format("YYYY-MM-DD") : ""); setPage(0); }}
                  slotProps={{ textField: { size: "small", fullWidth: true } }}
                />
              </Grid>
            </Grid>
          </Paper>

          {/* Tabla de movimientos con master-detail y pivot */}
          <ZenttoDataGrid
            gridId="inventario-movimientos"
            rows={movGridRows}
            columns={movColumns as ZenttoColDef[]}
            loading={isLoading}
            enableHeaderFilters
            exportFilename="movimientos-inventario"
            showTotals
            defaultCurrency="VES"
            // Paginación server-side
            paginationMode="server"
            rowCount={total}
            paginationModel={{ page, pageSize: rowsPerPage }}
            onPaginationModelChange={(m) => { setPage(m.page); setRowsPerPage(m.pageSize); }}
            pageSizeOptions={[10, 25, 50, 100]}
            // Master-detail: expande fila para ver lote, usuario, fecha creación
            getDetailContent={(row) => (
              <Box sx={{ px: 3, py: 2, bgcolor: "background.default" }}>
                <Stack direction="row" spacing={4}>
                  {!!row._lote && (
                    <Box>
                      <Typography variant="caption" color="text.secondary">Lote / Serie</Typography>
                      <Typography variant="body2" fontWeight={600}>{String(row._lote)}</Typography>
                    </Box>
                  )}
                  {!!row._usuario && (
                    <Box>
                      <Typography variant="caption" color="text.secondary">Registrado por</Typography>
                      <Typography variant="body2" fontWeight={600}>{String(row._usuario)}</Typography>
                    </Box>
                  )}
                  {!!row._fechaCreacion && (
                    <Box>
                      <Typography variant="caption" color="text.secondary">Fecha registro</Typography>
                      <Typography variant="body2" fontWeight={600}>{String(row._fechaCreacion)}</Typography>
                    </Box>
                  )}
                  <Box>
                    <Typography variant="caption" color="text.secondary">Almacén</Typography>
                    <Typography variant="body2" fontWeight={600}>{String(row.almacen || "—")}</Typography>
                  </Box>
                  <Box>
                    <Typography variant="caption" color="text.secondary">Notas</Typography>
                    <Typography variant="body2">{String(row.notas || "—")}</Typography>
                  </Box>
                </Stack>
              </Box>
            )}
            // Pivot: cantidad y total por tipo de movimiento por artículo
            pivotConfig={{
              rowField: "codigo",
              columnField: "tipo",
              valueField: "total",
              aggregation: "sum",
              rowFieldHeader: "Artículo",
              valueFormatter: (v) => formatCurrency(v),
            }}
          />
        </Grid>
      </Grid>
    </Box>
  );
}
