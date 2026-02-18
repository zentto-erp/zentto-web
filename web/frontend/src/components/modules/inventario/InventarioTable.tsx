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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  InputAdornment,
  Typography,
} from "@mui/material";
import { Add as AddIcon, Edit as EditIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { useInventarioList } from "@/hooks/useInventario";
import { debounce } from "lodash";

export default function InventarioTable() {
  const router = useRouter();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");

  const { data: inventario, isLoading } = useInventarioList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  // Debounced search
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

  const handlePageChange = (_: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleRowsPerPageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(e.target.value, 10));
    setPage(0);
  };

  const getStockColor = (stock: number, minimo: number): "error" | "warning" | "success" => {
    if (stock < minimo) return "error";
    if (stock < minimo * 1.5) return "warning";
    return "success";
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Inventario</Typography>
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
        placeholder="Buscar por código o nombre..."
        defaultValue=""
        onChange={handleSearchChange}
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

      {/* Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Código</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Artículo</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Stock Actual
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Stock Mínimo
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Stock Máximo
              </TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
              <TableCell align="center" sx={{ fontWeight: 600 }}>
                Acciones
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : !inventario?.data || inventario.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay registros de inventario
                </TableCell>
              </TableRow>
            ) : (
              inventario.data.map((item) => (
                <TableRow key={item.codigoArticulo} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{item.codigoArticulo}</TableCell>
                  <TableCell>{item.nombreArticulo}</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 500 }}>
                    {item.stock}
                  </TableCell>
                  <TableCell align="right">{item.stockMinimo}</TableCell>
                  <TableCell align="right">{item.stockMaximo}</TableCell>
                  <TableCell>
                    <Chip
                      label={item.stock < item.stockMinimo ? "Bajo" : "Normal"}
                      size="small"
                      color={getStockColor(item.stock, item.stockMinimo) as "error" | "warning" | "success"}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      onClick={() => router.push(`/inventario/${item.codigoArticulo}`)}
                      title="Ver"
                    >
                      <ViewIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {inventario && inventario.total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={inventario.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por página:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}
    </Box>
  );
}
