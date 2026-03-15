// components/modules/pagos/PagoForm.tsx
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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from "@mui/material";
import { usePagoById, useCreatePago, useUpdatePago } from "../../../hooks/usePagos";
import { CreatePagoDTO, UpdatePagoDTO } from "@datqbox/shared-api/types";
import { useTimezone } from "@datqbox/shared-auth";
import { toDateOnly } from "@datqbox/shared-api";

interface PagoFormProps {
  numeroPago?: string;
}

export default function PagoForm({ numeroPago }: PagoFormProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const isEdit = !!numeroPago;

  const [formData, setFormData] = useState({
    nombre: "",
    tipo: "cliente",
    monto: 0,
    fecha: toDateOnly(new Date(), timeZone),
    metodoPago: "Efectivo",
    referencia: "",
    observaciones: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { data: pago, isLoading: isLoadingPago } = usePagoById(numeroPago || "");
  const { mutate: createPago, isPending: isCreating } = useCreatePago();
  const { mutate: updatePago, isPending: isUpdating } = useUpdatePago(numeroPago || "");

  useEffect(() => {
    if (isEdit && pago) {
      setFormData({
        nombre: pago.nombre,
        tipo: pago.tipo,
        monto: pago.monto,
        fecha: pago.fecha,
        metodoPago: pago.metodoPago,
        referencia: pago.referencia,
        observaciones: pago.observaciones || "",
      });
    }
  }, [pago, isEdit]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.nombre?.trim()) {
      newErrors.nombre = "El nombre es requerido";
    }

    if (!formData.monto || formData.monto <= 0) {
      newErrors.monto = "El monto debe ser mayor que 0";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);

    if (!validateForm()) return;

    setIsSubmitting(true);

    try {
      const submitData: CreatePagoDTO = {
        nombre: formData.nombre,
        tipo: formData.tipo,
        monto: formData.monto,
        fecha: formData.fecha,
        metodoPago: formData.metodoPago,
        referencia: formData.referencia,
        observaciones: formData.observaciones,
      };

      if (isEdit && numeroPago) {
        updatePago(submitData as UpdatePagoDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/pagos"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createPago(submitData, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/pagos"), 1500);
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

  if (isEdit && isLoadingPago) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Pago" : "Nuevo Pago"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Pago actualizado exitosamente" : "Pago registrado exitosamente"}
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6}>
            <TextField
              label="Nombre"
              placeholder="Cliente o Proveedor"
              value={formData.nombre}
              onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
              fullWidth
              size="small"
              required
              error={!!errors.nombre}
              helperText={errors.nombre}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <FormControl fullWidth size="small">
              <InputLabel>Tipo</InputLabel>
              <Select
                value={formData.tipo}
                label="Tipo"
                onChange={(e) => setFormData({ ...formData, tipo: e.target.value })}
              >
                <MenuItem value="cliente">Pago de Cliente</MenuItem>
                <MenuItem value="proveedor">Pago a Proveedor</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Monto (Bs.)"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.monto}
              onChange={(e) => setFormData({ ...formData, monto: parseFloat(e.target.value) })}
              fullWidth
              size="small"
              required
              error={!!errors.monto}
              helperText={errors.monto}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Fecha"
              type="date"
              value={formData.fecha}
              onChange={(e) => setFormData({ ...formData, fecha: e.target.value })}
              fullWidth
              size="small"
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <FormControl fullWidth size="small">
              <InputLabel>Método de Pago</InputLabel>
              <Select
                value={formData.metodoPago}
                label="Método de Pago"
                onChange={(e) => setFormData({ ...formData, metodoPago: e.target.value })}
              >
                <MenuItem value="Efectivo">Efectivo</MenuItem>
                <MenuItem value="Cheque">Cheque</MenuItem>
                <MenuItem value="Transferencia">Transferencia</MenuItem>
                <MenuItem value="Tarjeta">Tarjeta</MenuItem>
                <MenuItem value="Otro">Otro</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Referencia"
              placeholder="Número de cheque o ref. transf."
              value={formData.referencia}
              onChange={(e) => setFormData({ ...formData, referencia: e.target.value })}
              fullWidth
              size="small"
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              label="Observaciones"
              value={formData.observaciones}
              onChange={(e) => setFormData({ ...formData, observaciones: e.target.value })}
              fullWidth
              multiline
              rows={3}
              size="small"
            />
          </Grid>
        </Grid>

        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/pagos")}
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
            {isSubmitting ? "Guardando..." : isEdit ? "Actualizar" : "Registrar"}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
