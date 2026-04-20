"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, TextField, Chip, IconButton, Dialog, DialogTitle,
  DialogContent, DialogActions, Stack, MenuItem, Select, InputLabel, FormControl,
  Tooltip, CircularProgress, Autocomplete,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { ModulePageShell } from "@zentto/shared-ui";
import {
  useCategoriasList, useUpsertCategoria, type FixedAssetCategory,
} from "../hooks/useActivosFijos";
import { usePlanCuentas } from "../hooks/useContabilidad";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";


const DEPRECIATION_METHODS = [
  { value: "STRAIGHT_LINE", label: "Linea recta" },
  { value: "DOUBLE_DECLINING", label: "Doble declinacion" },
  { value: "UNITS_PRODUCED", label: "Unidades producidas" },
  { value: "NONE", label: "Sin depreciacion" },
];

interface CategoryForm {
  categoryCode: string; categoryName: string; defaultUsefulLifeMonths: number;
  defaultDepreciationMethod: string; defaultResidualPercent: number;
  defaultAssetAccountCode: string; defaultDeprecAccountCode: string;
  defaultExpenseAccountCode: string; countryCode: string;
}

const emptyForm: CategoryForm = {
  categoryCode: "", categoryName: "", defaultUsefulLifeMonths: 60,
  defaultDepreciationMethod: "STRAIGHT_LINE", defaultResidualPercent: 0,
  defaultAssetAccountCode: "", defaultDeprecAccountCode: "",
  defaultExpenseAccountCode: "", countryCode: "",
};

const COLUMNS: ColumnDef[] = [
  { field: "CategoryCode", header: "Codigo", width: 120, sortable: true },
  { field: "CategoryName", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "DefaultUsefulLifeMonths", header: "Vida util", width: 150, type: "number", sortable: true },
  { field: "DefaultDepreciationMethod", header: "Metodo dep.", width: 170, sortable: true },
  { field: "DefaultResidualPercent", header: "% Residual", width: 110, type: "number" },
  { field: "CountryCode", header: "Pais", width: 80, sortable: true },
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
  gridRef: buildContabilidadGridId("categorias-activos", "main"),
} as const;

export default function CategoriasActivosPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const [openDialog, setOpenDialog] = useState(false);
  const [form, setForm] = useState<CategoryForm>({ ...emptyForm });
  const [isEditing, setIsEditing] = useState(false);

  const { data, isLoading } = useCategoriasList();
  const upsertMutation = useUpsertCategoria();
  const { data: cuentasData } = usePlanCuentas();
  const cuentas = (cuentasData?.data ?? cuentasData?.rows ?? []).map((c: any) => ({
    code: c.codCuenta ?? c.Cod_Cuenta ?? c.AccountCode ?? "",
    name: c.descripcion ?? c.Desc_Cta ?? c.AccountName ?? "",
  }));

  const rows = data?.rows ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.CategoryId }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      const cat = rows.find((r: any) => r.CategoryId === row.id);
      if (!cat) return;
      if (action === 'view') handleEdit(cat);
      if (action === 'edit') handleEdit(cat);
    };
    const createHandler = () => handleNew();
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
  }, [registered, rows]);

  const handleEdit = (row: FixedAssetCategory) => {
    setForm({
      categoryCode: row.CategoryCode, categoryName: row.CategoryName,
      defaultUsefulLifeMonths: row.DefaultUsefulLifeMonths,
      defaultDepreciationMethod: row.DefaultDepreciationMethod,
      defaultResidualPercent: row.DefaultResidualPercent ?? 0,
      defaultAssetAccountCode: row.DefaultAssetAccountCode ?? "",
      defaultDeprecAccountCode: row.DefaultDeprecAccountCode ?? "",
      defaultExpenseAccountCode: row.DefaultExpenseAccountCode ?? "",
      countryCode: row.CountryCode ?? "",
    });
    setIsEditing(true); setOpenDialog(true);
  };

  const handleNew = () => { setForm({ ...emptyForm }); setIsEditing(false); setOpenDialog(true); };

  const handleSave = async () => {
    await upsertMutation.mutateAsync(form);
    setOpenDialog(false); setForm({ ...emptyForm });
  };

  const setField = <K extends keyof CategoryForm>(key: K, val: CategoryForm[K]) =>
    setForm((f) => ({ ...f, [key]: val }));

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <>
      <ModulePageShell sx={{ display: "flex", flexDirection: "column", minHeight: 500 }}>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 500, width: "100%", elevation: 0, border: (t) => `1px solid ${t.palette.divider}` }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="categorias-activos"
            height="100%"
            enable-create
            create-label="Nueva categoria"
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
      </ModulePageShell>

      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{isEditing ? "Editar categoria" : "Nueva categoria"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
              <TextField label="Codigo" fullWidth value={form.categoryCode} onChange={(e) => setField("categoryCode", e.target.value)} disabled={isEditing} />
              <TextField label="Nombre" fullWidth value={form.categoryName} onChange={(e) => setField("categoryName", e.target.value)} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="Vida util (meses)" type="number" fullWidth value={form.defaultUsefulLifeMonths} onChange={(e) => setField("defaultUsefulLifeMonths", Number(e.target.value))} />
              <FormControl fullWidth>
                <InputLabel>Metodo depreciacion</InputLabel>
                <Select label="Metodo depreciacion" value={form.defaultDepreciationMethod} onChange={(e) => setField("defaultDepreciationMethod", e.target.value)}>
                  {DEPRECIATION_METHODS.map((m) => (<MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>))}
                </Select>
              </FormControl>
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField label="% Residual" type="number" fullWidth value={form.defaultResidualPercent} onChange={(e) => setField("defaultResidualPercent", Number(e.target.value))} />
              <TextField label="Pais" fullWidth value={form.countryCode} onChange={(e) => setField("countryCode", e.target.value)} placeholder="VE, ES, CO..." />
            </Stack>
            <Stack direction="row" spacing={2}>
              <Autocomplete options={cuentas} getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultAssetAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultAssetAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta activo" />} fullWidth isOptionEqualToValue={(opt, val) => opt.code === val.code} />
              <Autocomplete options={cuentas} getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultDeprecAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultDeprecAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta dep. acum." />} fullWidth isOptionEqualToValue={(opt, val) => opt.code === val.code} />
              <Autocomplete options={cuentas} getOptionLabel={(opt: any) => opt.code ? `${opt.code} — ${opt.name}` : ""}
                value={cuentas.find((c: any) => c.code === form.defaultExpenseAccountCode) ?? null}
                onChange={(_, sel) => setField("defaultExpenseAccountCode", sel?.code ?? "")}
                renderInput={(params) => <TextField {...params} label="Cuenta gasto" />} fullWidth isOptionEqualToValue={(opt, val) => opt.code === val.code} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={upsertMutation.isPending || !form.categoryCode || !form.categoryName}
            startIcon={upsertMutation.isPending ? <CircularProgress size={16} /> : undefined}>
            {isEditing ? "Guardar" : "Crear"}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
