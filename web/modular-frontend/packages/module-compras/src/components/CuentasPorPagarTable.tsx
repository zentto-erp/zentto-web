// components/CuentasPorPagarTable.tsx
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
import { Add as AddIcon, Delete as DeleteIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { useCuentasPorPagarList, useDeleteCuentaPorPagar } from "../hooks/useCuentasPorPagar";
import { formatCurrency, formatDate } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";
import { debounce } from "lodash";

export default function CuentasPorPagarTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedCuenta, setSelectedCuenta] = useState<string | null>(null);

  const { data: cuentas, isLoading } = useCuentasPorPagarList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: deleteCuenta, isPending: isDeleting } = useDeleteCuentaPorPagar();

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

  const handleDeleteClick = (id: string) => {
    setSelectedCuenta(id);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedCuenta) {
      deleteCuenta(selectedCuenta, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedCuenta(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
          alert("Error al eliminar la cuenta");
        }
      });
    }
  };

  const getStatusColor = (estado: string): "success" | "warning" | "error" | "default" => {
    const colorMap: Record<string, "success" | "warning" | "error" | "default"> = {
      "Pagada": "success",
      "Pendiente": "warning",
      "Vencida": "error",
      "Parcial": "warning",
    };
    return colorMap[estado] || "default";
  };

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Cuentas por Pagar</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/cuentas-por-pagar/new")}
        >
          Nueva Cuenta
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por proveedor, numero o referencia..."
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
              <TableCell sx={{ fontWeight: 600 }}>Proveedor</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Numero Ref.</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Vencimiento</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Monto
              </TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Saldo
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
                <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : !cuentas?.data || cuentas.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay cuentas por pagar
                </TableCell>
              </TableRow>
            ) : (
              cuentas.data.map((cuenta) => (
                <TableRow key={cuenta.id} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{cuenta.nombreProveedor}</TableCell>
                  <TableCell>{cuenta.numeroReferencia}</TableCell>
                  <TableCell>{formatDate(cuenta.fechaCreacion, { timeZone })}</TableCell>
                  <TableCell>{formatDate(cuenta.fechaVencimiento, { timeZone })}</TableCell>
                  <TableCell align="right">{formatCurrency(cuenta.montoTotal)}</TableCell>
                  <TableCell align="right" sx={{ color: cuenta.saldo > 0 ? "error.main" : "success.main" }}>
                    {formatCurrency(cuenta.saldo)}
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={cuenta.estado}
                      size="small"
                      color={getStatusColor(cuenta.estado)}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      onClick={() => router.push(`/cuentas-por-pagar/${cuenta.id}`)}
                      title="Ver"
                    >
                      <ViewIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDeleteClick(cuenta.id)}
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

      {cuentas && cuentas.total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={cuentas.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por pagina:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Eliminar Cuenta</DialogTitle>
        <DialogContent>
          Estas seguro de que deseas eliminar esta cuenta por pagar?
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
