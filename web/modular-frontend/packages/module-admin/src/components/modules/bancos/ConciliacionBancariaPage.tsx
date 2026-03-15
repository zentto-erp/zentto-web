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
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography
} from "@mui/material";
import { toDateOnly } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";
import {
  useCerrarConciliacion,
  useConciliacionDetalle,
  useConciliaciones,
  useConciliarMovimiento,
  useCrearConciliacion,
  useCuentasBank,
  useGenerarAjuste,
  useImportarExtracto
} from "../../../hooks/useConciliacionBancaria";

type CuentaRow = Record<string, unknown>;
type ConciliacionRow = Record<string, any>;

function firstDayOfCurrentMonth(tz: string) {
  const d = new Date();
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(d);
  const y = parts.find((p) => p.type === "year")!.value;
  const m = parts.find((p) => p.type === "month")!.value;
  return `${y}-${m}-01`;
}

function lastDayOfCurrentMonth(tz: string) {
  const d = new Date();
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone: tz, year: "numeric", month: "2-digit" }).formatToParts(d);
  const y = Number(parts.find((p) => p.type === "year")!.value);
  const m = Number(parts.find((p) => p.type === "month")!.value);
  const last = new Date(y, m, 0);
  return toDateOnly(last, tz);
}

export default function ConciliacionBancariaPage() {
  const { timeZone } = useTimezone();
  const [nroCta, setNroCta] = useState("");
  const [estado, setEstado] = useState("");
  const [page, setPage] = useState(1);
  const [limit] = useState(50);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [msg, setMsg] = useState<string>("");
  const [err, setErr] = useState<string>("");

  const [newDesde, setNewDesde] = useState(firstDayOfCurrentMonth(timeZone));
  const [newHasta, setNewHasta] = useState(lastDayOfCurrentMonth(timeZone));
  const [newCta, setNewCta] = useState("");

  const [importOpen, setImportOpen] = useState(false);
  const [importText, setImportText] = useState(
    JSON.stringify(
      [
        { Fecha: firstDayOfCurrentMonth(timeZone), Descripcion: "Deposito", Referencia: "DEP-001", Tipo: "CREDITO", Monto: 100, Saldo: 100 }
      ],
      null,
      2
    )
  );

  const [movSistemaId, setMovSistemaId] = useState("");
  const [extractoId, setExtractoId] = useState("");
  const [ajusteTipo, setAjusteTipo] = useState<"NOTA_CREDITO" | "NOTA_DEBITO">("NOTA_DEBITO");
  const [ajusteMonto, setAjusteMonto] = useState("");
  const [ajusteDesc, setAjusteDesc] = useState("");
  const [saldoFinalBanco, setSaldoFinalBanco] = useState("");
  const [obsCierre, setObsCierre] = useState("");

  const filter = useMemo(() => ({ Nro_Cta: nroCta || undefined, Estado: estado || undefined, page, limit }), [nroCta, estado, page, limit]);
  const { data: cuentasData } = useCuentasBank();
  const { data: listData, isLoading } = useConciliaciones(filter);
  const { data: detalleData, refetch: refetchDetalle } = useConciliacionDetalle(selectedId ?? undefined);

  const crear = useCrearConciliacion();
  const importar = useImportarExtracto();
  const conciliar = useConciliarMovimiento();
  const ajustar = useGenerarAjuste();
  const cerrar = useCerrarConciliacion();

  const rows = (listData?.rows ?? []) as ConciliacionRow[];

  const handleCrear = async () => {
    setErr("");
    setMsg("");
    try {
      const r = await crear.mutateAsync({ Nro_Cta: newCta, Fecha_Desde: newDesde, Fecha_Hasta: newHasta });
      setMsg(`Conciliacion creada: ${r?.conciliacionId ?? ""}`);
    } catch (e: unknown) {
      setErr(String(e instanceof Error ? e.message : e));
    }
  };

  const handleImportar = async () => {
    if (!selectedId) return;
    setErr("");
    setMsg("");
    try {
      const parsed = JSON.parse(importText);
      const r = await importar.mutateAsync({ conciliacionId: selectedId, extracto: parsed });
      setMsg(`Extracto importado. Registros: ${r?.registrosImportados ?? "ok"}`);
      setImportOpen(false);
      await refetchDetalle();
    } catch (e: unknown) {
      setErr(String(e instanceof Error ? e.message : e));
    }
  };

  const handleConciliar = async () => {
    if (!selectedId) return;
    setErr("");
    setMsg("");
    try {
      const r = await conciliar.mutateAsync({
        Conciliacion_ID: selectedId,
        MovimientoSistema_ID: Number(movSistemaId),
        Extracto_ID: extractoId ? Number(extractoId) : undefined
      });
      setMsg(r?.mensaje || "Movimiento conciliado");
      await refetchDetalle();
    } catch (e: unknown) {
      setErr(String(e instanceof Error ? e.message : e));
    }
  };

  const handleAjuste = async () => {
    if (!selectedId) return;
    setErr("");
    setMsg("");
    try {
      const r = await ajustar.mutateAsync({
        Conciliacion_ID: selectedId,
        Tipo_Ajuste: ajusteTipo,
        Monto: Number(ajusteMonto),
        Descripcion: ajusteDesc
      });
      setMsg(r?.mensaje || "Ajuste generado");
      await refetchDetalle();
    } catch (e: unknown) {
      setErr(String(e instanceof Error ? e.message : e));
    }
  };

  const handleCerrar = async () => {
    if (!selectedId) return;
    setErr("");
    setMsg("");
    try {
      const r = await cerrar.mutateAsync({
        Conciliacion_ID: selectedId,
        Saldo_Final_Banco: Number(saldoFinalBanco),
        Observaciones: obsCierre || undefined
      });
      setMsg(`Conciliacion cerrada. Estado: ${r?.estado ?? "ok"} Diferencia: ${r?.diferencia ?? 0}`);
      await refetchDetalle();
    } catch (e: unknown) {
      setErr(String(e instanceof Error ? e.message : e));
    }
  };

  return (
    <Box>

      {msg && <Alert severity="success" sx={{ mb: 2 }}>{msg}</Alert>}
      {err && <Alert severity="error" sx={{ mb: 2 }}>{err}</Alert>}

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>Crear Conciliacion</Typography>
        <Grid container spacing={1}>
          <Grid item xs={12} md={4}>
            <TextField select SelectProps={{ native: true }} fullWidth size="small" label="Cuenta" value={newCta} onChange={(e) => setNewCta(e.target.value)}>
              <option value="">Seleccione</option>
              {((cuentasData?.rows ?? []) as CuentaRow[]).map((c) => (
                <option key={String(c.Nro_Cta)} value={String(c.Nro_Cta)}>{String(c.Nro_Cta)} - {String(c.BancoNombre ?? c.Banco ?? "")}</option>
              ))}
            </TextField>
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" type="date" label="Desde" InputLabelProps={{ shrink: true }} value={newDesde} onChange={(e) => setNewDesde(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" type="date" label="Hasta" InputLabelProps={{ shrink: true }} value={newHasta} onChange={(e) => setNewHasta(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={2}>
            <Button fullWidth variant="contained" onClick={handleCrear} disabled={crear.isPending}>Crear</Button>
          </Grid>
        </Grid>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>Filtros</Typography>
        <Grid container spacing={1}>
          <Grid item xs={12} md={4}>
            <TextField fullWidth size="small" label="Nro Cta" value={nroCta} onChange={(e) => setNroCta(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" label="Estado" value={estado} onChange={(e) => setEstado(e.target.value)} />
          </Grid>
          <Grid item xs={12} md={3}>
            <TextField fullWidth size="small" label="Pagina" type="number" value={page} onChange={(e) => setPage(Number(e.target.value) || 1)} />
          </Grid>
        </Grid>
      </Paper>

      <Paper sx={{ mb: 2 }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell>Cuenta</TableCell>
              <TableCell>Desde</TableCell>
              <TableCell>Hasta</TableCell>
              <TableCell>Saldo Sistema</TableCell>
              <TableCell>Diferencia</TableCell>
              <TableCell>Estado</TableCell>
              <TableCell>Accion</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading && (
              <TableRow><TableCell colSpan={8}>Cargando...</TableCell></TableRow>
            )}
            {!isLoading && rows.length === 0 && (
              <TableRow><TableCell colSpan={8}>Sin conciliaciones.</TableCell></TableRow>
            )}
            {!isLoading && rows.map((r) => (
              <TableRow key={String(r.ID)} selected={selectedId === Number(r.ID)}>
                <TableCell>{r.ID}</TableCell>
                <TableCell>{r.Nro_Cta}</TableCell>
                <TableCell>{r.Fecha_Desde ? toDateOnly(r.Fecha_Desde as string, timeZone) : ""}</TableCell>
                <TableCell>{r.Fecha_Hasta ? toDateOnly(r.Fecha_Hasta as string, timeZone) : ""}</TableCell>
                <TableCell>{Number(r.Saldo_Final_Sistema || 0).toFixed(2)}</TableCell>
                <TableCell>{Number(r.Diferencia || 0).toFixed(2)}</TableCell>
                <TableCell>{r.Estado}</TableCell>
                <TableCell>
                  <Button size="small" onClick={() => setSelectedId(Number(r.ID))}>Abrir</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Paper>

      {selectedId && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="subtitle1" sx={{ mb: 1 }}>Detalle Conciliacion #{selectedId}</Typography>

          <Stack direction="row" spacing={1} sx={{ mb: 2 }}>
            <Button variant="outlined" onClick={() => setImportOpen(true)}>Importar Extracto</Button>
            <Button variant="outlined" onClick={() => refetchDetalle()}>Refrescar</Button>
          </Stack>

          <Grid container spacing={1} sx={{ mb: 2 }}>
            <Grid item xs={12} md={4}>
              <TextField fullWidth size="small" label="MovimientoSistema_ID" value={movSistemaId} onChange={(e) => setMovSistemaId(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField fullWidth size="small" label="Extracto_ID (opcional)" value={extractoId} onChange={(e) => setExtractoId(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={4}>
              <Button fullWidth variant="contained" onClick={handleConciliar} disabled={conciliar.isPending}>Conciliar</Button>
            </Grid>
          </Grid>

          <Grid container spacing={1} sx={{ mb: 2 }}>
            <Grid item xs={12} md={3}>
              <TextField select SelectProps={{ native: true }} fullWidth size="small" label="Tipo Ajuste" value={ajusteTipo} onChange={(e) => setAjusteTipo(e.target.value as "NOTA_CREDITO" | "NOTA_DEBITO")}>
                <option value="NOTA_CREDITO">NOTA_CREDITO</option>
                <option value="NOTA_DEBITO">NOTA_DEBITO</option>
              </TextField>
            </Grid>
            <Grid item xs={12} md={3}>
              <TextField fullWidth size="small" label="Monto" type="number" value={ajusteMonto} onChange={(e) => setAjusteMonto(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField fullWidth size="small" label="Descripcion" value={ajusteDesc} onChange={(e) => setAjusteDesc(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={2}>
              <Button fullWidth variant="contained" onClick={handleAjuste} disabled={ajustar.isPending}>Ajustar</Button>
            </Grid>
          </Grid>

          <Grid container spacing={1} sx={{ mb: 2 }}>
            <Grid item xs={12} md={4}>
              <TextField fullWidth size="small" label="Saldo Final Banco" type="number" value={saldoFinalBanco} onChange={(e) => setSaldoFinalBanco(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField fullWidth size="small" label="Observaciones" value={obsCierre} onChange={(e) => setObsCierre(e.target.value)} />
            </Grid>
            <Grid item xs={12} md={2}>
              <Button fullWidth variant="contained" color="warning" onClick={handleCerrar} disabled={cerrar.isPending}>Cerrar</Button>
            </Grid>
          </Grid>

          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>Movimientos del Sistema</Typography>
          <Paper variant="outlined" sx={{ p: 1, mb: 2, maxHeight: 220, overflow: "auto" }}>
            <pre style={{ margin: 0, whiteSpace: "pre-wrap" }}>
              {JSON.stringify(detalleData?.movimientosSistema ?? [], null, 2)}
            </pre>
          </Paper>

          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>Extracto Pendiente</Typography>
          <Paper variant="outlined" sx={{ p: 1, maxHeight: 220, overflow: "auto" }}>
            <pre style={{ margin: 0, whiteSpace: "pre-wrap" }}>
              {JSON.stringify(detalleData?.extractoPendiente ?? [], null, 2)}
            </pre>
          </Paper>
        </Paper>
      )}

      <Dialog open={importOpen} onClose={() => setImportOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Importar Extracto (JSON Array)</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            multiline
            minRows={12}
            value={importText}
            onChange={(e) => setImportText(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setImportOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleImportar} disabled={importar.isPending}>Importar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

