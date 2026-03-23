// components/modules/articulos/ArticuloForm.tsx
"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
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
  Autocomplete,
  Switch,
  FormControlLabel,
  InputAdornment,
  Tooltip,
} from "@mui/material";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import { FormGrid, FormField } from '@zentto/shared-ui';
import { useArticuloById, useCreateArticulo, useUpdateArticulo } from "../../../hooks/useArticulos";
import { apiGet } from "@zentto/shared-api";
import { useQuery } from "@tanstack/react-query";

interface ArticuloFormProps {
  codigoArticulo?: string;
}

interface FormState {
  codigo?: string;
  nombre: string;
  categoria: string;
  marca: string;
  tipo: string;
  linea: string;
  clase: string;
  unidad: string;
  precioVenta: number;
  precioCompra: number;
  stock: number;
  minimo: number;
  maximo: number;
  ubicacion: string;
  barra: string;
  referencia: string;
  nParte: string;
  porcentaje: number;
  servicio: boolean;
  descripcion: string;
}

const INITIAL_FORM: FormState = {
  nombre: "", categoria: "", marca: "", tipo: "", linea: "",
  clase: "", unidad: "", precioVenta: 0, precioCompra: 0, stock: 0,
  minimo: 0, maximo: 0, ubicacion: "", barra: "", referencia: "", nParte: "",
  porcentaje: 0, servicio: false, descripcion: "",
};

