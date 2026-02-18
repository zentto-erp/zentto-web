"use client";

import React, { useMemo, useState, useCallback } from "react";
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
  Toolbar,
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
import { useProveedoresList } from "../../../hooks/useProveedores";
import {
  CxpAplicarPagoPayload,
  CxpDocumentoPendiente,
  useAplicarPagoTx,
  useCxpDocumentosPendientes,
  useCxpSaldo,
} from "../../../hooks/useCxpTx";

// ─── Tipos internos ───────────────────────────────────────────

type SelDoc = CxpDocumentoPendiente & { checked: boolean; montoAplicar: number };
type FormaPagoLine = {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
};

// ─── Componente Principal ─────────────────────────────────────

export default function CxpMasterPage() {
  const [search, setSearch] = useState("");
  const [selectedCod, setSelectedCod] = useState("");
  const [selectedNombre, setSelectedNombre] = useState("");
  const [tabValue, setTabValue] = useState(0);

  // ─── Datos de proveedores ─────────────────────────────────
  const provQuery = useProveedoresList({ search, limit: 50 });
  const proveedores = (provQuery.data?.items || provQuery.data?.data || []) as any[];

  // ─── Datos CxP del proveedor seleccionado ─────────────────
  const docsQuery = useCxpDocumentosPendientes(selectedCod);
  const saldoQuery = useCxpSaldo(selectedCod);
  const documentos = docsQuery.data?.data ?? [];
  const saldoData = saldoQuery.data?.data as Record<string, any> | null;

  const handleSelectProveedor = useCallback((prov: any) => {
    const cod = prov.codigo || prov.CODIGO || "";
    setSelectedCod(cod);
    setSelectedNombre(prov.nombre || prov.NOMBRE || cod);
    setTabValue(0);
  }, []);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", gap: 2, minHeight: 0 }}>
      {/* ── Sección superior: Lista de Proveedores ───────────── */}
      <Paper sx={{ p: 2 }}>
        <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 2 }}>
          <Typography variant="h6" fontWeight={700} sx={{ flex: 1 }}>
            Cuentas por Pagar
          </Typography>
          <TextField
            placeholder="Buscar proveedor..."
            size="small"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            InputProps={{ startAdornment: <SearchIcon fontSize="small" sx={{ mr: 1, color: "text.secondary" }} /> }}
            sx={{ width: 300 }}
          />
          <Tooltip title="Recargar">
            <IconButton onClick={() => provQuery.refetch()} size="small">
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Stack>

        <Box sx={{ maxHeight: 280, overflow: "auto" }}>
          {provQuery.isLoading ? (
            <Box sx={{ display: "flex", justifyContent: "center", p: 3 }}>
              <CircularProgress size={28} />
            </Box>
          ) : (
            <Table size="small" stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Codigo</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Nombre</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>RIF</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Telefono</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }} align="right">Saldo</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: "0.78rem" }}>Estado</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {proveedores.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center" sx={{ py: 3, color: "text.secondary" }}>
                      No se encontraron proveedores
                    </TableCell>
                  </TableRow>
                ) : (
                  proveedores.map((p: any) => {
                    const cod = p.codigo || p.CODIGO || "";
                    const isSelected = cod === selectedCod;
                    return (
                      <TableRow
                        key={cod}
                        hover
                        selected={isSelected}
                        onClick={() => handleSelectProveedor(p)}
                        sx={{ cursor: "pointer", "&.Mui-selected": { bgcolor: "primary.50" } }}
                      >
                        <TableCell sx={{ fontSize: "0.82rem" }}>{cod}</TableCell>
                        <TableCell sx={{ fontSize: "0.82rem", fontWeight: isSelected ? 700 : 400 }}>
                          {p.nombre || p.NOMBRE}
                        </TableCell>
                        <TableCell sx={{ fontSize: "0.82rem" }}>{p.rif || p.RIF || ""}</TableCell>
                        <TableCell sx={{ fontSize: "0.82rem" }}>{p.telefono || p.TELEFONO || ""}</TableCell>
                        <TableCell sx={{ fontSize: "0.82rem" }} align="right">
                          {Number(p.saldo || p.SALDO_TOT || 0).toFixed(2)}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={p.estado || "Activo"}
                            size="small"
                            color={p.estado === "Inactivo" ? "error" : "success"}
                            variant="outlined"
                            sx={{ fontSize: "0.72rem" }}
                          />
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          )}
        </Box>
      </Paper>

      {/* ── Info del proveedor seleccionado ───────────────────── */}
      {selectedCod && (
        <Paper sx={{ px: 2, py: 1 }}>
          <Stack direction="row" spacing={3} alignItems="center">
            <Typography variant="subtitle2" color="text.secondary">
              Proveedor:
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

      {/* ── Sección inferior: Tabs de detalle ─────────────────── */}
      {selectedCod ? (
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
          <Tabs
            value={tabValue}
            onChange={(_, v) => setTabValue(v)}
            sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}
          >
            <Tab icon={<ReceiptIcon fontSize="small" />} iconPosition="start" label="Estado de Cuenta" />
            <Tab icon={<PaymentIcon fontSize="small" />} iconPosition="start" label="Aplicar Pagos" />
            <Tab icon={<AccountBalanceIcon fontSize="small" />} iconPosition="start" label="Pagos Aplicados" />
          </Tabs>

          <Box sx={{ flex: 1, overflow: "auto", p: 2 }}>
            {tabValue === 0 && (
              <EstadoCuentaTab documentos={documentos} isLoading={docsQuery.isLoading} />
            )}
            {tabValue === 1 && (
              <AplicarPagosTab
                codProveedor={selectedCod}
                documentos={documentos}
                isLoadingDocs={docsQuery.isLoading}
                onRefresh={() => {
                  docsQuery.refetch();
                  saldoQuery.refetch();
                }}
              />
            )}
            {tabValue === 2 && (
              <PagosAplicadosTab codProveedor={selectedCod} />
            )}
          </Box>
        </Paper>
      ) : (
        <Paper sx={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <Stack alignItems="center" spacing={1} sx={{ color: "text.secondary" }}>
            <AccountBalanceIcon sx={{ fontSize: 48, opacity: 0.4 }} />
            <Typography variant="body1">Seleccione un proveedor para ver su estado de cuenta</Typography>
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
}: {
  documentos: CxpDocumentoPendiente[];
  isLoading: boolean;
}) {
  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress size={28} />
      </Box>
    );
  }

  if (documentos.length === 0) {
    return <Alert severity="info">No hay documentos pendientes para este proveedor.</Alert>;
  }

  const totalPendiente = documentos.reduce((acc, d) => acc + Number(d.pendiente || 0), 0);
  const totalDocumentos = documentos.reduce((acc, d) => acc + Number(d.total || 0), 0);

  return (
    <Box>
      <Stack direction="row" spacing={3} sx={{ mb: 2 }}>
        <Chip label={`${documentos.length} documentos`} variant="outlined" />
        <Chip label={`Total: ${totalDocumentos.toFixed(2)}`} variant="outlined" />
        <Chip label={`Pendiente: ${totalPendiente.toFixed(2)}`} color="warning" />
      </Stack>

      <Table size="small">
        <TableHead>
          <TableRow sx={{ bgcolor: "#f5f5f5" }}>
            <TableCell sx={{ fontWeight: 700 }}>Tipo</TableCell>
            <TableCell sx={{ fontWeight: 700 }}>Documento</TableCell>
            <TableCell sx={{ fontWeight: 700 }}>Fecha</TableCell>
            <TableCell sx={{ fontWeight: 700 }} align="right">Total</TableCell>
            <TableCell sx={{ fontWeight: 700 }} align="right">Pendiente</TableCell>
            <TableCell sx={{ fontWeight: 700 }}>Estado</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {documentos.map((d, i) => (
            <TableRow key={`${d.tipoDoc}-${d.numDoc}-${i}`} hover>
              <TableCell>
                <Chip label={d.tipoDoc} size="small" variant="outlined" sx={{ fontSize: "0.75rem" }} />
              </TableCell>
              <TableCell sx={{ fontFamily: "monospace" }}>{d.numDoc}</TableCell>
              <TableCell>{d.fecha ? String(d.fecha).slice(0, 10) : ""}</TableCell>
              <TableCell align="right">{Number(d.total || 0).toFixed(2)}</TableCell>
              <TableCell align="right" sx={{ fontWeight: 600, color: Number(d.pendiente) > 0 ? "error.main" : "success.main" }}>
                {Number(d.pendiente || 0).toFixed(2)}
              </TableCell>
              <TableCell>
                <Chip
                  label={Number(d.pendiente) > 0 ? "Pendiente" : "Pagado"}
                  size="small"
                  color={Number(d.pendiente) > 0 ? "warning" : "success"}
                  sx={{ fontSize: "0.72rem" }}
                />
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
}

// ─── Tab 2: Aplicar Pagos ─────────────────────────────────────

function AplicarPagosTab({
  codProveedor,
  documentos,
  isLoadingDocs,
  onRefresh,
}: {
  codProveedor: string;
  documentos: CxpDocumentoPendiente[];
  isLoadingDocs: boolean;
  onRefresh: () => void;
}) {
  const [fecha, setFecha] = useState(new Date().toISOString().slice(0, 10));
  const [codUsuario] = useState("SUP");
  const [observaciones, setObservaciones] = useState("");
  const [rows, setRows] = useState<SelDoc[]>([]);
  const [formasPago, setFormasPago] = useState<FormaPagoLine[]>([{ formaPago: "EFECTIVO", monto: 0 }]);
  const pagoMutation = useAplicarPagoTx();

  // Sincronizar documentos cuando llegan
  React.useEffect(() => {
    if (documentos.length > 0 && rows.length === 0) {
      setRows(documentos.map((d) => ({ ...d, checked: false, montoAplicar: Number(d.pendiente || 0) })));
    }
  }, [documentos, rows.length]);

  // Recargar filas
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

    const payload: CxpAplicarPagoPayload = {
      requestId: `cxp_${Date.now()}`,
      codProveedor,
      fecha,
      montoTotal: totalSeleccionado,
      codUsuario,
      observaciones,
      documentos: docs,
      formasPago: fp,
    };

    await pagoMutation.mutateAsync(payload);
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
      {pagoMutation.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Pago aplicado exitosamente. Recibo: {String((pagoMutation.data as any)?.numPago || "")}
        </Alert>
      )}
      {pagoMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>Error aplicando pago. Intente nuevamente.</Alert>
      )}

      {/* Cabecera del pago */}
      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={3}>
            <TextField
              fullWidth size="small" label="Fecha de Pago" type="date" value={fecha}
              InputLabelProps={{ shrink: true }}
              onChange={(e) => setFecha(e.target.value)}
            />
          </Grid>
          <Grid item xs={12} sm={5}>
            <TextField
              fullWidth size="small" label="Observaciones" value={observaciones}
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
                disabled={pagoMutation.isPending || totalSeleccionado <= 0 || !estaCuadrado}
              >
                {pagoMutation.isPending ? "Procesando..." : "Generar Pago"}
              </Button>
            </Stack>
          </Grid>
        </Grid>
      </Paper>

      {/* Documentos pendientes */}
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
                <TableCell sx={{ fontSize: "0.82rem" }}>{r.fecha ? String(r.fecha).slice(0, 10) : ""}</TableCell>
                <TableCell align="right" sx={{ fontSize: "0.82rem" }}>{Number(r.pendiente || 0).toFixed(2)}</TableCell>
                <TableCell align="right">
                  <TextField
                    size="small" type="number" value={r.montoAplicar}
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

      {/* Formas de pago */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
        <Typography variant="subtitle2">Formas de Pago</Typography>
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
                  size="small" value={fp.formaPago} sx={{ minWidth: 130 }}
                  onChange={(e) => updateFormaPago(idx, { formaPago: e.target.value.toUpperCase() })}
                />
              </TableCell>
              <TableCell align="right">
                <TextField
                  size="small" type="number" value={fp.monto} sx={{ width: 130 }}
                  onChange={(e) => updateFormaPago(idx, { monto: Number(e.target.value) || 0 })}
                  inputProps={{ min: 0, step: "0.01" }}
                />
              </TableCell>
              <TableCell>
                <TextField size="small" value={fp.banco || ""} onChange={(e) => updateFormaPago(idx, { banco: e.target.value })} />
              </TableCell>
              <TableCell>
                <TextField size="small" value={fp.numCheque || ""} onChange={(e) => updateFormaPago(idx, { numCheque: e.target.value })} />
              </TableCell>
              <TableCell>
                <TextField
                  size="small" type="date" value={fp.fechaVencimiento || ""}
                  InputLabelProps={{ shrink: true }}
                  onChange={(e) => updateFormaPago(idx, { fechaVencimiento: e.target.value || undefined })}
                />
              </TableCell>
              <TableCell align="center">
                <IconButton color="error" size="small" onClick={() => removeFormaPago(idx)} disabled={formasPago.length === 1}>
                  <Delete fontSize="small" />
                </IconButton>
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
            Total formas pago: <strong>{totalFormasPago.toFixed(2)}</strong>
          </Typography>
          <Chip
            label={`Diferencia: ${diferencia.toFixed(2)}`}
            color={estaCuadrado ? "success" : "error"}
            size="small"
          />
        </Stack>
        {!estaCuadrado && totalSeleccionado > 0 && (
          <Alert severity="warning" sx={{ mt: 1 }}>
            La suma de formas de pago debe cuadrar con el total de documentos seleccionados.
          </Alert>
        )}
      </Paper>
    </Box>
  );
}

// ─── Tab 3: Pagos Aplicados ───────────────────────────────────

function PagosAplicadosTab({ codProveedor }: { codProveedor: string }) {
  const { data, isLoading } = useCxpSaldo(codProveedor);
  const saldoData = data?.data as Record<string, any> | null;

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
        Resumen de saldos del proveedor. Para ver el detalle completo de pagos aplicados,
        consulte el modulo de Pagos filtrando por este proveedor.
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
        <Alert severity="info">No hay datos de saldo disponibles para este proveedor.</Alert>
      )}
    </Box>
  );
}
