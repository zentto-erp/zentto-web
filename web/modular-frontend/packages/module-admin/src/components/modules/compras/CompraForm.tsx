"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
  Tooltip,
} from "@mui/material";
import { FormGrid, FormField, DatePicker } from '@zentto/shared-ui';
import dayjs from "dayjs";
import { Add, Delete } from "@mui/icons-material";
import { apiGet, apiPost, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useEmitirCompraTx } from "../../../hooks/useCompras";

type ProveedorRow = {
  CODIGO: string;
  NOMBRE?: string;
  RIF?: string;
};

type InventarioRow = {
  CODIGO: string;
  DESCRIPCION?: string;
  Referencia?: string;
  PRECIO_COMPRA?: number;
  Alicuota?: number;
  ALICUOTA?: number;
};

type DetalleRow = {
  CODIGO: string;
  REFERENCIA?: string;
  DESCRIPCION: string;
  CANTIDAD: number;
  PRECIO_COSTO: number;
  ALICUOTA: number;
};

interface CompraFormProps {
  numeroCompra?: string;
}

function autoNumFact() {
  const d = new Date();
  const p = [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, "0"),
    String(d.getDate()).padStart(2, "0"),
    String(d.getHours()).padStart(2, "0"),
    String(d.getMinutes()).padStart(2, "0"),
    String(d.getSeconds()).padStart(2, "0")
  ].join("");
  return `C${p}`;
}

