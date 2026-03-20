"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  MenuItem,
  Select,
  InputLabel,
  FormControl,
  Tooltip,
  CircularProgress,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useRetencionesList,
  useGenerarRetencion,
  type WithholdingFilter,
} from "../hooks/useFiscalTributaria";

const WITHHOLDING_TYPES = [
  { value: "", label: "Todos" },
  { value: "IVA", label: "IVA" },
  { value: "ISLR", label: "ISLR" },
  { value: "IRPF", label: "IRPF" },
];

const COUNTRY_CODES = [
  { value: "", label: "Todos" },
  { value: "VE", label: "Venezuela" },
  { value: "ES", label: "Espana" },
  { value: "CO", label: "Colombia" },
];

interface GenForm {
  documentId: number;
  withholdingType: string;
  countryCode: string;
}

export default function RetencionesPage() {
  const [filter, setFilter] = useState<WithholdingFilter>({ page: 1, limit: 25 });
  const [openGen, setOpenGen] = useState(false);
  const [genForm, setGenForm] = useState<GenForm>({
    documentId: 0,
    withholdingType: "IVA",
    countryCode: "VE",
  });

  const { data, isLoading } = useRetencionesList(filter);
  const generarMutation = useGenerarRetencion();

  const rows = data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "VoucherNumber", headerName: "N. Comprobante", width: 150 },
    { field: "VoucherDate", headerName: "Fecha", width: 110 },
    {
      field: "WithholdingType",
      headerName: "Tipo",
      width: 100,
      renderCell: (p) => <Chip label={p.value} size="small" color="primary" variant="outlined" />,
    },
    { field: "ThirdPartyName", headerName: "Tercero", flex: 1, minWidth: 180 },
    { field: "DocumentNumber", headerName: "N. Documento", width: 140 },
    {
      field: "TaxableBase",
      headerName: "Base imponible",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "WithholdingRate",
      headerName: "% Ret.",
      width: 80,
      renderCell: (p) => `${p.value}%`,
    },
    {
      field: "WithholdingAmount",
      headerName: "Monto retenido",
      width: 140,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value}
          size="small"
          color={p.value === "APPLIED" ? "success" : p.value === "VOIDED" ? "error" : "default"}
        />
      ),
    },
  ];

  const handleGenerar = async () => {
    await generarMutation.mutateAsync(genForm);
    setOpenGen(false);
    setGenForm({ documentId: 0, withholdingType: "IVA", countryCode: "VE" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Comprobantes de Retencion"
        primaryAction={{
          label: "Generar retención",
          onClick: () => setOpenGen(true),
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filtros */}
        <Stack direction="row" spacing={2} mb={2} flexWrap="wrap">
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Tipo</InputLabel>
            <Select
              label="Tipo"
              value={filter.withholdingType || ""}
              onChange={(e) => setFilter((f) => ({ ...f, withholdingType: e.target.value || undefined, page: 1 }))}
            >
              {WITHHOLDING_TYPES.map((t) => (
                <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            label="Periodo (YYYY-MM)"
            size="small"
            value={filter.periodCode || ""}
            onChange={(e) => setFilter((f) => ({ ...f, periodCode: e.target.value || undefined, page: 1 }))}
            sx={{ minWidth: 160 }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Pais</InputLabel>
            <Select
              label="Pais"
              value={filter.countryCode || ""}
              onChange={(e) => setFilter((f) => ({ ...f, countryCode: e.target.value || undefined, page: 1 }))}
            >
              {COUNTRY_CODES.map((c) => (
                <MenuItem key={c.value} value={c.value}>{c.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </Stack>

        {/* DataGrid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <DataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[25, 50]}
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            rowCount={data?.total ?? 0}
            paginationMode="server"
            disableRowSelectionOnClick
            getRowId={(row) => row.VoucherId}
            sx={{ border: "none" }}
          />
        </Paper>
      </Box>

      {/* Dialog Generar Retencion */}
      <Dialog open={openGen} onClose={() => setOpenGen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Generar retención</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="ID Documento"
              type="number"
              size="small"
              fullWidth
              value={genForm.documentId || ""}
              onChange={(e) => setGenForm((f) => ({ ...f, documentId: Number(e.target.value) }))}
            />
            <FormControl size="small" fullWidth>
              <InputLabel>Tipo retención</InputLabel>
              <Select
                label="Tipo retención"
                value={genForm.withholdingType}
                onChange={(e) => setGenForm((f) => ({ ...f, withholdingType: e.target.value }))}
              >
                {WITHHOLDING_TYPES.filter((t) => t.value).map((t) => (
                  <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl size="small" fullWidth>
              <InputLabel>Pais</InputLabel>
              <Select
                label="Pais"
                value={genForm.countryCode}
                onChange={(e) => setGenForm((f) => ({ ...f, countryCode: e.target.value }))}
              >
                <MenuItem value="VE">Venezuela</MenuItem>
                <MenuItem value="ES">Espana</MenuItem>
                <MenuItem value="CO">Colombia</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenGen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleGenerar}
            disabled={generarMutation.isPending || !genForm.documentId}
            startIcon={generarMutation.isPending ? <CircularProgress size={16} /> : <AddIcon />}
          >
            Generar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