export default function ArticuloForm({ codigoArticulo }: ArticuloFormProps) {
  const router = useRouter();
  const pathname = usePathname() || '';
  const basePath = pathname.includes('/inventario/') ? '/inventario/articulos' : '/articulos';
  const isEdit = !!codigoArticulo;

  const [formData, setFormData] = useState<FormState>(INITIAL_FORM);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [estado, setEstado] = useState("Activo");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Filters para autocomplete
  const { data: filters } = useQuery({
    queryKey: ["inventario-filters"],
    queryFn: () => apiGet("/v1/inventario/filters") as Promise<Record<string, string[]>>,
    staleTime: 5 * 60 * 1000,
  });

  // Tasa de cambio BCV
  const { data: tasaData } = useQuery({
    queryKey: ["config-tasas"],
    queryFn: () => apiGet("/v1/config/tasas") as Promise<{ success?: boolean; USD?: number; EUR?: number }>,
    staleTime: 10 * 60 * 1000,
  });
  const tasaCambio = tasaData?.USD || 1;

  const { data: articulo, isLoading: isLoadingArticulo } = useArticuloById(codigoArticulo || "");
  const { mutate: createArticulo, isPending: isCreating } = useCreateArticulo();
  const { mutate: updateArticulo, isPending: isUpdating } = useUpdateArticulo(codigoArticulo || "");

  useEffect(() => {
    if (isEdit && articulo) {
      setFormData({
        codigo: articulo.codigo,
        nombre: articulo.descripcion || articulo.nombre || "",
        categoria: articulo.categoria || "",
        marca: articulo.marca || "",
        tipo: articulo.tipo || "",
        linea: articulo.linea || "",
        clase: articulo.clase || "",
        unidad: articulo.unidad || "",
        precioVenta: articulo.precioVenta || articulo.precio || 0,
        precioCompra: articulo.precioCompra || 0,
        stock: articulo.stock || 0,
        minimo: articulo.minimo || 0,
        maximo: articulo.maximo || 0,
        ubicacion: articulo.ubicacion || "",
        barra: articulo.barra || "",
        referencia: articulo.referencia || "",
        nParte: articulo.nParte || "",
        porcentaje: (articulo.precioCompra && articulo.precioVenta && articulo.precioCompra > 0)
          ? Math.round(((articulo.precioVenta - articulo.precioCompra) / articulo.precioCompra) * 10000) / 100
          : 0,
        servicio: articulo.servicio || false,
        descripcion: (articulo as any).descripcion || "",
      });
      setEstado(articulo.estado);
    }
  }, [articulo, isEdit]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    if (!isEdit && !formData.codigo?.trim()) newErrors.codigo = "El código es requerido";
    if (!formData.nombre?.trim()) newErrors.nombre = "El nombre es requerido";
    if (!formData.categoria?.trim()) newErrors.categoria = "La categoría es requerida";
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const set = (field: keyof FormState) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setFormData({ ...formData, [field]: e.target.value });

  const setNum = (field: keyof FormState) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setFormData({ ...formData, [field]: e.target.value === "" ? 0 : parseFloat(e.target.value) });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);
    if (!validateForm()) return;
    setIsSubmitting(true);

    try {
      const submitData: Record<string, unknown> = {
        CODIGO: formData.codigo,
        DESCRIPCION: formData.nombre,
        Categoria: formData.categoria,
        Marca: formData.marca,
        Tipo: formData.servicio ? 'Servicio' : 'Producto',
        Linea: formData.linea,
        Clase: formData.clase,
        Unidad: formData.unidad,
        PRECIO_VENTA: formData.precioVenta,
        PRECIO_COMPRA: formData.precioCompra,
        EXISTENCIA: formData.stock,
        MINIMO: formData.minimo,
        MAXIMO: formData.maximo,
        UBICACION: formData.ubicacion,
        Barra: formData.barra,
        Referencia: formData.referencia,
        N_PARTE: formData.nParte,
        PORCENTAJE: formData.porcentaje,
        Servicio: formData.servicio,
        Descripcion: formData.descripcion,
      };

      const onSuccess = () => {
        setSubmitSuccess(true);
        setTimeout(() => router.push(basePath), 1500);
      };
      const onError = (error: unknown) => {
        setSubmitError(error instanceof Error ? error.message : "Error al guardar");
      };

      if (isEdit && codigoArticulo) {
        updateArticulo(submitData as any, { onSuccess, onError });
      } else {
        createArticulo(submitData as any, { onSuccess, onError });
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

  const autoField = (label: string, field: keyof FormState, options: string[], required = false) => (
    <Autocomplete
      freeSolo
      options={options}
      value={formData[field] as string}
      onInputChange={(_e, value) => setFormData({ ...formData, [field]: value })}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          size="small"
          required={required}
          error={!!errors[field]}
          helperText={errors[field]}
        />
      )}
    />
  );

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
        <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 2 }}>Información básica</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={4}>
            <TextField label="Código" placeholder="Ej: DEP-BAND-01" value={formData.codigo || ""}
              onChange={set('codigo' as any)} size="small" required disabled={isEdit}
              error={!!errors.codigo} helperText={errors.codigo} />
          </FormField>

          <FormField xs={12} sm={4}>
            <TextField label="Nombre del Producto" placeholder="Ej: Banda Deportiva" value={formData.nombre}
              onChange={set('nombre')} size="small" required error={!!errors.nombre} helperText={errors.nombre} />
          </FormField>

          <FormField xs={12} sm={4}>
            <TextField label="Referencia" value={formData.referencia} onChange={set('referencia')} size="small"
              InputProps={{ endAdornment: <InputAdornment position="end"><Tooltip title="Código que el proveedor asigna a este producto en su sistema. Útil para hacer pedidos de reposición."><InfoOutlinedIcon sx={{ fontSize: 18, color: 'text.secondary', cursor: 'pointer' }} /></Tooltip></InputAdornment> }} />
          </FormField>
        </FormGrid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>Clasificación</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={4}>
            {autoField("Categoría", "categoria", filters?.categorias ?? [], true)}
          </FormField>
          <FormField xs={12} sm={4}>
            {autoField("Marca", "marca", filters?.marcas ?? [])}
          </FormField>
          <FormField xs={12} sm={4}>
            {autoField("Línea", "linea", filters?.lineas ?? [])}
          </FormField>
          <FormField xs={12} sm={4}>
            {autoField("Clase", "clase", filters?.clases ?? [])}
          </FormField>
          <FormField xs={12} sm={4}>
            {formData.servicio ? (
              <TextField label="Unidad" value="UND" disabled size="small" />
            ) : (
              autoField("Unidad", "unidad", filters?.unidades ?? [])
            )}
          </FormField>
          <FormField xs={12} sm={4} sx={{ display: "flex", alignItems: "center" }}>
            <FormControlLabel
              control={<Switch checked={formData.servicio} onChange={(e) => setFormData({ ...formData, servicio: e.target.checked })} />}
              label="Es servicio (sin stock)"
            />
          </FormField>
        </FormGrid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>Precios</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={4}>
            <TextField label="Precio Compra (Bs)" type="number" inputProps={{ min: 0, step: "0.01" }}
              value={formData.precioCompra || ""} onChange={setNum('precioCompra')} size="small" />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField label="Precio Venta (Bs)" type="number" inputProps={{ min: 0, step: "0.01" }}
              value={formData.precioVenta || ""} onChange={setNum('precioVenta')} size="small" />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField
              label="Precio Venta ($)"
              value={formData.precioVenta > 0 && tasaCambio > 1 ? `$ ${(formData.precioVenta / tasaCambio).toFixed(2)}` : "—"}
              disabled
              size="small"
              helperText={tasaCambio > 1 ? `Tasa BCV: ${tasaCambio.toFixed(2)} Bs/$` : "Sin tasa disponible"}
            />
          </FormField>
        </FormGrid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>Inventario</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={4}>
            <TextField label="Stock" type={formData.servicio ? "text" : "number"} inputProps={{ min: 0 }}
              value={formData.servicio ? "—" : (formData.stock || "")} onChange={setNum('stock')} size="small" disabled={formData.servicio} />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField label="Mínimo" type={formData.servicio ? "text" : "number"} inputProps={{ min: 0 }}
              value={formData.servicio ? "—" : (formData.minimo || "")} onChange={setNum('minimo')} size="small" disabled={formData.servicio}
              InputProps={{ endAdornment: !formData.servicio ? <InputAdornment position="end"><Tooltip title="Cantidad mínima de stock. Si el inventario baja de este número, se genera una alerta de reposición."><InfoOutlinedIcon sx={{ fontSize: 18, color: 'text.secondary', cursor: 'pointer' }} /></Tooltip></InputAdornment> : undefined }} />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField label="Máximo" type={formData.servicio ? "text" : "number"} inputProps={{ min: 0 }}
              value={formData.servicio ? "—" : (formData.maximo || "")} onChange={setNum('maximo')} size="small" disabled={formData.servicio}
              InputProps={{ endAdornment: !formData.servicio ? <InputAdornment position="end"><Tooltip title="Cantidad máxima de stock recomendada. Ayuda a evitar sobrecompras."><InfoOutlinedIcon sx={{ fontSize: 18, color: 'text.secondary', cursor: 'pointer' }} /></Tooltip></InputAdornment> : undefined }} />
          </FormField>
        </FormGrid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>Identificación</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12} sm={4}>
            <TextField label="Código de Barras" value={formData.barra} onChange={set('barra')} size="small" />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField label="N° Parte" value={formData.nParte} onChange={set('nParte')} size="small" />
          </FormField>
          <FormField xs={12} sm={4}>
            <TextField label="Ubicación" value={formData.ubicacion} onChange={set('ubicacion')} size="small" />
          </FormField>

          {isEdit && (
            <FormField xs={12} sm={4}>
              <FormControl size="small" fullWidth>
                <InputLabel>Estado</InputLabel>
                <Select value={estado} label="Estado" onChange={(e) => setEstado(e.target.value)}>
                  <MenuItem value="Activo">Activo</MenuItem>
                  <MenuItem value="Inactivo">Inactivo</MenuItem>
                </Select>
              </FormControl>
            </FormField>
          )}
        </FormGrid>

        <Typography variant="subtitle2" color="text.secondary" sx={{ mt: 3, mb: 2 }}>Descripción</Typography>
        <FormGrid spacing={2}>
          <FormField xs={12}>
            <TextField label="Descripción del producto" value={formData.descripcion}
              onChange={set('descripcion')} multiline rows={3} size="small"
              placeholder="Detalles adicionales, notas internas, especificaciones..." />
          </FormField>
        </FormGrid>

        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button variant="outlined" onClick={() => router.push(basePath)}
            disabled={isSubmitting || isCreating || isUpdating}>
            Cancelar
          </Button>
          <Button variant="contained" type="submit"
            disabled={isSubmitting || isCreating || isUpdating}
            startIcon={isSubmitting && <CircularProgress size={20} />}>
            {isSubmitting ? "Guardando..." : isEdit ? "Actualizar" : "Crear"}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
