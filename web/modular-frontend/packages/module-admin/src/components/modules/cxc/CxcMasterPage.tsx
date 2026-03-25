"use client";

import React, { useMemo, useState, useCallback, useEffect, useRef } from "react";
import {
  Alert,
  Box,
  Button,
  Checkbox,
  Chip,
  CircularProgress,
  Divider,
  Grid,
  IconButton,
  Paper,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  Add,
  Delete,
  Search as SearchIcon,
  Refresh as RefreshIcon,
  AccountBalance as AccountBalanceIcon,
  Payment as PaymentIcon,
  Receipt as ReceiptIcon,
} from "@mui/icons-material";
import { useClientesList } from "../../../hooks/useClientes";
import { toDateOnly } from "@zentto/shared-api";
import { DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { useTimezone } from "@zentto/shared-auth";
import {
  CxcAplicarCobroPayload,
  CxcDocumentoPendiente,
  useAplicarCobroTx,
  useCxcDocumentosPendientes,
  useCxcSaldo,
} from "../../../hooks/useCxcTx";
import type { ColumnDef } from "@zentto/datagrid-core";

// ─── Tipos internos ───────────────────────────────────────────

type SelDoc = CxcDocumentoPendiente & { checked: boolean; montoAplicar: number };
type FormaPagoLine = {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
};
type ClienteRow = Record<string, any>;

// ─── Columnas de clientes ─────────────────────────────────────

const CLIENTE_COLUMNS: ColumnDef[] = [
  { field: "codigo", header: "Codigo", width: 90 },
  { field: "nombre", header: "Nombre", flex: 1, minWidth: 160 },
  { field: "rif", header: "RIF", width: 120 },
  { field: "telefono", header: "Telefono", width: 130 },
  { field: "saldo", header: "Saldo", width: 120, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "estado",
    header: "Estado",
    width: 100,
    statusColors: { Activo: "success", Inactivo: "error" },
    statusVariant: "outlined",
  },
];

// ─── Componente Principal ─────────────────────────────────────

export default function CxcMasterPage() {
  const { timeZone } = useTimezone();
  const [search, setSearch] = useState("");
  const [selectedCod, setSelectedCod] = useState("");
  const [selectedNombre, setSelectedNombre] = useState("");
  const [tabValue, setTabValue] = useState(0);
  const clienteGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // ─── Datos de clientes ────────────────────────────────────
  const clientesQuery = useClientesList({ search, limit: 50 });
  const clientes = (clientesQuery.data?.items || clientesQuery.data?.data || []) as unknown as ClienteRow[];

  // ─── Datos CxC del cliente seleccionado ───────────────────
  const docsQuery = useCxcDocumentosPendientes(selectedCod);
  const saldoQuery = useCxcSaldo(selectedCod);
  const documentos = docsQuery.data?.data ?? [];
  const saldoData = saldoQuery.data?.data as Record<string, unknown> | null;

  const handleSelectCliente = useCallback((cli: ClienteRow) => {
    const cod = String(cli.codigo || cli.CODIGO || "");
    setSelectedCod(cod);
    setSelectedNombre(String(cli.nombre || cli.NOMBRE || cod));
    setTabValue(0);
  }, []);

  const clienteRows = useMemo(
    () =>
      clientes.map((c: ClienteRow, idx: number) => ({
        id: c.codigo || c.CODIGO || idx,
        codigo: c.codigo || c.CODIGO || "",
        nombre: c.nombre || c.NOMBRE || "",
        rif: c.rif || c.RIF || "",
        telefono: c.telefono || c.TELEFONO || "",
        saldo: Number(c.saldo || c.SALDO_TOT || 0),
        estado: c.estado || "Activo",
      })),
    [clientes]
  );

  // Bind clientes grid
  useEffect(() => {
    const el = clienteGridRef.current;
    if (!el || !registered) return;
    el.columns = CLIENTE_COLUMNS;
    el.rows = clienteRows;
    el.loading = clientesQuery.isLoading;
  }, [clienteRows, clientesQuery.isLoading, registered]);

  // Listen for row-click on clientes grid
  useEffect(() => {
    const el = clienteGridRef.current;
    if (!el || !registered) return;

    const handler = (e: CustomEvent) => {
      const row = e.detail?.row;
      if (!row) return;
      const cli = clientes.find(
        (c: ClienteRow) => (c.codigo || c.CODIGO) === row.codigo
      );
      if (cli) handleSelectCliente(cli);
    };

    el.addEventListener("row-click", handler);
    return () => el.removeEventListener("row-click", handler);
  }, [registered, clientes, handleSelectCliente]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", gap: 2, minHeight: 0 }}>
      {/* ── Seccion superior: Lista de Clientes ──────────────── */}
      <Paper sx={{ p: 2 }}>
        <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 2 }}>
          <Typography variant="h6" fontWeight={700} sx={{ flex: 1 }}>
            Cuentas por Cobrar
          </Typography>
          <TextField
            placeholder="Buscar cliente..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            InputProps={{ startAdornment: <SearchIcon fontSize="small" sx={{ mr: 1, color: "text.secondary" }} /> }}
            sx={{ width: 300 }}
          />
          <Tooltip title="Recargar">
            <IconButton onClick={() => clientesQuery.refetch()} size="small">
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Stack>

        <Box sx={{ height: 280 }}>
          {registered && (
            <zentto-grid
              ref={clienteGridRef}
              default-currency="VES"
              height="280px"
              enable-toolbar
              enable-header-menu
              enable-header-filters
              enable-clipboard
              enable-quick-search
              enable-context-menu
              enable-status-bar
              enable-configurator
            ></zentto-grid>
          )}
        </Box>
      </Paper>

      {/* ── Info del cliente seleccionado ─────────────────────── */}
      {selectedCod && (
        <Paper sx={{ px: 2, py: 1 }}>
          <Stack direction="row" spacing={3} alignItems="center">
            <Typography variant="subtitle2" color="text.secondary">
              Cliente:
            </Typography>
            <Typography variant="subtitle1" fontWeight={700}>
              {selectedNombre}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Cod: {selectedCod}
            </Typography>
            {saldoData && (
              <>
                <Divider orientation="vertical" flexItem />
                <Chip
                  label={`Saldo 30d: ${Number(saldoData.saldo30 || saldoData.SALDO_30 || 0).toFixed(2)}`}
                  size="small"
                  variant="outlined"
                />
                <Chip
                  label={`Saldo 60d: ${Number(saldoData.saldo60 || saldoData.SALDO_60 || 0).toFixed(2)}`}
                  size="small"
                  variant="outlined"
                />
                <Chip
                  label={`Saldo 90d: ${Number(saldoData.saldo90 || saldoData.SALDO_90 || 0).toFixed(2)}`}
                  size="small"
                  variant="outlined"
                />
                <Chip
                  label={`Total: ${Number(saldoData.saldoTotal || saldoData.SALDO_TOT || 0).toFixed(2)}`}
                  size="small"
                  color="primary"
                />
              </>
            )}
          </Stack>
        </Paper>
      )}

      {/* ── Seccion inferior: Tabs de detalle ─────────────────── */}
      {selectedCod ? (
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
          <Tabs
            value={tabValue}
            onChange={(_, v) => setTabValue(v)}
            sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}
          >
            <Tab icon={<ReceiptIcon fontSize="small" />} iconPosition="start" label="Estado de Cuenta" />
            <Tab icon={<PaymentIcon fontSize="small" />} iconPosition="start" label="Aplicar Cobros" />
            <Tab icon={<AccountBalanceIcon fontSize="small" />} iconPosition="start" label="Cobros Aplicados" />
          </Tabs>

          <Box sx={{ flex: 1, overflow: "auto", p: 2 }}>
            {tabValue === 0 && (
              <EstadoCuentaTab documentos={documentos} isLoading={docsQuery.isLoading} timeZone={timeZone} />
            )}
            {tabValue === 1 && (
              <AplicarCobrosTab
                codCliente={selectedCod}
                documentos={documentos}
                isLoadingDocs={docsQuery.isLoading}
                timeZone={timeZone}
                onRefresh={() => {
                  docsQuery.refetch();
                  saldoQuery.refetch();
                }}
              />
            )}
            {tabValue === 2 && (
              <CobrosAplicadosTab codCliente={selectedCod} />
            )}
          </Box>
        </Paper>
      ) : (
        <Paper sx={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Stack alignItems="center" spacing={1} sx={{ color: "text.secondary" }}>
            <AccountBalanceIcon sx={{ fontSize: 48, opacity: 0.4 }} />
            <Typography variant="body1">Seleccione un cliente para ver su estado de cuenta</Typography>
          </Stack>
        </Paper>
      )}
    </Box>
  );
}