export default function CompraForm({ numeroCompra }: CompraFormProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const emitirTx = useEmitirCompraTx();
  const isEdit = !!numeroCompra;

  const [numFact, setNumFact] = useState(numeroCompra || autoNumFact());
  const [fecha, setFecha] = useState(toDateOnly(new Date(), timeZone));
  const [tipo, setTipo] = useState("CONTADO");
  const [codUsuario, setCodUsuario] = useState("SUP");
  const [concepto, setConcepto] = useState("");

  // --- Proveedor autocomplete state ---
  const [proveedorSelected, setProveedorSelected] = useState<ProveedorRow | null>(null);
  const [proveedorInput, setProveedorInput] = useState("");
  const [proveedorOptions, setProveedorOptions] = useState<ProveedorRow[]>([]);
  const [proveedorLoading, setProveedorLoading] = useState(false);
  const proveedorTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // --- Articulo autocomplete state ---
  const [articuloSelected, setArticuloSelected] = useState<InventarioRow | null>(null);
  const [articuloInput, setArticuloInput] = useState("");
  const [articuloOptions, setArticuloOptions] = useState<InventarioRow[]>([]);
  const [articuloLoading, setArticuloLoading] = useState(false);
  const articuloTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const [detalle, setDetalle] = useState<DetalleRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  const [linea, setLinea] = useState<DetalleRow>({
    CODIGO: "",
    REFERENCIA: "",
    DESCRIPCION: "",
    CANTIDAD: 1,
    PRECIO_COSTO: 0,
    ALICUOTA: 16
  });

  const [openNuevoArt, setOpenNuevoArt] = useState(false);
  const [newArt, setNewArt] = useState({
    CODIGO: "",
    DESCRIPCION: "",
    Referencia: "",
    PRECIO_COMPRA: 0,
    PRECIO_VENTA: 0,
    ALICUOTA: 16,
    EXISTENCIA: 0,
    Categoria: "GENERAL",
    Marca: ""
  });

  const subtotal = useMemo(
    () => detalle.reduce((acc, r) => acc + Number(r.CANTIDAD || 0) * Number(r.PRECIO_COSTO || 0), 0),
    [detalle]
  );
  const total = subtotal;

  // Derived from proveedorSelected
  const codProveedor = proveedorSelected?.CODIGO || "";
  const nombreProveedor = proveedorSelected?.NOMBRE || "";
  const rifProveedor = proveedorSelected?.RIF || "";

  // --- Proveedor search (debounced) ---
  const fetchProveedores = useCallback(async (search: string) => {
    if (!search.trim()) {
      setProveedorOptions([]);
      return;
    }
    setProveedorLoading(true);
    try {
      const resp = await apiGet("/api/v1/proveedores", { search: search.trim(), page: 1, limit: 10 });
      setProveedorOptions((resp?.rows as ProveedorRow[]) ?? []);
    } catch {
      setProveedorOptions([]);
    } finally {
      setProveedorLoading(false);
    }
  }, []);

  useEffect(() => {
    if (proveedorTimer.current) clearTimeout(proveedorTimer.current);
    if (!proveedorInput.trim()) {
      setProveedorOptions(proveedorSelected ? [proveedorSelected] : []);
      return;
    }
    proveedorTimer.current = setTimeout(() => fetchProveedores(proveedorInput), 300);
    return () => { if (proveedorTimer.current) clearTimeout(proveedorTimer.current); };
  }, [proveedorInput, fetchProveedores, proveedorSelected]);

  // --- Articulo search (debounced) ---
  const fetchArticulos = useCallback(async (search: string) => {
    if (!search.trim()) {
      setArticuloOptions([]);
      return;
    }
    setArticuloLoading(true);
    try {
      const resp = await apiGet("/api/v1/inventario", { search: search.trim(), page: 1, limit: 15 });
      setArticuloOptions((resp?.rows as InventarioRow[]) ?? []);
    } catch {
      setArticuloOptions([]);
    } finally {
      setArticuloLoading(false);
    }
  }, []);

  useEffect(() => {
    if (articuloTimer.current) clearTimeout(articuloTimer.current);
    if (!articuloInput.trim()) {
      setArticuloOptions([]);
      return;
    }
    articuloTimer.current = setTimeout(() => fetchArticulos(articuloInput), 300);
    return () => { if (articuloTimer.current) clearTimeout(articuloTimer.current); };
  }, [articuloInput, fetchArticulos]);

  // When artículo is selected, fill the line
  const handleArticuloSelect = (_: unknown, value: InventarioRow | null) => {
    setArticuloSelected(value);
    if (value) {
      setLinea((prev) => ({
        ...prev,
        CODIGO: value.CODIGO,
        REFERENCIA: value.Referencia || "",
        DESCRIPCION: value.DESCRIPCION || "",
        PRECIO_COSTO: Number(value.PRECIO_COMPRA || 0),
        ALICUOTA: Number(value.Alicuota ?? value.ALICUOTA ?? 16)
      }));
    }
  };

  const agregarLinea = () => {
    if (!linea.CODIGO || !linea.DESCRIPCION || Number(linea.CANTIDAD) <= 0) return;
    setDetalle((prev) => [...prev, { ...linea }]);
    setLinea({
      CODIGO: "",
      REFERENCIA: "",
      DESCRIPCION: "",
      CANTIDAD: 1,
      PRECIO_COSTO: 0,
      ALICUOTA: 16
    });
    setArticuloSelected(null);
    setArticuloInput("");
    setArticuloOptions([]);
  };

  const eliminarLinea = (idx: number) => {
    setDetalle((prev) => prev.filter((_, i) => i !== idx));
  };

  const crearArticuloRapido = async () => {
    if (!newArt.CODIGO.trim() || !newArt.DESCRIPCION.trim()) return;
    await apiPost("/api/v1/inventario", {
      ...newArt,
      CODIGO: newArt.CODIGO.trim(),
      DESCRIPCION: newArt.DESCRIPCION.trim(),
      Co_Usuario: codUsuario || "SUP"
    });
    setOpenNuevoArt(false);
    // Auto-select the new article
    setArticuloInput(newArt.CODIGO.trim());
  };

  const guardarCompraTx = async () => {
    setError(null);
    setOkMsg(null);
    if (!codProveedor.trim()) {
      setError("Debes seleccionar un proveedor.");
      return;
    }
    if (!detalle.length) {
      setError("Debes agregar al menos una linea de detalle.");
      return;
    }
    if (!numFact.trim()) {
      setError("NUM_FACT es obligatorio.");
      return;
    }

    try {
      const payload = {
        compra: {
          NUM_FACT: numFact.trim(),
          COD_PROVEEDOR: codProveedor.trim(),
          FECHA: fecha,
          NOMBRE: nombreProveedor,
          RIF: rifProveedor,
          TOTAL: total,
          TIPO: tipo.toUpperCase(),
          CONCEPTO: concepto || null,
          COD_USUARIO: codUsuario || "SUP"
        },
        detalle: detalle.map((d) => ({
          CODIGO: d.CODIGO,
          REFERENCIA: d.REFERENCIA || null,
          DESCRIPCION: d.DESCRIPCION,
          CANTIDAD: Number(d.CANTIDAD),
          PRECIO_COSTO: Number(d.PRECIO_COSTO),
          ALICUOTA: Number(d.ALICUOTA)
        })),
        options: {
          actualizarInventario: true,
          generarCxP: tipo.toUpperCase() === "CREDITO",
          actualizarSaldosProveedor: true
        }
      };

      const result = await emitirTx.mutateAsync(payload);
      setOkMsg(`Compra emitida: ${String(result?.numFact || numFact)}.`);
      if (!isEdit) {
        setNumFact(autoNumFact());
        setDetalle([]);
        setConcepto("");
        setProveedorSelected(null);
        setProveedorInput("");
      }
    } catch (e: unknown) {
      setError(String(e instanceof Error ? e.message : e));
    }
  };

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 600 }}>
        {isEdit ? "Compra" : "Nueva Compra Maestro-Detalle"}
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {okMsg && <Alert severity="success" sx={{ mb: 2 }}>{okMsg}</Alert>}

      <Paper sx={{ p: 2, mb: 2 }}>
        <FormGrid spacing={2}>
          <FormField xs={12} md={3}>
            <TextField size="small" label="NUM_FACT" value={numFact} onChange={(e) => setNumFact(e.target.value)} />
          </FormField>
          <FormField xs={12} md={3}>
            <DatePicker
              label="Fecha"
              value={fecha ? dayjs(fecha) : null}
              onChange={(v) => setFecha(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} md={2}>
            <TextField size="small" label="Tipo" value={tipo} onChange={(e) => setTipo(e.target.value.toUpperCase())} />
          </FormField>
          <FormField xs={12} md={2}>
            <TextField size="small" label="Cod Usuario" value={codUsuario} onChange={(e) => setCodUsuario(e.target.value)} />
          </FormField>
          <FormField xs={12} md={2}>
            <Button fullWidth variant="contained" onClick={guardarCompraTx} disabled={emitirTx.isPending}>
              Guardar TX
            </Button>
          </FormField>
        </FormGrid>

        <FormGrid spacing={2} sx={{ mt: 0.5 }}>
          <FormField xs={12} md={8}>
            <Autocomplete<ProveedorRow>
              value={proveedorSelected}
              onChange={(_, value) => setProveedorSelected(value)}
              inputValue={proveedorInput}
              onInputChange={(_, value) => setProveedorInput(value)}
              options={proveedorOptions}
              loading={proveedorLoading}
              getOptionLabel={(opt) => `${opt.CODIGO} — ${opt.NOMBRE || ""}`}
              isOptionEqualToValue={(a, b) => a.CODIGO === b.CODIGO}
              filterOptions={(x) => x}
              noOptionsText={proveedorInput.trim() ? "Sin resultados" : "Escriba para buscar..."}
              renderOption={(props, opt) => (
                <li {...props} key={opt.CODIGO}>
                  <Box>
                    <Typography variant="body2" fontWeight="bold">{opt.CODIGO}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {opt.NOMBRE}{opt.RIF ? ` — RIF: ${opt.RIF}` : ""}
                    </Typography>
                  </Box>
                </li>
              )}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Proveedor"
                  size="small"
                  placeholder="Buscar por codigo o nombre..."
                  InputProps={{
                    ...params.InputProps,
                    endAdornment: (
                      <>
                        {proveedorLoading ? <CircularProgress color="inherit" size={18} /> : null}
                        {params.InputProps.endAdornment}
                      </>
                    ),
                  }}
                />
              )}
            />
          </FormField>
          <FormField xs={12} md={4}>
            <TextField size="small" label="RIF" value={rifProveedor} InputProps={{ readOnly: true }} />
          </FormField>
          <FormField xs={12}>
            <TextField size="small" label="Concepto" value={concepto} onChange={(e) => setConcepto(e.target.value)} />
          </FormField>
        </FormGrid>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
          <Typography variant="subtitle1">Detalle de compra</Typography>
          <Button size="small" variant="outlined" startIcon={<Add />} onClick={() => setOpenNuevoArt(true)}>
            Nuevo Articulo
          </Button>
        </Stack>

        <FormGrid spacing={1} alignItems="center">
          <FormField xs={12} md={5}>
            <Autocomplete<InventarioRow>
              value={articuloSelected}
              onChange={handleArticuloSelect}
              inputValue={articuloInput}
              onInputChange={(_, value) => setArticuloInput(value)}
              options={articuloOptions}
              loading={articuloLoading}
              getOptionLabel={(opt) => `${opt.CODIGO} — ${opt.DESCRIPCION || ""}`}
              isOptionEqualToValue={(a, b) => a.CODIGO === b.CODIGO}
              filterOptions={(x) => x}
              noOptionsText={articuloInput.trim() ? "Sin resultados" : "Escriba para buscar..."}
              renderOption={(props, opt) => (
                <li {...props} key={opt.CODIGO}>
                  <Box>
                    <Typography variant="body2" fontWeight="bold">{opt.CODIGO}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {opt.DESCRIPCION}{opt.Referencia ? ` (Ref: ${opt.Referencia})` : ""}
                      {` — $${Number(opt.PRECIO_COMPRA || 0).toFixed(2)}`}
                    </Typography>
                  </Box>
                </li>
              )}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Articulo"
                  size="small"
                  placeholder="Buscar por codigo o descripcion..."
                  InputProps={{
                    ...params.InputProps,
                    endAdornment: (
                      <>
                        {articuloLoading ? <CircularProgress color="inherit" size={18} /> : null}
                        {params.InputProps.endAdornment}
                      </>
                    ),
                  }}
                />
              )}
            />
          </FormField>
          <FormField xs={6} md={2}>
            <TextField size="small" label="Referencia" value={linea.REFERENCIA || ""} InputProps={{ readOnly: true }} />
          </FormField>
          <FormField xs={6} md={1}>
            <TextField
              size="small"
              label="Cant"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.CANTIDAD}
              onChange={(e) => setLinea((p) => ({ ...p, CANTIDAD: Number(e.target.value) || 0 }))}
            />
          </FormField>
          <FormField xs={6} md={2}>
            <TextField
              size="small"
              label="P. Costo"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.PRECIO_COSTO}
              onChange={(e) => setLinea((p) => ({ ...p, PRECIO_COSTO: Number(e.target.value) || 0 }))}
            />
          </FormField>
          <FormField xs={6} md={1}>
            <TextField
              size="small"
              label="IVA %"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.ALICUOTA}
              onChange={(e) => setLinea((p) => ({ ...p, ALICUOTA: Number(e.target.value) || 0 }))}
            />
          </FormField>
          <FormField xs={12} md={1}>
            <Button fullWidth variant="contained" onClick={agregarLinea}>
              <Add />
            </Button>
          </FormField>
        </FormGrid>

        <Table size="small" sx={{ mt: 2 }}>
          <TableHead>
            <TableRow>
              <TableCell>Codigo</TableCell>
              <TableCell>Descripcion</TableCell>
              <TableCell align="right">Cant</TableCell>
              <TableCell align="right">P. Costo</TableCell>
              <TableCell align="right">SubTotal</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {detalle.length === 0 && (
              <TableRow>
                <TableCell colSpan={6}>Sin lineas.</TableCell>
              </TableRow>
            )}
            {detalle.map((d, idx) => (
              <TableRow key={`${d.CODIGO}_${idx}`}>
                <TableCell>{d.CODIGO}</TableCell>
                <TableCell>{d.DESCRIPCION}</TableCell>
                <TableCell align="right">{Number(d.CANTIDAD).toFixed(2)}</TableCell>
                <TableCell align="right">{Number(d.PRECIO_COSTO).toFixed(2)}</TableCell>
                <TableCell align="right">{(Number(d.CANTIDAD) * Number(d.PRECIO_COSTO)).toFixed(2)}</TableCell>
                <TableCell align="center">
                  <Tooltip title="Eliminar línea">
                    <IconButton size="small" color="error" onClick={() => eliminarLinea(idx)}>
                      <Delete fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        <Box sx={{ mt: 1, textAlign: "right" }}>
          <Typography variant="h6">Total: {total.toFixed(2)}</Typography>
        </Box>
      </Paper>

      <Stack direction="row" spacing={1} justifyContent="flex-end">
        <Button variant="outlined" onClick={() => router.push("/compras")}>
          Volver
        </Button>
        <Button variant="contained" onClick={guardarCompraTx} disabled={emitirTx.isPending}>
          Guardar Compra
        </Button>
      </Stack>

      <Dialog open={openNuevoArt} onClose={() => setOpenNuevoArt(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Articulo</DialogTitle>
        <DialogContent>
          <FormGrid spacing={1} sx={{ mt: 0.5 }}>
            <FormField xs={12} sm={4}>
              <TextField size="small" label="Codigo" value={newArt.CODIGO} onChange={(e) => setNewArt((p) => ({ ...p, CODIGO: e.target.value }))} />
            </FormField>
            <FormField xs={12} sm={8}>
              <TextField size="small" label="Descripcion" value={newArt.DESCRIPCION} onChange={(e) => setNewArt((p) => ({ ...p, DESCRIPCION: e.target.value }))} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField size="small" label="Referencia" value={newArt.Referencia} onChange={(e) => setNewArt((p) => ({ ...p, Referencia: e.target.value }))} />
            </FormField>
            <FormField xs={12} sm={3}>
              <TextField
                size="small"
                label="P. Costo"
                type="number"
                value={newArt.PRECIO_COMPRA}
                onChange={(e) => setNewArt((p) => ({ ...p, PRECIO_COMPRA: Number(e.target.value) || 0 }))}
              />
            </FormField>
            <FormField xs={12} sm={3}>
              <TextField
                size="small"
                label="P. Venta"
                type="number"
                value={newArt.PRECIO_VENTA}
                onChange={(e) => setNewArt((p) => ({ ...p, PRECIO_VENTA: Number(e.target.value) || 0 }))}
              />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenNuevoArt(false)}>Cancelar</Button>
          <Button variant="contained" onClick={crearArticuloRapido}>Crear</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
