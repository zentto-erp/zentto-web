"use client";

import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Chip,
  Divider,
  Grid,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography
} from "@mui/material";
import { useCompraById, useDetalleCompra, useIndicadoresCompra } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { formatDate } from "@zentto/shared-api";

interface CompraDetailProps {
  numFact: string;
}

type CompraDetalleRow = Record<string, any>;

export default function CompraDetail({ numFact }: CompraDetailProps) {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const compra = useCompraById(numFact);
  const detalle = useDetalleCompra(numFact);
  const indicadores = useIndicadoresCompra(numFact);

  const row = (compra.data ?? null) as Record<string, any> | null;
  const detRows = (detalle.data ?? []) as CompraDetalleRow[];
  const ind = (indicadores.data ?? null) as Record<string, any> | null;

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Detalle Compra: {numFact}
        </Typography>
        <Button variant="outlined" onClick={() => router.push("/compras")}>
          Volver
        </Button>
      </Box>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>
          Cabecera
        </Typography>
        <Grid container spacing={1}>
          <Grid item xs={12} md={3}><strong>Proveedor:</strong> {row?.NOMBRE || row?.COD_PROVEEDOR || ""}</Grid>
          <Grid item xs={12} md={3}><strong>RIF:</strong> {row?.RIF || ""}</Grid>
          <Grid item xs={12} md={2}><strong>Fecha:</strong> {row?.FECHA ? formatDate(row.FECHA, { timeZone }) : ""}</Grid>
          <Grid item xs={12} md={2}><strong>Tipo:</strong> {row?.TIPO || ""}</Grid>
          <Grid item xs={12} md={2}><strong>Total:</strong> {Number(row?.TOTAL || 0).toFixed(2)}</Grid>
        </Grid>
        {row?.CONCEPTO && (
          <>
            <Divider sx={{ my: 1 }} />
            <Typography variant="body2"><strong>Concepto:</strong> {String(row.CONCEPTO)}</Typography>
          </>
        )}
      </Paper>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>
          Indicadores de proceso
        </Typography>
        <Grid container spacing={1}>
          <Grid item xs={12} md={3}>
            Inventario:{" "}
            <Chip size="small" color={ind?.inventario?.impactado ? "success" : "default"} label={ind?.inventario?.impactado ? "Impactado" : "Sin impacto"} />
          </Grid>
          <Grid item xs={12} md={3}><strong>Mov. Inventario:</strong> {Number(ind?.inventario?.movimientos || 0)}</Grid>
          <Grid item xs={12} md={3}>
            CxP:{" "}
            <Chip size="small" color={ind?.cxp?.generado ? "success" : "default"} label={ind?.cxp?.generado ? "Generado" : "No generado"} />
          </Grid>
          <Grid item xs={12} md={3}><strong>Pendiente CxP:</strong> {Number(ind?.cxp?.pendienteTotal || 0).toFixed(2)}</Grid>
        </Grid>
      </Paper>

      <Paper sx={{ p: 2 }}>
        <Typography variant="subtitle1" sx={{ mb: 1 }}>
          Detalle
        </Typography>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Codigo</TableCell>
              <TableCell>Descripcion</TableCell>
              <TableCell align="right">Cantidad</TableCell>
              <TableCell align="right">P. Costo</TableCell>
              <TableCell align="right">IVA</TableCell>
              <TableCell align="right">SubTotal</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {detRows.length === 0 && (
              <TableRow>
                <TableCell colSpan={6}>Sin detalle.</TableCell>
              </TableRow>
            )}
            {detRows.map((d, idx: number) => {
              const c = Number(d.CANTIDAD || 0);
              const p = Number(d.PRECIO_COSTO || 0);
              return (
                <TableRow key={`${d.CODIGO || "row"}_${idx}`}>
                  <TableCell>{d.CODIGO}</TableCell>
                  <TableCell>{d.DESCRIPCION}</TableCell>
                  <TableCell align="right">{c.toFixed(2)}</TableCell>
                  <TableCell align="right">{p.toFixed(2)}</TableCell>
                  <TableCell align="right">{Number(d.Alicuota ?? d.ALICUOTA ?? 0).toFixed(2)}</TableCell>
                  <TableCell align="right">{(c * p).toFixed(2)}</TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </Paper>
    </Box>
  );
}
