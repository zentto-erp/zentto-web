"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  Stack,
  MenuItem,
  Select,
  InputLabel,
  FormControl,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Divider,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import AutorenewIcon from "@mui/icons-material/Autorenew";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useGenerarLibroFiscal,
  useLibroFiscal,
  useResumenLibroFiscal,
  type TaxBookFilter,
} from "../hooks/useFiscalTributaria";

const BOOK_TYPES = [
  { value: "PURCHASE", label: "Compras" },
  { value: "SALES", label: "Ventas" },
];

const COUNTRY_CODES = [
  { value: "VE", label: "Venezuela" },
  { value: "ES", label: "Espana" },
];

export default function LibroFiscalPage() {
  const [filter, setFilter] = useState<TaxBookFilter>({
    bookType: "PURCHASE",
    periodCode: "",
    countryCode: "VE",
    page: 1,
    limit: 50,
  });

  const generarMutation = useGenerarLibroFiscal();
  const { data: libroData, isLoading } = useLibroFiscal(
    filter.periodCode ? filter : null
  );
  const { data: resumenData } = useResumenLibroFiscal(
    filter.bookType,
    filter.periodCode,
    filter.countryCode
  );

  const rows = libroData?.rows ?? [];
  const resumenRows = resumenData?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "EntryDate", headerName: "Fecha", width: 110 },
    { field: "DocumentNumber", headerName: "N. Documento", width: 140 },
    {
      field: "DocumentType",
      headerName: "Tipo",
      width: 100,
      renderCell: (p) => <Chip label={p.value} size="small" variant="outlined" />,
    },
    { field: "ThirdPartyId", headerName: "RIF/NIF", width: 120 },
    { field: "ThirdPartyName", headerName: "Razón social", flex: 1, minWidth: 180 },
    {
      field: "TaxableBase",
      headerName: "Base imponible",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "ExemptAmount",
      headerName: "Exento",
      width: 110,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "TaxRate",
      headerName: "% IVA",
      width: 80,
      renderCell: (p) => `${p.value}%`,
    },
    {
      field: "TaxAmount",
      headerName: "Impuesto",
      width: 120,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "WithholdingAmount",
      headerName: "Retencion",
      width: 120,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "TotalAmount",
      headerName: "Total",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
  ];

  const handleGenerar = async () => {
    await generarMutation.mutateAsync({
      bookType: filter.bookType,
      periodCode: filter.periodCode,
      countryCode: filter.countryCode,
    });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Libro fiscal de compras / ventas" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filtros */}
        <Stack direction="row" spacing={2} mb={2} flexWrap="wrap" alignItems="center">
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Tipo</InputLabel>
            <Select
              label="Tipo"
              value={filter.bookType}
              onChange={(e) => setFilter((f) => ({ ...f, bookType: e.target.value }))}
            >
              {BOOK_TYPES.map((t) => (
                <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            label="Periodo (YYYY-MM)"
            size="small"
            placeholder="2026-03"
            value={filter.periodCode}
            onChange={(e) => setFilter((f) => ({ ...f, periodCode: e.target.value }))}
            sx={{ minWidth: 160 }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Pais</InputLabel>
            <Select
              label="Pais"
              value={filter.countryCode}
              onChange={(e) => setFilter((f) => ({ ...f, countryCode: e.target.value }))}
            >
              {COUNTRY_CODES.map((c) => (
                <MenuItem key={c.value} value={c.value}>{c.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <Button
            variant="contained"
            onClick={handleGenerar}
            disabled={!filter.periodCode || generarMutation.isPending}
            startIcon={generarMutation.isPending ? <CircularProgress size={16} /> : <AutorenewIcon />}
          >
            Generar libro
          </Button>
          <Button
            variant="outlined"
            startIcon={<FileDownloadIcon />}
            disabled={rows.length === 0}
          >
            Exportar
          </Button>
        </Stack>

        {/* DataGrid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[50, 100]}
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 50 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            rowCount={libroData?.total ?? 0}
            paginationMode="server"
            disableRowSelectionOnClick
            getRowId={(row) => row.EntryId}
            sx={{ border: "none" }}
            mobileVisibleFields={['EntryDate', 'ThirdPartyName']}
            smExtraFields={['TaxableBase', 'TaxAmount']}
          />
        </Paper>

        {/* Resumen por Tasa */}
        {resumenRows.length > 0 && (
          <Paper sx={{ mt: 3, p: 2, border: "1px solid #E5E7EB" }}>
            <Typography variant="h6" fontWeight={600} mb={1}>
              Resumen por tasa impositiva
            </Typography>
            <Divider sx={{ mb: 2 }} />
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Tasa (%)</TableCell>
                  <TableCell align="right">Base Imponible</TableCell>
                  <TableCell align="right">Impuesto</TableCell>
                  <TableCell align="right">Retenciones</TableCell>
                  <TableCell align="right">Registros</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {resumenRows.map((r: any, idx: number) => (
                  <TableRow key={idx}>
                    <TableCell>{r.TaxRate}%</TableCell>
                    <TableCell align="right">{formatCurrency(r.TaxableBase)}</TableCell>
                    <TableCell align="right">{formatCurrency(r.TaxAmount)}</TableCell>
                    <TableCell align="right">{formatCurrency(r.WithholdingAmount)}</TableCell>
                    <TableCell align="right">{r.EntryCount}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Paper>
        )}
      </Box>
    </Box>
  );
}
