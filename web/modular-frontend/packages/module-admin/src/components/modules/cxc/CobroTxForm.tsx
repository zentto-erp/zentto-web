"use client";

import { useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Checkbox,
  CircularProgress,
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
import { Add, Delete } from "@mui/icons-material";
import { toDateOnly } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";
import {
  CxcAplicarCobroPayload,
  CxcDocumentoPendiente,
  useAplicarCobroTx,
  useCxcDocumentosPendientes,
  useCxcSaldo
} from "../../../hooks/useCxcTx";

type SelDoc = CxcDocumentoPendiente & { checked: boolean; montoAplicar: number };
type FormaPagoLine = { formaPago: string; monto: number; banco?: string; numCheque?: string; fechaVencimiento?: string };

export default function CobroTxForm() {
  const { timeZone } = useTimezone();
  const [codCliente, setCodCliente] = useState("");
  const [fecha, setFecha] = useState(toDateOnly(new Date(), timeZone));
  const [codUsuario, setCodUsuario] = useState("SUP");
  const [observaciones, setObservaciones] = useState("");
  const [formasPago, setFormasPago] = useState<FormaPagoLine[]>([{ formaPago: "EFECTIVO", monto: 0 }]);
  const [rows, setRows] = useState<SelDoc[]>([]);

  const docsQuery = useCxcDocumentosPendientes(codCliente.trim());
  const saldoQuery = useCxcSaldo(codCliente.trim());
  const cobrarMutation = useAplicarCobroTx();

  const totalSeleccionado = useMemo(
    () => rows.filter((r) => r.checked).reduce((acc, r) => acc + Number(r.montoAplicar || 0), 0),
    [rows]
  );
  const totalFormasPago = useMemo(
    () => formasPago.reduce((acc, f) => acc + Number(f.monto || 0), 0),
    [formasPago]
  );
  const diferencia = useMemo(() => Number((totalSeleccionado - totalFormasPago).toFixed(2)), [totalSeleccionado, totalFormasPago]);
  const estaCuadrado = Math.abs(diferencia) <= 0.01;

  const syncRows = () => {
    const data = docsQuery.data?.data ?? [];
    setRows(data.map((d) => ({ ...d, checked: false, montoAplicar: Number(d.pendiente || 0) })));
  };

  const toggleRow = (idx: number, checked: boolean) => {
    setRows((prev) => prev.map((r, i) => (i === idx ? { ...r, checked } : r)));
  };

  const changeMonto = (idx: number, value: number) => {
    setRows((prev) =>
      prev.map((r, i) =>
        i === idx
          ? {
              ...r,
              montoAplicar: Number.isFinite(value) ? Math.max(0, Math.min(value, Number(r.pendiente || 0))) : 0
            }
          : r
      )
    );
  };

  const submit = async () => {
    const documentos = rows
      .filter((r) => r.checked && Number(r.montoAplicar) > 0)
      .map((r) => ({ tipoDoc: r.tipoDoc, numDoc: r.numDoc, montoAplicar: Number(r.montoAplicar) }));

    if (!codCliente.trim()) return;
    if (!documentos.length) return;
    const fp = formasPago.filter((f) => (f.formaPago || "").trim() && Number(f.monto) > 0);
    if (!fp.length || !estaCuadrado) return;

    const payload: CxcAplicarCobroPayload = {
      requestId: `cxc_${Date.now()}`,
      codCliente: codCliente.trim(),
      fecha,
      montoTotal: totalSeleccionado,
      codUsuario: codUsuario.trim() || "SUP",
      observaciones,
      documentos,
      formasPago: fp
    };

    await cobrarMutation.mutateAsync(payload);
  };

  const addFormaPago = () => {
    setFormasPago((prev) => [...prev, { formaPago: "EFECTIVO", monto: 0 }]);
  };

  const removeFormaPago = (idx: number) => {
    setFormasPago((prev) => (prev.length <= 1 ? prev : prev.filter((_, i) => i !== idx)));
  };

  const updateFormaPago = (idx: number, patch: Partial<FormaPagoLine>) => {
    setFormasPago((prev) => prev.map((r, i) => (i === idx ? { ...r, ...patch } : r)));
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 600 }}>
        Cobro CxC (Transaccional)
      </Typography>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={3}>
            <TextField
              fullWidth
              size="small"
              label="Cod Cliente"
              value={codCliente}
              onChange={(e) => setCodCliente(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} sm={2}>
            <TextField
              fullWidth
              size="small"
              label="Fecha"
              type="date"
              value={fecha}
              InputLabelProps={{ shrink: true }}
              onChange={(e) => setFecha(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} sm={2}>
            <TextField
              fullWidth
              size="small"
              label="Cod Usuario"
              value={codUsuario}
              onChange={(e) => setCodUsuario(e.target.value)}
            />
          </Grid>
          <Grid item xs={12}>
            <TextField
              fullWidth
              size="small"
              label="Observaciones"
              value={observaciones}
              onChange={(e) => setObservaciones(e.target.value)}
            />
          </Grid>
        </Grid>

        <Stack direction="row" spacing={1} sx={{ mt: 2 }}>
          <Button
            variant="outlined"
            onClick={async () => {
              await docsQuery.refetch();
              await saldoQuery.refetch();
              syncRows();
            }}
            disabled={!codCliente.trim() || docsQuery.isFetching}
          >
            Cargar Pendientes
          </Button>
          <Button variant="contained" onClick={submit} disabled={cobrarMutation.isPending || totalSeleccionado <= 0 || !estaCuadrado}>
            Aplicar Cobro TX
          </Button>
        </Stack>
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Stack direction="row" justifyContent="space-between" sx={{ mb: 1 }}>
          <Typography variant="subtitle1">Formas de pago</Typography>
          <Button size="small" variant="outlined" startIcon={<Add />} onClick={addFormaPago}>
            Agregar linea
          </Button>
        </Stack>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Tipo</TableCell>
              <TableCell align="right">Monto</TableCell>
              <TableCell>Banco</TableCell>
              <TableCell>Nro Cheque</TableCell>
              <TableCell>F. Vencimiento</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {formasPago.map((fp, idx) => (
              <TableRow key={idx}>
                <TableCell>
                  <TextField
                    size="small"
                    value={fp.formaPago}
                    onChange={(e) => updateFormaPago(idx, { formaPago: e.target.value.toUpperCase() })}
                    sx={{ minWidth: 140 }}
                  />
                </TableCell>
                <TableCell align="right">
                  <TextField
                    size="small"
                    type="number"
                    value={fp.monto}
                    onChange={(e) => updateFormaPago(idx, { monto: Number(e.target.value) || 0 })}
                    inputProps={{ min: 0, step: "0.01" }}
                    sx={{ width: 130 }}
                  />
                </TableCell>
                <TableCell>
                  <TextField size="small" value={fp.banco || ""} onChange={(e) => updateFormaPago(idx, { banco: e.target.value })} />
                </TableCell>
                <TableCell>
                  <TextField size="small" value={fp.numCheque || ""} onChange={(e) => updateFormaPago(idx, { numCheque: e.target.value })} />
                </TableCell>
                <TableCell>
                  <TextField
                    size="small"
                    type="date"
                    value={fp.fechaVencimiento || ""}
                    InputLabelProps={{ shrink: true }}
                    onChange={(e) => updateFormaPago(idx, { fechaVencimiento: e.target.value || undefined })}
                  />
                </TableCell>
                <TableCell align="center">
                  <Button color="error" size="small" onClick={() => removeFormaPago(idx)} disabled={formasPago.length === 1}>
                    <Delete fontSize="small" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <Stack direction="row" spacing={3} sx={{ mt: 2 }}>
          <Typography variant="body2">Total documentos: {totalSeleccionado.toFixed(2)}</Typography>
          <Typography variant="body2">Total formas pago: {totalFormasPago.toFixed(2)}</Typography>
          <Typography variant="body2" color={estaCuadrado ? "success.main" : "error.main"}>
            Diferencia: {diferencia.toFixed(2)}
          </Typography>
        </Stack>
        {!estaCuadrado && <Alert severity="warning" sx={{ mt: 1 }}>La suma de formas de pago debe cuadrar con el total seleccionado.</Alert>}
      </Paper>

      {docsQuery.isFetching && <CircularProgress size={24} />}
      {docsQuery.error && <Alert severity="error">Error cargando pendientes.</Alert>}
      {cobrarMutation.isError && <Alert severity="error">Error aplicando cobro.</Alert>}
      {cobrarMutation.isSuccess && (
        <Alert severity="success">Cobro aplicado. Recibo: {String((cobrarMutation.data as { numRecibo?: string })?.numRecibo || "")}</Alert>
      )}

      {saldoQuery.data?.data && (
        <Paper sx={{ p: 2, mb: 2 }}>
          <Typography variant="body2">
            Saldo cliente: {JSON.stringify(saldoQuery.data.data)}
          </Typography>
        </Paper>
      )}

      <Paper sx={{ p: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>
          Documentos pendientes
        </Typography>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell />
              <TableCell>Tipo</TableCell>
              <TableCell>Documento</TableCell>
              <TableCell>Fecha</TableCell>
              <TableCell align="right">Pendiente</TableCell>
              <TableCell align="right">Monto aplicar</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((r, i) => (
              <TableRow key={`${r.tipoDoc}-${r.numDoc}-${i}`}>
                <TableCell padding="checkbox">
                  <Checkbox checked={r.checked} onChange={(e) => toggleRow(i, e.target.checked)} />
                </TableCell>
                <TableCell>{r.tipoDoc}</TableCell>
                <TableCell>{r.numDoc}</TableCell>
                <TableCell>{r.fecha ? toDateOnly(r.fecha as string, timeZone) : ""}</TableCell>
                <TableCell align="right">{Number(r.pendiente || 0).toFixed(2)}</TableCell>
                <TableCell align="right">
                  <TextField
                    size="small"
                    type="number"
                    value={r.montoAplicar}
                    onChange={(e) => changeMonto(i, Number(e.target.value))}
                    inputProps={{ min: 0, step: "0.01" }}
                    sx={{ width: 140 }}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <Typography variant="h6" sx={{ mt: 2 }}>
          Total seleccionado: {totalSeleccionado.toFixed(2)}
        </Typography>
      </Paper>
    </Box>
  );
}
