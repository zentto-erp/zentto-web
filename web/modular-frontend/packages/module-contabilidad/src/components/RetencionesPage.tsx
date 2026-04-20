"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Tab, Tabs, Typography, Button, TextField, Dialog, DialogTitle,
  DialogContent, DialogActions, Stack, MenuItem, Select, InputLabel, FormControl,
  CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
import { useGridLayoutSync, useCountries, useLookup } from "@zentto/shared-api";
import { ModulePageShell } from "@zentto/shared-ui";
import { useRetencionesList, useGenerarRetencion, type WithholdingFilter } from "../hooks/useFiscalTributaria";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
import ConceptosRetencionPage from "./ConceptosRetencionPage";
import UnidadTributariaPage from "./UnidadTributariaPage";


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
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 100,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
    ],
  },
];

function ComprobantesTab() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const { data: countries = [] } = useCountries();
  const { data: withholdingTypes = [] } = useLookup('RETENTION_TYPE');
  const [filter] = useState<WithholdingFilter>({ page: 1, limit: 25 });
  const [openGen, setOpenGen] = useState(false);
  const [genForm, setGenForm] = useState<GenForm>({ documentId: 0, withholdingType: "IVA", countryCode: "VE" });

  const { data, isLoading } = useRetencionesList(filter);
  const generarMutation = useGenerarRetencion();
  const rows = data?.rows ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.VoucherId }));
    el.loading = isLoading;
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

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setOpenGen(true);
    el.addEventListener('create-click', handler);
    return () => el.removeEventListener('create-click', handler);
  }, [registered]);

  const handleGenerar = async () => {
    await generarMutation.mutateAsync(genForm);
    setOpenGen(false);
    setGenForm({ documentId: 0, withholdingType: "IVA", countryCode: "VE" });
  };

  if (!registered) return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;

  return (
    <>
      <ModulePageShell
        actions={<Button variant="contained" onClick={() => setOpenGen(true)}>Generar retencion</Button>}
        sx={{ display: "flex", flexDirection: "column", minHeight: 500 }}
      >
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 500, width: "100%", elevation: 0, border: (t) => `1px solid ${t.palette.divider}` }}>
          <zentto-grid ref={gridRef} default-currency="VES" export-filename="retenciones" height="100%" show-totals
            enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator
            enable-create create-label="Nueva Retencion"></zentto-grid>
        </Paper>
      </ModulePageShell>

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
    </>
  );
}

const GRID_IDS = {
  gridRef: buildContabilidadGridId("retenciones", "main"),
} as const;

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
