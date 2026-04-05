// components/AjusteInventarioForm.tsx
"use client";

import { useState, useCallback, useEffect, useRef, useMemo } from "react";
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
  InputAdornment,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { FormGrid, FormField } from "@zentto/shared-ui";
import SearchIcon from "@mui/icons-material/Search";
import { useCreateMovimiento, useInventarioList } from "../hooks/useInventario";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useInventarioGridRegistration } from "./zenttoGridPersistence";
import type { ColumnDef } from "@zentto/datagrid-core";
import { debounce } from "lodash";

interface SelectedArticulo {
  codigo: string;
  descripcion: string;
  stock: number;
  precio: number;
}

const GRID_ID = "module-inventario:ajuste:search";

const COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 110, sortable: true },
  { field: "articulo", header: "Articulo", flex: 1, minWidth: 160, sortable: true },
  { field: "stock", header: "Stock", width: 90, type: "number" },
  { field: "precio", header: "Precio", width: 110, type: "number", currency: "VES" },
];

export default function AjusteInventarioForm() {
  const router = useRouter();
  const gridRef = useRef<any>(null);

  // Search
  const [search, setSearch] = useState("");
  const { data: inventario, isLoading } = useInventarioList({ search, limit: 30 });
  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const debouncedSearch = useCallback(
    debounce((value: string) => setSearch(value), 400),
    []
  );

  const { ready } = useGridLayoutSync(GRID_ID);
  const { registered } = useInventarioGridRegistration(ready);

  // Selected article
  const [selected, setSelected] = useState<SelectedArticulo | null>(null);

  // Form
  const [cantidad, setCantidad] = useState(1);
  const [tipo, setTipo] = useState("ENTRADA");
  const [motivo, setMotivo] = useState("");
  const [observaciones, setObservaciones] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const { mutate: createMovimiento, isPending: isCreating } = useCreateMovimiento();

  const selectArticulo = (item: Record<string, unknown>) => {
    setSelected({
      codigo: String(item.CODIGO ?? item.ProductCode ?? ""),
      descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
      stock: Number(item.EXISTENCIA ?? item.Stock ?? 0),
      precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
    });
    setErrors((prev) => ({ ...prev, articulo: "" }));
  };

  const gridRows = useMemo(() => rows.map((item, i) => ({
    id: i,
    codigo: String(item.CODIGO ?? item.ProductCode ?? ""),
    articulo: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
    stock: Number(item.EXISTENCIA ?? item.Stock ?? 0),
    precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
  })), [rows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = gridRows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id;
  }, [gridRows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      if (e.detail?.row) {
        const row = e.detail.row;
        const item = rows.find((r) => String(r.CODIGO ?? r.ProductCode ?? "") === row.codigo);
        if (item) selectArticulo(item);
      }
    };
    el.addEventListener("row-click", handler);
    return () => el.removeEventListener("row-click", handler);
  }, [registered, rows]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    if (!selected) newErrors.articulo = "Seleccione un articulo de la lista";
    if (!cantidad || cantidad <= 0) newErrors.cantidad = "La cantidad debe ser mayor que 0";
    if (!motivo?.trim()) newErrors.motivo = "El motivo es requerido";
    if (tipo === "SALIDA" && selected && cantidad > selected.stock) {
      newErrors.cantidad = `Stock insuficiente. Disponible: ${selected.stock}`;
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSubmitSuccess(false);
    if (!validateForm()) return;

    createMovimiento(
      {
        productCode: selected!.codigo,
        movementType: tipo,
        quantity: cantidad,
        documentRef: motivo,
        notes: observaciones || undefined,
      },
      {
        onSuccess: () => {
          setSubmitSuccess(true);
          setSelected(null);
          setCantidad(1);
          setMotivo("");
          setObservaciones("");
        },
        onError: (error) => {
          setSubmitError(error instanceof Error ? error.message : "Error al crear movimiento");
        },
      }
    );
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600 }}>
        Ajuste de Inventario
      </Typography>

      {submitSuccess && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSubmitSuccess(false)}>
          Movimiento registrado exitosamente
        </Alert>
      )}
      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setSubmitError(null)}>
          {submitError}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Left: Article search grid */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Buscar Articulos
            </Typography>
            <TextField
              placeholder="Buscar por codigo o nombre..."
              onChange={(e) => debouncedSearch(e.target.value)}
              fullWidth
              sx={{ mb: 2 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon fontSize="small" />
                  </InputAdornment>
                ),
              }}
            />

            <zentto-grid
              ref={gridRef}
              grid-id={GRID_ID}
              height="420px"
              default-currency="VES"
              enable-header-filters
              enable-quick-search
              enable-status-bar
              enable-configurator
              enable-toolbar
              enable-header-menu
              enable-clipboard
              enable-context-menu
            />

            {errors.articulo && (
              <Alert severity="warning" sx={{ mt: 1 }}>{errors.articulo}</Alert>
            )}
          </Paper>
        </Grid>

        {/* Right: Form */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Paper component="form" onSubmit={handleSubmit} sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
              Datos del Movimiento
            </Typography>

            {/* Selected article info */}
            {selected ? (
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="body2" fontWeight={600}>{selected.codigo}</Typography>
                <Typography variant="caption" color="text.secondary">{selected.descripcion}</Typography>
                <Box sx={{ mt: 0.5, display: "flex", gap: 2 }}>
                  <Typography variant="caption">Stock: <strong>{selected.stock}</strong></Typography>
                  <Typography variant="caption">Precio: <strong>{formatCurrency(selected.precio)}</strong></Typography>
                </Box>
              </Alert>
            ) : (
              <Alert severity="warning" sx={{ mb: 2 }}>
                Seleccione un articulo de la lista
              </Alert>
            )}

            <FormGrid spacing={2}>
              <FormField xs={12}>
                <FormControl>
                  <InputLabel>Tipo de Movimiento</InputLabel>
                  <Select value={tipo} label="Tipo de Movimiento" onChange={(e) => setTipo(e.target.value)}>
                    <MenuItem value="ENTRADA">Entrada (Suma)</MenuItem>
                    <MenuItem value="SALIDA">Salida (Resta)</MenuItem>
                    <MenuItem value="AJUSTE">Ajuste</MenuItem>
                  </Select>
                </FormControl>
              </FormField>

              <FormField xs={12}>
                <TextField
                  label="Cantidad"
                  type="number"
                  inputProps={{ min: 1 }}
                  value={cantidad}
                  onChange={(e) => setCantidad(parseInt(e.target.value, 10) || 0)}
                  required
                  error={!!errors.cantidad}
                  helperText={errors.cantidad}
                />
              </FormField>

              <FormField xs={12}>
                <FormControl error={!!errors.motivo}>
                  <InputLabel>Motivo</InputLabel>
                  <Select value={motivo} label="Motivo" onChange={(e) => setMotivo(e.target.value)}>
                    <MenuItem value="">-- Seleccionar --</MenuItem>
                    <MenuItem value="Compra">Compra a proveedor</MenuItem>
                    <MenuItem value="Devolucion">Devolucion de cliente</MenuItem>
                    <MenuItem value="Ajuste">Ajuste de inventario</MenuItem>
                    <MenuItem value="Perdida">Perdida / Rotura</MenuItem>
                    <MenuItem value="Venta">Venta a cliente</MenuItem>
                    <MenuItem value="Otro">Otro</MenuItem>
                  </Select>
                  {errors.motivo && (
                    <Typography variant="caption" color="error" sx={{ ml: 2, mt: 0.5 }}>
                      {errors.motivo}
                    </Typography>
                  )}
                </FormControl>
              </FormField>

              <FormField xs={12}>
                <TextField
                  label="Observaciones"
                  placeholder="Detalles adicionales del movimiento"
                  value={observaciones}
                  onChange={(e) => setObservaciones(e.target.value)}
                  multiline
                  rows={3}
                />
              </FormField>
            </FormGrid>

            <Box sx={{ display: "flex", gap: 2, mt: 3, justifyContent: "flex-end" }}>
              <Button variant="outlined" onClick={() => router.back()} disabled={isCreating}>
                Cancelar
              </Button>
              <Button
                variant="contained"
                type="submit"
                disabled={isCreating || !selected}
                startIcon={isCreating ? <CircularProgress size={20} /> : null}
              >
                {isCreating ? "Guardando..." : "Registrar Movimiento"}
              </Button>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
