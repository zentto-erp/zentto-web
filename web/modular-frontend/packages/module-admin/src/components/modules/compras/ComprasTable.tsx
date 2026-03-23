"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  Chip,
  IconButton,
  InputAdornment,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
  Tooltip,
} from "@mui/material";
import { Add, Search, Visibility } from "@mui/icons-material";
import { toDateOnly } from "@zentto/shared-api";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useTimezone } from "@zentto/shared-auth";
import { useComprasList } from "../../../hooks/useCompras";

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

export default function ComprasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const [search, setSearch] = useState("");
  const [fechaDesde, setFechaDesde] = useState(firstDayOfCurrentMonth(timeZone));
  const [fechaHasta, setFechaHasta] = useState(lastDayOfCurrentMonth(timeZone));
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(50);

  const filter = useMemo(
    () => ({
      search: search.trim() || undefined,
      fechaDesde,
      fechaHasta,
      page: page + 1,
      limit: rowsPerPage
    }),
    [search, fechaDesde, fechaHasta, page, rowsPerPage]
  );

  const { data, isLoading } = useComprasList(filter);

  return (
    <Box>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 600 }}>
          Compras
        </Typography>
        <Button variant="contained" startIcon={<Add />} onClick={() => router.push("/compras/new")}>
          Nueva Compra
        </Button>
      </Box>

      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: "grid", gap: 1.5, gridTemplateColumns: { xs: "1fr", md: "2fr 1fr 1fr" } }}>
          <TextField
            size="small"
            label="Buscar"
            placeholder="Numero, proveedor, rif"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(0);
            }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search fontSize="small" />
                </InputAdornment>
              )
            }}
          />
          <DatePicker
            label="Desde"
            value={fechaDesde ? dayjs(fechaDesde) : null}
            onChange={(v) => { setFechaDesde(v ? v.format('YYYY-MM-DD') : ''); setPage(0); }}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
          <DatePicker
            label="Hasta"
            value={fechaHasta ? dayjs(fechaHasta) : null}
            onChange={(v) => { setFechaHasta(v ? v.format('YYYY-MM-DD') : ''); setPage(0); }}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Box>
      </Paper>

      <Paper>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Numero</TableCell>
              <TableCell>Proveedor</TableCell>
              <TableCell>Fecha</TableCell>
              <TableCell>Tipo</TableCell>
              <TableCell align="right">Total</TableCell>
              <TableCell align="center">Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {isLoading && (
              <TableRow>
                <TableCell colSpan={6}>Cargando...</TableCell>
              </TableRow>
            )}
            {!isLoading && (data?.rows?.length ?? 0) === 0 && (
              <TableRow>
                <TableCell colSpan={6}>Sin compras para el rango seleccionado.</TableCell>
              </TableRow>
            )}
            {!isLoading &&
              (data?.rows ?? []).map((row) => (
                <TableRow key={String(row.NUM_FACT)}>
                  <TableCell>{row.NUM_FACT}</TableCell>
                  <TableCell>{row.NOMBRE || row.COD_PROVEEDOR}</TableCell>
                  <TableCell>{row.FECHA ? toDateOnly(row.FECHA as string, timeZone) : ""}</TableCell>
                  <TableCell>
                    <Chip size="small" label={row.TIPO || "CONTADO"} />
                  </TableCell>
                  <TableCell align="right">{Number(row.TOTAL || 0).toFixed(2)}</TableCell>
                  <TableCell align="center">
                    <Tooltip title="Ver detalle de compra">
                      <IconButton size="small" onClick={() => router.push(`/compras/${encodeURIComponent(String(row.NUM_FACT))}`)}>
                        <Visibility fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>

        <TablePagination
          component="div"
          count={data?.total ?? 0}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(Number(e.target.value));
            setPage(0);
          }}
          rowsPerPageOptions={[25, 50, 100]}
        />
      </Paper>
    </Box>
  );
}