// ─── Tab 1: Estado de Cuenta ──────────────────────────────────

function EstadoCuentaTab({
  documentos,
  isLoading,
  timeZone,
}: {
  documentos: CxcDocumentoPendiente[];
  isLoading: boolean;
  timeZone: string;
}) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  const totalPendiente = useMemo(
    () => documentos.reduce((acc, d) => acc + Number(d.pendiente || 0), 0),
    [documentos]
  );
  const totalDocumentos = useMemo(
    () => documentos.reduce((acc, d) => acc + Number(d.total || 0), 0),
    [documentos]
  );

  const columns = useMemo<ColumnDef[]>(
    () => [
      {
        field: "tipoDoc",
        header: "Tipo",
        width: 100,
        statusColors: { FACT: "primary", NC: "info", ND: "warning" },
        statusVariant: "outlined",
      },
      { field: "numDoc", header: "Documento", width: 150, sortable: true },
      { field: "fecha", header: "Fecha", width: 120, type: "date", sortable: true },
      { field: "total", header: "Total", width: 130, type: "number", currency: "VES", aggregation: "sum" },
      { field: "pendiente", header: "Pendiente", width: 130, type: "number", currency: "VES", aggregation: "sum" },
      {
        field: "estadoCalc",
        header: "Estado",
        width: 110,
        statusColors: { Pendiente: "warning", Cobrado: "success" },
      },
    ],
    []
  );

  const rows = useMemo(
    () =>
      documentos.map((d, i) => ({
        id: `${d.tipoDoc}-${d.numDoc}-${i}`,
        ...d,
        total: Number(d.total || 0),
        pendiente: Number(d.pendiente || 0),
        fecha: d.fecha ? toDateOnly(d.fecha as string, timeZone) : "",
        estadoCalc: Number(d.pendiente) > 0 ? "Pendiente" : "Cobrado",
      })),
    [documentos, timeZone]
  );

  // Bind data
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [columns, rows, isLoading, registered]);

  if (isLoading && !registered) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  if (documentos.length === 0 && !isLoading) {
    return <Alert severity="info">No hay documentos pendientes para este cliente.</Alert>;
  }

  return (
    <Box>
      <Stack direction="row" spacing={3} sx={{ mb: 2 }}>
        <Chip label={`${documentos.length} documentos`} variant="outlined" />
        <Chip label={`Total: ${totalDocumentos.toFixed(2)}`} variant="outlined" />
        <Chip label={`Pendiente: ${totalPendiente.toFixed(2)}`} color="warning" />
      </Stack>

      <Box sx={{ height: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="estado-cuenta"
            height="400px"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
          ></zentto-grid>
        )}
      </Box>
    </Box>
  );
}

