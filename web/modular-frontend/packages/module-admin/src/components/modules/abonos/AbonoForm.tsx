// components/modules/abonos/AbonoForm.tsx
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
  Typography,
} from "@mui/material";
import { FormGrid, FormField } from '@zentto/shared-ui';
import { useAbonoById, useCreateAbono, useUpdateAbono } from "../../../hooks/useAbonos";
import { CreateAbonoDTO, UpdateAbonoDTO } from "@zentto/shared-api/types";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly } from "@zentto/shared-api";

interface AbonoFormProps {
  numeroAbono?: string;
}

export default function AbonoForm({ numeroAbono }: AbonoFormProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const isEdit = !!numeroAbono;

  const [formData, setFormData] = useState({
    numeroFactura: "",
    nombreCliente: "",
    monto: 0,
    fecha: toDateOnly(new Date(), timeZone),
    referencia: "",
    observaciones: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { data: abono, isLoading: isLoadingAbono } = useAbonoById(numeroAbono || "");
  const { mutate: createAbono, isPending: isCreating } = useCreateAbono();
  const { mutate: updateAbono, isPending: isUpdating } = useUpdateAbono(numeroAbono || "");

  useEffect(() => {
    if (isEdit && abono) {
      setFormData({
        numeroFactura: abono.numeroFactura,
        nombreCliente: abono.nombreCliente,
        monto: abono.monto,
        fecha: abono.fecha,
        referencia: abono.referencia,
        observaciones: abono.observaciones || "",
      });
    }
  }, [abono, isEdit]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.numeroFactura?.trim()) {
      newErrors.numeroFactura = "El número de factura es requerido";
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
      const submitData: CreateAbonoDTO = {
        numeroFactura: formData.numeroFactura,
        nombreCliente: formData.nombreCliente,
        monto: formData.monto,
        fecha: formData.fecha,
        referencia: formData.referencia,
        observaciones: formData.observaciones,
      };

      if (isEdit && numeroAbono) {
        updateAbono(submitData as UpdateAbonoDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/abonos"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createAbono(submitData, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/abonos"), 1500);
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

  if (isEdit && isLoadingAbono) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Abono" : "Nuevo Abono"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Abono actualizado exitosamente" : "Abono creado exitosamente"}
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={6}>
            <TextField
              label="Número de Factura"
              value={formData.numeroFactura}
              onChange={(e) => setFormData({ ...formData, numeroFactura: e.target.value })}
              size="small"
              required
              error={!!errors.numeroFactura}
              helperText={errors.numeroFactura}
            />
          </FormField>

          <FormField xs={12} sm={6}>
            <TextField
              label="Nombre Cliente"
              value={formData.nombreCliente}
              onChange={(e) => setFormData({ ...formData, nombreCliente: e.target.value })}
              size="small"
            />
          </FormField>

          <FormField xs={12} sm={6}>
            <TextField
              label="Monto (Bs.)"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.monto}
              onChange={(e) => setFormData({ ...formData, monto: parseFloat(e.target.value) })}
              size="small"
              required
              error={!!errors.monto}
              helperText={errors.monto}
            />
          </FormField>

          <FormField xs={12} sm={6}>
            <TextField
              label="Fecha"
              type="date"
              value={formData.fecha}
              onChange={(e) => setFormData({ ...formData, fecha: e.target.value })}
              size="small"
              InputLabelProps={{ shrink: true }}
            />
          </FormField>

          <FormField xs={12}>
            <TextField
              label="Referencia"
              placeholder="Cheque, referencia de banco, etc."
              value={formData.referencia}
              onChange={(e) => setFormData({ ...formData, referencia: e.target.value })}
              size="small"
            />
          </FormField>

          <FormField xs={12}>
            <TextField
              label="Observaciones"
              value={formData.observaciones}
              onChange={(e) => setFormData({ ...formData, observaciones: e.target.value })}
              multiline
              rows={3}
              size="small"
            />
          </FormField>
        </FormGrid>

        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/abonos")}
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
