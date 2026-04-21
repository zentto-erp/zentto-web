// components/modules/inventario/InventarioTable.tsx
"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
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
  IconButton,
  Chip,
  InputAdornment,
  Typography,
  Tooltip,
} from "@mui/material";
import { Add as AddIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { useInventarioList } from "../../../hooks/useInventario";
import { formatCurrency } from "@zentto/shared-api";
import { debounce } from "lodash";

export default function InventarioTable() {
  const router = useRouter();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [search, setSearch] = useState("");

  const { data: inventario, isLoading } = useInventarioList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];
  const total = inventario?.total ?? 0;

  const debouncedSearch = useCallback(
    debounce((value: string) => {
      setSearch(value);
      setPage(0);
    }, 500),
    []
  );

  const getStockColor = (stock: number, minimo: number): "error" | "warning" | "success" => {
    if (minimo > 0 && stock < minimo) return "error";
    if (minimo > 0 && stock < minimo * 1.5) return "warning";
    return "success";
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "flex-end", alignItems: "center", mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/inventario/ajuste")}
        >
          Ajuste de Inventario
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por codigo, nombre, categoria..."
        defaultValue=""
        onChange={(e) => debouncedSearch(e.target.value)}
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

      {/* Table */}
      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Articulo</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Categoria</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Stock</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Minimo</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Costo</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Precio</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
              <TableCell align="center" sx={{ fontWeight: 600 }}>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay registros de inventario
                </TableCell>
              </TableRow>
            ) : (
              rows.map((item) => {
                const codigo = String(item.CODIGO ?? item.ProductCode ?? "");
                const nombre = String(item.DescripcionCompleta ?? item.DESCRIPCION ?? item.ProductName ?? "");
                const categoria = String(item.Categoria ?? "");
                const stock = Number(item.EXISTENCIA ?? item.StockQty ?? 0);
                const minimo = Number(item.MINIMO ?? item.StockMin ?? 0);
                const costo = Number(item.PRECIO_COMPRA ?? item.CostPrice ?? 0);
                const precio = Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0);

                return (
                  <TableRow key={codigo} hover>
                    <TableCell sx={{ fontWeight: 500 }}>{codigo}</TableCell>
                    <TableCell>{nombre}</TableCell>
                    <TableCell>{categoria}</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 500 }}>{stock}</TableCell>
                    <TableCell align="right">{minimo}</TableCell>
                    <TableCell align="right">{formatCurrency(costo)}</TableCell>
                    <TableCell align="right">{formatCurrency(precio)}</TableCell>
                    <TableCell>
                      <Chip
                        label={minimo > 0 && stock < minimo ? "Bajo" : "Normal"}
                        size="small"
                        color={getStockColor(stock, minimo)}
                        variant="outlined"
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Tooltip title="Ver detalle">
                        <IconButton
                          size="small"
                          onClick={() => router.push(`/inventario/${codigo}`)}
                        >
                          <ViewIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {total > 0 && (
        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(_, p) => setPage(p)}
          onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
          labelRowsPerPage="Filas por pagina:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}
    </Box>
  );
}