// ─── Tab 2: Aplicar Cobros ────────────────────────────────────
// NOTA: Las tablas de documentos pendientes y formas de pago se mantienen
// como Table HTML porque son formularios de edicion inline (checkboxes,
// inputs de monto) — no son listados de solo lectura.

function AplicarCobrosTab({
  codCliente,
  documentos,
  isLoadingDocs,
  timeZone,
  onRefresh,
}: {
  codCliente: string;
  documentos: CxcDocumentoPendiente[];
  isLoadingDocs: boolean;
  timeZone: string;
  onRefresh: () => void;
}) {
  const [fecha, setFecha] = useState(toDateOnly(new Date(), timeZone));
  const [codUsuario] = useState("SUP");
  const [observaciones, setObservaciones] = useState("");
  const [rows, setRows] = useState<SelDoc[]>([]);
  const [formasPago, setFormasPago] = useState<FormaPagoLine[]>([{ formaPago: "EFECTIVO", monto: 0 }]);
  const cobroMutation = useAplicarCobroTx();

  React.useEffect(() => {
    if (documentos.length > 0 && rows.length === 0) {
      setRows(documentos.map((d) => ({ ...d, checked: false, montoAplicar: Number(d.pendiente || 0) })));
    }
  }, [documentos, rows.length]);

  const reloadRows = useCallback(() => {
    setRows(documentos.map((d) => ({ ...d, checked: false, montoAplicar: Number(d.pendiente || 0) })));
  }, [documentos]);

  const totalSeleccionado = useMemo(
    () => rows.filter((r) => r.checked).reduce((acc, r) => acc + Number(r.montoAplicar || 0), 0),
    [rows],
  );
  const totalFormasPago = useMemo(
    () => formasPago.reduce((acc, f) => acc + Number(f.monto || 0), 0),
    [formasPago],
  );
  const diferencia = useMemo(() => Number((totalSeleccionado - totalFormasPago).toFixed(2)), [totalSeleccionado, totalFormasPago]);
  const estaCuadrado = Math.abs(diferencia) <= 0.01;

  const toggleRow = (idx: number, checked: boolean) => {
    setRows((prev) => prev.map((r, i) => (i === idx ? { ...r, checked } : r)));
  };

  const changeMonto = (idx: number, value: number) => {
    setRows((prev) =>
      prev.map((r, i) =>
        i === idx
          ? { ...r, montoAplicar: Number.isFinite(value) ? Math.max(0, Math.min(value, Number(r.pendiente || 0))) : 0 }
          : r,
      ),
    );
  };

  const toggleAll = (checked: boolean) => {
    setRows((prev) => prev.map((r) => ({ ...r, checked })));
  };

  const autoFillFormasPago = () => {
    if (totalSeleccionado > 0) {
      setFormasPago([{ formaPago: "EFECTIVO", monto: Number(totalSeleccionado.toFixed(2)) }]);
    }
  };

  const addFormaPago = () => setFormasPago((prev) => [...prev, { formaPago: "EFECTIVO", monto: 0 }]);
  const removeFormaPago = (idx: number) => setFormasPago((prev) => (prev.length <= 1 ? prev : prev.filter((_, i) => i !== idx)));
  const updateFormaPago = (idx: number, patch: Partial<FormaPagoLine>) => {
    setFormasPago((prev) => prev.map((r, i) => (i === idx ? { ...r, ...patch } : r)));
  };

  const submit = async () => {
    const docs = rows
      .filter((r) => r.checked && Number(r.montoAplicar) > 0)
      .map((r) => ({ tipoDoc: r.tipoDoc, numDoc: r.numDoc, montoAplicar: Number(r.montoAplicar) }));

    if (!docs.length || !estaCuadrado) return;

    const fp = formasPago.filter((f) => f.formaPago.trim() && Number(f.monto) > 0);

    const payload: CxcAplicarCobroPayload = {
      requestId: `cxc_${Date.now()}`,
      codCliente,
      fecha,
      montoTotal: totalSeleccionado,
      codUsuario,
      observaciones,
      documentos: docs,
      formasPago: fp,
    };

    await cobroMutation.mutateAsync(payload);
    onRefresh();
    reloadRows();
  };

  if (isLoadingDocs) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  return (
    <Box>
      {cobroMutation.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Cobro aplicado exitosamente. Recibo: {String((cobroMutation.data as { numCobro?: string })?.numCobro || "")}
        </Alert>
      )}
      {cobroMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>Error aplicando cobro. Intente nuevamente.</Alert>
      )}

      {/* Cabecera del cobro */}
      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={3}>
            <DatePicker
              label="Fecha de Cobro"
              value={fecha ? dayjs(fecha) : null}
              onChange={(v) => setFecha(v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </Grid>
          <Grid item xs={12} sm={5}>
            <TextField
              fullWidth label="Observaciones" value={observaciones}
              onChange={(e) => setObservaciones(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} sm={4}>
            <Stack direction="row" spacing={1}>
              <Button variant="outlined" size="small" onClick={reloadRows} startIcon={<RefreshIcon />}>
                Recargar
              </Button>
              <Button
                variant="contained" size="small" onClick={submit}
                disabled={cobroMutation.isPending || totalSeleccionado <= 0 || !estaCuadrado}
              >
                {cobroMutation.isPending ? "Procesando..." : "Generar Cobro"}
              </Button>
            </Stack>
          </Grid>
        </Grid>
      </Paper>

      {/* Documentos pendientes — formulario inline, se mantiene Table nativo */}
      <Typography variant="subtitle2" sx={{ mb: 1 }}>
        Documentos Pendientes ({rows.filter((r) => r.checked).length} seleccionados)
      </Typography>
      <Table size="small" sx={{ mb: 2 }}>
        <TableHead>
          <TableRow sx={{ bgcolor: "#f9f9f9" }}>
            <TableCell padding="checkbox">
              <Checkbox
                indeterminate={rows.some((r) => r.checked) && !rows.every((r) => r.checked)}
                checked={rows.length > 0 && rows.every((r) => r.checked)}
                onChange={(e) => toggleAll(e.target.checked)}
                size="small"
              />
            </TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Tipo</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Documento</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Fecha</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }} align="right">Pendiente</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }} align="right">Monto a Aplicar</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.length === 0 ? (
            <TableRow>
              <TableCell colSpan={6} align="center" sx={{ py: 2, color: "text.secondary" }}>
                Sin documentos pendientes
              </TableCell>
            </TableRow>
          ) : (
            rows.map((r, i) => (
              <TableRow key={`${r.tipoDoc}-${r.numDoc}-${i}`} hover selected={r.checked}>
                <TableCell padding="checkbox">
                  <Checkbox checked={r.checked} onChange={(e) => toggleRow(i, e.target.checked)} size="small" />
                </TableCell>
                <TableCell sx={{ fontSize: "0.82rem" }}>{r.tipoDoc}</TableCell>
                <TableCell sx={{ fontSize: "0.82rem", fontFamily: "monospace" }}>{r.numDoc}</TableCell>
                <TableCell sx={{ fontSize: "0.82rem" }}>{r.fecha ? toDateOnly(r.fecha as string, timeZone) : ""}</TableCell>
                <TableCell align="right" sx={{ fontSize: "0.82rem" }}>{Number(r.pendiente || 0).toFixed(2)}</TableCell>
                <TableCell align="right">
                  <TextField
                    type="number" value={r.montoAplicar}
                    onChange={(e) => changeMonto(i, Number(e.target.value))}
                    inputProps={{ min: 0, step: "0.01" }}
                    sx={{ width: 130 }}
                    disabled={!r.checked}
                  />
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      {/* Formas de pago — formulario inline, se mantiene Table nativo */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
        <Typography variant="subtitle2">Formas de Cobro</Typography>
        <Stack direction="row" spacing={1}>
          <Button size="small" variant="text" onClick={autoFillFormasPago}>
            Auto-llenar
          </Button>
          <Button size="small" variant="outlined" startIcon={<Add />} onClick={addFormaPago}>
            Agregar
          </Button>
        </Stack>
      </Stack>
      <Table size="small">
        <TableHead>
          <TableRow sx={{ bgcolor: "#f9f9f9" }}>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Tipo</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }} align="right">Monto</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Banco</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Nro Cheque</TableCell>
            <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>F. Vencimiento</TableCell>
            <TableCell />
          </TableRow>
        </TableHead>
        <TableBody>
          {formasPago.map((fp, idx) => (
            <TableRow key={idx}>
              <TableCell>
                <TextField
                  value={fp.formaPago} sx={{ minWidth: 130 }}
                  onChange={(e) => updateFormaPago(idx, { formaPago: e.target.value.toUpperCase() })}
                />
              </TableCell>
              <TableCell align="right">
                <TextField
                  type="number" value={fp.monto} sx={{ width: 130 }}
                  onChange={(e) => updateFormaPago(idx, { monto: Number(e.target.value) || 0 })}
                  inputProps={{ min: 0, step: "0.01" }}
                />
              </TableCell>
              <TableCell>
                <TextField value={fp.banco || ""} onChange={(e) => updateFormaPago(idx, { banco: e.target.value })} />
              </TableCell>
              <TableCell>
                <TextField value={fp.numCheque || ""} onChange={(e) => updateFormaPago(idx, { numCheque: e.target.value })} />
              </TableCell>
              <TableCell>
                <DatePicker
                  value={fp.fechaVencimiento ? dayjs(fp.fechaVencimiento) : null}
                  onChange={(v) => updateFormaPago(idx, { fechaVencimiento: v ? v.format('YYYY-MM-DD') : undefined })}
                  slotProps={{ textField: { size: 'small', fullWidth: true } }}
                />
              </TableCell>
              <TableCell align="center">
                <Tooltip title="Eliminar forma de pago">
                  <span>
                    <IconButton color="error" size="small" onClick={() => removeFormaPago(idx)} disabled={formasPago.length === 1}>
                      <Delete fontSize="small" />
                    </IconButton>
                  </span>
                </Tooltip>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {/* Resumen */}
      <Paper variant="outlined" sx={{ p: 2, mt: 2 }}>
        <Stack direction="row" spacing={4} alignItems="center">
          <Typography variant="body2">
            Total documentos: <strong>{totalSeleccionado.toFixed(2)}</strong>
          </Typography>
          <Typography variant="body2">
            Total formas cobro: <strong>{totalFormasPago.toFixed(2)}</strong>
          </Typography>
          <Chip
            label={`Diferencia: ${diferencia.toFixed(2)}`}
            color={estaCuadrado ? "success" : "error"}
            size="small"
          />
        </Stack>
        {!estaCuadrado && totalSeleccionado > 0 && (
          <Alert severity="warning" sx={{ mt: 1 }}>
            La suma de formas de cobro debe cuadrar con el total de documentos seleccionados.
          </Alert>
        )}
      </Paper>
    </Box>
  );
}

// ─── Tab 3: Cobros Aplicados ──────────────────────────────────

function CobrosAplicadosTab({ codCliente }: { codCliente: string }) {
  const { data, isLoading } = useCxcSaldo(codCliente);
  const saldoData = data?.data as Record<string, unknown> | null;

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  return (
    <Box>
      <Alert severity="info" sx={{ mb: 2 }}>
        Resumen de saldos del cliente. Para ver el detalle completo de cobros aplicados,
        consulte el modulo de Abonos filtrando por este cliente.
      </Alert>

      {saldoData ? (
        <Paper variant="outlined" sx={{ p: 3 }}>
          <Grid container spacing={3}>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary">Saldo 30 dias</Typography>
              <Typography variant="h6" fontWeight={700}>
                {Number(saldoData.saldo30 || saldoData.SALDO_30 || 0).toFixed(2)}
              </Typography>
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary">Saldo 60 dias</Typography>
              <Typography variant="h6" fontWeight={700}>
                {Number(saldoData.saldo60 || saldoData.SALDO_60 || 0).toFixed(2)}
              </Typography>
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary">Saldo 90 dias</Typography>
              <Typography variant="h6" fontWeight={700}>
                {Number(saldoData.saldo90 || saldoData.SALDO_90 || 0).toFixed(2)}
              </Typography>
            </Grid>
            <Grid item xs={6} sm={3}>
              <Typography variant="caption" color="text.secondary">Saldo Total</Typography>
              <Typography variant="h6" fontWeight={700} color="primary.main">
                {Number(saldoData.saldoTotal || saldoData.SALDO_TOT || 0).toFixed(2)}
              </Typography>
            </Grid>
          </Grid>
        </Paper>
      ) : (
        <Alert severity="info">No hay datos de saldo disponibles para este cliente.</Alert>
      )}
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
