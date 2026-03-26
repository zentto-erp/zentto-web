"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, InputLabel, MenuItem, Paper, Select, Stack, TextField, Tooltip, Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import Grid from "@mui/material/Grid2";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useToast, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import {
  useBancosList, useCuentasBancarias, useMovimientosCuenta,
  useCreateCuentaBancaria, useUpdateCuentaBancaria, useDeleteCuentaBancaria,
} from "../../hooks/useBancosAuxiliares";

const MOVIMIENTOS_FILTERS: FilterFieldDef[] = [
  { field: "tipo", label: "Tipo", type: "select", options: [
    { value: "DEP", label: "Depósito" }, { value: "PCH", label: "Cheque" },
    { value: "NCR", label: "Nota Crédito" }, { value: "NDB", label: "Nota Débito" }, { value: "IDB", label: "Int. Débito" },
  ]},
  { field: "from", label: "Fecha desde", type: "date" }, { field: "to", label: "Fecha hasta", type: "date" },
];

const COLS_CUENTAS: ColumnDef[] = [
  { field: "Nro_Cta", header: "Nro Cuenta", width: 130, sortable: true },
  { field: "BancoNombre", header: "Banco", flex: 1, sortable: true },
  { field: "Saldo", header: "Saldo", width: 130, type: "number", aggregation: "sum" },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

const COLS_MOVIMIENTOS: ColumnDef[] = [
  { field: "Fecha", header: "Fecha", width: 140 },
  { field: "Tipo", header: "Tipo", width: 90, statusColors: { DEP: "success", PCH: "error", NCR: "info", NDB: "warning" } },
  { field: "Nro_Ref", header: "Referencia", width: 130 },
  { field: "Beneficiario", header: "Beneficiario", flex: 1, minWidth: 180 },
  { field: "Monto", header: "Monto", width: 140, type: "number", aggregation: "sum" },
];

const CURRENCY_OPTIONS = ["VES", "USD", "EUR"];


export default function CuentasBancariasPage() {
  const ctasGridRef = useRef<any>(null);
  const movsGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const router = useRouter();
  const { timeZone } = useTimezone();
  const { showToast } = useToast();

  const [formOpen, setFormOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState({ BankId: 0, AccountNumber: "", AccountName: "", CurrencyCode: "VES" });
  const [deleteTarget, setDeleteTarget] = useState<number | null>(null);

  const crear = useCreateCuentaBancaria();
  const actualizar = useUpdateCuentaBancaria();
  const eliminar = useDeleteCuentaBancaria();
  const { data: bancosData } = useBancosList({ limit: 200 });
  const bancos = (bancosData?.rows ?? bancosData?.items ?? []) as Record<string, any>[];
  const saving = crear.isPending || actualizar.isPending;

  const [nroCta, setNroCta] = useState<string>("");
  const [movSearch, setMovSearch] = useState("");
  const [movFilterValues, setMovFilterValues] = useState<Record<string, string>>({
    from: dayjs().tz(timeZone).startOf("month").format("YYYY-MM-DD"),
    to: dayjs().tz(timeZone).format("YYYY-MM-DD"),
  });
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(50);

  const { data: cuentasData, isLoading: loadingCtas } = useCuentasBancarias();
  const input = useMemo(() => ({ nroCta: nroCta || undefined, desde: movFilterValues.from, hasta: movFilterValues.to, page, limit }), [nroCta, movFilterValues, page, limit]);
  const { data: movsData, isLoading: loadingMovs } = useMovimientosCuenta(input);

  const cuentas = (cuentasData?.rows ?? []) as Record<string, any>[];
  const movs = (movsData?.rows ?? []) as Record<string, any>[];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  // Cuentas grid
  useEffect(() => {
    const el = ctasGridRef.current; if (!el || !registered) return;
    el.columns = COLS_CUENTAS; el.rows = cuentas; el.loading = loadingCtas;
    el.getRowId = (r: any) => r.BankAccountId ?? r.Nro_Cta ?? Math.random();
  }, [cuentas, loadingCtas, registered]);

  useEffect(() => {
    const el = ctasGridRef.current; if (!el || !registered) return;
    const rowHandler = (e: CustomEvent) => { if (e.detail?.row?.Nro_Cta) setNroCta(String(e.detail.row.Nro_Cta)); };
    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") { setForm({ BankId: row.BankId ?? 0, AccountNumber: row.Nro_Cta ?? "", AccountName: row.Descripcion ?? "", CurrencyCode: row.Moneda?.trim() ?? "VES" }); setEditId(row.BankAccountId); setFormOpen(true); }
      if (action === "delete") setDeleteTarget(row.BankAccountId);
    };
    el.addEventListener("row-click", rowHandler);
    el.addEventListener("action-click", actionHandler);
    return () => { el.removeEventListener("row-click", rowHandler); el.removeEventListener("action-click", actionHandler); };
  }, [registered, cuentas]);

  // Movimientos grid
  useEffect(() => {
    const el = movsGridRef.current; if (!el || !registered) return;
    el.columns = COLS_MOVIMIENTOS; el.rows = movs; el.loading = loadingMovs;
    el.getRowId = (r: any) => r.id ?? r.ID ?? Math.random();
  }, [movs, loadingMovs, registered]);

  const handleNew = () => { setForm({ BankId: 0, AccountNumber: "", AccountName: "", CurrencyCode: "VES" }); setEditId(null); setFormOpen(true); };
  const handleSave = async () => {
    try {
      if (editId) { await actualizar.mutateAsync({ id: editId, data: form }); showToast("Cuenta actualizada", "success"); }
      else { await crear.mutateAsync(form); showToast("Cuenta creada", "success"); }
      setFormOpen(false);
    } catch (err: any) { showToast(err?.message ?? "Error al guardar", "error"); }
  };
  const handleDelete = async () => {
    if (!deleteTarget) return;
    try { await eliminar.mutateAsync(deleteTarget); showToast("Cuenta desactivada", "success"); setDeleteTarget(null); }
    catch (err: any) { showToast(err?.message ?? "Error al eliminar", "error"); }
  };

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5" fontWeight={600}>Cuentas bancarias</Typography>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>Nueva cuenta</Button>
          <Button variant="outlined" size="small" onClick={() => window.print()}>Imprimir</Button>
          <Button variant="outlined" size="small" onClick={() => { window.location.href = "/bancos/conciliacion"; }}>Nueva conciliación</Button>
        </Box>
      </Stack>

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold" mb={1}>Cuentas</Typography>
            <zentto-grid ref={ctasGridRef} height="400px" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ p: 2 }}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
              <Typography variant="subtitle1" fontWeight="bold">Movimientos</Typography>
              <Button variant="contained" size="small" startIcon={<AddIcon />} disabled={!nroCta} onClick={() => router.push(`/bancos/movimientos/generar?cuenta=${nroCta}`)}>Agregar Movimiento</Button>
            </Stack>
            <ZenttoFilterPanel filters={MOVIMIENTOS_FILTERS} values={movFilterValues} onChange={(v) => { setMovFilterValues(v); setPage(1); }} searchPlaceholder="Buscar movimiento..." searchValue={movSearch} onSearchChange={(v) => { setMovSearch(v); setPage(1); }} />
            {nroCta && <Chip label={`Cuenta: ${nroCta}`} onDelete={() => setNroCta("")} color="primary" sx={{ mb: 1 }} />}
            <zentto-grid ref={movsGridRef} height="400px" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
          </Paper>
        </Grid>
      </Grid>

      {/* CRUD Dialogs */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editId ? "Editar cuenta" : "Nueva cuenta"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <FormControl fullWidth><InputLabel>Banco</InputLabel><Select value={form.BankId || ""} label="Banco" onChange={(e) => setForm((f) => ({ ...f, BankId: Number(e.target.value) }))}>{bancos.map((b) => <MenuItem key={b.BankId ?? b.Nombre} value={b.BankId ?? 0}>{b.Nombre ?? b.BankName}</MenuItem>)}</Select></FormControl>
            <TextField label="Número de cuenta" fullWidth value={form.AccountNumber} onChange={(e) => setForm((f) => ({ ...f, AccountNumber: e.target.value }))} />
            <TextField label="Descripción" fullWidth value={form.AccountName} onChange={(e) => setForm((f) => ({ ...f, AccountName: e.target.value }))} />
            <FormControl fullWidth><InputLabel>Moneda</InputLabel><Select value={form.CurrencyCode} label="Moneda" onChange={(e) => setForm((f) => ({ ...f, CurrencyCode: e.target.value }))}>{CURRENCY_OPTIONS.map((c) => <MenuItem key={c} value={c}>{c}</MenuItem>)}</Select></FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving || !form.BankId || !form.AccountNumber}>{editId ? "Actualizar" : "Guardar"}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar eliminación</DialogTitle>
        <DialogContent><Typography>¿Desactivar esta cuenta bancaria?</Typography></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={eliminar.isPending}>Desactivar</Button>
        </DialogActions>
      </Dialog>

      <style>{`@media print { .print-only { display: block !important; } body { background: white !important; } nav, header, .MuiAppBar-root, .MuiDrawer-root { display: none !important; } }`}</style>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
