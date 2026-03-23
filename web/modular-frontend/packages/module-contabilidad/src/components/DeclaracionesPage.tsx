"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
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
import VisibilityIcon from "@mui/icons-material/Visibility";
import SendIcon from "@mui/icons-material/Send";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import CalculateIcon from "@mui/icons-material/Calculate";
import { formatCurrency, useCountries } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useDeclaracionesList,
  useCalcularDeclaracion,
  usePresentarDeclaracion,
  type DeclarationFilter,
} from "../hooks/useFiscalTributaria";

const DECLARATION_TYPES = [
  { value: "", label: "Todos" },
  { value: "IVA", label: "IVA" },
  { value: "ISLR", label: "ISLR" },
  { value: "IRPF", label: "IRPF" },
  { value: "MODELO_303", label: "Modelo 303" },
];

const STATUS_OPTIONS = [
  { value: "", label: "Todos" },
  { value: "DRAFT", label: "Borrador" },
  { value: "CALCULATED", label: "Calculada" },
  { value: "SUBMITTED", label: "Presentada" },
  { value: "PAID", label: "Pagada" },
];

const statusColor = (s: string) => {
  switch (s) {
    case "DRAFT": return "default";
    case "CALCULATED": return "info";
    case "SUBMITTED": return "warning";
    case "PAID": return "success";
    default: return "default";
  }
};

interface CalcForm {
  declarationType: string;
  periodCode: string;
  countryCode: string;
}

export default function DeclaracionesPage() {
  const { data: countries = [] } = useCountries();
  const router = useRouter();
  const [filter, setFilter] = useState<DeclarationFilter>({ page: 1, limit: 25 });
  const [openCalc, setOpenCalc] = useState(false);
  const [calcForm, setCalcForm] = useState<CalcForm>({
    declarationType: "IVA",
    periodCode: "",
    countryCode: "VE",
  });

  const { data, isLoading } = useDeclaracionesList(filter);
  const calcularMutation = useCalcularDeclaracion();
  const presentarMutation = usePresentarDeclaracion();

  const rows = data?.rows ?? [];

  const columns: GridColDef[] = [
    {
      field: "DeclarationType",
      headerName: "Tipo",
      width: 130,
      renderCell: (p) => <Chip label={p.value} size="small" color="primary" variant="outlined" />,
    },
    { field: "PeriodCode", headerName: "Periodo", width: 110 },
    { field: "CountryCode", headerName: "Pais", width: 80 },
    {
      field: "SalesBase",
      headerName: "Base Ventas",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "SalesTax",
      headerName: "Imp. Ventas",
      width: 120,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "PurchasesBase",
      headerName: "Base Compras",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "PurchasesTax",
      headerName: "Imp. Compras",
      width: 120,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "NetPayable",
      headerName: "Neto a Pagar",
      width: 140,
      renderCell: (p) => (
        <Typography variant="body2" fontWeight={700}>
          {formatCurrency(p.value)}
        </Typography>
      ),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
      renderCell: (p) => (
        <Chip label={p.value} size="small" color={statusColor(p.value) as any} />
      ),
    },
    {
      field: "acciones",
      headerName: "",
      width: 130,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Ver detalle">
            <IconButton
              size="small"
              onClick={() => router.push(`/contabilidad/fiscal/declaraciones/${p.row.DeclarationId}`)}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          {p.row.Status === "CALCULATED" && (
            <Tooltip title="Presentar">
              <IconButton
                size="small"
                color="primary"
                onClick={() => presentarMutation.mutate({ id: p.row.DeclarationId })}
                disabled={presentarMutation.isPending}
              >
                <SendIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          <Tooltip title="Exportar">
            <IconButton size="small">
              <FileDownloadIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ),
    },
  ];

  const handleCalcular = async () => {
    await calcularMutation.mutateAsync(calcForm);
    setOpenCalc(false);
    setCalcForm({ declarationType: "IVA", periodCode: "", countryCode: "VE" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Declaraciones tributarias"
        primaryAction={{
          label: "Calcular declaración",
          onClick: () => setOpenCalc(true),
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filtros */}
        <Stack direction="row" spacing={2} mb={2} flexWrap="wrap">
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>Tipo</InputLabel>
            <Select
              label="Tipo"
              value={filter.declarationType || ""}
              onChange={(e) => setFilter((f) => ({ ...f, declarationType: e.target.value || undefined, page: 1 }))}
            >
              {DECLARATION_TYPES.map((t) => (
                <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            label="Ano"
            type="number"
            size="small"
            value={filter.year || ""}
            onChange={(e) => setFilter((f) => ({ ...f, year: Number(e.target.value) || undefined, page: 1 }))}
            sx={{ minWidth: 100 }}
          />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              label="Estado"
              value={filter.status || ""}
              onChange={(e) => setFilter((f) => ({ ...f, status: e.target.value || undefined, page: 1 }))}
            >
              {STATUS_OPTIONS.map((o) => (
                <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </Stack>

        {/* DataGrid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
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
            getRowId={(row) => row.DeclarationId}
            sx={{ border: "none" }}
            mobileVisibleFields={['DeclarationType', 'PeriodCode']}
            smExtraFields={['Status', 'NetPayable']}
          />
        </Paper>
      </Box>

      {/* Dialog Calcular Declaracion */}
      <Dialog open={openCalc} onClose={() => setOpenCalc(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Calcular declaración</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <FormControl size="small" fullWidth>
              <InputLabel>Tipo declaración</InputLabel>
              <Select
                label="Tipo declaración"
                value={calcForm.declarationType}
                onChange={(e) => setCalcForm((f) => ({ ...f, declarationType: e.target.value }))}
              >
                {DECLARATION_TYPES.filter((t) => t.value).map((t) => (
                  <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="Periodo (YYYY-MM)"
              size="small"
              fullWidth
              placeholder="2026-03"
              value={calcForm.periodCode}
              onChange={(e) => setCalcForm((f) => ({ ...f, periodCode: e.target.value }))}
            />
            <FormControl size="small" fullWidth>
              <InputLabel>Pais</InputLabel>
              <Select
                label="Pais"
                value={calcForm.countryCode}
                onChange={(e) => setCalcForm((f) => ({ ...f, countryCode: e.target.value }))}
              >
                {countries.map((c) => (
                  <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCalc(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCalcular}
            disabled={calcularMutation.isPending || !calcForm.periodCode}
            startIcon={calcularMutation.isPending ? <CircularProgress size={16} /> : <CalculateIcon />}
          >
            Calcular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
