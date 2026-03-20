"use client";

import React, { useState, useCallback, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Card,
  CardContent,
  Chip,
  TextField,
  MenuItem,
  CircularProgress,
  IconButton,
  Tooltip,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef, type GridRowSelectionModel } from "@mui/x-data-grid";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import LinkIcon from "@mui/icons-material/Link";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import PendingIcon from "@mui/icons-material/Pending";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import { formatCurrency } from "@zentto/shared-api";
import {
  useConciliaciones,
  useCuentasBank,
  useConciliacionDetalle,
  useCrearConciliacion,
  useImportarExtracto,
  useConciliarMovimiento,
  useGenerarAjuste,
  useCerrarConciliacion,
  type ConciliacionFilter,
} from "@zentto/module-bancos";
import { useAsientosList } from "../hooks/useContabilidad";

// ─── Summary Cards ───────────────────────────────────────────

function SummaryCards({
  detalle,
  isLoading,
}: {
  detalle: any;
  isLoading: boolean;
}) {
  const cabecera = detalle?.cabecera;
  const cards = [
    {
      title: "Pendientes",
      value: cabecera?.Pendientes ?? 0,
      color: "#e65100",
      isCurrency: false,
    },
    {
      title: "Conciliados",
      value: cabecera?.Conciliados ?? 0,
      color: "#2e7d32",
      isCurrency: false,
    },
    {
      title: "Saldo sistema",
      value: cabecera?.Saldo_Final_Sistema ?? 0,
      color: "#1565c0",
      isCurrency: true,
    },
    {
      title: "Diferencia",
      value: cabecera?.Diferencia ?? 0,
      color: "#c62828",
      isCurrency: true,
    },
  ];

  return (
    <Grid container spacing={2} sx={{ mb: 3 }}>
      {cards.map((card, idx) => (
        <Grid size={{ xs: 6, md: 3 }} key={idx}>
          <Card sx={{ borderRadius: 2, borderTop: `3px solid ${card.color}` }}>
            <CardContent sx={{ py: 1.5 }}>
              {isLoading ? (
                <Skeleton width={80} height={36} />
              ) : (
                <Typography variant="h5" fontWeight={700} sx={{ color: card.color }}>
                  {card.isCurrency ? formatCurrency(card.value) : card.value}
                </Typography>
              )}
              <Typography variant="body2" color="text.secondary">
                {card.title}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}

// ─── CSV Import ──────────────────────────────────────────────

function parseCSVLines(csvText: string): any[] {
  const lines = csvText.trim().split("\n");
  if (lines.length < 2) return [];

  const headers = lines[0].split(",").map((h) => h.trim().replace(/"/g, ""));
  const rows: any[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(",").map((v) => v.trim().replace(/"/g, ""));
    const row: any = {};
    headers.forEach((h, idx) => {
      row[h] = values[idx] || "";
    });
    // Try to map common CSV fields
    rows.push({
      date: row.date || row.Date || row.fecha || row.Fecha || "",
      description:
        row.description || row.Description || row.descripcion || row.Descripcion || row.concepto || "",
      amount: parseFloat(row.amount || row.Amount || row.monto || row.Monto || "0") || 0,
    });
  }

  return rows;
}

// ─── Main Component ──────────────────────────────────────────

export default function ConciliacionBancariaPage() {
  const [selectedNroCta, setSelectedNroCta] = useState<string>("");
  const [selectedConciliacionId, setSelectedConciliacionId] = useState<number | null>(null);
  const [selectedMovSistemaId, setSelectedMovSistemaId] = useState<number | null>(null);
  const [selectedExtractoId, setSelectedExtractoId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Data hooks — delegados al modulo de bancos
  const conciliacionFilter: ConciliacionFilter = {
    ...(selectedNroCta && { Nro_Cta: selectedNroCta }),
  };
  const { data: conciliacionesData, isLoading: conciliacionesLoading } =
    useConciliaciones(conciliacionFilter);
  const { data: cuentasData } = useCuentasBank();
  const { data: detalleData, isLoading: detalleLoading } =
    useConciliacionDetalle(selectedConciliacionId ?? undefined);
  const { data: asientosData } = useAsientosList({ page: 1, limit: 100 });

  // Mutations — delegados al modulo de bancos
  const importMutation = useImportarExtracto();
  const conciliarMutation = useConciliarMovimiento();
  const ajusteMutation = useGenerarAjuste();
  const cerrarMutation = useCerrarConciliacion();
  const crearMutation = useCrearConciliacion();

  const conciliaciones: any[] = conciliacionesData?.rows ?? conciliacionesData?.data ?? [];
  const cuentas: any[] = cuentasData?.data ?? cuentasData ?? [];
  const detalle = detalleData?.data ?? detalleData ?? null;
  const movimientosSistema: any[] = detalle?.movimientosSistema ?? [];
  const extractoPendiente: any[] = detalle?.extractoPendiente ?? [];
  const asientos = asientosData?.data ?? asientosData?.rows ?? [];

  // Movimientos sistema columns
  const movSistemaCols: GridColDef[] = [
    { field: "Fecha", headerName: "Fecha", width: 100 },
    { field: "Tipo", headerName: "Tipo", width: 80 },
    { field: "Nro_Ref", headerName: "Referencia", width: 120 },
    { field: "Concepto", headerName: "Concepto", flex: 1, minWidth: 180 },
    {
      field: "Monto",
      headerName: "Monto",
      width: 130,
      type: "number",
      renderCell: (p) => (
        <Typography
          variant="body2"
          fontWeight={500}
          sx={{ color: (p.value ?? 0) >= 0 ? "success.main" : "error.main" }}
        >
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
    {
      field: "Estado",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          icon={p.value === "CONCILIADO" ? <CheckCircleIcon /> : <PendingIcon />}
          label={p.value === "CONCILIADO" ? "Conciliado" : "Pendiente"}
          size="small"
          color={p.value === "CONCILIADO" ? "success" : "warning"}
        />
      ),
    },
  ];

  // Extracto pendiente columns
  const extractoCols: GridColDef[] = [
    { field: "Fecha", headerName: "Fecha", width: 100 },
    { field: "Descripcion", headerName: "Descripcion", flex: 1, minWidth: 180 },
    { field: "Referencia", headerName: "Referencia", width: 120 },
    {
      field: "Monto",
      headerName: "Monto",
      width: 130,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    { field: "Tipo", headerName: "Tipo", width: 100 },
  ];

  // Accounting entries columns
  const entryCols: GridColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "id", headerName: "N Asiento", width: 100 },
    { field: "concepto", headerName: "Concepto", flex: 1, minWidth: 180 },
    {
      field: "totalDebe",
      headerName: "Debe",
      width: 120,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "totalHaber",
      headerName: "Haber",
      width: 120,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
  ];

  // File import handler — uses bancos importar-extracto
  const handleImportCSV = useCallback(
    async (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0];
      if (!file || !selectedConciliacionId) return;

      setError(null);
      setSuccessMsg(null);

      try {
        const text = await file.text();
        const lines = parseCSVLines(text);

        if (lines.length === 0) {
          setError("El archivo CSV no contiene datos validos");
          return;
        }

        await importMutation.mutateAsync({
          conciliacionId: selectedConciliacionId,
          extracto: lines.map((l) => ({
            Fecha: l.date,
            Descripcion: l.description,
            Tipo: (l.amount ?? 0) >= 0 ? "CREDITO" : "DEBITO",
            Monto: Math.abs(l.amount ?? 0),
          })),
        });

        setSuccessMsg(`${lines.length} lineas importadas correctamente`);
      } catch (err: any) {
        setError(err.message || "Error al importar el archivo");
      }

      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    },
    [selectedConciliacionId, importMutation]
  );

  // Conciliar handler — uses bancos conciliar-movimiento
  const handleConciliar = async () => {
    if (selectedMovSistemaId == null || selectedConciliacionId == null) {
      setError("Seleccione un movimiento del sistema para conciliar");
      return;
    }
    setError(null);
    try {
      await conciliarMutation.mutateAsync({
        Conciliacion_ID: selectedConciliacionId,
        MovimientoSistema_ID: selectedMovSistemaId,
        Extracto_ID: selectedExtractoId ?? undefined,
      });
      setSuccessMsg("Movimiento conciliado correctamente");
      setSelectedMovSistemaId(null);
      setSelectedExtractoId(null);
    } catch (err: any) {
      setError(err.message || "Error al conciliar");
    }
  };

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 3 }}>
        Conciliación bancaria
      </Typography>

      {/* Top Section */}
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <TextField
          select
          label="Cuenta bancaria"
          value={selectedNroCta}
          onChange={(e) => {
            setSelectedNroCta(e.target.value);
            setSelectedConciliacionId(null);
          }}
          size="small"
          sx={{ minWidth: 200 }}
        >
          <MenuItem value="">Todas</MenuItem>
          {(Array.isArray(cuentas) ? cuentas : []).map((c: any) => (
            <MenuItem key={c.nroCta ?? c.Nro_Cta} value={c.nroCta ?? c.Nro_Cta}>
              {c.bankName ?? c.Banco ?? c.nroCta ?? c.Nro_Cta}
            </MenuItem>
          ))}
        </TextField>

        {conciliaciones.length > 0 && (
          <TextField
            select
            label="Conciliacion"
            value={selectedConciliacionId ?? ""}
            onChange={(e) => setSelectedConciliacionId(Number(e.target.value) || null)}
            size="small"
            sx={{ minWidth: 250 }}
          >
            {conciliaciones.map((c: any) => (
              <MenuItem key={c.ID} value={c.ID}>
                #{c.ID} - {c.Fecha_Desde} a {c.Fecha_Hasta} ({c.Estado})
              </MenuItem>
            ))}
          </TextField>
        )}

        <Box sx={{ flex: 1 }} />

        <input
          type="file"
          accept=".csv"
          ref={fileInputRef}
          style={{ display: "none" }}
          onChange={handleImportCSV}
        />
        <Button
          variant="outlined"
          startIcon={<CloudUploadIcon />}
          onClick={() => fileInputRef.current?.click()}
          disabled={importMutation.isPending || !selectedConciliacionId}
        >
          {importMutation.isPending ? "Importando..." : "Importar CSV"}
        </Button>
      </Stack>

      {/* Messages */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}
      {successMsg && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMsg(null)}>
          {successMsg}
        </Alert>
      )}

      {/* Summary Cards */}
      {selectedConciliacionId && (
        <SummaryCards detalle={detalle} isLoading={detalleLoading} />
      )}

      {/* Main Split View */}
      <Grid container spacing={2}>
        {/* Left: Movimientos del Sistema */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box
              sx={{
                p: 2,
                borderBottom: "1px solid",
                borderColor: "divider",
                display: "flex",
                alignItems: "center",
                gap: 1,
              }}
            >
              <AccountBalanceIcon color="primary" />
              <Typography variant="h6" fontWeight={600}>
                Movimientos del Sistema
              </Typography>
            </Box>

            {!selectedConciliacionId ? (
              <Box sx={{ p: 4, textAlign: "center" }}>
                <Typography color="text.secondary">
                  Seleccione una conciliacion para ver los movimientos
                </Typography>
              </Box>
            ) : detalleLoading ? (
              <Box sx={{ p: 4, textAlign: "center" }}>
                <CircularProgress />
              </Box>
            ) : (
              <DataGrid
                rows={movimientosSistema}
                columns={movSistemaCols}
                getRowId={(r) => r.ID ?? r.id ?? Math.random()}
                autoHeight
                disableMultipleRowSelection
                onRowSelectionModelChange={(model: GridRowSelectionModel) => {
                  const ids = Array.isArray(model) ? model : Array.from(model as any);
                  const id = ids[0] as number;
                  setSelectedMovSistemaId(id ?? null);
                }}
                sx={{
                  border: 0,
                  "& .MuiDataGrid-row": { cursor: "pointer" },
                  "& .MuiDataGrid-row.Mui-selected": { bgcolor: "primary.light" },
                }}
                initialState={{
                  pagination: { paginationModel: { pageSize: 10 } },
                }}
                pageSizeOptions={[10, 25]}
              />
            )}
          </Paper>
        </Grid>

        {/* Right: Extracto Bancario + Asientos */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden", mb: 2 }}>
            <Box
              sx={{
                p: 2,
                borderBottom: "1px solid",
                borderColor: "divider",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <Typography variant="h6" fontWeight={600}>
                Extracto pendiente
              </Typography>
              <Stack direction="row" spacing={1}>
                <Tooltip title="Conciliar seleccion">
                  <span>
                    <IconButton
                      color="success"
                      disabled={
                        selectedMovSistemaId == null ||
                        selectedConciliacionId == null ||
                        conciliarMutation.isPending
                      }
                      onClick={handleConciliar}
                    >
                      <LinkIcon />
                    </IconButton>
                  </span>
                </Tooltip>
              </Stack>
            </Box>

            {selectedConciliacionId && extractoPendiente.length > 0 ? (
              <DataGrid
                rows={extractoPendiente}
                columns={extractoCols}
                getRowId={(r) => r.ID ?? r.id ?? Math.random()}
                autoHeight
                disableMultipleRowSelection
                onRowSelectionModelChange={(model: GridRowSelectionModel) => {
                  const ids = Array.isArray(model) ? model : Array.from(model as any);
                  const id = ids[0] as number;
                  setSelectedExtractoId(id ?? null);
                }}
                sx={{
                  border: 0,
                  "& .MuiDataGrid-row": { cursor: "pointer" },
                }}
                initialState={{
                  pagination: { paginationModel: { pageSize: 5 } },
                }}
                pageSizeOptions={[5, 10]}
              />
            ) : (
              <Box sx={{ p: 3, textAlign: "center" }}>
                <Typography color="text.secondary">
                  {selectedConciliacionId ? "Sin extractos pendientes" : "Seleccione una conciliacion"}
                </Typography>
              </Box>
            )}
          </Paper>

          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box
              sx={{
                p: 2,
                borderBottom: "1px solid",
                borderColor: "divider",
              }}
            >
              <Typography variant="h6" fontWeight={600}>
                Asientos contables
              </Typography>
            </Box>

            <DataGrid
              rows={asientos}
              columns={entryCols}
              getRowId={(r) => r.id ?? r.asientoId}
              autoHeight
              disableMultipleRowSelection
              sx={{
                border: 0,
                "& .MuiDataGrid-row": { cursor: "pointer" },
              }}
              initialState={{
                pagination: { paginationModel: { pageSize: 5 } },
              }}
              pageSizeOptions={[5, 10]}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Bottom: Reconciliation Status */}
      {selectedConciliacionId && detalle?.cabecera && (
        <Paper sx={{ mt: 3, p: 3, borderRadius: 2 }}>
          <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
            Resumen de Conciliacion
          </Typography>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="success.main">
                  {(detalle.cabecera.Conciliados ?? 0) + (detalle.cabecera.Pendientes ?? 0) > 0
                    ? (
                        ((detalle.cabecera.Conciliados ?? 0) /
                          ((detalle.cabecera.Conciliados ?? 0) + (detalle.cabecera.Pendientes ?? 0))) *
                        100
                      ).toFixed(1)
                    : 0}
                  %
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Porcentaje conciliado
                </Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="primary.main">
                  {formatCurrency(detalle.cabecera.Saldo_Final_Sistema ?? 0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Saldo final sistema
                </Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="error.main">
                  {formatCurrency(detalle.cabecera.Diferencia ?? 0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Diferencia
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Paper>
      )}
    </Box>
  );
}
