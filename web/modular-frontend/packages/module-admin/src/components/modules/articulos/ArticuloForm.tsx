// components/modules/articulos/ArticuloForm.tsx
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
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from "@mui/material";
import { FormGrid, FormField } from '@zentto/shared-ui';
import { useArticuloById, useCreateArticulo, useUpdateArticulo } from "../../../hooks/useArticulos";
import { Articulo, CreateArticuloDTO, UpdateArticuloDTO } from "@zentto/shared-api/types";

interface ArticuloFormProps {
  codigoArticulo?: string;
}

export default function ArticuloForm({ codigoArticulo }: ArticuloFormProps) {
  const router = useRouter();
  const isEdit = !!codigoArticulo;

  // State
  const [formData, setFormData] = useState<CreateArticuloDTO & { codigo?: string }>({
    nombre: "",
    descripcion: "",
    precio: 0,
    stock: 0,
    categoria: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [estado, setEstado] = useState("Activo");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Queries
  const { data: articulo, isLoading: isLoadingArticulo } = useArticuloById(codigoArticulo || "");
  const { mutate: createArticulo, isPending: isCreating } = useCreateArticulo();
  const { mutate: updateArticulo, isPending: isUpdating } = useUpdateArticulo(codigoArticulo || "");

  // Load articulo data on edit
  useEffect(() => {
    if (isEdit && articulo) {
      setFormData({
        codigo: articulo.codigo,
        nombre: articulo.nombre,
        descripcion: articulo.descripcion,
        precio: articulo.precio,
        stock: articulo.stock,
        categoria: articulo.categoria,
      });
      setEstado(articulo.estado);
    }
  }, [articulo, isEdit]);

  // Validation
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.nombre?.trim()) {
      newErrors.nombre = "El nombre es requerido";
    } else if (formData.nombre.length < 3) {
      newErrors.nombre = "El nombre debe tener al menos 3 caracteres";
    }

    if (!formData.precio || formData.precio < 0) {
      newErrors.precio = "El precio debe ser mayor que 0";
    }

    if (formData.stock < 0) {
      newErrors.stock = "El stock no puede ser negativo";
    }

    if (!formData.categoria?.trim()) {
      newErrors.categoria = "La categoría es requerida";
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
      const submitData: CreateArticuloDTO & { estado?: string } = {
        nombre: formData.nombre,
        descripcion: formData.descripcion || "",
        precio: formData.precio,
        stock: formData.stock,
        categoria: formData.categoria,
        estado,
      };

      if (isEdit && codigoArticulo) {
        updateArticulo(submitData as UpdateArticuloDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/articulos"), 1500);
          },
          onError: (error) => {
            setSubmitError(error instanceof Error ? error.message : "Error al actualizar");
          }
        });
      } else {
        createArticulo(submitData as CreateArticuloDTO, {
          onSuccess: () => {
            setSubmitSuccess(true);
            setTimeout(() => router.push("/articulos"), 1500);
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

  if (isEdit && isLoadingArticulo) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        {isEdit ? "Editar Artículo" : "Nuevo Artículo"}
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {isEdit ? "Artículo actualizado exitosamente" : "Artículo creado exitosamente"}
        </Alert>
      )}

      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <FormGrid spacing={2}>
          {/* Código (Read-only en edición) */}
          {isEdit && (
            <FormField xs={12} sm={6}>
              <TextField
                label="Código"
                value={formData.codigo || ""}
                disabled
               
              />
            </FormField>
          )}

          {/* Nombre */}
          <FormField xs={12} sm={isEdit ? 6 : 12}>
            <TextField
              label="Nombre del Artículo"
              placeholder="Ej: Laptop Dell"
              value={formData.nombre}
              onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
              required
              error={!!errors.nombre}
              helperText={errors.nombre}
            />
          </FormField>

          {/* Descripción */}
          <FormField xs={12}>
            <TextField
              label="Descripción"
              placeholder="Detalles adicionales del artículo"
              value={formData.descripcion}
              onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
              multiline
              rows={3}
            />
          </FormField>

          {/* Categoría */}
          <FormField xs={12} sm={6}>
            <TextField
              label="Categoría"
              placeholder="Ej: Electrónica, Ropa, etc."
              value={formData.categoria}
              onChange={(e) => setFormData({ ...formData, categoria: e.target.value })}
              required
              error={!!errors.categoria}
              helperText={errors.categoria}
            />
          </FormField>

          {/* Precio */}
          <FormField xs={12} sm={6}>
            <TextField
              label="Precio (Bs.)"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.precio}
              onChange={(e) => setFormData({ ...formData, precio: parseFloat(e.target.value) })}
              required
              error={!!errors.precio}
              helperText={errors.precio}
            />
          </FormField>

          {/* Stock */}
          <FormField xs={12} sm={6}>
            <TextField
              label="Stock Disponible"
              type="number"
              inputProps={{ min: 0 }}
              value={formData.stock}
              onChange={(e) => setFormData({ ...formData, stock: parseInt(e.target.value, 10) })}
              error={!!errors.stock}
              helperText={errors.stock}
            />
          </FormField>

          {/* Estado */}
          {isEdit && (
            <FormField xs={12} sm={6}>
              <FormControl>
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
            </FormField>
          )}
        </FormGrid>

        {/* Actions */}
        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/articulos")}
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
