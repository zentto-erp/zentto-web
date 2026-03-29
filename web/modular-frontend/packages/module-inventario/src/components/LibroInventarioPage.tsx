// components/LibroInventarioPage.tsx
"use client";

import { useState } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  CircularProgress,
  Typography,
  Alert,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import MenuBookIcon from "@mui/icons-material/MenuBook";
import DownloadIcon from "@mui/icons-material/Download";
import { useLibroInventario } from "../hooks/useInventario";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

export default function LibroInventarioPage() {
  const { timeZone } = useTimezone();
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return toDateOnly(d, timeZone);
  });
  const [fechaHasta, setFechaHasta] = useState(() => toDateOnly(new Date(), timeZone));
  const [filter, setFilter] = useState<{ fechaDesde: string; fechaHasta: string } | undefined>(undefined);

  const { data, isLoading } = useLibroInventario(filter);
  const rows = (data?.rows ?? []) as Record<string, unknown>[];

  const handleGenerar = () => {
    setFilter({ fechaDesde, fechaHasta });
  };

  // Totales
  const totales = rows.reduce<{ stockInicial: number; entradas: number; salidas: number; stockFinal: number; valorTotal: number }>(
    (acc, r) => ({
      stockInicial: acc.stockInicial + Number(r.StockInicial ?? 0),
      entradas: acc.entradas + Number(r.Entradas ?? 0),
      salidas: acc.salidas + Number(r.Salidas ?? 0),
      stockFinal: acc.stockFinal + Number(r.StockFinal ?? 0),
      valorTotal: acc.valorTotal + Number(r.StockFinal ?? 0) * Number(r.CostoUnitario ?? 0),
    }),
    { stockInicial: 0, entradas: 0, salidas: 0, stockFinal: 0, valorTotal: 0 }
  );

  const handleExportCsv = () => {
    if (rows.length === 0) return;
    const headers = ["Codigo", "Articulo", "Unidad", "Stock Inicial", "Entradas", "Salidas", "Stock Final", "Costo Unit.", "Valor Total"];
    const csvRows = rows.map((r) => [
      r.CODIGO, r.DescripcionCompleta ?? r.DESCRIPCION, r.Unidad ?? "",
      r.StockInicial, r.Entradas, r.Salidas, r.StockFinal, r.CostoUnitario,
      (Number(r.StockFinal ?? 0) * Number(r.CostoUnitario ?? 0)).toFixed(2),
    ].join(","));
    const csv = [headers.join(","), ...csvRows].join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `libro-inventario-${fechaDesde}-${fechaHasta}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, display: "flex", alignItems: "center", gap: 1 }}>
        <MenuBookIcon /> Libro de Inventario
      </Typography>

      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid size={{ xs: 12, sm: 4 }}>
            <DatePicker
              label="Desde"
              value={fechaDesde ? dayjs(fechaDesde) : null}
              onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <DatePicker
              label="Hasta"
              value={fechaHasta ? dayjs(fechaHasta) : null}
              onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button variant="contained" onClick={handleGenerar} disabled={isLoading} startIcon={isLoading ? <CircularProgress size={18} /> : <MenuBookIcon />}>
                Generar
              </Button>
              {rows.length > 0 && (
                <Button variant="outlined" onClick={handleExportCsv} startIcon={<DownloadIcon />}>
                  CSV
                </Button>
              )}
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Resultado */}
      {!filter && (
        <Alert severity="info">Seleccione un rango de fechas y presione "Generar" para ver el libro de inventario.</Alert>
      )}

      {filter && isLoading && (
        <Box sx={{ display: "flex", justifyContent: "center", py: 6 }}>
          <CircularProgress />
        </Box>
      )}

      {filter && !isLoading && rows.length === 0 && (
        <Alert severity="warning">No hay datos para el rango seleccionado.</Alert>
      )}

      {rows.length > 0 && (
        <TableContainer component={Paper}>
          <Table size="small">
            <TableHead>
              <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
                <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Articulo</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>Unidad</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600 }}>Stock Inicial</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600, color: "success.main" }}>Entradas</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600, color: "error.main" }}>Salidas</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600 }}>Stock Final</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600 }}>Costo Unit.</TableCell>
                <TableCell align="right" sx={{ fontWeight: 600 }}>Valor Total</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r, i) => {
                const stockFinal = Number(r.StockFinal ?? 0);
                const costoUnit = Number(r.CostoUnitario ?? 0);
                return (
                  <TableRow key={i} hover>
                    <TableCell sx={{ fontWeight: 500 }}>{String(r.CODIGO ?? "")}</TableCell>
                    <TableCell>{String(r.DescripcionCompleta ?? r.DESCRIPCION ?? "")}</TableCell>
                    <TableCell>{String(r.Unidad ?? "")}</TableCell>
                    <TableCell align="right">{Number(r.StockInicial ?? 0)}</TableCell>
                    <TableCell align="right" sx={{ color: "success.main" }}>{Number(r.Entradas ?? 0)}</TableCell>
                    <TableCell align="right" sx={{ color: "error.main" }}>{Number(r.Salidas ?? 0)}</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 500 }}>{stockFinal}</TableCell>
                    <TableCell align="right">{formatCurrency(costoUnit)}</TableCell>
                    <TableCell align="right" sx={{ fontWeight: 500 }}>{formatCurrency(stockFinal * costoUnit)}</TableCell>
                  </TableRow>
                );
              })}
              {/* Totales */}
              <TableRow sx={{ backgroundColor: "#e8eaf6" }}>
                <TableCell colSpan={3} sx={{ fontWeight: 700 }}>TOTALES</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>{totales.stockInicial}</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: "success.main" }}>{totales.entradas}</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: "error.main" }}>{totales.salidas}</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>{totales.stockFinal}</TableCell>
                <TableCell />
                <TableCell align="right" sx={{ fontWeight: 700 }}>{formatCurrency(totales.valorTotal)}</TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
}
