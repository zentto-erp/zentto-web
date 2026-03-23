// components/modules/abonos/AbonosaTable.tsx
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
  InputAdornment,
  Typography,
  Tooltip,
} from "@mui/material";
import { Add as AddIcon, Delete as DeleteIcon, Visibility as ViewIcon, Search as SearchIcon } from "@mui/icons-material";
import { useAbonosList, useDeleteAbono } from "../../../hooks/useAbonos";
import { formatCurrency, formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

export default function AbonosTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedAbono, setSelectedAbono] = useState<string | null>(null);

  const { data: abonos, isLoading } = useAbonosList({
    search,
    page: page + 1,
    limit: rowsPerPage,
  });

  const { mutate: deleteAbono, isPending: isDeleting } = useDeleteAbono();

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
    setSelectedAbono(numero);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = () => {
    if (selectedAbono) {
      deleteAbono(selectedAbono, {
        onSuccess: () => {
          setDeleteDialogOpen(false);
          setSelectedAbono(null);
        },
        onError: (err) => {
          console.error("Error deleting:", err);
          alert("Error al eliminar el abono");
        }
      });
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>Abonos</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/abonos/new")}
        >
          Nuevo Abono
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por número, cliente o factura..."
        defaultValue=""
        onChange={handleSearchChange}
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

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ fontWeight: 600 }}>Número Abono</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Cliente</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Factura</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>
                Monto
              </TableCell>
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
            ) : !abonos?.data || abonos.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay abonos registrados
                </TableCell>
              </TableRow>
            ) : (
              abonos.data.map((abono) => (
                <TableRow key={abono.numeroAbono} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{abono.numeroAbono}</TableCell>
                  <TableCell>{abono.nombreCliente}</TableCell>
                  <TableCell>{abono.numeroFactura}</TableCell>
                  <TableCell>{formatDate(abono.fecha, { timeZone })}</TableCell>
                  <TableCell align="right">{formatCurrency(abono.monto)}</TableCell>
                  <TableCell align="center">
                    <Tooltip title="Ver abono">
                      <IconButton
                        size="small"
                        onClick={() => router.push(`/abonos/${abono.numeroAbono}`)}
                      >
                        <ViewIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Eliminar abono">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleDeleteClick(abono.numeroAbono)}
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

      {abonos && abonos.total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={abonos.total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por página:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Eliminar Abono</DialogTitle>
        <DialogContent>
          ¿Estás seguro de que deseas eliminar este abono?
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
