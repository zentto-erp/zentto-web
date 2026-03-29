"use client";

import { useMemo, useState } from "react";
import {
  Box,
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
import { useCuentasBancarias, useMovimientosCuenta } from "../../../hooks/useBancosAuxiliares";
import { toDateOnly, formatDateTime } from "@zentto/shared-api";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useTimezone } from "@zentto/shared-auth";

type CuentaRow = Record<string, unknown>;
type MovimientoRow = Record<string, unknown>;

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

export default function CuentasBancariasPage() {
  const { timeZone } = useTimezone();
  const [nroCta, setNroCta] = useState("");
  const [desde, setDesde] = useState(firstDayOfCurrentMonth(timeZone));
  const [hasta, setHasta] = useState(lastDayOfCurrentMonth(timeZone));
  const [page, setPage] = useState(1);
  const [limit] = useState(50);

  const { data: cuentasData, isLoading: loadingCtas } = useCuentasBancarias();
  const input = useMemo(() => ({ nroCta: nroCta || undefined, desde, hasta, page, limit }), [nroCta, desde, hasta, page, limit]);
  const { data: movsData, isLoading: loadingMovs } = useMovimientosCuenta(input);

  const cuentas = (cuentasData?.rows ?? []) as CuentaRow[];
  const movs = (movsData?.rows ?? []) as MovimientoRow[];

  return (
    <Box>

      <Grid container spacing={2}>
        <Grid item xs={12} lg={5}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" sx={{ mb: 1 }}>Cuentas</Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Nro Cta</TableCell>
                  <TableCell>Banco</TableCell>
                  <TableCell align="right">Saldo</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loadingCtas && <TableRow><TableCell colSpan={3}>Cargando...</TableCell></TableRow>}
                {!loadingCtas && cuentas.length === 0 && <TableRow><TableCell colSpan={3}>Sin cuentas.</TableCell></TableRow>}
                {!loadingCtas && cuentas.map((c) => (
                  <TableRow key={String(c.Nro_Cta)} selected={nroCta === String(c.Nro_Cta)} onClick={() => setNroCta(String(c.Nro_Cta))} sx={{ cursor: "pointer" }}>
                    <TableCell>{String(c.Nro_Cta)}</TableCell>
                    <TableCell>{String(c.BancoNombre ?? c.Banco ?? "")}</TableCell>
                    <TableCell align="right">{Number(c.Saldo ?? 0).toFixed(2)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Paper>
        </Grid>

        <Grid item xs={12} lg={7}>
          <Paper sx={{ p: 2, mb: 1 }}>
            <Typography variant="subtitle1" sx={{ mb: 1 }}>Filtro Movimientos</Typography>
            <Grid container spacing={1}>
              <Grid item xs={12} md={4}>
                <TextField fullWidth label="Cuenta" value={nroCta} onChange={(e) => setNroCta(e.target.value)} />
              </Grid>
              <Grid item xs={12} md={3}>
                <DatePicker label="Desde" value={desde ? dayjs(desde) : null} onChange={(v) => setDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
              </Grid>
              <Grid item xs={12} md={3}>
                <DatePicker label="Hasta" value={hasta ? dayjs(hasta) : null} onChange={(v) => setHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
              </Grid>
              <Grid item xs={12} md={2}>
                <TextField fullWidth type="number" label="Pagina" value={page} onChange={(e) => setPage(Number(e.target.value) || 1)} />
              </Grid>
            </Grid>
          </Paper>

          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" sx={{ mb: 1 }}>Movimientos</Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>ID</TableCell>
                  <TableCell>Fecha</TableCell>
                  <TableCell>Tipo</TableCell>
                  <TableCell>Ref</TableCell>
                  <TableCell>Beneficiario</TableCell>
                  <TableCell align="right">Monto</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loadingMovs && <TableRow><TableCell colSpan={6}>Cargando...</TableCell></TableRow>}
                {!loadingMovs && movs.length === 0 && <TableRow><TableCell colSpan={6}>Sin movimientos.</TableCell></TableRow>}
                {!loadingMovs && movs.map((m) => (
                  <TableRow key={String(m.id ?? m.ID)}>
                    <TableCell>{String(m.id ?? m.ID)}</TableCell>
                    <TableCell>{m.Fecha ? formatDateTime(m.Fecha as string, { timeZone }) : ""}</TableCell>
                    <TableCell>{String(m.Tipo ?? "")}</TableCell>
                    <TableCell>{String(m.Nro_Ref ?? "")}</TableCell>
                    <TableCell>{String(m.Beneficiario ?? "")}</TableCell>
                    <TableCell align="right">{Number(m.Monto ?? 0).toFixed(2)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

