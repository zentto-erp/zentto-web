// components/modules/pagos/PagosTable.tsx
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
  Tooltip,
} from "@mui/material";
import { Add as AddIcon, Delete as DeleteIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { usePagosList, useDeletePago } from "../../../hooks/usePagos";
import { formatCurrency, formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

export default function PagosTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedPago, setSelectedPago] = useState<string | null>(null);

  const { data: pagos, isLoading } = usePagosList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: deletePago, isPending: isDeleting } = useDeletePago();

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
    setSelectedPago(numero);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedPago) {
      deletePago(selectedPago, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedPago(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
          alert("Error al eliminar el pago");
        }
      });
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Pagos</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/pagos/new")}
        >
          Nuevo Pago
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por número, cliente/proveedor..."
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

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Número</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Entidad</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Monto
              </TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Método</TableCell>
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
            ) : !pagos?.data || pagos.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay pagos registrados
                </TableCell>
              </TableRow>
            ) : (
              pagos.data.map((pago) => (
                <TableRow key={pago.numeroPago} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{pago.numeroPago}</TableCell>
                  <TableCell>{pago.nombre}</TableCell>
                  <TableCell>{formatDate(pago.fecha, { timeZone })}</TableCell>
                  <TableCell align="right">{formatCurrency(pago.monto)}</TableCell>
                  <TableCell>
                    <Chip
                      label={pago.metodoPago}
                      size="small"
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Tooltip title="Ver pago">
                      <IconButton
                        size="small"
                        onClick={() => router.push(`/pagos/${pago.numeroPago}`)}
                      >
                        <ViewIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Eliminar pago">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleDeleteClick(pago.numeroPago)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {pagos && pagos.total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={pagos.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por página:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Eliminar Pago</DialogTitle>
        <DialogContent>
          ¿Estás seguro de que deseas eliminar este pago?
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
