"use client";

import React, { useState, useCallback, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, Button, Stack, Alert, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Chip, IconButton, Tooltip, Tabs, Tab, Card, CardContent, CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import ArticleIcon from "@mui/icons-material/Article";
import { useRouter } from "next/navigation";
import {
  usePlanCuentas, useSeedPlanCuentas, useLibroMayor, useMayorAnalitico,
  useCreateCuenta, useUpdateCuenta, useDeleteCuenta,
} from "../hooks/useContabilidad";
import EditableDataGrid from "./EditableDataGrid";
import { ContextActionHeader, DatePicker, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

interface CuentaContable { id: string; codCuenta: string; descripcion: string; tipo: string; nivel: number; isNew?: boolean; }

// ---- Mayor Analitico Dialog ----
const MAYOR_COLUMNS: ColumnDef[] = [
  { field: "fecha", header: "Fecha", width: 110, type: "date" },
  { field: "concepto", header: "Concepto", flex: 1, sortable: true },
  { field: "debe", header: "Debe", width: 110, type: "number", currency: "VES" },
  { field: "haber", header: "Haber", width: 110, type: "number", currency: "VES" },
  { field: "saldo", header: "Saldo", width: 120, type: "number", currency: "VES" },
];

function MayorAnaliticoDialog({ open, onClose, cuenta }: { open: boolean; onClose: () => void; cuenta: CuentaContable | null }) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { timeZone } = useTimezone();
  const [fechaDesde, setFechaDesde] = useState(toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone));
  const [fechaHasta, setFechaHasta] = useState(toDateOnly(new Date(), timeZone));
  const { data, isLoading } = useMayorAnalitico(cuenta?.codCuenta || "", fechaDesde, fechaHasta, open && !!cuenta?.codCuenta);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = MAYOR_COLUMNS;
    el.rows = (data?.rows ?? []).map((row: any, i: number) => ({ id: i, ...row }));
    el.loading = isLoading;
    // No actionButtons needed — read-only mayor analitico report
  }, [data, isLoading, registered]);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Mayor Analitico - {cuenta?.codCuenta} {cuenta?.descripcion}</DialogTitle>
      <DialogContent>
        <Stack direction="row" spacing={2} sx={{ mb: 2, mt: 1 }}>
          <DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
          <DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
        </Stack>
        {registered ? (
          <Box sx={{ height: 300 }}>
            <zentto-grid ref={gridRef} default-currency="VES" height="100%" show-totals
              enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator></zentto-grid>
          </Box>
        ) : <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}><CircularProgress /></Box>}
      </DialogContent>
      <DialogActions><Button onClick={onClose}>Cerrar</Button></DialogActions>
    </Dialog>
  );
}

// ---- Main Component ----
const PLAN_MEJORADO_FILTERS: FilterFieldDef[] = [
  { field: "tipo", label: "Tipo", type: "select", options: [{ value: "A", label: "Acreedor" }, { value: "D", label: "Deudor" }] },
  { field: "nivel", label: "Nivel", type: "select", options: [{ value: "1", label: "Nivel 1" }, { value: "2", label: "Nivel 2" }, { value: "3", label: "Nivel 3" }] },
];

const EDITABLE_COLUMNS: ColumnDef[] = [
  { field: "codCuenta", header: "Codigo", width: 120, sortable: true },
  { field: "descripcion", header: "Descripcion", flex: 1, minWidth: 250, sortable: true },
  { field: "tipo", header: "Tipo", width: 100, sortable: true, groupable: true },
  { field: "nivel", header: "Nivel", width: 80, type: "number", sortable: true },
];

