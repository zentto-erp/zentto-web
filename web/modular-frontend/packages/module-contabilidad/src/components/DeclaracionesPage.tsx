"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, TextField, Dialog, DialogTitle, DialogContent,
  DialogActions, Stack, MenuItem, Select, InputLabel, FormControl, CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync, useCountries } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useDeclaracionesList, useCalcularDeclaracion, usePresentarDeclaracion, type DeclarationFilter,
} from "../hooks/useFiscalTributaria";

import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
const DECLARATION_TYPES = [
  { value: "", label: "Todos" }, { value: "IVA", label: "IVA" },
  { value: "ISLR", label: "ISLR" }, { value: "IRPF", label: "IRPF" },
  { value: "MODELO_303", label: "Modelo 303" },
];
const STATUS_OPTIONS = [
  { value: "", label: "Todos" }, { value: "DRAFT", label: "Borrador" },
  { value: "CALCULATED", label: "Calculada" }, { value: "SUBMITTED", label: "Presentada" },
  { value: "PAID", label: "Pagada" },
];

const COLUMNS: ColumnDef[] = [
  { field: "DeclarationType", header: "Tipo", width: 130, sortable: true, groupable: true },
  { field: "PeriodCode", header: "Periodo", width: 110, sortable: true },
  { field: "CountryCode", header: "Pais", width: 80, sortable: true },
  { field: "SalesBase", header: "Base Ventas", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "SalesTax", header: "Imp. Ventas", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  { field: "PurchasesBase", header: "Base Compras", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "PurchasesTax", header: "Imp. Compras", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  { field: "NetPayable", header: "Neto a Pagar", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "Status", header: "Estado", width: 130, sortable: true, groupable: true,
    statusColors: { DRAFT: "default", CALCULATED: "info", SUBMITTED: "warning", PAID: "success" },
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
      { icon: "edit", label: "Presentar", action: "edit", color: "#e67e22" },
    ],
  },
];


interface CalcForm { declarationType: string; periodCode: string; countryCode: string; }

const GRID_IDS = {
  gridRef: buildContabilidadGridId("declaraciones", "main"),
} as const;

export default function DeclaracionesPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const { data: countries = [] } = useCountries();
  const [filter] = useState<DeclarationFilter>({ page: 1, limit: 25 });
  const [openCalc, setOpenCalc] = useState(false);
  const [calcForm, setCalcForm] = useState<CalcForm>({ declarationType: "IVA", periodCode: "", countryCode: "VE" });

  const { data, isLoading } = useDeclaracionesList(filter);
  const calcularMutation = useCalcularDeclaracion();
  const presentarMutation = usePresentarDeclaracion();
  const rows = data?.rows ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.DeclarationId }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view') {
        // View declaration detail (could open a detail dialog in the future)
      }
      if (action === 'edit' && row.Status === 'CALCULATED') {
        presentarMutation.mutate(row.DeclarationId);
      }
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, presentarMutation]);

  const handleCalcular = async () => {
    await calcularMutation.mutateAsync(calcForm);
    setOpenCalc(false);
    setCalcForm({ declarationType: "IVA", periodCode: "", countryCode: "VE" });
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Declaraciones tributarias" primaryAction={{ label: "Calcular declaracion", onClick: () => setOpenCalc(true) }} />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="declaraciones"
            height="100%"
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
          ></zentto-grid>
        </Paper>
      </Box>

      <Dialog open={openCalc} onClose={() => setOpenCalc(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Calcular declaracion</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <FormControl fullWidth>
              <InputLabel>Tipo declaracion</InputLabel>
              <Select label="Tipo declaracion" value={calcForm.declarationType} onChange={(e) => setCalcForm((f) => ({ ...f, declarationType: e.target.value }))}>
                {DECLARATION_TYPES.filter((t) => t.value).map((t) => (<MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>))}
              </Select>
            </FormControl>
            <TextField label="Periodo (YYYY-MM)" fullWidth placeholder="2026-03" value={calcForm.periodCode} onChange={(e) => setCalcForm((f) => ({ ...f, periodCode: e.target.value }))} />
            <FormControl fullWidth>
              <InputLabel>Pais</InputLabel>
              <Select label="Pais" value={calcForm.countryCode} onChange={(e) => setCalcForm((f) => ({ ...f, countryCode: e.target.value }))}>
                {countries.map((c) => (<MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>))}
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCalc(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCalcular} disabled={calcularMutation.isPending || !calcForm.periodCode}
            startIcon={calcularMutation.isPending ? <CircularProgress size={16} /> : undefined}>
            Calcular
          </Button>
        </DialogActions>
      </Dialog>
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
