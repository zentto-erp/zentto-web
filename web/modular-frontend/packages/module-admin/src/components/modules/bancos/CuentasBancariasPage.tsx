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

type CuentaRow = Record<string, unknown>;
type MovimientoRow = Record<string, unknown>;

function firstDayOfCurrentMonth() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().slice(0, 10);
}

function lastDayOfCurrentMonth() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).toISOString().slice(0, 10);
}

export default function CuentasBancariasPage() {
  const [nroCta, setNroCta] = useState("");
  const [desde, setDesde] = useState(firstDayOfCurrentMonth());
  const [hasta, setHasta] = useState(lastDayOfCurrentMonth());
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
                <TextField fullWidth size="small" label="Cuenta" value={nroCta} onChange={(e) => setNroCta(e.target.value)} />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField fullWidth size="small" type="date" label="Desde" InputLabelProps={{ shrink: true }} value={desde} onChange={(e) => setDesde(e.target.value)} />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField fullWidth size="small" type="date" label="Hasta" InputLabelProps={{ shrink: true }} value={hasta} onChange={(e) => setHasta(e.target.value)} />
              </Grid>
              <Grid item xs={12} md={2}>
                <TextField fullWidth size="small" type="number" label="Pagina" value={page} onChange={(e) => setPage(Number(e.target.value) || 1)} />
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
                    <TableCell>{String(m.Fecha ?? "").slice(0, 19).replace("T", " ")}</TableCell>
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

