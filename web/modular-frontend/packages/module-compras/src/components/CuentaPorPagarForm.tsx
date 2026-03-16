// components/CuentaPorPagarForm.tsx
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
} from "@mui/material";
import { useCuentaPorPagarById, useCreateCuentaPorPagar, useUpdateCuentaPorPagar } from "../hooks/useCuentasPorPagar";
import { CreateCuentaPorPagarDTO, UpdateCuentaPorPagarDTO } from "@zentto/shared-api/types";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";

interface CuentaPorPagarFormProps {
  id?: string;
}

export default function CuentaPorPagarForm({ id }: CuentaPorPagarFormProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const isEdit = !!id;

  const [formData, setFormData] = useState({
    codigoProveedor: "",
    nombreProveedor: "",
    numeroReferencia: "",
    montoTotal: 0,
    saldo: 0,
    fechaCreacion: toDateOnly(new Date(), timeZone),
    fechaVencimiento: toDateOnly(new Date(), timeZone),
    descripcion: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { data: cuenta, isLoading: isLoadingCuenta } = useCuentaPorPagarById(id || "");
  const { mutate: createCuenta, isPending: isCreating } = useCreateCuentaPorPagar();
  const { mutate: updateCuenta, isPending: isUpdating } = useUpdateCuentaPorPagar(id || "");

  useEffect(() => {
    if (isEdit && cuenta) {
      setFormData({
        codigoProveedor: cuenta.codigoProveedor ?? "",
        nombreProveedor: cuenta.nombreProveedor ?? "",
        numeroReferencia: cuenta.numeroReferencia ?? "",
        montoTotal: cuenta.montoTotal ?? 0,
        saldo: cuenta.saldo ?? 0,
        fechaCreacion: String(cuenta.fechaCreacion ?? ""),
        fechaVencimiento: String(cuenta.fechaVencimiento ?? ""),
        descripcion: cuenta.descripcion ?? "",
      });
    }
  }, [cuenta, isEdit]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.codigoProveedor?.trim()) {
      newErrors.codigoProveedor = "El codigo de proveedor es requerido";
    }

    if (!formData.montoTotal || formData.montoTotal <= 0) {
      newErrors.montoTotal = "El monto debe ser mayor que 0";
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
      const submitData: CreateCuentaPorPagarDTO = {
        codigoProveedor: formData.codigoProveedor,
        nombreProveedor: formData.nombreProveedor,
        numeroReferencia: formData.numeroReferencia,
        montoTotal: formData.montoTotal,
        saldo: formData.saldo || formData.montoTotal,
        fechaCreacion: formData.fechaCreacion,
        fechaVencimiento: formData.fechaVencimiento,
        descripcion: formData.descripcion,
      };

      if (isEdit && id) {
        updateCuenta(submitData as UpdateCuentaPorPagarDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/cuentas-por-pagar"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createCuenta(submitData, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/cuentas-por-pagar"), 1500);
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

  if (isEdit && isLoadingCuenta) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Cuenta por Pagar" : "Nueva Cuenta por Pagar"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Cuenta actualizada exitosamente" : "Cuenta creada exitosamente"}
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
              label="Codigo Proveedor"
              placeholder="Ej: PROV001"
              value={formData.codigoProveedor}
              onChange={(e) => setFormData({ ...formData, codigoProveedor: e.target.value })}
              fullWidth
              size="small"
              required
              error={!!errors.codigoProveedor}
              helperText={errors.codigoProveedor}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Nombre Proveedor"
              value={formData.nombreProveedor}
              onChange={(e) => setFormData({ ...formData, nombreProveedor: e.target.value })}
              fullWidth
              size="small"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Numero de Referencia"
              placeholder="Factura, PO, etc."
              value={formData.numeroReferencia}
              onChange={(e) => setFormData({ ...formData, numeroReferencia: e.target.value })}
              fullWidth
              size="small"
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Monto Total (Bs.)"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.montoTotal}
              onChange={(e) => setFormData({ ...formData, montoTotal: parseFloat(e.target.value) })}
              fullWidth
              size="small"
              required
              error={!!errors.montoTotal}
              helperText={errors.montoTotal}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Fecha de Creacion"
              type="date"
              value={formData.fechaCreacion}
              onChange={(e) => setFormData({ ...formData, fechaCreacion: e.target.value })}
              fullWidth
              size="small"
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Fecha de Vencimiento"
              type="date"
              value={formData.fechaVencimiento}
              onChange={(e) => setFormData({ ...formData, fechaVencimiento: e.target.value })}
              fullWidth
              size="small"
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12}>
            <TextField
              label="Descripcion"
              value={formData.descripcion}
              onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
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
            onClick={() => router.push("/cuentas-por-pagar")}
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
    </Box>
  );
}
