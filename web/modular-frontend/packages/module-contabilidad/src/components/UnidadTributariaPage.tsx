"use client";

import { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, MenuItem, Dialog,
  DialogTitle, DialogContent, DialogActions, CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useGridLayoutSync, useCountries } from "@zentto/shared-api";
import { useTaxUnitList, useTaxUnitUpsert } from "../hooks/useFiscalTributaria";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";


const COLUMNS: ColumnDef[] = [
  { field: "CountryCode", header: "Pais", width: 80, sortable: true },
  { field: "TaxYear", header: "Ano", width: 80, type: "number", sortable: true },
  { field: "UnitValue", header: "Valor UT", width: 120, type: "number" },
  { field: "Currency", header: "Moneda", width: 80 },
  { field: "EffectiveDate", header: "Vigente desde", width: 130, type: "date" },
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

const GRID_IDS = {
  gridRef: buildContabilidadGridId("unidad-tributaria", "main"),
} as const;

export default function UnidadTributariaPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const { data: countries = [] } = useCountries();
  const [filterCountry, setFilterCountry] = useState("");
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({ countryCode: "VE", taxYear: new Date().getFullYear(), unitValue: 0, currency: "VES", effectiveDate: "" });

  const { data, isLoading } = useTaxUnitList(filterCountry || undefined);
  const upsert = useTaxUnitUpsert();
  const rows = data?.rows ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.TaxUnitId ?? `${r.CountryCode}-${r.TaxYear}`, EffectiveDate: r.EffectiveDate?.slice(0, 10) }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      const item = rows.find((r: any) => (r.TaxUnitId ?? `${r.CountryCode}-${r.TaxYear}`) === row.id);
      if (!item) return;
      if (action === 'view' || action === 'edit') {
        setForm({
          countryCode: item.CountryCode, taxYear: item.TaxYear,
          unitValue: item.UnitValue, currency: item.Currency,
          effectiveDate: item.EffectiveDate?.slice(0, 10) ?? "",
        });
        setDialogOpen(true);
      }
    };
    const createHandler = () => {
      setForm({ countryCode: "VE", taxYear: new Date().getFullYear(), unitValue: 0, currency: "VES", effectiveDate: `${new Date().getFullYear()}-01-01` });
      setDialogOpen(true);
    };
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
  }, [registered, rows]);

  const handleSave = async () => {
    try { await upsert.mutateAsync(form); setDialogOpen(false); } catch { /* handled */ }
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box>
      <Typography variant="h6" sx={{ mb: 2 }}>Unidad Tributaria</Typography>

      <ZenttoFilterPanel
        filters={[
          { field: "countryCode", label: "Periodo (pais)", type: "select", options: countries.map((c) => ({ value: c.CountryCode, label: c.CountryName })) },
        ] as FilterFieldDef[]}
        values={filterValues}
        onChange={(vals) => { setFilterValues(vals); setFilterCountry(vals.countryCode || ""); }}
        searchPlaceholder="Buscar..."
        searchValue={search}
        onSearchChange={setSearch}
      />

      <zentto-grid
        ref={gridRef}
        export-filename="unidad-tributaria"
        height="calc(100vh - 300px)"
        enable-create
        create-label="Nuevo Valor"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Valor Unidad Tributaria</DialogTitle>
        <DialogContent>
          <FormGrid spacing={2} sx={{ mt: 1 }}>
            <FormField xs={12} sm={6}>
              <TextField select label="Pais" fullWidth value={form.countryCode}
                onChange={(e) => {
                  const country = countries.find((c) => c.CountryCode === e.target.value);
                  setForm({ ...form, countryCode: e.target.value, currency: country?.CurrencyCode ?? "VES" });
                }}>
                {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
              </TextField>
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Ano" type="number" fullWidth value={form.taxYear} onChange={(e) => setForm({ ...form, taxYear: Number(e.target.value) })} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Valor UT" type="number" fullWidth value={form.unitValue} onChange={(e) => setForm({ ...form, unitValue: Number(e.target.value) })} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Moneda" fullWidth value={form.currency} disabled />
            </FormField>
            <FormField xs={12}>
              <DatePicker label="Vigente desde" value={form.effectiveDate ? dayjs(form.effectiveDate) : null}
                onChange={(v) => setForm({ ...form, effectiveDate: v ? v.format('YYYY-MM-DD') : '' })}
                slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={upsert.isPending || !form.unitValue}>
            {upsert.isPending ? "Guardando..." : "Guardar"}
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
