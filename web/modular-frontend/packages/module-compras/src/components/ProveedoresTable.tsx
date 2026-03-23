// components/ProveedoresTable.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  CircularProgress,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Pagination,
  Paper,
  Toolbar,
  Typography,
  Tooltip,
} from "@mui/material";
import { Edit as EditIcon, Delete as DeleteIcon, Visibility as ViewIcon, Add as AddIcon } from "@mui/icons-material";
import { useProveedoresList, useDeleteProveedor } from "../hooks/useProveedores";
import { Proveedor, ProveedorFilter } from "@zentto/shared-api/types";

export default function ProveedoresTable() {
  const router = useRouter();
  const [filter, setFilter] = useState<ProveedorFilter>({ page: 1, limit: 10 });
  const [searchTerm, setSearchTerm] = useState("");
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedProveedor, setSelectedProveedor] = useState<Proveedor | null>(null);

  // Queries
  const { data, isLoading } = useProveedoresList({ ...filter, search: searchTerm });
  const { mutate: deleteProveedor, isPending: isDeleting } = useDeleteProveedor();

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
    setFilter({ ...filter, page: 1 });
  };

  const handlePageChange = (_: unknown, page: number) => {
    setFilter({ ...filter, page });
  };

  const handleDeleteClick = (proveedor: Proveedor) => {
    setSelectedProveedor(proveedor);
    setDeleteOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (selectedProveedor) {
      deleteProveedor(selectedProveedor.codigo, {
        onSuccess: () => {
          setDeleteOpen(false);
          setSelectedProveedor(null);
        }
      });
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Gestion de Proveedores
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/proveedores/new")}
        >
          Nuevo Proveedor
        </Button>
      </Box>

      {/* Search */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <TextField
          placeholder="Buscar por nombre o RIF..."
          value={searchTerm}
          onChange={handleSearch}
          fullWidth
          size="small"
          variant="outlined"
        />
      </Paper>

      {/* Table Loading */}
      {isLoading ? (
        <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <Paper>
          <Toolbar sx={{ backgroundColor: "#f5f5f5" }}>
            <Typography variant="body2" sx={{ flex: 1 }}>
              {data?.total || 0} proveedores
            </Typography>
          </Toolbar>

          <Table size="small">
            <TableHead>
              <TableRow sx={{ backgroundColor: "#f9f9f9" }}>
                <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Nombre</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>RIF</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Email</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">
                  Saldo
                </TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="center">
                  Acciones
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.items || []).length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7} align="center" sx={{ py: 3 }}>
                    No hay proveedores registrados
                  </TableCell>
                </TableRow>
              ) : (
                (data?.items || []).map((proveedor) => (
                  <TableRow key={proveedor.codigo} hover>
                    <TableCell>{proveedor.codigo}</TableCell>
                    <TableCell>{proveedor.nombre}</TableCell>
                    <TableCell>{proveedor.rif}</TableCell>
                    <TableCell>{proveedor.email}</TableCell>
                    <TableCell align="right">
                      ${proveedor.saldo?.toFixed(2) || "0.00"}
                    </TableCell>
                    <TableCell>
                      <Box
                        sx={{
                          display: "inline-block",
                          px: 1.5,
                          py: 0.5,
                          borderRadius: 1,
                          backgroundColor:
                            proveedor.estado === "Activo" ? "#d4edda" : "#f8d7da",
                          color:
                            proveedor.estado === "Activo" ? "#155724" : "#721c24",
                          fontSize: "0.85rem"
                        }}
                      >
                        {proveedor.estado}
                      </Box>
                    </TableCell>
                    <TableCell align="center">
                      <Tooltip title="Ver proveedor">
                        <IconButton
                          size="small"
                          color="primary"
                          onClick={() =>
                            router.push(`/proveedores/${proveedor.codigo}`)
                          }
                        >
                          <ViewIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Editar proveedor">
                        <IconButton
                          size="small"
                          color="primary"
                          onClick={() =>
                            router.push(`/proveedores/${proveedor.codigo}/edit`)
                          }
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Eliminar proveedor">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDeleteClick(proveedor)}
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

          {/* Pagination */}
          {data?.totalPages && data.totalPages > 1 && (
            <Box sx={{ display: "flex", justifyContent: "center", p: 2 }}>
              <Pagination
                count={data.totalPages}
                page={filter.page || 1}
                onChange={handlePageChange}
                color="primary"
              />
            </Box>
          )}
        </Paper>
      )}

      {/* Delete Dialog */}
      <Dialog open={deleteOpen} onClose={() => setDeleteOpen(false)}>
        <DialogTitle>Eliminar Proveedor</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Estas seguro que deseas eliminar a <strong>{selectedProveedor?.nombre}</strong>?
            Esta accion no se puede deshacer.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setDeleteOpen(false)}
            disabled={isDeleting}
          >
            Cancelar
          </Button>
          <Button
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
            disabled={isDeleting}
          >
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
