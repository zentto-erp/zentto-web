// components/modules/inventario/AjusteInventarioForm.tsx
"use client";

import { useState } from "react";
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
import { useCreateMovimiento } from "../../../hooks/useInventario";
import { CreateInventarioDTO } from "@zentto/shared-api/types";

export default function AjusteInventarioForm() {
  const router = useRouter();

  const [formData, setFormData] = useState({
    codigoArticulo: "",
    cantidad: 0,
    tipo: "entrada",
    motivo: "",
    observaciones: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { mutate: createMovimiento, isPending: isCreating } = useCreateMovimiento();

  // Validation
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.codigoArticulo?.trim()) {
      newErrors.codigoArticulo = "El código de artículo es requerido";
    }

    if (!formData.cantidad || formData.cantidad === 0) {
      newErrors.cantidad = "La cantidad debe ser mayor que 0";
    }

    if (!formData.motivo?.trim()) {
      newErrors.motivo = "El motivo es requerido";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);

    if (!validateForm()) return;

    setIsSubmitting(true);

    try {
      const movimentoData: CreateInventarioDTO = {
        codigoArticulo: formData.codigoArticulo,
        cantidad: formData.tipo === "entrada" ? formData.cantidad : -formData.cantidad,
        motivo: formData.motivo,
        observaciones: formData.observaciones || "",
      };

      createMovimiento(movimentoData, {
        onSuccess: () => {
          setSubmitSuccess(true);
          setTimeout(() => router.push("/inventario"), 1500);
        },
        onError: (error) => {
          setSubmitError(error instanceof Error ? error.message : "Error al crear movimiento");
        }
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        Ajuste de Inventario
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Movimiento registrado exitosamente
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <Grid container spacing={2}>
          {/* Código Artículo */}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Código del Artículo"
              placeholder="Ej: ART001"
              value={formData.codigoArticulo}
              onChange={(e) => setFormData({ ...formData, codigoArticulo: e.target.value })}
              fullWidth
              size="small"
              required
              error={!!errors.codigoArticulo}
              helperText={errors.codigoArticulo}
            />
          </Grid>

          {/* Tipo Movimiento */}
          <Grid item xs={12} sm={6}>
            <FormControl fullWidth size="small">
              <InputLabel>Tipo de Movimiento</InputLabel>
              <Select
                value={formData.tipo}
                label="Tipo de Movimiento"
                onChange={(e) => setFormData({ ...formData, tipo: e.target.value })}
              >
                <MenuItem value="entrada">Entrada (Suma)</MenuItem>
                <MenuItem value="salida">Salida (Resta)</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* Cantidad */}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Cantidad"
              type="number"
              inputProps={{ min: 1 }}
              value={formData.cantidad}
              onChange={(e) => setFormData({ ...formData, cantidad: parseInt(e.target.value, 10) })}
              fullWidth
              size="small"
              required
              error={!!errors.cantidad}
              helperText={errors.cantidad}
            />
          </Grid>

          {/* Motivo */}
          <Grid item xs={12} sm={6}>
            <FormControl fullWidth size="small">
              <InputLabel>Motivo</InputLabel>
              <Select
                value={formData.motivo}
                label="Motivo"
                onChange={(e) => setFormData({ ...formData, motivo: e.target.value })}
              >
                <MenuItem value="">--- Seleccionar ---</MenuItem>
                <MenuItem value="Compra">Compra a proveedor</MenuItem>
                <MenuItem value="Devolución">Devolución de cliente</MenuItem>
                <MenuItem value="Ajuste">Ajuste de inventario</MenuItem>
                <MenuItem value="Pérdida">Pérdida/Rotura</MenuItem>
                <MenuItem value="Venta">Venta a cliente</MenuItem>
                <MenuItem value="Traslado">Traslado entre almacenes</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* Observaciones */}
          <Grid item xs={12}>
            <TextField
              label="Observaciones"
              placeholder="Detalles adicionales del movimiento"
              value={formData.observaciones}
              onChange={(e) => setFormData({ ...formData, observaciones: e.target.value })}
              fullWidth
              multiline
              rows={3}
              size="small"
            />
          </Grid>
        </Grid>

        {/* Actions */}
        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/inventario")}
            disabled={isSubmitting || isCreating}
          >
            Cancelar
          </Button>
          <Button
            variant="contained"
            type="submit"
            disabled={isSubmitting || isCreating}
            startIcon={isSubmitting && <CircularProgress size={20} />}
          >
            {isSubmitting ? "Guardando..." : "Registrar Movimiento"}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
