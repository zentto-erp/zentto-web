"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Tab, Tabs, Typography, Button, TextField, Dialog, DialogTitle,
  DialogContent, DialogActions, Stack, MenuItem, Select, InputLabel, FormControl,
  CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
import { useCountries, useLookup } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { useRetencionesList, useGenerarRetencion, type WithholdingFilter } from "../hooks/useFiscalTributaria";
import ConceptosRetencionPage from "./ConceptosRetencionPage";
import UnidadTributariaPage from "./UnidadTributariaPage";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';

interface GenForm { documentId: number; withholdingType: string; countryCode: string; }

const COLUMNS: ColumnDef[] = [
  { field: "VoucherNumber", header: "N. Comprobante", width: 150, sortable: true },
  { field: "VoucherDate", header: "Fecha", width: 110, type: "date", sortable: true },
  { field: "WithholdingType", header: "Tipo", width: 100, sortable: true, groupable: true },
  { field: "ThirdPartyName", header: "Tercero", flex: 1, minWidth: 180, sortable: true },
  { field: "DocumentNumber", header: "N. Documento", width: 140 },
  { field: "TaxableBase", header: "Base imponible", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "WithholdingRate", header: "% Ret.", width: 80, type: "number" },
  { field: "WithholdingAmount", header: "Monto retenido", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "Status", header: "Estado", width: 120, sortable: true, groupable: true,
    statusColors: { APPLIED: "success", VOIDED: "error", PENDING: "default" },
    statusVariant: "outlined",
  },
];

function ComprobantesTab() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { data: countries = [] } = useCountries();
  const { data: withholdingTypes = [] } = useLookup('RETENTION_TYPE');
  const [filter, setFilter] = useState<WithholdingFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [openGen, setOpenGen] = useState(false);
  const [genForm, setGenForm] = useState<GenForm>({ documentId: 0, withholdingType: "IVA", countryCode: "VE" });

  const { data, isLoading } = useRetencionesList(filter);
  const generarMutation = useGenerarRetencion();
  const rows = data?.rows ?? [];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.VoucherId }));
    el.loading = isLoading;
    el.actionButtons = [
      { icon: SVG_VIEW, label: 'Ver', action: 'view' },
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
    ];
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view') {
        // View withholding voucher detail
      }
      if (action === 'edit') {
        // Edit withholding voucher
      }
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered]);

  const handleGenerar = async () => {
    await generarMutation.mutateAsync(genForm);
    setOpenGen(false);
    setGenForm({ documentId: 0, withholdingType: "IVA", countryCode: "VE" });
  };

  if (!registered) return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Comprobantes de Retencion" primaryAction={{ label: "Generar retencion", onClick: () => setOpenGen(true) }} />
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
            setFilter((f) => ({ ...f, withholdingType: vals.withholdingType || undefined, periodCode: vals.periodCode || undefined, countryCode: vals.countryCode || undefined, page: 1 }));
          }}
          searchPlaceholder="Buscar retencion..."
          searchValue={search}
          onSearchChange={setSearch}
        />
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid ref={gridRef} default-currency="VES" export-filename="retenciones" height="100%" show-totals
            enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
        </Paper>
      </Box>

      <Dialog open={openGen} onClose={() => setOpenGen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Generar retencion</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="ID Documento" type="number" fullWidth value={genForm.documentId || ""} onChange={(e) => setGenForm((f) => ({ ...f, documentId: Number(e.target.value) }))} />
            <FormControl fullWidth><InputLabel>Tipo retencion</InputLabel>
              <Select label="Tipo retencion" value={genForm.withholdingType} onChange={(e) => setGenForm((f) => ({ ...f, withholdingType: e.target.value }))}>
                {withholdingTypes.map((t) => (<MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>))}
              </Select>
            </FormControl>
            <FormControl fullWidth><InputLabel>Pais</InputLabel>
              <Select label="Pais" value={genForm.countryCode} onChange={(e) => setGenForm((f) => ({ ...f, countryCode: e.target.value }))}>
                {countries.map((c) => (<MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>))}
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenGen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleGenerar} disabled={generarMutation.isPending || !genForm.documentId}
            startIcon={generarMutation.isPending ? <CircularProgress size={16} /> : <AddIcon />}>Generar</Button>
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
        <Tab label="Comprobantes" /><Tab label="Conceptos" /><Tab label="Unidad Tributaria" />
      </Tabs>
      {tab === 0 && <ComprobantesTab />}
      {tab === 1 && <ConceptosRetencionPage />}
      {tab === 2 && <UnidadTributariaPage />}
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
