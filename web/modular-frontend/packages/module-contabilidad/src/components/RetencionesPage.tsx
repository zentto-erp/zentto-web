"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Tab,
  Tabs,
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
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency, useCountries, useLookup } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import {
  useRetencionesList,
  useGenerarRetencion,
  type WithholdingFilter,
} from "../hooks/useFiscalTributaria";
import ConceptosRetencionPage from "./ConceptosRetencionPage";
import UnidadTributariaPage from "./UnidadTributariaPage";

interface GenForm {
  documentId: number;
  withholdingType: string;
  countryCode: string;
}

function ComprobantesTab() {
  const { data: countries = [] } = useCountries();
  const { data: withholdingTypes = [] } = useLookup('RETENTION_TYPE');
  const [filter, setFilter] = useState<WithholdingFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [openGen, setOpenGen] = useState(false);
  const [genForm, setGenForm] = useState<GenForm>({
    documentId: 0,
    withholdingType: "IVA",
    countryCode: "VE",
  });

  const { data, isLoading } = useRetencionesList(filter);
  const generarMutation = useGenerarRetencion();

  const rows = data?.rows ?? [];

  const columns: ZenttoColDef[] = [
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
      type: "number",
      aggregation: "sum",
      currency: "VES",
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
      type: "number",
      aggregation: "sum",
      currency: "VES",
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "Status",
      headerName: "Estado",
      width: 120,
      statusColors: { APPLIED: "success", VOIDED: "error", PENDING: "default" },
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
        <ZenttoFilterPanel
          filters={[
            { field: "withholdingType", label: "Tipo", type: "select", options: withholdingTypes.map((t) => ({ value: t.Code, label: t.Label })) },
            { field: "periodCode", label: "Fecha (YYYY-MM)", type: "text", placeholder: "2026-03", minWidth: 160 },
            { field: "countryCode", label: "Pais", type: "select", options: countries.map((c) => ({ value: c.CountryCode, label: c.CountryName })) },
          ] as FilterFieldDef[]}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              withholdingType: vals.withholdingType || undefined,
              periodCode: vals.periodCode || undefined,
              countryCode: vals.countryCode || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar retencion..."
          searchValue={search}
          onSearchChange={setSearch}
        />

        {/* DataGrid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            gridId="contabilidad-retenciones-list"
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
            mobileVisibleFields={['VoucherDate', 'ThirdPartyName']}
            smExtraFields={['WithholdingType', 'WithholdingAmount']}
            showTotals
            enableClipboard
            enableHeaderFilters
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
             
              fullWidth
              value={genForm.documentId || ""}
              onChange={(e) => setGenForm((f) => ({ ...f, documentId: Number(e.target.value) }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo retención</InputLabel>
              <Select
                label="Tipo retención"
                value={genForm.withholdingType}
                onChange={(e) => setGenForm((f) => ({ ...f, withholdingType: e.target.value }))}
              >
                {withholdingTypes.map((t) => (
                  <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Pais</InputLabel>
              <Select
                label="Pais"
                value={genForm.countryCode}
                onChange={(e) => setGenForm((f) => ({ ...f, countryCode: e.target.value }))}
              >
                {countries.map((c) => (
                  <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>
                ))}
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

export default function RetencionesPage() {
  const [tab, setTab] = useState(0);

  return (
    <Box>
      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3, borderBottom: 1, borderColor: "divider" }}>
        <Tab label="Comprobantes" />
        <Tab label="Conceptos" />
        <Tab label="Unidad Tributaria" />
      </Tabs>

      {tab === 0 && <ComprobantesTab />}
      {tab === 1 && <ConceptosRetencionPage />}
      {tab === 2 && <UnidadTributariaPage />}
    </Box>
  );
}
