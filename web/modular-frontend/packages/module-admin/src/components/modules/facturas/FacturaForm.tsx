// components/modules/facturas/FacturaForm.tsx
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  Paper,
  CircularProgress,
  Alert,
  Grid,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  MenuItem,
  Tooltip,
} from "@mui/material";
import { FormGrid, FormField, DatePicker } from '@zentto/shared-ui';
import dayjs from "dayjs";
import Autocomplete from "@mui/material/Autocomplete";
import { Delete as DeleteIcon, Add as AddIcon } from "@mui/icons-material";
import { useQuery } from "@tanstack/react-query";
import { useFacturaById, useCreateFactura, useUpdateFactura } from "../../../hooks/useFacturas";
import { Factura, CreateFacturaDTO, UpdateFacturaDTO } from "@zentto/shared-api/types";
import { formatCurrency, toDateOnly, apiGet } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

interface FacturaFormProps {
  numeroFactura?: string;
}

interface DetalleFactura {
  codigoArticulo: string;
  nombreArticulo: string;
  cantidad: number;
  precioUnitario: number;
  descuento: number;
}

const FORMAS_PAGO = [
  { value: "EFECTIVO", label: "Efectivo" },
  { value: "TRANSFERENCIA", label: "Transferencia" },
  { value: "TARJETA", label: "Tarjeta" },
  { value: "CHEQUE", label: "Cheque" },
  { value: "PAGO_MOVIL", label: "Pago Móvil" },
];

const MONEDAS = [
  { value: "VES", label: "VES - Bolívar" },
  { value: "USD", label: "USD - Dólar" },
  { value: "EUR", label: "EUR - Euro" },
];

