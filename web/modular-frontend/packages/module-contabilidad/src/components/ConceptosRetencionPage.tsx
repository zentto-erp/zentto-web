"use client";

import { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, Stack, TextField, MenuItem, Dialog,
  DialogTitle, DialogContent, DialogActions, Alert, CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync, useCountries, useLookup } from "@zentto/shared-api";
import { useConceptosList, useConceptoUpsert, type ConceptoFilter } from "../hooks/useFiscalTributaria";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";


const COLUMNS: ColumnDef[] = [
  { field: "ConceptCode", header: "Codigo", width: 140, sortable: true },
  { field: "Description", header: "Descripcion", flex: 1, minWidth: 200, sortable: true },
  { field: "SupplierType", header: "Tipo Persona", width: 130, sortable: true, groupable: true },
  { field: "ActivityCode", header: "Actividad", width: 130, sortable: true },
  { field: "RetentionType", header: "Tipo Ret.", width: 100, sortable: true, groupable: true },
  { field: "Rate", header: "%", width: 80, type: "number" },
  { field: "SubtrahendUT", header: "Sustraendo UT", width: 120, type: "number" },
  { field: "MinBaseUT", header: "Min Base UT", width: 110, type: "number" },
  { field: "SeniatCode", header: "Cod SENIAT", width: 100 },
  { field: "CountryCode", header: "Pais", width: 60, sortable: true },
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
  gridRef: buildContabilidadGridId("conceptos-retencion", "main"),
} as const;

export default function ConceptosRetencionPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const { data: countries = [] } = useCountries();
  const { data: retTypes = [] } = useLookup('RETENTION_TYPE');
  const { data: supplierTypes = [] } = useLookup('SUPPLIER_TYPE');
  const [filter] = useState<ConceptoFilter>({ page: 1, limit: 50 });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<Record<string, any>>({
    conceptCode: "", description: "", supplierType: "AMBOS", activityCode: "",
    retentionType: "ISLR", rate: 0, subtrahendUT: 0, minBaseUT: 0,
    seniatCode: "", countryCode: "VE",
  });

  const { data, isLoading } = useConceptosList(filter);
  const upsert = useConceptoUpsert();
  const rows = data?.rows ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.ConceptId ?? r.ConceptCode }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      const concepto = rows.find((r: any) => (r.ConceptId ?? r.ConceptCode) === row.id);
      if (!concepto) return;
      if (action === 'view') handleEdit(concepto);
      if (action === 'edit') handleEdit(concepto);
    };
    const createHandler = () => {
      setForm({ conceptCode: "", description: "", supplierType: "AMBOS", activityCode: "",
        retentionType: "ISLR", rate: 0, subtrahendUT: 0, minBaseUT: 0, seniatCode: "", countryCode: "VE" });
      setDialogOpen(true);
    };
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
  }, [registered, rows]);

  const handleSave = async () => {
    try { await upsert.mutateAsync(form as any); setDialogOpen(false); }
    catch { /* toast handled by mutation */ }
  };

  const handleEdit = (row: any) => {
    setForm({
      conceptCode: row.ConceptCode, description: row.Description,
      supplierType: row.SupplierType, activityCode: row.ActivityCode ?? "",
      retentionType: row.RetentionType, rate: row.Rate,
      subtrahendUT: row.SubtrahendUT, minBaseUT: row.MinBaseUT,
      seniatCode: row.SeniatCode ?? "", countryCode: row.CountryCode,
    });
    setDialogOpen(true);
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box>
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="conceptos-retencion"
        height="calc(100vh - 300px)"
        enable-create
        create-label="Nuevo Concepto"
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-configurator
      ></zentto-grid>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{form.conceptCode ? "Editar Concepto" : "Nuevo Concepto"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
              <TextField label="Codigo" fullWidth value={form.conceptCode}
                onChange={(e) => setForm({ ...form, conceptCode: e.target.value })}
                disabled={!!form.conceptCode && rows.some((r: any) => r.ConceptCode === form.conceptCode)} />
              <TextField select label="Pais" value={form.countryCode} sx={{ minWidth: 120 }}
                onChange={(e) => setForm({ ...form, countryCode: e.target.value })}>
                {countries.map((c) => <MenuItem key={c.CountryCode} value={c.CountryCode}>{c.CountryName}</MenuItem>)}
              </TextField>
            </Stack>
            <TextField label="Descripcion" fullWidth value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
            <Stack direction="row" spacing={2}>
              <TextField select label="Tipo Persona" fullWidth value={form.supplierType} onChange={(e) => setForm({ ...form, supplierType: e.target.value })}>
                {supplierTypes.map((t) => <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>)}
              </TextField>
              <TextField label="Actividad" fullWidth value={form.activityCode} onChange={(e) => setForm({ ...form, activityCode: e.target.value })} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField select label="Tipo Retencion" fullWidth value={form.retentionType} onChange={(e) => setForm({ ...form, retentionType: e.target.value })}>
                {retTypes.map((t) => <MenuItem key={t.Code} value={t.Code}>{t.Label}</MenuItem>)}
              </TextField>
              <TextField label="% Retencion" type="number" fullWidth value={form.rate} onChange={(e) => setForm({ ...form, rate: Number(e.target.value) })} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="Sustraendo (UT)" type="number" fullWidth value={form.subtrahendUT} onChange={(e) => setForm({ ...form, subtrahendUT: Number(e.target.value) })} />
              <TextField label="Base Minima (UT)" type="number" fullWidth value={form.minBaseUT} onChange={(e) => setForm({ ...form, minBaseUT: Number(e.target.value) })} />
              <TextField label="Cod SENIAT" fullWidth value={form.seniatCode} onChange={(e) => setForm({ ...form, seniatCode: e.target.value })} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={upsert.isPending || !form.conceptCode || !form.description}>
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
