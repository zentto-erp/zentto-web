// components/modules/proveedores/ProveedorForm.tsx
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
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from "@mui/material";
import { useProveedorById, useCreateProveedor, useUpdateProveedor } from "@/hooks/useProveedores";
import { Proveedor, CreateProveedorDTO, UpdateProveedorDTO } from "@/lib/types";

interface ProveedorFormProps {
  proveedorCodigo?: string;
}

export default function ProveedorForm({ proveedorCodigo }: ProveedorFormProps) {
  const router = useRouter();
  const isEdit = !!proveedorCodigo;

  // State
  const [formData, setFormData] = useState<CreateProveedorDTO & { codigo?: string }>({
    nombre: "",
    rif: "",
    direccion: "",
    telefono: "",
    email: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [estado, setEstado] = useState("Activo");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Queries
  const { data: proveedor, isLoading: isLoadingProveedor } = useProveedorById(
    proveedorCodigo || ""
  );
  const { mutate: createProveedor, isPending: isCreating } = useCreateProveedor();
  const { mutate: updateProveedor, isPending: isUpdating } = useUpdateProveedor(
    proveedorCodigo || ""
  );

  // Load proveedor data on edit
  useEffect(() => {
    if (isEdit && proveedor) {
      setFormData({
        codigo: proveedor.codigo,
        nombre: proveedor.nombre,
        rif: proveedor.rif,
        direccion: proveedor.direccion,
        telefono: proveedor.telefono,
        email: proveedor.email,
      });
      setEstado(proveedor.estado);
    }
  }, [proveedor, isEdit]);

  // Validation
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.nombre?.trim()) {
      newErrors.nombre = "El nombre es requerido";
    } else if (formData.nombre.length < 3) {
      newErrors.nombre = "El nombre debe tener al menos 3 caracteres";
    }

    if (!formData.rif?.trim()) {
      newErrors.rif = "El RIF es requerido";
    } else if (!/^[A-Z0-9]{1,20}$/.test(formData.rif)) {
      newErrors.rif = "RIF inválido";
    }

    if (!formData.direccion?.trim()) {
      newErrors.direccion = "La dirección es requerida";
    }

    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = "Email inválido";
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
      const submitData: CreateProveedorDTO & { estado?: string } = {
        nombre: formData.nombre,
        rif: formData.rif,
        direccion: formData.direccion,
        telefono: formData.telefono || "",
        email: formData.email || "",
        estado,
      };

      if (isEdit && proveedorCodigo) {
        updateProveedor(submitData as UpdateProveedorDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/proveedores"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createProveedor(submitData as CreateProveedorDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/proveedores"), 1500);
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

  if (isEdit && isLoadingProveedor) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Proveedor" : "Nuevo Proveedor"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Proveedor actualizado exitosamente" : "Proveedor creado exitosamente"}
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <Grid container spacing={2}>
          {/* Código (Read-only en edición) */}
          {isEdit && (
            <Grid item xs={12} sm={6}>
              <TextField
                label="Código"
                value={formData.codigo || ""}
                disabled
                fullWidth
                size="small"
              />
            </Grid>
          )}

          {/* Nombre */}
          <Grid item xs={12} sm={isEdit ? 6 : 12}>
            <TextField
              label="Nombre del Proveedor"
              placeholder="Ej: Empresa XYZ"
              value={formData.nombre}
              onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
              fullWidth
              size="small"
              required
              error={!!errors.nombre}
              helperText={errors.nombre}
            />
          </Grid>

          {/* RIF */}
          <Grid item xs={12} sm={6}>
            <TextField
              label="RIF"
              placeholder="Ej: J12345678"
              value={formData.rif}
              onChange={(e) => setFormData({ ...formData, rif: e.target.value.toUpperCase() })}
              fullWidth
              size="small"
              required
              error={!!errors.rif}
              helperText={errors.rif}
            />
          </Grid>

          {/* Dirección */}
          <Grid item xs={12}>
            <TextField
              label="Dirección"
              placeholder="Calle, número, ciudad"
              value={formData.direccion}
              onChange={(e) => setFormData({ ...formData, direccion: e.target.value })}
              fullWidth
              multiline
              rows={3}
              size="small"
              required
              error={!!errors.direccion}
              helperText={errors.direccion}
            />
          </Grid>

          {/* Teléfono */}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Teléfono"
              placeholder="+58 212 1234567"
              value={formData.telefono}
              onChange={(e) => setFormData({ ...formData, telefono: e.target.value })}
              fullWidth
              size="small"
              type="tel"
            />
          </Grid>

          {/* Email */}
          <Grid item xs={12} sm={6}>
            <TextField
              label="Email"
              placeholder="proveedor@example.com"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              fullWidth
              size="small"
              type="email"
              error={!!errors.email}
              helperText={errors.email}
            />
          </Grid>

          {/* Estado */}
          {isEdit && (
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth size="small">
                <InputLabel>Estado</InputLabel>
                <Select
                  value={estado}
                  label="Estado"
                  onChange={(e) => setEstado(e.target.value)}
                >
                  <MenuItem value="Activo">Activo</MenuItem>
                  <MenuItem value="Inactivo">Inactivo</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          )}
        </Grid>

        {/* Actions */}
        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/proveedores")}
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

