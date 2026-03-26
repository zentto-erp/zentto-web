"use client";

import React, { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  MenuItem,
  Select,
  InputLabel,
  FormControl,
  CircularProgress,
  Alert,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";


import {
  useActivosFijosList,
  useCategoriasList,
  useCreateActivoFijo,
  useDisposeActivoFijo,
  type AssetFilter,
  type CreateAssetInput,
} from "../hooks/useActivosFijos";

const DEPRECIATION_METHODS = [
  { value: "STRAIGHT_LINE", label: "Linea recta" },
  { value: "DOUBLE_DECLINING", label: "Doble declinacion" },
  { value: "UNITS_PRODUCED", label: "Unidades producidas" },
  { value: "NONE", label: "Sin depreciacion" },
];

const emptyForm: CreateAssetInput = {
  assetCode: "",
  description: "",
  categoryId: 0,
  acquisitionDate: "",
  acquisitionCost: 0,
  residualValue: 0,
  usefulLifeMonths: 0,
  depreciationMethod: "STRAIGHT_LINE",
  assetAccountCode: "",
  deprecAccountCode: "",
  expenseAccountCode: "",
  costCenterCode: "",
  location: "",
  serialNumber: "",
};

const ACTIVOS_FILTERS: FilterFieldDef[] = [
  { field: "status", label: "Estado", type: "select", options: [
    { value: "ACTIVE", label: "Activo" },
    { value: "DISPOSED", label: "Dado de baja" },
    { value: "FULLY_DEPRECIATED", label: "Totalmente depreciado" },
  ]},
  { field: "categoryCode", label: "Categoria", type: "select", options: [] },
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
];

const COLUMNS: ColumnDef[] = [
  { field: "AssetCode", header: "Codigo", width: 110, sortable: true },
  { field: "Description", header: "Descripcion", flex: 1, minWidth: 200, sortable: true },
  { field: "CategoryName", header: "Categoria", width: 150, sortable: true, groupable: true },
  { field: "AcquisitionDate", header: "Fecha adq.", width: 120, sortable: true },
  { field: "AcquisitionCost", header: "Costo adq.", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  { field: "BookValue", header: "Valor en Libros", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "Status", header: "Estado", width: 150, sortable: true, groupable: true,
    statusColors: { ACTIVE: "success", DISPOSED: "error", FULLY_DEPRECIATED: "warning" },
    statusVariant: "outlined",
  },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 130,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Dar de baja", action: "delete", color: "#dc2626" },
    ],
  },
];

