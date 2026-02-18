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
  Grid,
  Typography,
  MenuItem,
} from "@mui/material";
import { useArticuloById, useCreateArticulo, useUpdateArticulo, useArticuloFilterOptions } from "@/hooks/useArticulos";
import { CreateArticuloDTO, UpdateArticuloDTO } from "@/lib/types";

interface ArticuloFormProps {
  codigoArticulo?: string;
}

/** Datos del formulario mapeados a los nombres de columna SQL */
interface FormState {
  CODIGO: string;
  DESCRIPCION: string;
  Referencia: string;
  Categoria: string;
  Tipo: string;
  Marca: string;
  Clase: string;
  Linea: string;
  Unidad: string;
  PRECIO_VENTA: number;
  PRECIO_COMPRA: number;
  PORCENTAJE: number;
  Barra: string;
}

const EMPTY_FORM: FormState = {
  CODIGO: "",
  DESCRIPCION: "",
  Referencia: "",
  Categoria: "",
  Tipo: "",
  Marca: "",
  Clase: "",
  Linea: "",
  Unidad: "",
  PRECIO_VENTA: 0,
  PRECIO_COMPRA: 0,
  PORCENTAJE: 0,
  Barra: "",
};

export default function ArticuloForm({ codigoArticulo }: ArticuloFormProps) {
  const router = useRouter();
  const isEdit = !!codigoArticulo;

  const [formData, setFormData] = useState<FormState>({ ...EMPTY_FORM });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Queries
  const { data: articulo, isLoading: isLoadingArticulo } = useArticuloById(codigoArticulo || "");
  const { data: filterOptions } = useArticuloFilterOptions();
  const { mutate: createArticulo, isPending: isCreating } = useCreateArticulo();
  const { mutate: updateArticulo, isPending: isUpdating } = useUpdateArticulo(codigoArticulo || "");

  const isBusy = isCreating || isUpdating;

  // Cargar datos del artículo al editar
  useEffect(() => {
    if (isEdit && articulo) {
      setFormData({
        CODIGO: articulo.codigo,
        DESCRIPCION: articulo.descripcion,
        Referencia: articulo.referencia,
        Categoria: articulo.categoria,
        Tipo: articulo.tipo,
        Marca: articulo.marca,
        Clase: articulo.clase,
        Linea: articulo.linea,
        Unidad: articulo.unidad,
        PRECIO_VENTA: articulo.precioVenta,
        PRECIO_COMPRA: articulo.precioCompra,
        PORCENTAJE: articulo.porcentaje,
        Barra: articulo.barra,
      });
    }
  }, [articulo, isEdit]);

  // Validación
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.DESCRIPCION?.trim()) {
      newErrors.DESCRIPCION = "La descripción es requerida";
    }

    if (formData.PRECIO_VENTA < 0) {
      newErrors.PRECIO_VENTA = "El precio no puede ser negativo";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Helper para cambiar un campo
  const setField = (field: keyof FormState, value: string | number) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  // Submit
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);
    if (!validateForm()) return;

    const dto: CreateArticuloDTO = {
      DESCRIPCION: formData.DESCRIPCION.trim(),
      Categoria: formData.Categoria.trim() || undefined,
      Tipo: formData.Tipo.trim() || undefined,
      Marca: formData.Marca.trim() || undefined,
      Clase: formData.Clase.trim() || undefined,
      Linea: formData.Linea.trim() || undefined,
      Unidad: formData.Unidad.trim() || undefined,
      PRECIO_VENTA: formData.PRECIO_VENTA,
      PRECIO_COMPRA: formData.PRECIO_COMPRA,
      PORCENTAJE: formData.PORCENTAJE,
      Referencia: formData.Referencia.trim() || undefined,
      Barra: formData.Barra.trim() || undefined,
    };

    const onSuccess = () => {
      setSubmitSuccess(true);
      setTimeout(() => router.push("/articulos"), 1200);
    };
    const onError = (error: Error) => {
      setSubmitError(error.message || "Error al guardar");
    };

    if (isEdit) {
      updateArticulo(dto as UpdateArticuloDTO, { onSuccess, onError });
    } else {
      if (formData.CODIGO.trim()) {
        (dto as any).CODIGO = formData.CODIGO.trim();
      }
      createArticulo(dto, { onSuccess, onError });
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
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>
          Identificación
        </Typography>
        <Grid container spacing={2}>
          {/* Código */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Código"
              value={formData.CODIGO}
              onChange={(e) => setField("CODIGO", e.target.value)}
              disabled={isEdit}
              fullWidth
              size="small"
            />
          </Grid>
          {/* Referencia */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Referencia"
              value={formData.Referencia}
              onChange={(e) => setField("Referencia", e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
          {/* Código de Barras */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Código de Barras"
              value={formData.Barra}
              onChange={(e) => setField("Barra", e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
        </Grid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>
          Descripción
        </Typography>
        <Grid container spacing={2}>
          {/* Línea (Departamento) */}
          <Grid item xs={12} sm={4}>
            <TextField
              select
              label="Línea (Departamento)"
              value={formData.Linea}
              onChange={(e) => setField("Linea", e.target.value)}
              fullWidth
              size="small"
            >
              <MenuItem value="">Sin línea</MenuItem>
              {(filterOptions?.lineas ?? []).map((l) => (
                <MenuItem key={l} value={l}>{l}</MenuItem>
              ))}
            </TextField>
          </Grid>
          {/* Categoría */}
          <Grid item xs={12} sm={4}>
            <TextField
              select
              label="Categoría"
              value={formData.Categoria}
              onChange={(e) => setField("Categoria", e.target.value)}
              fullWidth
              size="small"
            >
              <MenuItem value="">Sin categoría</MenuItem>
              {(filterOptions?.categorias ?? []).map((c) => (
                <MenuItem key={c} value={c}>{c}</MenuItem>
              ))}
            </TextField>
          </Grid>
          {/* Tipo */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Tipo"
              value={formData.Tipo}
              onChange={(e) => setField("Tipo", e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
          {/* Marca */}
          <Grid item xs={12} sm={4}>
            <TextField
              select
              label="Marca"
              value={formData.Marca}
              onChange={(e) => setField("Marca", e.target.value)}
              fullWidth
              size="small"
            >
              <MenuItem value="">Sin marca</MenuItem>
              {(filterOptions?.marcas ?? []).map((m) => (
                <MenuItem key={m} value={m}>{m}</MenuItem>
              ))}
            </TextField>
          </Grid>
          {/* Clase */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Clase"
              value={formData.Clase}
              onChange={(e) => setField("Clase", e.target.value)}
              fullWidth
              size="small"
            />
          </Grid>
          {/* Unidad */}
          <Grid item xs={12} sm={4}>
            <TextField
              select
              label="Unidad"
              value={formData.Unidad}
              onChange={(e) => setField("Unidad", e.target.value)}
              fullWidth
              size="small"
            >
              <MenuItem value="">Sin unidad</MenuItem>
              {(filterOptions?.unidades ?? []).map((u) => (
                <MenuItem key={u} value={u}>{u}</MenuItem>
              ))}
            </TextField>
          </Grid>
          {/* Descripción libre */}
          <Grid item xs={12}>
            <TextField
              label="Descripción"
              placeholder="Descripción adicional del artículo"
              value={formData.DESCRIPCION}
              onChange={(e) => setField("DESCRIPCION", e.target.value)}
              fullWidth
              size="small"
              required
              error={!!errors.DESCRIPCION}
              helperText={errors.DESCRIPCION}
            />
          </Grid>
        </Grid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>
          Precios
        </Typography>
        <Grid container spacing={2}>
          {/* Precio Compra */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Precio Compra"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.PRECIO_COMPRA}
              onChange={(e) => setField("PRECIO_COMPRA", parseFloat(e.target.value) || 0)}
              fullWidth
              size="small"
            />
          </Grid>
          {/* % Ganancia */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="% Ganancia"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.PORCENTAJE}
              onChange={(e) => setField("PORCENTAJE", parseFloat(e.target.value) || 0)}
              fullWidth
              size="small"
            />
          </Grid>
          {/* Precio Venta */}
          <Grid item xs={12} sm={4}>
            <TextField
              label="Precio Venta"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={formData.PRECIO_VENTA}
              onChange={(e) => setField("PRECIO_VENTA", parseFloat(e.target.value) || 0)}
              fullWidth
              size="small"
              error={!!errors.PRECIO_VENTA}
              helperText={errors.PRECIO_VENTA}
            />
          </Grid>
        </Grid>

        {/* Botones */}
        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button
            variant="outlined"
            onClick={() => router.push("/articulos")}
            disabled={isBusy}
          >
            Cancelar
          </Button>
          <Button
            variant="contained"
            type="submit"
            disabled={isBusy}
            startIcon={isBusy ? <CircularProgress size={20} /> : undefined}
          >
            {isBusy ? "Guardando..." : isEdit ? "Actualizar" : "Crear"}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