export default function FacturaForm({ numeroFactura }: FacturaFormProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const isEdit = !!numeroFactura;

  // State
  const [formData, setFormData] = useState({
    codigoCliente: "",
    nombreCliente: "",
    fecha: toDateOnly(new Date(), timeZone),
    referencia: "",
    observaciones: "",
    formaPago: "EFECTIVO",
    moneda: "VES",
  });
  const [detalles, setDetalles] = useState<DetalleFactura[]>([]);
  const [currentDetalle, setCurrentDetalle] = useState<DetalleFactura>({
    codigoArticulo: "",
    nombreArticulo: "",
    cantidad: 1,
    precioUnitario: 0,
    descuento: 0,
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [detalleDialogOpen, setDetalleDialogOpen] = useState(false);

  // Autocomplete: Cliente search
  const [clienteInput, setClienteInput] = useState("");
  const [clienteSelected, setClienteSelected] = useState<any | null>(null);
  const { data: clientesData, isLoading: isLoadingClientes } = useQuery({
    queryKey: ["clientes-search", clienteInput],
    queryFn: () => apiGet("/api/v1/clientes", { search: clienteInput, limit: 10 }),
    enabled: clienteInput.length >= 2,
  });
  const clienteOptions: any[] = clientesData?.rows ?? clientesData?.data ?? [];

  // Autocomplete: Artículo search
  const [articuloInput, setArticuloInput] = useState("");
  const [articuloSelected, setArticuloSelected] = useState<any | null>(null);
  const { data: articulosData, isLoading: isLoadingArticulos } = useQuery({
    queryKey: ["articulos-search", articuloInput],
    queryFn: () => apiGet("/api/v1/inventario", { search: articuloInput, limit: 10 }),
    enabled: articuloInput.length >= 2,
  });
  const articuloOptions: any[] = articulosData?.rows ?? articulosData?.data ?? [];

  // Queries
  const { data: factura, isLoading: isLoadingFactura } = useFacturaById(numeroFactura || "");
  const { mutate: createFactura, isPending: isCreating } = useCreateFactura();
  const { mutate: updateFactura, isPending: isUpdating } = useUpdateFactura(numeroFactura || "");

  // Load factura data on edit
  useEffect(() => {
    if (isEdit && factura) {
      setFormData({
        codigoCliente: factura.codigoCliente,
        nombreCliente: factura.nombreCliente,
        fecha: factura.fecha,
        referencia: factura.referencia,
        observaciones: factura.observaciones,
        formaPago: (factura as any).formaPago ?? "EFECTIVO",
        moneda: (factura as any).moneda ?? "VES",
      });
      // Pre-populate the Autocomplete display for edit mode
      setClienteSelected({ codigo: factura.codigoCliente, nombre: factura.nombreCliente });
      // setDetalles(factura.detalles || []);
    }
  }, [factura, isEdit]);

  // Validation
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.codigoCliente?.trim()) {
      newErrors.codigoCliente = "El código de cliente es requerido";
    }

    if (detalles.length === 0) {
      newErrors.detalles = "Debe añadir al menos un artículo";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Calculate totals
  const calcularTotales = () => {
    let subtotal = 0;
    let totalDescuentos = 0;

    detalles.forEach((det) => {
      const lineTotal = det.cantidad * det.precioUnitario;
      subtotal += lineTotal;
      totalDescuentos += det.descuento || 0;
    });

    const iva = (subtotal - totalDescuentos) * 0.16;
    const total = subtotal - totalDescuentos + iva;

    return { subtotal, totalDescuentos, iva, total };
  };

  // Add detalle
  const handleAddDetalle = () => {
    if (!currentDetalle.codigoArticulo) {
      alert("Ingrese el código del artículo");
      return;
    }

    setDetalles([...detalles, { ...currentDetalle }]);
    setCurrentDetalle({
      codigoArticulo: "",
      nombreArticulo: "",
      cantidad: 1,
      precioUnitario: 0,
      descuento: 0,
    });
    setArticuloSelected(null);
    setArticuloInput("");
    setDetalleDialogOpen(false);
  };

  // Remove detalle
  const handleRemoveDetalle = (index: number) => {
    setDetalles(detalles.filter((_, i) => i !== index));
  };

  // Submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);

    if (!validateForm()) return;

    setIsSubmitting(true);

    try {
      const totales = calcularTotales();
      const submitData: CreateFacturaDTO = {
        codigoCliente: formData.codigoCliente,
        nombreCliente: formData.nombreCliente,
        fecha: formData.fecha,
        referencia: formData.referencia || "",
        observaciones: formData.observaciones || "",
        detalles,
        subtotal: totales.subtotal,
        totalDescuentos: totales.totalDescuentos,
        iva: totales.iva,
        totalFactura: totales.total,
      };

      if (isEdit && numeroFactura) {
        updateFactura(submitData as any, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/facturas"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createFactura(submitData as any, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/facturas"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al crear");
          }
        });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const totales = calcularTotales();

  if (isEdit && isLoadingFactura) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Factura" : "Nueva Factura"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Factura actualizada exitosamente" : "Factura creada exitosamente"}
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      {errors.detalles && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          {errors.detalles}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        {/* Encabezado */}
        <FormGrid spacing={2} sx={{ mb: 3 }}>
          <FormField xs={12} sm={6}>
            <Autocomplete
              options={clienteOptions}
              getOptionLabel={(opt: any) =>
                `${opt.CODIGO ?? opt.codigo ?? ""} — ${opt.NOMBRE ?? opt.nombre ?? ""}`
              }
              value={clienteSelected}
              loading={isLoadingClientes}
              onInputChange={(_, val) => setClienteInput(val)}
              onChange={(_, selected) => {
                setClienteSelected(selected);
                if (selected) {
                  setFormData((prev) => ({
                    ...prev,
                    codigoCliente: selected.CODIGO ?? selected.codigo ?? "",
                    nombreCliente: selected.NOMBRE ?? selected.nombre ?? "",
                  }));
                } else {
                  setFormData((prev) => ({
                    ...prev,
                    codigoCliente: "",
                    nombreCliente: "",
                  }));
                }
              }}
              isOptionEqualToValue={(opt: any, val: any) =>
                (opt.CODIGO ?? opt.codigo) === (val.CODIGO ?? val.codigo)
              }
              noOptionsText={clienteInput.length < 2 ? "Escriba al menos 2 caracteres" : "Sin resultados"}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Cliente"
                  size="small"
                  required
                  error={!!errors.codigoCliente}
                  helperText={errors.codigoCliente}
                  InputProps={{
                    ...params.InputProps,
                    endAdornment: (
                      <>
                        {isLoadingClientes ? <CircularProgress color="inherit" size={18} /> : null}
                        {params.InputProps.endAdornment}
                      </>
                    ),
                  }}
                />
              )}
              size="small"
            />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField
              label="Nombre Cliente"
              value={formData.nombreCliente}
              onChange={(e) => setFormData({ ...formData, nombreCliente: e.target.value })}
              size="small"
              InputProps={{ readOnly: true }}
            />
          </FormField>
          <FormField xs={12} sm={6}>
            <DatePicker
              label="Fecha"
              value={formData.fecha ? dayjs(formData.fecha) : null}
              onChange={(v) => setFormData({ ...formData, fecha: v ? v.format('YYYY-MM-DD') : '' })}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField
              label="Referencia"
              value={formData.referencia}
              onChange={(e) => setFormData({ ...formData, referencia: e.target.value })}
              size="small"
            />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField
              select
              label="Forma de Pago"
              value={formData.formaPago}
              onChange={(e) => setFormData({ ...formData, formaPago: e.target.value })}
              size="small"
            >
              {FORMAS_PAGO.map((fp) => (
                <MenuItem key={fp.value} value={fp.value}>
                  {fp.label}
                </MenuItem>
              ))}
            </TextField>
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField
              select
              label="Moneda"
              value={formData.moneda}
              onChange={(e) => setFormData({ ...formData, moneda: e.target.value })}
              size="small"
            >
              {MONEDAS.map((m) => (
                <MenuItem key={m.value} value={m.value}>
                  {m.label}
                </MenuItem>
              ))}
            </TextField>
          </FormField>
          <FormField xs={12}>
            <TextField
              label="Observaciones"
              value={formData.observaciones}
              onChange={(e) => setFormData({ ...formData, observaciones: e.target.value })}
              multiline
              rows={2}
              size="small"
            />
          </FormField>
        </FormGrid>

        {/* Detalles */}
        <Box sx={{ mb: 3 }}>
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Detalles de la Factura
            </Typography>
            <Button
              variant="outlined"
              size="small"
              startIcon={<AddIcon />}
              onClick={() => setDetalleDialogOpen(true)}
            >
              Agregar Artículo
            </Button>
          </Box>

          {detalles.length > 0 ? (
            <Table size="small">
              <TableHead>
                <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
                  <TableCell>Artículo</TableCell>
                  <TableCell align="right">Cantidad</TableCell>
                  <TableCell align="right">Precio</TableCell>
                  <TableCell align="right">Total</TableCell>
                  <TableCell align="center">Acciones</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {detalles.map((det, idx) => (
                  <TableRow key={idx}>
                    <TableCell>{det.nombreArticulo}</TableCell>
                    <TableCell align="right">{det.cantidad}</TableCell>
                    <TableCell align="right">{formatCurrency(det.precioUnitario)}</TableCell>
                    <TableCell align="right">
                      {formatCurrency(det.cantidad * det.precioUnitario - (det.descuento || 0))}
                    </TableCell>
                    <TableCell align="center">
                      <Tooltip title="Eliminar línea">
                        <IconButton size="small" color="error" onClick={() => handleRemoveDetalle(idx)}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <Alert severity="info">No hay detalles. Agregue artículos a la factura.</Alert>
          )}
        </Box>

        {/* Totales */}
        {detalles.length > 0 && (
          <Box sx={{
            p: 2,
            backgroundColor: "#f5f5f5",
            borderRadius: 1,
            mb: 3,
            textAlign: "right"
          }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6} />
              <Grid item xs={12} sm={6}>
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 1 }}>
                  <Typography>Subtotal:</Typography>
                  <Typography>{formatCurrency(totales.subtotal)}</Typography>
                </Box>
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 1 }}>
                  <Typography>Descuentos:</Typography>
                  <Typography>{formatCurrency(totales.totalDescuentos)}</Typography>
                </Box>
                <Box sx={{ display: "flex", justifyContent: "space-between", mb: 1 }}>
                  <Typography>IVA (16%):</Typography>
                  <Typography>{formatCurrency(totales.iva)}</Typography>
                </Box>
                <Box sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  fontWeight: 600,
                  fontSize: "1.1em",
                  pt: 1,
                  borderTop: "1px solid #ddd"
                }}>
                  <Typography>Total:</Typography>
                  <Typography sx={{ color: "primary.main" }}>{formatCurrency(totales.total)}</Typography>
                </Box>
              </Grid>
            </Grid>
          </Box>
        )}

        {/* Actions */}
        <Box sx={{ display: "flex", gap: 2, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/facturas")}
            disabled={isSubmitting || isCreating || isUpdating}
          >
            Cancelar
          </Button>
          <Button
            variant="contained"
            type="submit"
            disabled={isSubmitting || isCreating || isUpdating}
            startIcon={isSubmitting && <CircularProgress size={20} />}
          >
            {isSubmitting ? "Guardando..." : isEdit ? "Actualizar" : "Crear"}
          </Button>
        </Box>
      </Paper>

      {/* Detalle Dialog */}
      <Dialog open={detalleDialogOpen} onClose={() => setDetalleDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Agregar Artículo</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <FormGrid spacing={2} sx={{ mt: 0.5 }}>
            <FormField xs={12}>
              <Autocomplete
                options={articuloOptions}
                getOptionLabel={(opt: any) =>
                  `${opt.CODIGO ?? opt.codigo ?? ""} — ${opt.NOMBRE ?? opt.nombre ?? opt.DESCRIPCION ?? opt.descripcion ?? ""}`
                }
                value={articuloSelected}
                loading={isLoadingArticulos}
                onInputChange={(_, val) => setArticuloInput(val)}
                onChange={(_, selected) => {
                  setArticuloSelected(selected);
                  if (selected) {
                    setCurrentDetalle((prev) => ({
                      ...prev,
                      codigoArticulo: selected.CODIGO ?? selected.codigo ?? "",
                      nombreArticulo: selected.NOMBRE ?? selected.nombre ?? selected.DESCRIPCION ?? selected.descripcion ?? "",
                      precioUnitario: selected.PRECIO ?? selected.precio ?? selected.PRECIO_VENTA ?? selected.precioVenta ?? 0,
                    }));
                  } else {
                    setCurrentDetalle((prev) => ({
                      ...prev,
                      codigoArticulo: "",
                      nombreArticulo: "",
                      precioUnitario: 0,
                    }));
                  }
                }}
                isOptionEqualToValue={(opt: any, val: any) =>
                  (opt.CODIGO ?? opt.codigo) === (val.CODIGO ?? val.codigo)
                }
                noOptionsText={articuloInput.length < 2 ? "Escriba al menos 2 caracteres" : "Sin resultados"}
                renderInput={(params) => (
                  <TextField
                    {...params}
                    label="Buscar Artículo"
                    size="small"
                    required
                    InputProps={{
                      ...params.InputProps,
                      endAdornment: (
                        <>
                          {isLoadingArticulos ? <CircularProgress color="inherit" size={18} /> : null}
                          {params.InputProps.endAdornment}
                        </>
                      ),
                    }}
                  />
                )}
                size="small"
              />
            </FormField>
            <FormField xs={12}>
              <TextField
                label="Nombre Artículo"
                value={currentDetalle.nombreArticulo}
                size="small"
                InputProps={{ readOnly: true }}
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField
                label="Cantidad"
                type="number"
                inputProps={{ min: 1 }}
                value={currentDetalle.cantidad}
                onChange={(e) => setCurrentDetalle({ ...currentDetalle, cantidad: parseInt(e.target.value, 10) })}
                size="small"
              />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField
                label="Precio Unitario"
                type="number"
                inputProps={{ min: 0, step: "0.01" }}
                value={currentDetalle.precioUnitario}
                onChange={(e) => setCurrentDetalle({ ...currentDetalle, precioUnitario: parseFloat(e.target.value) })}
                size="small"
              />
            </FormField>
            <FormField xs={12}>
              <TextField
                label="Descuento (Bs.)"
                type="number"
                inputProps={{ min: 0, step: "0.01" }}
                value={currentDetalle.descuento}
                onChange={(e) => setCurrentDetalle({ ...currentDetalle, descuento: parseFloat(e.target.value) })}
                size="small"
              />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetalleDialogOpen(false)}>Cancelar</Button>
          <Button onClick={handleAddDetalle} variant="contained">
            Agregar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
