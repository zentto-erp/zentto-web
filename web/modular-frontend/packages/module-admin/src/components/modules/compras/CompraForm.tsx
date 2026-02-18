"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  IconButton,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography
} from "@mui/material";
import { Add, Delete, Search } from "@mui/icons-material";
import { apiGet, apiPost } from "@datqbox/shared-api";
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
  const emitirTx = useEmitirCompraTx();
  const isEdit = !!numeroCompra;

  const [numFact, setNumFact] = useState(numeroCompra || autoNumFact());
  const [fecha, setFecha] = useState(new Date().toISOString().slice(0, 10));
  const [tipo, setTipo] = useState("CONTADO");
  const [codUsuario, setCodUsuario] = useState("SUP");
  const [concepto, setConcepto] = useState("");

  const [codProveedor, setCodProveedor] = useState("");
  const [nombreProveedor, setNombreProveedor] = useState("");
  const [rifProveedor, setRifProveedor] = useState("");

  const [detalle, setDetalle] = useState<DetalleRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  const [openBuscaArt, setOpenBuscaArt] = useState(false);
  const [artSearch, setArtSearch] = useState("");
  const [artRows, setArtRows] = useState<InventarioRow[]>([]);

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

  const [linea, setLinea] = useState<DetalleRow>({
    CODIGO: "",
    REFERENCIA: "",
    DESCRIPCION: "",
    CANTIDAD: 1,
    PRECIO_COSTO: 0,
    ALICUOTA: 16
  });

  const subtotal = useMemo(
    () => detalle.reduce((acc, r) => acc + Number(r.CANTIDAD || 0) * Number(r.PRECIO_COSTO || 0), 0),
    [detalle]
  );
  const total = subtotal;

  const buscarProveedor = async (value: string) => {
    setCodProveedor(value);
    if (!value.trim()) {
      setNombreProveedor("");
      setRifProveedor("");
      return;
    }
    const resp = await apiGet(`/api/v1/proveedores?search=${encodeURIComponent(value.trim())}&page=1&limit=1`);
    const p = (resp?.rows?.[0] ?? null) as ProveedorRow | null;
    if (p) {
      setCodProveedor(p.CODIGO);
      setNombreProveedor(p.NOMBRE || "");
      setRifProveedor(p.RIF || "");
    }
  };

  const buscarArticulos = async () => {
    const resp = await apiGet(`/api/v1/inventario?search=${encodeURIComponent(artSearch.trim())}&page=1&limit=30`);
    setArtRows(resp?.rows ?? []);
  };

  const seleccionarArticulo = (a: InventarioRow) => {
    setLinea((prev) => ({
      ...prev,
      CODIGO: a.CODIGO,
      REFERENCIA: a.Referencia || "",
      DESCRIPCION: a.DESCRIPCION || "",
      PRECIO_COSTO: Number(a.PRECIO_COMPRA || 0),
      ALICUOTA: Number(a.ALICUOTA ?? 16)
    }));
    setOpenBuscaArt(false);
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
    setArtSearch(newArt.CODIGO.trim());
    await buscarArticulos();
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
      }
    } catch (e: any) {
      setError(String(e?.message || e));
    }
  };

  useEffect(() => {
    if (!openBuscaArt) return;
    buscarArticulos().catch(() => undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [openBuscaArt]);

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 600 }}>
        {isEdit ? "Compra" : "Nueva Compra Maestro-Detalle"}
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {okMsg && <Alert severity="success" sx={{ mb: 2 }}>{okMsg}</Alert>}

      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" label="NUM_FACT" value={numFact} onChange={(e) => setNumFact(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              size="small"
              label="Fecha"
              type="date"
              InputLabelProps={{ shrink: true }}
              value={fecha}
              onChange={(e) => setFecha(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Tipo" value={tipo} onChange={(e) => setTipo(e.target.value.toUpperCase())} />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Cod Usuario" value={codUsuario} onChange={(e) => setCodUsuario(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={2}>
            <Button fullWidth variant="contained" onClick={guardarCompraTx} disabled={emitirTx.isPending}>
              Guardar TX
            </Button>
          </Grid>
        </Grid>

        <Grid container spacing={2} sx={{ mt: 0.5 }}>
          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              size="small"
              label="Cod Proveedor"
              value={codProveedor}
              onBlur={(e) => buscarProveedor(e.target.value)}
              onChange={(e) => setCodProveedor(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} md={5}>
            <TextField fullWidth size="small" label="Nombre Proveedor" value={nombreProveedor} onChange={(e) => setNombreProveedor(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="RIF" value={rifProveedor} onChange={(e) => setRifProveedor(e.target.value)} />
          </Grid>
          <Grid item xs={12}>
            <TextField fullWidth size="small" label="Concepto" value={concepto} onChange={(e) => setConcepto(e.target.value)} />
          </Grid>
        </Grid>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
          <Typography variant="subtitle1">Detalle de compra</Typography>
          <Stack direction="row" spacing={1}>
            <Button size="small" variant="outlined" startIcon={<Search />} onClick={() => setOpenBuscaArt(true)}>
              Buscar Articulo
            </Button>
            <Button size="small" variant="outlined" startIcon={<Add />} onClick={() => setOpenNuevoArt(true)}>
              Nuevo Articulo
            </Button>
          </Stack>
        </Stack>

        <Grid container spacing={1}>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Codigo" value={linea.CODIGO} onChange={(e) => setLinea((p) => ({ ...p, CODIGO: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Referencia" value={linea.REFERENCIA || ""} onChange={(e) => setLinea((p) => ({ ...p, REFERENCIA: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Descripcion" value={linea.DESCRIPCION} onChange={(e) => setLinea((p) => ({ ...p, DESCRIPCION: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={1}>
            <TextField
              fullWidth
              size="small"
              label="Cant"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.CANTIDAD}
              onChange={(e) => setLinea((p) => ({ ...p, CANTIDAD: Number(e.target.value) || 0 }))}
            />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField
              fullWidth
              size="small"
              label="P. Costo"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.PRECIO_COSTO}
              onChange={(e) => setLinea((p) => ({ ...p, PRECIO_COSTO: Number(e.target.value) || 0 }))}
            />
          </Grid>
          <Grid item xs={12} md={1}>
            <TextField
              fullWidth
              size="small"
              label="IVA %"
              type="number"
              inputProps={{ min: 0, step: "0.01" }}
              value={linea.ALICUOTA}
              onChange={(e) => setLinea((p) => ({ ...p, ALICUOTA: Number(e.target.value) || 0 }))}
            />
          </Grid>
          <Grid item xs={12} md={1}>
            <Button fullWidth variant="contained" onClick={agregarLinea}>
              <Add />
            </Button>
          </Grid>
        </Grid>

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
                  <IconButton size="small" color="error" onClick={() => eliminarLinea(idx)}>
                    <Delete fontSize="small" />
                  </IconButton>
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

      <Dialog open={openBuscaArt} onClose={() => setOpenBuscaArt(false)} maxWidth="md" fullWidth>
        <DialogTitle>Buscar Articulo</DialogTitle>
        <DialogContent>
          <Stack direction="row" spacing={1} sx={{ my: 1 }}>
            <TextField
              fullWidth
              size="small"
              label="Buscar por codigo/descripcion"
              value={artSearch}
              onChange={(e) => setArtSearch(e.target.value)}
            />
            <Button variant="outlined" onClick={buscarArticulos}>Buscar</Button>
          </Stack>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Codigo</TableCell>
                <TableCell>Descripcion</TableCell>
                <TableCell>Referencia</TableCell>
                <TableCell align="right">Costo</TableCell>
                <TableCell />
              </TableRow>
            </TableHead>
            <TableBody>
              {artRows.map((a) => (
                <TableRow key={a.CODIGO}>
                  <TableCell>{a.CODIGO}</TableCell>
                  <TableCell>{a.DESCRIPCION}</TableCell>
                  <TableCell>{a.Referencia}</TableCell>
                  <TableCell align="right">{Number(a.PRECIO_COMPRA || 0).toFixed(2)}</TableCell>
                  <TableCell align="right">
                    <Button size="small" onClick={() => seleccionarArticulo(a)}>Seleccionar</Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenBuscaArt(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={openNuevoArt} onClose={() => setOpenNuevoArt(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Articulo</DialogTitle>
        <DialogContent>
          <Grid container spacing={1} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={4}>
              <TextField fullWidth size="small" label="Codigo" value={newArt.CODIGO} onChange={(e) => setNewArt((p) => ({ ...p, CODIGO: e.target.value }))} />
            </Grid>
            <Grid item xs={12} sm={8}>
              <TextField fullWidth size="small" label="Descripcion" value={newArt.DESCRIPCION} onChange={(e) => setNewArt((p) => ({ ...p, DESCRIPCION: e.target.value }))} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth size="small" label="Referencia" value={newArt.Referencia} onChange={(e) => setNewArt((p) => ({ ...p, Referencia: e.target.value }))} />
            </Grid>
            <Grid item xs={12} sm={3}>
              <TextField
                fullWidth
                size="small"
                label="P. Costo"
                type="number"
                value={newArt.PRECIO_COMPRA}
                onChange={(e) => setNewArt((p) => ({ ...p, PRECIO_COMPRA: Number(e.target.value) || 0 }))}
              />
            </Grid>
            <Grid item xs={12} sm={3}>
              <TextField
                fullWidth
                size="small"
                label="P. Venta"
                type="number"
                value={newArt.PRECIO_VENTA}
                onChange={(e) => setNewArt((p) => ({ ...p, PRECIO_VENTA: Number(e.target.value) || 0 }))}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenNuevoArt(false)}>Cancelar</Button>
          <Button variant="contained" onClick={crearArticuloRapido}>Crear</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