export default function ActivosFijosListPage() {
  const router = useRouter();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<AssetFilter>({ page: 1, limit: 25 });
  const [openCreate, setOpenCreate] = useState(false);
  const [form, setForm] = useState<CreateAssetInput>({ ...emptyForm });
  const [disposeId, setDisposeId] = useState<number | null>(null);
  const [disposeReason, setDisposeReason] = useState("");

  const { data, isLoading } = useActivosFijosList(filter);
  const { data: categoriasData } = useCategoriasList();
  const createMutation = useCreateActivoFijo();
  const disposeMutation = useDisposeActivoFijo();

  const rows = data?.rows ?? [];
  const categorias: any[] = categoriasData?.rows ?? [];
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});

  const activosFilterDefs: FilterFieldDef[] = React.useMemo(() => {
    const catOptions = categorias.map((c) => ({ value: c.CategoryCode, label: c.CategoryName }));
    return ACTIVOS_FILTERS.map((f) =>
      f.field === "categoryCode" ? { ...f, options: catOptions } : f
    );
  }, [categorias]);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.AssetId }));
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view') router.push(`/contabilidad/activos-fijos/${row.AssetId}`);
      if (action === 'edit') router.push(`/contabilidad/activos-fijos/${row.AssetId}/edit`);
      if (action === 'delete') { setDisposeId(row.AssetId); setDisposeReason(""); }
    };
    const createHandler = () => setOpenCreate(true);
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
  }, [registered, router]);

  const handleCreate = async () => {
    await createMutation.mutateAsync(form);
    setOpenCreate(false);
    setForm({ ...emptyForm });
  };

  const handleDispose = async () => {
    if (!disposeId) return;
    await disposeMutation.mutateAsync({
      id: disposeId,
      disposalDate: new Date().toISOString().slice(0, 10),
      disposalReason: disposeReason,
    });
    setDisposeId(null);
    setDisposeReason("");
  };

  const setField = <K extends keyof CreateAssetInput>(key: K, val: CreateAssetInput[K]) =>
    setForm((f) => ({ ...f, [key]: val }));

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Activos fijos" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <ZenttoFilterPanel
          filters={activosFilterDefs}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              status: vals.status || undefined,
              categoryCode: vals.categoryCode || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar activo..."
          searchValue={search}
          onSearchChange={(v) => {
            setSearch(v);
            setFilter((f) => ({ ...f, search: v || undefined, page: 1 }));
          }}
        />

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="activos-fijos"
            height="100%"
            show-totals
            enable-create
            create-label="Nuevo activo"
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

      {/* Dialog Crear Activo */}
      <Dialog open={openCreate} onClose={() => setOpenCreate(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nuevo activo fijo</DialogTitle>
        <DialogContent>
          <FormGrid spacing={2} sx={{ mt: 1 }}>
            <FormField xs={12} sm={6}>
              <TextField label="Codigo" fullWidth value={form.assetCode} onChange={(e) => setField("assetCode", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Numero de Serie" fullWidth value={form.serialNumber || ""} onChange={(e) => setField("serialNumber", e.target.value)} />
            </FormField>
            <FormField xs={12}>
              <TextField label="Descripcion" fullWidth value={form.description} onChange={(e) => setField("description", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Categoria</InputLabel>
                <Select label="Categoria" value={form.categoryId || ""} onChange={(e) => setField("categoryId", Number(e.target.value))}>
                  {categorias.map((c) => (
                    <MenuItem key={c.CategoryId} value={c.CategoryId}>{c.CategoryName}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} sm={6}>
              <DatePicker
                label="Fecha adquisicion"
                value={form.acquisitionDate ? dayjs(form.acquisitionDate) : null}
                onChange={(v) => setField("acquisitionDate", v ? v.format('YYYY-MM-DD') : '')}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Costo adquisicion" type="number" fullWidth value={form.acquisitionCost} onChange={(e) => setField("acquisitionCost", Number(e.target.value))} />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Valor residual" type="number" fullWidth value={form.residualValue || 0} onChange={(e) => setField("residualValue", Number(e.target.value))} />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Vida Util (meses)" type="number" fullWidth value={form.usefulLifeMonths} onChange={(e) => setField("usefulLifeMonths", Number(e.target.value))} />
            </FormField>
            <FormField xs={12}>
              <FormControl fullWidth>
                <InputLabel>Metodo de Depreciacion</InputLabel>
                <Select label="Metodo de Depreciacion" value={form.depreciationMethod || "STRAIGHT_LINE"} onChange={(e) => setField("depreciationMethod", e.target.value)}>
                  {DEPRECIATION_METHODS.map((m) => (
                    <MenuItem key={m.value} value={m.value}>{m.label}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Cuenta activo" fullWidth value={form.assetAccountCode} onChange={(e) => setField("assetAccountCode", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Cuenta dep. acum." fullWidth value={form.deprecAccountCode} onChange={(e) => setField("deprecAccountCode", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={4}>
              <TextField label="Cuenta gasto" fullWidth value={form.expenseAccountCode} onChange={(e) => setField("expenseAccountCode", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Centro de Costo" fullWidth value={form.costCenterCode || ""} onChange={(e) => setField("costCenterCode", e.target.value)} />
            </FormField>
            <FormField xs={12} sm={6}>
              <TextField label="Ubicacion" fullWidth value={form.location || ""} onChange={(e) => setField("location", e.target.value)} />
            </FormField>
          </FormGrid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCreate(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={createMutation.isPending || !form.assetCode || !form.description}
            startIcon={createMutation.isPending ? <CircularProgress size={16} /> : undefined}
          >
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog Dar de Baja */}
      <Dialog open={disposeId != null} onClose={() => setDisposeId(null)}>
        <DialogTitle>Dar de baja activo</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            Esta accion registrara la baja del activo y no se puede deshacer.
          </Alert>
          <TextField
            label="Motivo de la baja"
            fullWidth
            multiline
            rows={3}
            value={disposeReason}
            onChange={(e) => setDisposeReason(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDisposeId(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDispose} disabled={!disposeReason || disposeMutation.isPending}>
            Dar de Baja
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
