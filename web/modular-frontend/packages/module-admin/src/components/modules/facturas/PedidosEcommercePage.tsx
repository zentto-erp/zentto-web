// components/modules/facturas/PedidosEcommercePage.tsx
"use client";

import { useState, useCallback } from "react";
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
  Chip,
  InputAdornment,
  Typography,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  ToggleButton,
  ToggleButtonGroup,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Stack,
  Alert,
  Snackbar,
} from "@mui/material";
import {
  Search as SearchIcon,
  Receipt as ReceiptIcon,
} from "@mui/icons-material";
import {
  usePedidosPendientes,
  useFacturarDesdePedido,
  type PedidoEcommerce,
} from "../../../hooks/usePedidosEcommerce";
import { formatCurrency, formatDate } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { debounce } from "lodash";

type FormaPagoItem = {
  tipo: string;
  monto: number;
};

const FORMAS_PAGO_OPTIONS = ["EFECTIVO", "TRANSFERENCIA", "TARJETA"];

export default function PedidosEcommercePage() {
  const { timeZone } = useTimezone();

  // List state
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [search, setSearch] = useState("");
  const [filtro, setFiltro] = useState<"pendientes" | "todos">("pendientes");

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedPedido, setSelectedPedido] = useState<PedidoEcommerce | null>(null);
  const [numFacturaInput, setNumFacturaInput] = useState("");
  const [formasPago, setFormasPago] = useState<FormaPagoItem[]>([]);

  // Toast state
  const [toast, setToast] = useState<{ open: boolean; message: string; severity: "success" | "error" }>({
    open: false,
    message: "",
    severity: "success",
  });

  const { data: pedidos, isLoading } = usePedidosPendientes({
    search,
    page: page + 1,
    limit: rowsPerPage,
    solosPendientes: filtro === "pendientes",
  });

  const { mutate: facturar, isPending: isFacturando } = useFacturarDesdePedido();

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

  const handleOpenFacturar = (pedido: PedidoEcommerce) => {
    setSelectedPedido(pedido);
    setNumFacturaInput("");
    setFormasPago([]);
    setDialogOpen(true);
  };

  const handleAddFormaPago = () => {
    setFormasPago((prev) => [...prev, { tipo: "EFECTIVO", monto: 0 }]);
  };

  const handleRemoveFormaPago = (index: number) => {
    setFormasPago((prev) => prev.filter((_, i) => i !== index));
  };

  const handleFormaPagoChange = (index: number, field: keyof FormaPagoItem, value: string | number) => {
    setFormasPago((prev) =>
      prev.map((fp, i) => (i === index ? { ...fp, [field]: value } : fp))
    );
  };

  const handleConfirmFacturar = () => {
    if (!selectedPedido || !numFacturaInput.trim()) return;

    facturar(
      {
        numFactPedido: selectedPedido.DocumentNumber,
        factura: {
          NUM_FACT: numFacturaInput.trim(),
          CODIGO: selectedPedido.CustomerCode,
          NOMBRE: selectedPedido.CustomerName,
          TOTAL: selectedPedido.TotalAmount,
          FECHA: new Date().toISOString().slice(0, 10),
        },
        formasPago: formasPago.length > 0 ? formasPago : undefined,
      },
      {
        onSuccess: () => {
          setToast({
            open: true,
            message: `Factura ${numFacturaInput} generada desde pedido ${selectedPedido.DocumentNumber}`,
            severity: "success",
          });
          setDialogOpen(false);
          setSelectedPedido(null);
        },
        onError: (err: unknown) => {
          const message = err instanceof Error ? err.message : "Error al facturar el pedido";
          setToast({ open: true, message, severity: "error" });
        },
      }
    );
  };

  const rows = pedidos?.rows ?? [];
  const total = pedidos?.total ?? 0;

  return (
    <Box sx={{ p: 2 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Pedidos Ecommerce
        </Typography>
        <ToggleButtonGroup
          value={filtro}
          exclusive
          onChange={(_, val) => {
            if (val) {
              setFiltro(val);
              setPage(0);
            }
          }}
          size="small"
        >
          <ToggleButton value="pendientes">Pendientes</ToggleButton>
          <ToggleButton value="todos">Todos</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* Search */}
      <TextField
        placeholder="Buscar por numero de pedido o cliente..."
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
              <TableCell sx={{ fontWeight: 600 }}>Pedido</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Cliente</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>RIF/Cedula</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600 }}>Total</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Estado</TableCell>
              <TableCell sx={{ fontWeight: 600 }}>Entregado</TableCell>
              <TableCell align="center" sx={{ fontWeight: 600 }}>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={8} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={40} />
                </TableCell>
              </TableRow>
            ) : rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} align="center" sx={{ py: 4, color: "text.secondary" }}>
                  No hay pedidos disponibles
                </TableCell>
              </TableRow>
            ) : (
              rows.map((pedido) => (
                <TableRow key={pedido.DocumentNumber} hover>
                  <TableCell sx={{ fontWeight: 500 }}>{pedido.DocumentNumber}</TableCell>
                  <TableCell>{pedido.CustomerName}</TableCell>
                  <TableCell>{pedido.FiscalId}</TableCell>
                  <TableCell>{formatDate(pedido.IssueDate, { timeZone })}</TableCell>
                  <TableCell align="right">{formatCurrency(pedido.TotalAmount)}</TableCell>
                  <TableCell>
                    <Chip
                      label={pedido.IsInvoiced === "S" ? "Facturado" : "Pendiente"}
                      size="small"
                      color={pedido.IsInvoiced === "S" ? "success" : "warning"}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={pedido.IsDelivered === "S" ? "Si" : "No"}
                      size="small"
                      color={pedido.IsDelivered === "S" ? "success" : "default"}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell align="center">
                    {pedido.IsInvoiced !== "S" && (
                      <Button
                        size="small"
                        variant="outlined"
                        startIcon={<ReceiptIcon fontSize="small" />}
                        onClick={() => handleOpenFacturar(pedido)}
                      >
                        Facturar
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {total > 0 && (
        <TablePagination
          rowsPerPageOptions={[5, 10, 25, 50]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handlePageChange}
          onRowsPerPageChange={handleRowsPerPageChange}
          labelRowsPerPage="Filas por pagina:"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} de ${count}`}
        />
      )}

      {/* Facturar Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Facturar Pedido</DialogTitle>
        <DialogContent>
          {selectedPedido && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Alert severity="info" variant="outlined">
                <Typography variant="body2">
                  <strong>Pedido:</strong> {selectedPedido.DocumentNumber}
                </Typography>
                <Typography variant="body2">
                  <strong>Cliente:</strong> {selectedPedido.CustomerName} ({selectedPedido.CustomerCode})
                </Typography>
                <Typography variant="body2">
                  <strong>Total:</strong> {formatCurrency(selectedPedido.TotalAmount)}
                </Typography>
              </Alert>

              <TextField
                label="Numero de Factura"
                value={numFacturaInput}
                onChange={(e) => setNumFacturaInput(e.target.value)}
                required
                fullWidth
                size="small"
                helperText="Numero generado por la impresora fiscal"
                autoFocus
              />

              {/* Formas de pago */}
              <Box>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 1 }}>
                  <Typography variant="subtitle2">Formas de pago (opcional)</Typography>
                  <Button size="small" onClick={handleAddFormaPago}>
                    Agregar
                  </Button>
                </Box>
                {formasPago.map((fp, index) => (
                  <Stack key={index} direction="row" spacing={1} sx={{ mb: 1 }} alignItems="center">
                    <FormControl size="small" sx={{ minWidth: 160 }}>
                      <InputLabel>Tipo</InputLabel>
                      <Select
                        value={fp.tipo}
                        label="Tipo"
                        onChange={(e) => handleFormaPagoChange(index, "tipo", e.target.value)}
                      >
                        {FORMAS_PAGO_OPTIONS.map((opt) => (
                          <MenuItem key={opt} value={opt}>
                            {opt}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                    <TextField
                      label="Monto"
                      type="number"
                      size="small"
                      value={fp.monto}
                      onChange={(e) => handleFormaPagoChange(index, "monto", Number(e.target.value))}
                      sx={{ flex: 1 }}
                    />
                    <Button size="small" color="error" onClick={() => handleRemoveFormaPago(index)}>
                      X
                    </Button>
                  </Stack>
                ))}
              </Box>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            onClick={handleConfirmFacturar}
            variant="contained"
            disabled={isFacturando || !numFacturaInput.trim()}
          >
            {isFacturando ? "Generando..." : "Generar Factura"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Toast */}
      <Snackbar
        open={toast.open}
        autoHideDuration={5000}
        onClose={() => setToast((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          onClose={() => setToast((prev) => ({ ...prev, open: false }))}
          severity={toast.severity}
          variant="filled"
          sx={{ width: "100%" }}
        >
          {toast.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
