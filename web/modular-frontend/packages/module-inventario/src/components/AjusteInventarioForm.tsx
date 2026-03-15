// components/AjusteInventarioForm.tsx
"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  Paper,
  CircularProgress,
  Alert,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  InputAdornment,
  Chip,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SearchIcon from "@mui/icons-material/Search";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { useCreateMovimiento, useInventarioList } from "../hooks/useInventario";
import { formatCurrency } from "@datqbox/shared-api";
import { debounce } from "lodash";

interface SelectedArticulo {
  codigo: string;
  descripcion: string;
  stock: number;
  precio: number;
}

export default function AjusteInventarioForm() {
  const router = useRouter();

  // Search
  const [search, setSearch] = useState("");
  const { data: inventario, isLoading } = useInventarioList({ search, limit: 30 });
  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const debouncedSearch = useCallback(
    debounce((value: string) => setSearch(value), 400),
    []
  );

  // Selected article
  const [selected, setSelected] = useState<SelectedArticulo | null>(null);

  // Form
  const [cantidad, setCantidad] = useState(1);
  const [tipo, setTipo] = useState("ENTRADA");
  const [motivo, setMotivo] = useState("");
  const [observaciones, setObservaciones] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { mutate: createMovimiento, isPending: isCreating } = useCreateMovimiento();

  const selectArticulo = (item: Record<string, unknown>) => {
    setSelected({
      codigo: String(item.CODIGO ?? item.ProductCode ?? ""),
      descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
      stock: Number(item.EXISTENCIA ?? item.Stock ?? 0),
      precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
    });
    setErrors((prev) => ({ ...prev, articulo: "" }));
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    if (!selected) newErrors.articulo = "Seleccione un artículo de la lista";
    if (!cantidad || cantidad <= 0) newErrors.cantidad = "La cantidad debe ser mayor que 0";
    if (!motivo?.trim()) newErrors.motivo = "El motivo es requerido";
    if (tipo === "SALIDA" && selected && cantidad > selected.stock) {
      newErrors.cantidad = `Stock insuficiente. Disponible: ${selected.stock}`;
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);
    if (!validateForm()) return;

    createMovimiento(
      {
        productCode: selected!.codigo,
        movementType: tipo,
        quantity: cantidad,
        documentRef: motivo,
        notes: observaciones || undefined,
      },
      {
        onSuccess: () => {
          setSubmitSuccess(true);
          setSelected(null);
          setCantidad(1);
          setMotivo("");
          setObservaciones("");
        },
        onError: (error) => {
          setSubmitError(error instanceof Error ? error.message : "Error al crear movimiento");
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        Ajuste de Inventario
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSubmitSuccess(false)}>
          Movimiento registrado exitosamente
        </Alert>
      )}
      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setSubmitError(null)}>
          {submitError}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Left: Article search table */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Buscar Artículos
            </Typography>
            <TextField
              placeholder="Buscar por código o nombre..."
              onChange={(e) => debouncedSearch(e.target.value)}
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

            {isLoading && (
              <Box sx={{ textAlign: "center", py: 3 }}>
                <CircularProgress size={28} />
              </Box>
            )}

            {!isLoading && rows.length > 0 && (
              <TableContainer sx={{ maxHeight: 420 }}>
                <Table size="small" stickyHeader>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Código</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>Artículo</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>Stock</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>Precio</TableCell>
                      <TableCell />
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.map((item, i) => {
                      const codigo = String(item.CODIGO ?? item.ProductCode ?? "");
                      const isSelected = selected?.codigo === codigo;
                      return (
                        <TableRow
                          key={i}
                          hover
                          selected={isSelected}
                          onClick={() => selectArticulo(item)}
                          sx={{ cursor: "pointer" }}
                        >
                          <TableCell sx={{ fontWeight: 500 }}>{codigo}</TableCell>
                          <TableCell>
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
                          <TableCell align="right">
                            {formatCurrency(Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0))}
                          </TableCell>
                          <TableCell align="center">
                            {isSelected && <CheckCircleIcon fontSize="small" color="primary" />}
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            {!isLoading && !search && rows.length === 0 && (
              <Typography variant="body2" color="text.secondary" sx={{ py: 3, textAlign: "center" }}>
                Escriba para buscar artículos...
              </Typography>
            )}

            {!isLoading && search && rows.length === 0 && (
              <Typography variant="body2" color="text.secondary" sx={{ py: 3, textAlign: "center" }}>
                No se encontraron artículos para &ldquo;{search}&rdquo;
              </Typography>
            )}

            {errors.articulo && (
              <Alert severity="warning" sx={{ mt: 1 }}>{errors.articulo}</Alert>
            )}
          </Paper>
        </Grid>

        {/* Right: Form */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper component="form" onSubmit={handleSubmit} sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Datos del Movimiento
            </Typography>

            {/* Selected article info */}
            {selected ? (
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="body2" fontWeight={600}>{selected.codigo}</Typography>
                <Typography variant="caption" color="text.secondary">{selected.descripcion}</Typography>
                <Box sx={{ mt: 0.5, display: "flex", gap: 2 }}>
                  <Typography variant="caption">Stock: <strong>{selected.stock}</strong></Typography>
                  <Typography variant="caption">Precio: <strong>{formatCurrency(selected.precio)}</strong></Typography>
                </Box>
              </Alert>
            ) : (
              <Alert severity="warning" sx={{ mb: 2 }}>
                Seleccione un artículo de la lista
              </Alert>
            )}

            <Grid container spacing={2}>
              <Grid size={12}>
                <FormControl fullWidth size="small">
                  <InputLabel>Tipo de Movimiento</InputLabel>
                  <Select value={tipo} label="Tipo de Movimiento" onChange={(e) => setTipo(e.target.value)}>
                    <MenuItem value="ENTRADA">Entrada (Suma)</MenuItem>
                    <MenuItem value="SALIDA">Salida (Resta)</MenuItem>
                    <MenuItem value="AJUSTE">Ajuste</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid size={12}>
                <TextField
                  label="Cantidad"
                  type="number"
                  inputProps={{ min: 1 }}
                  value={cantidad}
                  onChange={(e) => setCantidad(parseInt(e.target.value, 10) || 0)}
                  fullWidth
                  size="small"
                  required
                  error={!!errors.cantidad}
                  helperText={errors.cantidad}
                />
              </Grid>

              <Grid size={12}>
                <FormControl fullWidth size="small" error={!!errors.motivo}>
                  <InputLabel>Motivo</InputLabel>
                  <Select value={motivo} label="Motivo" onChange={(e) => setMotivo(e.target.value)}>
                    <MenuItem value="">— Seleccionar —</MenuItem>
                    <MenuItem value="Compra">Compra a proveedor</MenuItem>
                    <MenuItem value="Devolucion">Devolución de cliente</MenuItem>
                    <MenuItem value="Ajuste">Ajuste de inventario</MenuItem>
                    <MenuItem value="Perdida">Pérdida / Rotura</MenuItem>
                    <MenuItem value="Venta">Venta a cliente</MenuItem>
                    <MenuItem value="Otro">Otro</MenuItem>
                  </Select>
                  {errors.motivo && (
                    <Typography variant="caption" color="error" sx={{ ml: 2, mt: 0.5 }}>
                      {errors.motivo}
                    </Typography>
                  )}
                </FormControl>
              </Grid>

              <Grid size={12}>
                <TextField
                  label="Observaciones"
                  placeholder="Detalles adicionales del movimiento"
                  value={observaciones}
                  onChange={(e) => setObservaciones(e.target.value)}
                  fullWidth
                  multiline
                  rows={3}
                  size="small"
                />
              </Grid>
            </Grid>

            <Box sx={{ display: "flex", gap: 2, mt: 3, justifyContent: "flex-end" }}>
              <Button variant="outlined" onClick={() => router.back()} disabled={isCreating}>
                Cancelar
              </Button>
              <Button
                variant="contained"
                type="submit"
                disabled={isCreating || !selected}
                startIcon={isCreating ? <CircularProgress size={20} /> : null}
              >
                {isCreating ? "Guardando..." : "Registrar Movimiento"}
              </Button>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
