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
  Typography
} from "@mui/material";
import { Add, Search, Visibility } from "@mui/icons-material";
import { useComprasList } from "../hooks/useCompras";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, formatDate } from "@zentto/shared-api";

export default function ComprasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  function firstDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth(), 1), timeZone);
  }

  function lastDayOfCurrentMonth() {
    const d = new Date();
    return toDateOnly(new Date(d.getFullYear(), d.getMonth() + 1, 0), timeZone);
  }

  const [search, setSearch] = useState("");
  const [fechaDesde, setFechaDesde] = useState(firstDayOfCurrentMonth());
  const [fechaHasta, setFechaHasta] = useState(lastDayOfCurrentMonth());
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
          <TextField
            size="small"
            type="date"
            label="Desde"
            InputLabelProps={{ shrink: true }}
            value={fechaDesde}
            onChange={(e) => {
              setFechaDesde(e.target.value);
              setPage(0);
            }}
          />
          <TextField
            size="small"
            type="date"
            label="Hasta"
            InputLabelProps={{ shrink: true }}
            value={fechaHasta}
            onChange={(e) => {
              setFechaHasta(e.target.value);
              setPage(0);
            }}
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
                <TableRow key={String(row.documentNumber)}>
                  <TableCell>{row.documentNumber}</TableCell>
                  <TableCell>{row.supplierName || row.supplierCode}</TableCell>
                  <TableCell>{row.issueDate ? formatDate(row.issueDate, { timeZone }) : ""}</TableCell>
                  <TableCell>
                    <Chip size="small" label={row.documentType || "COMPRA"} />
                  </TableCell>
                  <TableCell align="right">{Number(row.totalAmount || 0).toFixed(2)}</TableCell>
                  <TableCell align="center">
                    <IconButton size="small" onClick={() => router.push(`/compras/${encodeURIComponent(String(row.documentNumber))}`)}>
                      <Visibility fontSize="small" />
                    </IconButton>
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
