"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import {
  Alert, Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  Paper, Stack, TextField, Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import LockIcon from "@mui/icons-material/Lock";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import { useRouter } from "next/navigation";
import { formatCurrency, toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useToast, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import {
  useCerrarConciliacion, useConciliacionDetalle, useConciliaciones, useConciliarMovimiento,
  useCuentasBank, useGenerarAjuste, useImportarExtracto, useAsientosVinculados,
} from "../../hooks/useConciliacionBancaria";
import { useAuth } from "@zentto/shared-auth";
import { useBancosGridRegistration } from "../zenttoGridPersistence";

type ConciliacionRow = Record<string, any>;

const SVG_LOCK = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>';
const LIST_GRID_ID = "module-bancos:conciliaciones:list";
const MOVIMIENTOS_SISTEMA_GRID_ID = "module-bancos:conciliaciones:movimientos-sistema";
const EXTRACTO_GRID_ID = "module-bancos:conciliaciones:extracto-pendiente";
const ASIENTOS_GRID_ID = "module-bancos:conciliaciones:asientos";

export default function ConciliacionBancariaPage() {
  const gridRef = useRef<any>(null);
  const movSistemaGridRef = useRef<any>(null);
  const extractoGridRef = useRef<any>(null);
  const asientosGridRef = useRef<any>(null);
  const router = useRouter();
  const { showToast } = useToast();
  const { timeZone } = useTimezone();
  const { hasModule } = useAuth();
  const showAsientos = hasModule("contabilidad");

  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [page, setPage] = useState(1);
  const [limit] = useState(50);
  const nroCta = filterValues.cuenta ?? "";
  const estado = filterValues.estado ?? "";
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [importOpen, setImportOpen] = useState(false);
  const [importText, setImportText] = useState(JSON.stringify([{ Fecha: toDateOnly(new Date(), timeZone), Descripcion: "Deposito", Referencia: "DEP-001", Tipo: "CREDITO", Monto: 100, Saldo: 100 }], null, 2));
  const [cerrarOpen, setCerrarOpen] = useState(false);
  const [saldoFinalBanco, setSaldoFinalBanco] = useState("");
  const [obsCierre, setObsCierre] = useState("");

  const { data: cuentasData } = useCuentasBank();
  const filter = useMemo(() => ({ Nro_Cta: nroCta || undefined, Estado: estado || undefined, page, limit }), [nroCta, estado, page, limit]);
  const { data: listData, isLoading } = useConciliaciones(filter);
  const { data: detalleData, refetch: refetchDetalle } = useConciliacionDetalle(selectedId ?? undefined);
  const { data: asientosVinculadosData } = useAsientosVinculados(showAsientos ? (selectedId ?? undefined) : undefined);
  const asientosVinculados: any[] = asientosVinculadosData?.rows ?? [];
  const importar = useImportarExtracto();
  const cerrar = useCerrarConciliacion();
  const { ready: listLayoutReady } = useGridLayoutSync(LIST_GRID_ID);
  const { ready: movimientosLayoutReady } = useGridLayoutSync(MOVIMIENTOS_SISTEMA_GRID_ID);
  const { ready: extractoLayoutReady } = useGridLayoutSync(EXTRACTO_GRID_ID);
  const { ready: asientosLayoutReady } = useGridLayoutSync(ASIENTOS_GRID_ID);
  const layoutReady = listLayoutReady && movimientosLayoutReady && extractoLayoutReady && asientosLayoutReady;
  const { registered } = useBancosGridRegistration(layoutReady);

  const rows = (listData?.rows ?? []) as ConciliacionRow[];
  const cuentas = (cuentasData?.rows ?? []) as Record<string, any>[];

  const conciliacionFilters = useMemo<FilterFieldDef[]>(() => [
    { field: "cuenta", label: "Cuenta", type: "select", options: cuentas.map((c) => ({ value: String(c.Nro_Cta), label: `${String(c.Nro_Cta)} - ${String(c.BancoNombre ?? c.Banco ?? "")}` })), minWidth: 220 },
    { field: "estado", label: "Estado", type: "select", options: [{ value: "ABIERTA", label: "Abierta" }, { value: "EN_PROCESO", label: "En Proceso" }, { value: "CERRADA", label: "Cerrada" }] },
  ], [cuentas]);

  const movSistema = (detalleData?.movimientosSistema ?? []) as Record<string, any>[];
  const extractoPendiente = (detalleData?.extractoPendiente ?? []) as Record<string, any>[];

  const COLUMNS: ColumnDef[] = useMemo(() => [
    { field: "ID", header: "ID", width: 70 },
    { field: "Nro_Cta", header: "Cuenta", width: 160, sortable: true },
    { field: "Fecha_Desde", header: "Desde", width: 120 },
    { field: "Fecha_Hasta", header: "Hasta", width: 120 },
    { field: "Saldo_Final_Sistema", header: "Saldo Sistema", width: 140, type: "number" },
    { field: "Diferencia", header: "Diferencia", width: 130, type: "number" },
    { field: "Estado", header: "Estado", width: 130, statusColors: { ABIERTA: "warning", EN_PROCESO: "info", CERRADA: "success", ANULADA: "error" } },
    {
      field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
      actions: [
        { icon: "view", label: "Ver", action: "view" },
        { icon: SVG_LOCK, label: "Cerrar", action: "close", color: "#ed6c02" },
      ],
    } as ColumnDef,
  ], []);

  const COLS_MOV: ColumnDef[] = [
    { field: "Fecha", header: "Fecha", width: 110 }, { field: "Tipo", header: "Tipo", width: 80 },
    { field: "Concepto", header: "Concepto", flex: 1, minWidth: 150 },
    { field: "Monto", header: "Monto", width: 120, type: "number" },
    { field: "Estado", header: "Estado", width: 100, statusColors: { CONCILIADO: "success" } },
  ];
  const COLS_EXTRACTO: ColumnDef[] = [
    { field: "Fecha", header: "Fecha", width: 110 }, { field: "Descripcion", header: "DescripciÃ³n", flex: 1, minWidth: 150 },
    { field: "Referencia", header: "Ref", width: 120 }, { field: "Tipo", header: "Tipo", width: 90, statusColors: { CREDITO: "success", DEBITO: "error" } },
    { field: "Monto", header: "Monto", width: 120, type: "number" },
  ];
  const COLS_ASIENTOS: ColumnDef[] = [
    { field: "EntryDate", header: "Fecha", width: 110 }, { field: "EntryNumber", header: "N Asiento", width: 120 },
    { field: "Concept", header: "Concepto", flex: 1, minWidth: 150 },
    { field: "TotalDebit", header: "Debe", width: 120, type: "number" }, { field: "TotalCredit", header: "Haber", width: 120, type: "number" },
  ];

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.ID ?? Math.random();
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setSelectedId(Number(row.ID));
      if (action === "close" && row.Estado === "ABIERTA") { setSelectedId(Number(row.ID)); setCerrarOpen(true); }
    };
    const createHandler = () => router.push("/conciliacion");
    el.addEventListener("action-click", handler);
    el.addEventListener("create-click", createHandler);
    return () => { el.removeEventListener("action-click", handler); el.removeEventListener("create-click", createHandler); };
  }, [registered, rows, router]);

  useEffect(() => {
    const el = movSistemaGridRef.current; if (!el || !registered || !selectedId) return;
    el.columns = COLS_MOV; el.rows = movSistema; el.getRowId = (r: any) => r.id ?? r.ID ?? r.Mov_ID ?? Math.random();
  }, [movSistema, registered, selectedId]);

  useEffect(() => {
    const el = extractoGridRef.current; if (!el || !registered || !selectedId) return;
    el.columns = COLS_EXTRACTO; el.rows = extractoPendiente; el.getRowId = (r: any) => r.id ?? r.ID ?? r.Extracto_ID ?? Math.random();
  }, [extractoPendiente, registered, selectedId]);

  useEffect(() => {
    const el = asientosGridRef.current; if (!el || !registered || !selectedId) return;
    el.columns = COLS_ASIENTOS; el.rows = asientosVinculados; el.getRowId = (r: any) => r.JournalEntryId ?? Math.random();
  }, [asientosVinculados, registered, selectedId]);

  const handleImportar = async () => {
    if (!selectedId) return;
    try { const parsed = JSON.parse(importText); const r = await importar.mutateAsync({ conciliacionId: selectedId, extracto: parsed }); showToast(`Extracto importado. Registros: ${r?.registrosImportados ?? "ok"}`); setImportOpen(false); await refetchDetalle(); }
    catch (e: unknown) { showToast(e instanceof Error ? e.message : "Error al importar extracto"); }
  };

  const handleCerrar = async () => {
    if (!selectedId) return;
    try { const r = await cerrar.mutateAsync({ Conciliacion_ID: selectedId, Saldo_Final_Banco: Number(saldoFinalBanco), Observaciones: obsCierre || undefined }); showToast(`ConciliaciÃ³n cerrada. Estado: ${r?.estado ?? "ok"}, Diferencia: ${r?.diferencia ?? 0}`); setCerrarOpen(false); setSelectedId(null); }
    catch (e: unknown) { showToast(e instanceof Error ? e.message : "Error al cerrar conciliaciÃ³n"); }
  };

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
      <Typography variant="h5" fontWeight={600}>Conciliaciones</Typography>

      <ZenttoFilterPanel filters={conciliacionFilters} values={filterValues} onChange={(v) => { setFilterValues(v); setPage(1); }} searchPlaceholder="Buscar conciliaciÃ³n..." searchValue={search} onSearchChange={(v) => { setSearch(v); setPage(1); }} />

      <Paper sx={{ p: 0 }}>
        <zentto-grid ref={gridRef} grid-id={LIST_GRID_ID} height="400px" enable-create create-label="Nueva ConciliaciÃ³n" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      </Paper>

      <Dialog open={selectedId != null && !cerrarOpen} onClose={() => setSelectedId(null)} maxWidth="lg" fullWidth>
        <DialogTitle>ConciliaciÃ³n #{selectedId}
          {detalleData?.cabecera && <Typography variant="body2" color="text.secondary">Cuenta: {detalleData.cabecera.Nro_Cta} | PerÃ­odo: {toDateOnly(detalleData.cabecera.Fecha_Desde, timeZone)} - {toDateOnly(detalleData.cabecera.Fecha_Hasta, timeZone)}</Typography>}
        </DialogTitle>
        <DialogContent>
          {detalleData?.cabecera && (
            <Alert severity="info" sx={{ mb: 2 }}>
              <Stack direction="row" spacing={3}>
                <Typography variant="body2"><strong>Saldo Sistema:</strong> {formatCurrency(Number(detalleData.cabecera.Saldo_Final_Sistema ?? 0))}</Typography>
                <Typography variant="body2"><strong>Saldo Banco:</strong> {formatCurrency(Number(detalleData.cabecera.Saldo_Final_Banco ?? 0))}</Typography>
                <Typography variant="body2"><strong>Diferencia:</strong> {formatCurrency(Number(detalleData.cabecera.Diferencia ?? 0))}</Typography>
              </Stack>
            </Alert>
          )}
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="subtitle2" gutterBottom>Movimientos del Sistema</Typography>
              <Box sx={{ height: 350 }}><zentto-grid ref={movSistemaGridRef} grid-id={MOVIMIENTOS_SISTEMA_GRID_ID} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator /></Box>
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="subtitle2" gutterBottom>Extracto Pendiente</Typography>
              <Box sx={{ height: 350 }}><zentto-grid ref={extractoGridRef} grid-id={EXTRACTO_GRID_ID} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator /></Box>
            </Grid>
          </Grid>
          {showAsientos && asientosVinculados.length > 0 && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="subtitle2" gutterBottom>Asientos Contables Vinculados</Typography>
              <Box sx={{ height: 200 }}><zentto-grid ref={asientosGridRef} grid-id={ASIENTOS_GRID_ID} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator /></Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button variant="outlined" startIcon={<UploadFileIcon />} onClick={() => setImportOpen(true)}>Importar Extracto</Button>
          {detalleData?.cabecera?.Estado === "ABIERTA" && <Button variant="contained" color="warning" startIcon={<LockIcon />} onClick={() => setCerrarOpen(true)}>Cerrar ConciliaciÃ³n</Button>}
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={importOpen} onClose={() => setImportOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Importar Extracto Bancario (JSON)</DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>Ingrese un array JSON con los movimientos del extracto bancario.</Alert>
          <TextField fullWidth multiline minRows={10} value={importText} onChange={(e) => setImportText(e.target.value)} sx={{ fontFamily: "monospace" }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setImportOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleImportar} disabled={importar.isPending}>{importar.isPending ? "Importando..." : "Importar"}</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={cerrarOpen} onClose={() => setCerrarOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Cerrar ConciliaciÃ³n #{selectedId}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField fullWidth label="Saldo Final del Banco" type="number" value={saldoFinalBanco} onChange={(e) => setSaldoFinalBanco(e.target.value)} />
            <TextField fullWidth label="Observaciones" multiline rows={3} value={obsCierre} onChange={(e) => setObsCierre(e.target.value)} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCerrarOpen(false)}>Cancelar</Button>
          <Button variant="contained" color="warning" onClick={handleCerrar} disabled={cerrar.isPending || !saldoFinalBanco}>{cerrar.isPending ? "Cerrando..." : "Cerrar ConciliaciÃ³n"}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
