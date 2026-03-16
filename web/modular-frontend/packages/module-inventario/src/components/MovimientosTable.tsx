// components/MovimientosTable.tsx
"use client";

import { useState, useCallback } from "react";
import {
  Box,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Paper,
  CircularProgress,
  Chip,
  InputAdornment,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SearchIcon from "@mui/icons-material/Search";
import ClearIcon from "@mui/icons-material/Clear";
import { useMovimientosList, useInventarioList } from "../hooks/useInventario";
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
  const { data: inventario, isLoading: artLoading } = useInventarioList({ search: artSearch, limit: 20 });
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

  const getTypeColor = (type: string) => {
    switch (type) {
      case "ENTRADA": return "success";
      case "SALIDA": return "error";
      case "AJUSTE": return "info";
      case "TRASLADO": return "warning";
      default: return "default";
    }
  };

  const selectArticle = (codigo: string) => {
    setSelectedProductCode(codigo);
    setPage(0);
  };

  const clearArticleFilter = () => {
    setSelectedProductCode("");
    setPage(0);
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
        Movimientos de Inventario
      </Typography>

      <Grid container spacing={3}>
        {/* Left: Article browser */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Artículos
            </Typography>
            <TextField
              placeholder="Buscar artículos..."
              onChange={(e) => debouncedArtSearch(e.target.value)}
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

            {artLoading && (
              <Box sx={{ textAlign: "center", py: 2 }}>
                <CircularProgress size={24} />
              </Box>
            )}

            {!artLoading && artRows.length > 0 && (
              <TableContainer sx={{ maxHeight: 500 }}>
                <Table size="small" stickyHeader>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Código</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Artículo</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>Stock</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {artRows.map((item, i) => {
                      const codigo = String(item.CODIGO ?? item.ProductCode ?? "");
                      const isActive = selectedProductCode === codigo;
                      return (
                        <TableRow
                          key={i}
                          hover
                          selected={isActive}
                          onClick={() => selectArticle(codigo)}
                          sx={{ cursor: "pointer" }}
                        >
                          <TableCell sx={{ fontWeight: 500 }}>{codigo}</TableCell>
                          <TableCell sx={{ maxWidth: 180, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                            {String(item.DescripcionCompleta ?? item.DESCRIPCION ?? "")}
                          </TableCell>
                          <TableCell align="right">
                            <Chip
                              label={Number(item.EXISTENCIA ?? item.Stock ?? 0)}
                              size="small"
                              color={Number(item.EXISTENCIA ?? item.Stock ?? 0) > 0 ? "success" : "error"}
                              variant="outlined"
                            />
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            {!artLoading && !artSearch && artRows.length === 0 && (
              <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: "center" }}>
                Escriba para buscar artículos...
              </Typography>
            )}
          </Paper>
        </Grid>

        {/* Right: Movements */}
        <Grid size={{ xs: 12, md: 8 }}>
          {/* Active article filter chip */}
          {selectedProductCode && (
            <Alert
              severity="info"
              sx={{ mb: 2 }}
              action={
                <IconButton size="small" onClick={clearArticleFilter}>
                  <ClearIcon fontSize="small" />
                </IconButton>
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
                  size="small"
                  InputProps={{
                    startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment>,
                  }}
                />
              </Grid>
              <Grid size={{ xs: 6, sm: 2 }}>
                <FormControl fullWidth size="small">
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
              <Grid size={{ xs: 6, sm: 3 }}>
                <TextField
                  label="Desde"
                  type="date"
                  value={fechaDesde}
                  onChange={(e) => { setFechaDesde(e.target.value); setPage(0); }}
                  fullWidth
                  size="small"
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid size={{ xs: 6, sm: 3 }}>
                <TextField
                  label="Hasta"
                  type="date"
                  value={fechaHasta}
                  onChange={(e) => { setFechaHasta(e.target.value); setPage(0); }}
                  fullWidth
                  size="small"
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
            </Grid>
          </Paper>

          {/* Tabla de movimientos */}
          <TableContainer component={Paper}>
            <Table size="small">
              <TableHead>
                <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
                  <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Código</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Artículo</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Tipo</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600 }}>Cantidad</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600 }}>Costo Unit.</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600 }}>Total</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Almacén</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Referencia</TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>Notas</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center" sx={{ py: 4 }}>
                      <CircularProgress size={40} />
                    </TableCell>
                  </TableRow>
                ) : rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={10} align="center" sx={{ py: 4, color: "text.secondary" }}>
                      No hay movimientos en el rango seleccionado
                    </TableCell>
                  </TableRow>
                ) : (
                  rows.map((m, i) => {
                    const type = String(m.MovementType ?? "");
                    const whFrom = String(m.WarehouseFrom ?? "");
                    const whTo = String(m.WarehouseTo ?? "");
                    const warehouse = whFrom && whTo ? `${whFrom} → ${whTo}` : whFrom || whTo || "";

                    return (
                      <TableRow key={i} hover>
                        <TableCell>{String(m.MovementDate ?? "").slice(0, 10)}</TableCell>
                        <TableCell sx={{ fontWeight: 500 }}>{String(m.ProductCode ?? "")}</TableCell>
                        <TableCell>{String(m.ProductName ?? "")}</TableCell>
                        <TableCell>
                          <Chip label={type} size="small" color={getTypeColor(type) as "success" | "error" | "info" | "warning" | "default"} variant="outlined" />
                        </TableCell>
                        <TableCell align="right" sx={{ fontWeight: 500 }}>{Number(m.Quantity ?? 0)}</TableCell>
                        <TableCell align="right">{formatCurrency(Number(m.UnitCost ?? 0))}</TableCell>
                        <TableCell align="right">{formatCurrency(Number(m.TotalCost ?? 0))}</TableCell>
                        <TableCell>{warehouse}</TableCell>
                        <TableCell>{String(m.DocumentRef ?? "")}</TableCell>
                        <TableCell sx={{ maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                          {String(m.Notes ?? "")}
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </TableContainer>

          {total > 0 && (
            <TablePagination
              rowsPerPageOptions={[10, 25, 50, 100]}
              component="div"
              count={total}
              rowsPerPage={rowsPerPage}
              page={page}
              onPageChange={(_, p) => setPage(p)}
              onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
              labelRowsPerPage="Filas por página:"
              labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
            />
          )}
        </Grid>
      </Grid>
    </Box>
  );
}