export default function PlanCuentasPageMejorado() {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [tabValue, setTabValue] = useState(0);
  const [cuentaMayor, setCuentaMayor] = useState<CuentaContable | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading, refetch } = usePlanCuentas({ search });
  const seedMutation = useSeedPlanCuentas();
  const createMutation = useCreateCuenta();
  const updateMutation = useUpdateCuenta();
  const deleteMutation = useDeleteCuenta();

  const rows: CuentaContable[] = React.useMemo(() => {
    return (data?.data || []).map((c: any) => ({
      id: c.codCuenta || c.Cod_Cuenta || String(Math.random()),
      codCuenta: c.codCuenta || c.Cod_Cuenta,
      descripcion: c.descripcion || c.Desc_Cta || c.Desc_Cuenta,
      tipo: c.tipo || c.Tipo || "",
      nivel: c.nivel || c.Nivel || 1,
    }));
  }, [data]);

  const filteredRows = React.useMemo(() => {
    if (tabValue === 0) return rows;
    return rows.filter((r) => {
      const primerDigito = r.codCuenta?.charAt(0);
      switch (tabValue) {
        case 1: return primerDigito === "1";
        case 2: return primerDigito === "2";
        case 3: return primerDigito === "3";
        case 4: return primerDigito === "4";
        case 5: return primerDigito === "5" || primerDigito === "6";
        default: return true;
      }
    });
  }, [rows, tabValue]);

  const handleSave = useCallback(async (row: CuentaContable) => {
    const payload = { codCuenta: row.codCuenta, descripcion: row.descripcion, tipo: row.tipo, nivel: row.nivel };
    try {
      if (row.isNew) await createMutation.mutateAsync(payload); else await updateMutation.mutateAsync(payload);
    } catch (err: any) { setError(err.message || "Error al guardar la cuenta"); throw err; }
  }, [createMutation, updateMutation]);

  const handleDelete = useCallback(async (id: string | number) => {
    try { await deleteMutation.mutateAsync(String(id)); } catch (err: any) { setError(err.message || "Error al eliminar la cuenta"); }
  }, [deleteMutation]);

  const handleSeedData = async () => {
    try { await seedMutation.mutateAsync(); refetch(); } catch { setError("Error al crear datos de ejemplo"); }
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Plan de Cuentas"
        primaryAction={{ label: "Nueva cuenta", onClick: () => console.log("Nueva cuenta activada") }}
        secondaryActions={[
          { label: seedMutation.isPending ? "Creando..." : "Crear datos ejemplo", onClick: handleSeedData, disabled: seedMutation.isPending },
          { label: "Nuevo asiento", onClick: () => router.push("/contabilidad/asientos/new") },
        ]}
        onSearch={setSearch}
        searchPlaceholder="Buscar por codigo o descripcion..."
      />
      <ZenttoFilterPanel filters={PLAN_MEJORADO_FILTERS} values={filterValues} onChange={setFilterValues}
        searchPlaceholder="Buscar por codigo o descripcion..." searchValue={search} onSearchChange={setSearch} />
      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}
      <Paper sx={{ mb: 2 }}>
        <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} variant="scrollable" scrollButtons="auto">
          <Tab label="Todas" /><Tab label="Activos" sx={{ color: "success.main" }} /><Tab label="Pasivos" sx={{ color: "error.main" }} />
          <Tab label="Capital" sx={{ color: "info.main" }} /><Tab label="Ingresos" sx={{ color: "warning.main" }} /><Tab label="Gastos" sx={{ color: "secondary.main" }} />
        </Tabs>
      </Paper>
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction="row" spacing={3}>
            <Box><Typography variant="body2" color="text.secondary">Total Cuentas</Typography><Typography variant="h6" fontWeight={700}>{rows.length}</Typography></Box>
            <Box><Typography variant="body2" color="text.secondary">Nivel 1</Typography><Typography variant="h6" fontWeight={700}>{rows.filter((r) => r.nivel === 1).length}</Typography></Box>
            <Box><Typography variant="body2" color="text.secondary">Cuentas de Detalle</Typography><Typography variant="h6" fontWeight={700}>{rows.filter((r) => r.nivel === 3).length}</Typography></Box>
          </Stack>
        </CardContent>
      </Card>

      <EditableDataGrid
        rows={filteredRows}
        columns={EDITABLE_COLUMNS}
        onSave={handleSave}
        onDelete={handleDelete}
        loading={isLoading}
        title={`Plan de Cuentas (${filteredRows.length} registros)`}
        addButtonText="Nueva cuenta"
        getRowId={(row) => row.codCuenta}
        defaultNewRow={{ codCuenta: "", descripcion: "", tipo: "A", nivel: 3 }}
      />

      <MayorAnaliticoDialog open={!!cuentaMayor} onClose={() => setCuentaMayor(null)} cuenta={cuentaMayor} />
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
