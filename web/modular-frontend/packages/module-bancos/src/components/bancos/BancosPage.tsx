"use client";

import { useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography
} from "@mui/material";
import {
  useBancosList,
  useCreateBanco,
  useDeleteBanco,
  useGenerarMovimientoBancario,
  useUpdateBanco,
  useCuentasBancarias
} from "../../hooks/useBancosAuxiliares";

export default function BancosPage() {
  const [search, setSearch] = useState("");
  const [page] = useState(1);
  const [limit] = useState(50);
  const [msg, setMsg] = useState("");
  const [err, setErr] = useState("");
  const [selectedNombre, setSelectedNombre] = useState("");

  const [form, setForm] = useState({ Nombre: "", Contacto: "", Direccion: "", Telefonos: "", Co_Usuario: "SUP" });
  const [movOpen, setMovOpen] = useState(false);
  const [mov, setMov] = useState({
    Nro_Cta: "",
    Tipo: "DEP",
    Nro_Ref: "",
    Beneficiario: "",
    Monto: 0,
    Concepto: "",
    Categoria: "",
    Documento_Relacionado: "",
    Tipo_Doc_Rel: ""
  });

  const filter = useMemo(() => ({ search: search || undefined, page, limit }), [search, page, limit]);
  const { data, isLoading } = useBancosList(filter);
  const { data: cuentas } = useCuentasBancarias();
  const crear = useCreateBanco();
  const editar = useUpdateBanco();
  const eliminar = useDeleteBanco();
  const generarMov = useGenerarMovimientoBancario();

  const rows = data?.rows ?? data?.items ?? [];

  const onCreate = async () => {
    setErr("");
    setMsg("");
    try {
      await crear.mutateAsync(form);
      setMsg("Banco creado");
      setForm({ Nombre: "", Contacto: "", Direccion: "", Telefonos: "", Co_Usuario: "SUP" });
    } catch (e: any) {
      setErr(String(e?.message || e));
    }
  };

  const onUpdate = async () => {
    if (!selectedNombre) return;
    setErr("");
    setMsg("");
    try {
      await editar.mutateAsync({ nombre: selectedNombre, data: form });
      setMsg("Banco actualizado");
    } catch (e: any) {
      setErr(String(e?.message || e));
    }
  };

  const onDelete = async (nombre: string) => {
    setErr("");
    setMsg("");
    try {
      await eliminar.mutateAsync(nombre);
      setMsg("Banco eliminado");
    } catch (e: any) {
      setErr(String(e?.message || e));
    }
  };

  const onGenerarMov = async () => {
    setErr("");
    setMsg("");
    try {
      const payload = { ...mov, Monto: Number(mov.Monto) };
      await generarMov.mutateAsync(payload as any);
      setMsg("Movimiento bancario generado");
      setMovOpen(false);
    } catch (e: any) {
      setErr(String(e?.message || e));
    }
  };

  return (
    <Box>
      {msg && <Alert severity="success" sx={{ mb: 2 }}>{msg}</Alert>}
      {err && <Alert severity="error" sx={{ mb: 2 }}>{err}</Alert>}

      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={1}>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Buscar banco" value={search} onChange={(e) => setSearch(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={4}>
            <Button variant="outlined" onClick={() => setMovOpen(true)}>Generar Movimiento Bancario</Button>
          </Grid>
        </Grid>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>Nuevo / Editar Banco</Typography>
        <Grid container spacing={1}>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" label="Nombre" value={form.Nombre} onChange={(e) => setForm((s) => ({ ...s, Nombre: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Contacto" value={form.Contacto} onChange={(e) => setForm((s) => ({ ...s, Contacto: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" label="Direccion" value={form.Direccion} onChange={(e) => setForm((s) => ({ ...s, Direccion: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Telefonos" value={form.Telefonos} onChange={(e) => setForm((s) => ({ ...s, Telefonos: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={2}>
            <TextField fullWidth size="small" label="Usuario" value={form.Co_Usuario} onChange={(e) => setForm((s) => ({ ...s, Co_Usuario: e.target.value }))} />
          </Grid>
          <Grid item xs={12} md={2}>
            <Button fullWidth variant="contained" onClick={onCreate} disabled={crear.isPending}>Crear</Button>
          </Grid>
          <Grid item xs={12} md={2}>
            <Button fullWidth variant="contained" color="warning" onClick={onUpdate} disabled={editar.isPending || !selectedNombre}>Actualizar</Button>
          </Grid>
        </Grid>
      </Paper>

      <Paper>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Nombre</TableCell>
              <TableCell>Contacto</TableCell>
              <TableCell>Direccion</TableCell>
              <TableCell>Telefonos</TableCell>
              <TableCell>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading && <TableRow><TableCell colSpan={5}>Cargando...</TableCell></TableRow>}
            {!isLoading && rows.length === 0 && <TableRow><TableCell colSpan={5}>Sin bancos.</TableCell></TableRow>}
            {!isLoading && rows.map((r: any) => (
              <TableRow key={String(r.Nombre ?? r.NOMBRE)} selected={selectedNombre === String(r.Nombre ?? r.NOMBRE)}>
                <TableCell>{String(r.Nombre ?? r.NOMBRE)}</TableCell>
                <TableCell>{String(r.Contacto ?? "")}</TableCell>
                <TableCell>{String(r.Direccion ?? "")}</TableCell>
                <TableCell>{String(r.Telefonos ?? "")}</TableCell>
                <TableCell>
                  <Button
                    size="small"
                    onClick={() => {
                      const nombre = String(r.Nombre ?? r.NOMBRE);
                      setSelectedNombre(nombre);
                      setForm({
                        Nombre: nombre,
                        Contacto: String(r.Contacto ?? ""),
                        Direccion: String(r.Direccion ?? ""),
                        Telefonos: String(r.Telefonos ?? ""),
                        Co_Usuario: "SUP"
                      });
                    }}
                  >
                    Editar
                  </Button>
                  <Button size="small" color="error" onClick={() => onDelete(String(r.Nombre ?? r.NOMBRE))}>Eliminar</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Paper>

      <Dialog open={movOpen} onClose={() => setMovOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Generar Movimiento Bancario</DialogTitle>
        <DialogContent>
          <Grid container spacing={1} sx={{ mt: 0.5 }}>
            <Grid item xs={12} md={4}>
              <TextField
                select
                SelectProps={{ native: true }}
                fullWidth
                size="small"
                label="Cuenta"
                value={mov.Nro_Cta}
                onChange={(e) => setMov((s) => ({ ...s, Nro_Cta: e.target.value }))}
              >
                <option value="">Seleccione</option>
                {(cuentas?.rows ?? []).map((c: any) => (
                  <option key={String(c.Nro_Cta)} value={String(c.Nro_Cta)}>{String(c.Nro_Cta)} - {String(c.BancoNombre ?? c.Banco ?? "")}</option>
                ))}
              </TextField>
            </Grid>
            <Grid item xs={12} md={2}>
              <TextField select SelectProps={{ native: true }} fullWidth size="small" label="Tipo" value={mov.Tipo} onChange={(e) => setMov((s) => ({ ...s, Tipo: e.target.value }))}>
                <option value="DEP">DEP</option>
                <option value="PCH">PCH</option>
                <option value="NCR">NCR</option>
                <option value="NDB">NDB</option>
                <option value="IDB">IDB</option>
              </TextField>
            </Grid>
            <Grid item xs={12} md={3}>
              <TextField fullWidth size="small" label="Nro Ref" value={mov.Nro_Ref} onChange={(e) => setMov((s) => ({ ...s, Nro_Ref: e.target.value }))} />
            </Grid>
            <Grid item xs={12} md={3}>
              <TextField fullWidth size="small" label="Monto" type="number" value={mov.Monto} onChange={(e) => setMov((s) => ({ ...s, Monto: Number(e.target.value) }))} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField fullWidth size="small" label="Beneficiario" value={mov.Beneficiario} onChange={(e) => setMov((s) => ({ ...s, Beneficiario: e.target.value }))} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField fullWidth size="small" label="Concepto" value={mov.Concepto} onChange={(e) => setMov((s) => ({ ...s, Concepto: e.target.value }))} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField fullWidth size="small" label="Categoria" value={mov.Categoria} onChange={(e) => setMov((s) => ({ ...s, Categoria: e.target.value }))} />
            </Grid>
            <Grid item xs={12} md={3}>
              <TextField fullWidth size="small" label="Doc Rel" value={mov.Documento_Relacionado} onChange={(e) => setMov((s) => ({ ...s, Documento_Relacionado: e.target.value }))} />
            </Grid>
            <Grid item xs={12} md={3}>
              <TextField fullWidth size="small" label="Tipo Doc Rel" value={mov.Tipo_Doc_Rel} onChange={(e) => setMov((s) => ({ ...s, Tipo_Doc_Rel: e.target.value }))} />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setMovOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={onGenerarMov} disabled={generarMov.isPending}>Generar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

