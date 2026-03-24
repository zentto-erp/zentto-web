"use client";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, IconButton, InputLabel, MenuItem, Paper, Select, Stack,
  TextField, Tooltip, Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import Grid from "@mui/material/Grid2";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useToast, ZenttoDataGrid, ZenttoFilterPanel, type ZenttoColDef, type FilterFieldDef } from "@zentto/shared-ui";
import {
  useBancosList,
  useCuentasBancarias,
  useMovimientosCuenta,
  useCreateCuentaBancaria,
  useUpdateCuentaBancaria,
  useDeleteCuentaBancaria,
} from "../../hooks/useBancosAuxiliares";

const MOVIMIENTOS_FILTERS: FilterFieldDef[] = [
  {
    field: "tipo",
    label: "Tipo",
    type: "select",
    options: [
      { value: "DEP", label: "Depósito" },
      { value: "PCH", label: "Cheque" },
      { value: "NCR", label: "Nota Crédito" },
      { value: "NDB", label: "Nota Débito" },
      { value: "IDB", label: "Int. Débito" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

const tipoColors: Record<string, "success" | "error" | "info" | "warning" | "default"> = {
  DEP: "success",
  PCH: "error",
  NCR: "info",
  NDB: "warning",
  IDB: "default",
};

const CURRENCY_OPTIONS = ["VES", "USD", "EUR"];

export default function CuentasBancariasPage() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  const colsMovimientos: ZenttoColDef[] = [
    {
      field: "Fecha",
      headerName: "Fecha",
      width: 140,
      renderCell: (p) => toDateOnly(p.value as string, timeZone),
    },
    {
      field: "Tipo",
      headerName: "Tipo",
      width: 90,
      renderCell: (p) => (
        <Chip
          size="small"
          label={String(p.value)}
          color={tipoColors[String(p.value)] ?? "default"}
        />
      ),
    },
    { field: "Nro_Ref", headerName: "Referencia", width: 130 },
    { field: "Beneficiario", headerName: "Beneficiario", flex: 1, minWidth: 180 },
    {
      field: "Monto",
      headerName: "Monto",
      width: 140,
      align: "right",
      headerAlign: "right",
      currency: true,
      aggregation: "sum",
      renderCell: (p) => formatCurrency(Number(p.value ?? 0)),
    },
  ];
  const colsCuentas: ZenttoColDef[] = useMemo(() => [
    { field: "Nro_Cta", headerName: "Nro Cuenta", width: 130 },
    { field: "BancoNombre", headerName: "Banco", flex: 1, valueGetter: (_v: any, row: any) => row.BancoNombre ?? row.Banco ?? "" },
    {
      field: "Saldo", headerName: "Saldo", width: 130, align: "right" as const, headerAlign: "right" as const, currency: true, aggregation: "sum" as const,
      renderCell: (p: any) => <Chip size="small" label={formatCurrency(Number(p.value ?? 0))} color={Number(p.value ?? 0) >= 0 ? "success" : "error"} variant="outlined" />,
    },
    {
      field: "acciones", headerName: "Acciones", width: 90, sortable: false,
      renderCell: (params: any) => (
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Editar"><IconButton size="small" onClick={(e) => { e.stopPropagation(); handleEditCta(params.row); }}><EditIcon fontSize="small" /></IconButton></Tooltip>
          <Tooltip title="Eliminar"><IconButton size="small" color="error" onClick={(e) => { e.stopPropagation(); setDeleteTarget(params.row.BankAccountId); }}><DeleteIcon fontSize="small" /></IconButton></Tooltip>
        </Stack>
      ),
    },
  ], []);

  const handleEditCta = (row: Record<string, any>) => {
    setForm({ BankId: row.BankId ?? 0, AccountNumber: row.Nro_Cta ?? "", AccountName: row.Descripcion ?? "", CurrencyCode: row.Moneda?.trim() ?? "VES" });
    setEditId(row.BankAccountId); setFormOpen(true);
  };

  /* ── CRUD state ── */
  const [formOpen, setFormOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState({ BankId: 0, AccountNumber: "", AccountName: "", CurrencyCode: "VES" });
  const [deleteTarget, setDeleteTarget] = useState<number | null>(null);
  const crear = useCreateCuentaBancaria();
  const actualizar = useUpdateCuentaBancaria();
  const eliminar = useDeleteCuentaBancaria();
  const { showToast } = useToast();
  const { data: bancosData } = useBancosList({ limit: 200 });
  const bancos = (bancosData?.rows ?? bancosData?.items ?? []) as Record<string, any>[];
  const saving = crear.isPending || actualizar.isPending;

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

  const [nroCta, setNroCta] = useState<string>("");
  const [movSearch, setMovSearch] = useState("");
  const [movFilterValues, setMovFilterValues] = useState<Record<string, string>>({
    from: dayjs().tz(timeZone).startOf("month").format("YYYY-MM-DD"),
    to: dayjs().tz(timeZone).format("YYYY-MM-DD"),
  });
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(50);

  const fechaDesde = movFilterValues.from ? dayjs(movFilterValues.from) : null;
  const fechaHasta = movFilterValues.to ? dayjs(movFilterValues.to) : null;

  const { data: cuentasData, isLoading: loadingCtas } = useCuentasBancarias();

  const input = useMemo(
    () => ({
      nroCta: nroCta || undefined,
      desde: fechaDesde?.format("YYYY-MM-DD"),
      hasta: fechaHasta?.format("YYYY-MM-DD"),
      page,
      limit,
    }),
    [nroCta, fechaDesde, fechaHasta, page, limit],
  );

  const { data: movsData, isLoading: loadingMovs } = useMovimientosCuenta(input);

  const cuentas = (cuentasData?.rows ?? []) as Record<string, any>[];
  const movs = (movsData?.rows ?? []) as Record<string, any>[];

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5" fontWeight={600}>Cuentas bancarias</Typography>
        <Box sx={{ display: "flex", gap: 1 }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
            Nueva cuenta
          </Button>
          <Button variant="outlined" size="small" onClick={() => window.print()}>
            Imprimir
          </Button>
          <Button variant="outlined" size="small" onClick={() => { window.location.href = "/bancos/conciliacion"; }}>
            Nueva conciliación
          </Button>
        </Box>
      </Stack>

      {/* Print header (hidden on screen, visible on print) */}
      <Box className="print-only" sx={{ display: "none", mb: 2 }}>
        <Typography variant="h5" fontWeight={700}>Estado de Cuenta Bancaria</Typography>
        {nroCta && <Typography variant="subtitle1">Cuenta: {nroCta}</Typography>}
        <Typography variant="body2" color="text.secondary">
          Período: {fechaDesde?.format("DD/MM/YYYY") ?? "—"} al {fechaHasta?.format("DD/MM/YYYY") ?? "—"}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Generado: {new Date().toLocaleString("es-VE")}
        </Typography>
      </Box>

      <Grid container spacing={2}>
        {/* Panel izquierdo: Cuentas */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold" mb={1}>
              Cuentas
            </Typography>
            <ZenttoDataGrid
            gridId="bancos-cuentas-list"
              rows={cuentas}
              columns={colsCuentas}
              loading={loadingCtas}
              onRowClick={(params) => setNroCta(String(params.row.Nro_Cta))}
              getRowId={(r) => r.BankAccountId ?? r.Nro_Cta ?? Math.random()}
              density="compact"
              hideFooter
              disableRowSelectionOnClick
              showTotals
              enableClipboard
              sx={{
                minHeight: 400,
                "& .MuiDataGrid-row.Mui-selected": { bgcolor: "action.selected" },
              }}
              mobileVisibleFields={['Nro_Cta', 'Saldo']}
              smExtraFields={['BancoNombre']}
            />
          </Paper>
        </Grid>

        {/* Panel derecho: Movimientos */}
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ p: 2 }}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
              <Typography variant="subtitle1" fontWeight="bold">
                Movimientos
              </Typography>
              <Button
                variant="contained"
                size="small"
                startIcon={<AddIcon />}
                disabled={!nroCta}
                onClick={() => router.push(`/bancos/movimientos/generar?cuenta=${nroCta}`)}
              >
                Agregar Movimiento
              </Button>
            </Stack>

            <ZenttoFilterPanel
              filters={MOVIMIENTOS_FILTERS}
              values={movFilterValues}
              onChange={(v) => { setMovFilterValues(v); setPage(1); }}
              searchPlaceholder="Buscar movimiento..."
              searchValue={movSearch}
              onSearchChange={(v) => { setMovSearch(v); setPage(1); }}
            />
            {nroCta && (
              <Chip
                label={`Cuenta: ${nroCta}`}
                onDelete={() => setNroCta("")}
                color="primary"
                sx={{ mb: 1 }}
              />
            )}

            <ZenttoDataGrid
            gridId="bancos-cuentas-movimientos"
              rows={movs}
              columns={colsMovimientos}
              loading={loadingMovs}
              enableHeaderFilters
              rowCount={movsData?.total ?? movs.length}
              pageSizeOptions={[25, 50, 100]}
              paginationModel={{ page: page - 1, pageSize: limit }}
              onPaginationModelChange={(m) => setPage(m.page + 1)}
              paginationMode="server"
              disableRowSelectionOnClick
              getRowId={(r) => r.id ?? r.ID ?? Math.random()}
              density="compact"
              showTotals
              enableClipboard
              sx={{ minHeight: 400 }}
              mobileVisibleFields={['Fecha', 'Monto']}
              smExtraFields={['Tipo', 'Beneficiario']}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Create / Edit Dialog */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editId ? "Editar cuenta" : "Nueva cuenta"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <FormControl fullWidth>
              <InputLabel>Banco</InputLabel>
              <Select value={form.BankId || ""} label="Banco" onChange={(e) => setForm((f) => ({ ...f, BankId: Number(e.target.value) }))}>
                {bancos.map((b) => (
                  <MenuItem key={b.BankId ?? b.Nombre} value={b.BankId ?? 0}>{b.Nombre ?? b.BankName}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField label="Número de cuenta" fullWidth value={form.AccountNumber} onChange={(e) => setForm((f) => ({ ...f, AccountNumber: e.target.value }))} />
            <TextField label="Descripción" fullWidth value={form.AccountName} onChange={(e) => setForm((f) => ({ ...f, AccountName: e.target.value }))} />
            <FormControl fullWidth>
              <InputLabel>Moneda</InputLabel>
              <Select value={form.CurrencyCode} label="Moneda" onChange={(e) => setForm((f) => ({ ...f, CurrencyCode: e.target.value }))}>
                {CURRENCY_OPTIONS.map((c) => <MenuItem key={c} value={c}>{c}</MenuItem>)}
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving || !form.BankId || !form.AccountNumber}>
            {editId ? "Actualizar" : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar eliminación</DialogTitle>
        <DialogContent>
          <Typography>¿Desactivar esta cuenta bancaria?</Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={eliminar.isPending}>Desactivar</Button>
        </DialogActions>
      </Dialog>

      {/* Print styles */}
      <style>{`
        @media print {
          .print-only { display: block !important; }
          body { background: white !important; }
          nav, header, .MuiAppBar-root, .MuiDrawer-root { display: none !important; }
        }
      `}</style>
    </Box>
  );
}
