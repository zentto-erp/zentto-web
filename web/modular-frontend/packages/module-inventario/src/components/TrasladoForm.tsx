// components/TrasladoForm.tsx
"use client";

import { useState, useEffect, useCallback, useRef } from "react";
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
  Autocomplete,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import SwapHorizIcon from "@mui/icons-material/SwapHoriz";
import { useCreateTraslado } from "../hooks/useInventario";
import { apiGet } from "@zentto/shared-api";

interface ArticuloOption {
  CODIGO: string;
  DESCRIPCION?: string;
  DescripcionCompleta?: string;
  EXISTENCIA?: number;
}

interface AlmacenOption {
  Codigo: string;
  Descripcion: string;
  Tipo?: string;
}

export default function TrasladoForm() {
  const router = useRouter();
  const { mutate: crearTraslado, isPending } = useCreateTraslado();

  // Articulo autocomplete
  const [articuloSelected, setArticuloSelected] = useState<ArticuloOption | null>(null);
  const [articuloInput, setArticuloInput] = useState("");
  const [articuloOptions, setArticuloOptions] = useState<ArticuloOption[]>([]);
  const [articuloLoading, setArticuloLoading] = useState(false);
  const articuloTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Almacenes
  const [almacenes, setAlmacenes] = useState<AlmacenOption[]>([]);
  const [warehouseFrom, setWarehouseFrom] = useState("");
  const [warehouseTo, setWarehouseTo] = useState("");

  // Form
  const [quantity, setQuantity] = useState(1);
  const [notes, setNotes] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Cargar almacenes
  useEffect(() => {
    apiGet("/api/v1/almacen").then((resp: unknown) => {
      const data = resp as { rows?: AlmacenOption[] };
      setAlmacenes(data.rows ?? []);
    }).catch(() => {});
  }, []);

  // Buscar articulos
  const fetchArticulos = useCallback(async (search: string) => {
    if (!search.trim()) { setArticuloOptions([]); return; }
    setArticuloLoading(true);
    try {
      const resp = await apiGet("/api/v1/inventario", { search: search.trim(), page: 1, limit: 10 });
      setArticuloOptions(((resp as Record<string, unknown>)?.rows as ArticuloOption[]) ?? []);
    } catch { setArticuloOptions([]); }
    finally { setArticuloLoading(false); }
  }, []);

  useEffect(() => {
    if (articuloTimer.current) clearTimeout(articuloTimer.current);
    if (!articuloInput.trim()) {
      setArticuloOptions(articuloSelected ? [articuloSelected] : []);
      return;
    }
    articuloTimer.current = setTimeout(() => fetchArticulos(articuloInput), 300);
    return () => { if (articuloTimer.current) clearTimeout(articuloTimer.current); };
  }, [articuloInput, fetchArticulos, articuloSelected]);

  const validate = (): boolean => {
    const e: Record<string, string> = {};
    if (!articuloSelected) e.articulo = "Seleccione un articulo";
    if (!warehouseFrom) e.warehouseFrom = "Seleccione almacen origen";
    if (!warehouseTo) e.warehouseTo = "Seleccione almacen destino";
    if (warehouseFrom && warehouseTo && warehouseFrom === warehouseTo) e.warehouseTo = "Destino debe ser diferente al origen";
    if (!quantity || quantity <= 0) e.quantity = "Cantidad debe ser mayor a 0";
    if (articuloSelected && quantity > (articuloSelected.EXISTENCIA ?? 0)) e.quantity = `Stock insuficiente. Disponible: ${articuloSelected.EXISTENCIA ?? 0}`;
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);
    if (!validate()) return;

    crearTraslado(
      {
        productCode: articuloSelected!.CODIGO,
        quantity,
        warehouseFrom,
        warehouseTo,
        notes: notes || undefined,
      },
      {
        onSuccess: () => {
          setSubmitSuccess(true);
          setTimeout(() => router.push("/movimientos"), 1500);
        },
        onError: (err) => {
          setSubmitError(err instanceof Error ? err.message : "Error al ejecutar traslado");
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, display: "flex", alignItems: "center", gap: 1 }}>
        <SwapHorizIcon /> Traslado entre Almacenes
      </Typography>

      {submitSuccess && <Alert severity="success" sx={{ mb: 2 }}>Traslado ejecutado exitosamente</Alert>}
      {submitError && <Alert severity="error" sx={{ mb: 2 }}>{submitError}</Alert>}

      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3 }}>
        <Grid container spacing={2}>
          {/* Articulo */}
          <Grid size={12}>
            <Autocomplete<ArticuloOption>
              value={articuloSelected}
              onChange={(_, value) => setArticuloSelected(value)}
              inputValue={articuloInput}
              onInputChange={(_, value) => setArticuloInput(value)}
              options={articuloOptions}
              loading={articuloLoading}
              getOptionLabel={(opt) => `${opt.CODIGO} — ${opt.DescripcionCompleta ?? opt.DESCRIPCION ?? ""}`}
              isOptionEqualToValue={(a, b) => a.CODIGO === b.CODIGO}
              filterOptions={(x) => x}
              noOptionsText={articuloInput.trim() ? "Sin resultados" : "Escriba para buscar..."}
              renderOption={(props, opt) => (
                <li {...props} key={opt.CODIGO}>
                  <Box>
                    <Typography variant="body2" fontWeight="bold">{opt.CODIGO}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {opt.DescripcionCompleta ?? opt.DESCRIPCION ?? ""}
                      {opt.EXISTENCIA !== undefined ? ` — Stock: ${opt.EXISTENCIA}` : ""}
                    </Typography>
                  </Box>
                </li>
              )}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Articulo"
                  size="small"
                  placeholder="Buscar por codigo o nombre..."
                  error={!!errors.articulo}
                  helperText={errors.articulo}
                  InputProps={{
                    ...params.InputProps,
                    endAdornment: (
                      <>{articuloLoading ? <CircularProgress color="inherit" size={18} /> : null}{params.InputProps.endAdornment}</>
                    ),
                  }}
                />
              )}
            />
          </Grid>

          {/* Stock actual */}
          {articuloSelected && (
            <Grid size={12}>
              <Alert severity="info" sx={{ py: 0.5 }}>
                Stock actual de <strong>{articuloSelected.CODIGO}</strong>: <strong>{articuloSelected.EXISTENCIA ?? 0}</strong> unidades
              </Alert>
            </Grid>
          )}

          {/* Almacen Origen */}
          <Grid size={{ xs: 12, sm: 6 }}>
            <FormControl fullWidth size="small" error={!!errors.warehouseFrom}>
              <InputLabel>Almacen Origen</InputLabel>
              <Select value={warehouseFrom} label="Almacen Origen" onChange={(e) => setWarehouseFrom(e.target.value)}>
                <MenuItem value="">— Seleccionar —</MenuItem>
                {almacenes.map((a) => (
                  <MenuItem key={a.Codigo} value={a.Codigo}>{a.Codigo} — {a.Descripcion}</MenuItem>
                ))}
              </Select>
              {errors.warehouseFrom && <Typography variant="caption" color="error" sx={{ ml: 2 }}>{errors.warehouseFrom}</Typography>}
            </FormControl>
          </Grid>

          {/* Almacen Destino */}
          <Grid size={{ xs: 12, sm: 6 }}>
            <FormControl fullWidth size="small" error={!!errors.warehouseTo}>
              <InputLabel>Almacen Destino</InputLabel>
              <Select value={warehouseTo} label="Almacen Destino" onChange={(e) => setWarehouseTo(e.target.value)}>
                <MenuItem value="">— Seleccionar —</MenuItem>
                {almacenes.filter((a) => a.Codigo !== warehouseFrom).map((a) => (
                  <MenuItem key={a.Codigo} value={a.Codigo}>{a.Codigo} — {a.Descripcion}</MenuItem>
                ))}
              </Select>
              {errors.warehouseTo && <Typography variant="caption" color="error" sx={{ ml: 2 }}>{errors.warehouseTo}</Typography>}
            </FormControl>
          </Grid>

          {/* Cantidad */}
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Cantidad"
              type="number"
              inputProps={{ min: 1 }}
              value={quantity}
              onChange={(e) => setQuantity(parseInt(e.target.value, 10) || 0)}
              fullWidth
              size="small"
              required
              error={!!errors.quantity}
              helperText={errors.quantity}
            />
          </Grid>

          {/* Notas */}
          <Grid size={12}>
            <TextField
              label="Notas / Observaciones"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              fullWidth
              multiline
              rows={2}
              size="small"
            />
          </Grid>
        </Grid>

        {/* Actions */}
        <Box sx={{ display: "flex", gap: 2, mt: 4, justifyContent: "flex-end" }}>
          <Button variant="outlined" onClick={() => router.push("/movimientos")} disabled={isPending}>
            Cancelar
          </Button>
          <Button variant="contained" type="submit" disabled={isPending} startIcon={isPending ? <CircularProgress size={20} /> : <SwapHorizIcon />}>
            {isPending ? "Ejecutando..." : "Ejecutar Traslado"}
          </Button>
        </Box>
      </Paper>
    </Box>
  );
}
