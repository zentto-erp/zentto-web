// components/modules/facturas/FacturasTable.tsx
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
import { Add as AddIcon, Edit as EditIcon, Delete as DeleteIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { useFacturasList, useDeleteFactura } from "../../../hooks/useFacturas";
import { formatCurrency, formatDate } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";
import { debounce } from "lodash";

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);

  const { data: facturas, isLoading } = useFacturasList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: deleteFactura, isPending: isDeleting } = useDeleteFactura();

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

  const handleDeleteClick = (numero: string) => {
    setSelectedFactura(numero);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedFactura) {
      deleteFactura(selectedFactura, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedFactura(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
          alert("Error al eliminar la factura");
        }
      });
    }
  };

  const getStatusColor = (estado: string): "success" | "warning" | "error" | "info" | "default" => {
    const colorMap: Record<string, "success" | "warning" | "error" | "info" | "default"> = {
      "Pagada": "success",
      "Pendiente": "warning",
      "Cancelada": "error",
      "Anulada": "error",
      "Crédito": "info",
    };
    return colorMap[estado] || "default";
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Facturas</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/facturas/new")}
        >
          Nueva Factura
        </Button>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por número, cliente o referencia..."
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
              <TableCell sx={{ fontWeight: 600 }}>Número</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Cliente</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Monto
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
                <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : !facturas?.data || facturas.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay facturas disponibles
                </TableCell>
              </TableRow>
            ) : (
              facturas.data.map((factura) => (
                <TableRow key={factura.numeroFactura} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{factura.numeroFactura}</TableCell>
                  <TableCell>{factura.nombreCliente}</TableCell>
                  <TableCell>{formatDate(factura.fecha, { timeZone })}</TableCell>
                  <TableCell align="right">{formatCurrency(factura.totalFactura)}</TableCell>
                  <TableCell>
                    <Chip
                      label={factura.estado}
                      size="small"
                      color={getStatusColor(factura.estado)}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      onClick={() => router.push(`/facturas/${factura.numeroFactura}`)}
                      title="Ver"
                    >
                      <ViewIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={() => router.push(`/facturas/${factura.numeroFactura}/edit`)}
                      title="Editar"
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDeleteClick(factura.numeroFactura)}
                      title="Eliminar"
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {facturas && facturas.total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={facturas.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por página:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Eliminar Factura</DialogTitle>
        <DialogContent>
          ¿Estás seguro de que deseas eliminar esta factura? Esta acción no puede deshacerse.
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancelar</Button>
          <Button
            onClick={handleConfirmDelete}
            color="error"
            variant="contained"
            disabled={isDeleting}
          >
            {isDeleting ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
