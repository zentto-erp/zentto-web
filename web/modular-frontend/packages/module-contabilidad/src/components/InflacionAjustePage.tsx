"use client";

import React, { useState, useMemo } from "react";
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
  CircularProgress,
  Alert,
  Tab,
  Tabs,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useInflationIndices,
  useUpsertInflationIndex,
  useMonetaryClassifications,
  useUpsertMonetaryClass,
  useAutoClassifyAccounts,
  useCalculateInflation,
  usePostInflation,
  useVoidInflation,
  type InflationIndex,
  type MonetaryClassification,
} from "../hooks/useContabilidadLegal";

// ─── Tab Panel Helper ────────────────────────────────────────
function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

export default function InflacionAjustePage() {
  const [tab, setTab] = useState(0);

  // ─── Tab 0: Indices INPC ─────────────────────────────────
  const currentYear = new Date().getFullYear();
  const [indiceYear, setIndiceYear] = useState(currentYear);
  const [indiceDialogOpen, setIndiceDialogOpen] = useState(false);
  const [newIndice, setNewIndice] = useState({ periodCode: "", indexValue: "", sourceReference: "" });

  const indicesQuery = useInflationIndices("VE", indiceYear, indiceYear);
  const upsertIndiceMutation = useUpsertInflationIndex();

  const indicesRows: InflationIndex[] = indicesQuery.data?.data ?? indicesQuery.data?.rows ?? [];

  const indicesColumns: GridColDef[] = [
    { field: "PeriodCode", headerName: "Periodo", width: 120 },
    {
      field: "IndexValue",
      headerName: "Valor Índice",
      width: 150,
      renderCell: (p) => Number(p.value).toFixed(4),
    },
    { field: "SourceReference", headerName: "Fuente / Referencia", flex: 1, minWidth: 200 },
  ];

  const handleSaveIndice = async () => {
    if (!newIndice.periodCode || !newIndice.indexValue) return;
    await upsertIndiceMutation.mutateAsync({
      countryCode: "VE",
      indexName: "INPC",
      periodCode: newIndice.periodCode,
      indexValue: Number(newIndice.indexValue),
      sourceReference: newIndice.sourceReference || undefined,
    });
    setIndiceDialogOpen(false);
    setNewIndice({ periodCode: "", indexValue: "", sourceReference: "" });
  };

  // ─── Tab 1: Clasificacion Monetaria ──────────────────────
  const [clasSearch, setClasSearch] = useState("");
  const [clasDialogRow, setClasDialogRow] = useState<MonetaryClassification | null>(null);
  const [clasNewValue, setClasNewValue] = useState<"MONETARY" | "NON_MONETARY">("MONETARY");

  const clasificacionQuery = useMonetaryClassifications(undefined, clasSearch || undefined);
  const upsertClasMutation = useUpsertMonetaryClass();
  const autoClassifyMutation = useAutoClassifyAccounts();

  const clasificacionRows: MonetaryClassification[] = clasificacionQuery.data?.data ?? clasificacionQuery.data?.rows ?? [];

  const clasificacionColumns: GridColDef[] = [
    { field: "AccountCode", headerName: "Código", width: 120 },
    { field: "AccountName", headerName: "Cuenta", flex: 1, minWidth: 200 },
    { field: "AccountType", headerName: "Tipo", width: 120 },
    {
      field: "Classification",
      headerName: "Clasificación",
      width: 180,
      renderCell: (p) => (
        <Chip
          label={p.value === "MONETARY" ? "Monetaria" : "No monetaria"}
          size="small"
          color={p.value === "MONETARY" ? "info" : "warning"}
        />
      ),
    },
  ];

  const handleSaveClasificacion = async () => {
    if (!clasDialogRow) return;
    await upsertClasMutation.mutateAsync({
      accountId: clasDialogRow.AccountId,
      classification: clasNewValue,
    });
    setClasDialogRow(null);
  };

  // ─── Tab 2: Calcular Ajuste ──────────────────────────────
  const [calcPeriod, setCalcPeriod] = useState("");
  const [calcFiscalYear, setCalcFiscalYear] = useState(currentYear);
  const calculateMutation = useCalculateInflation();
  const postMutation = usePostInflation();

  const calcResult = calculateMutation.data as any;
  const calcPreviewRows = calcResult?.data ?? calcResult?.rows ?? [];

  const calcPreviewColumns: GridColDef[] = [
    { field: "AccountCode", headerName: "Cuenta", width: 120 },
    { field: "AccountName", headerName: "Nombre", flex: 1, minWidth: 180 },
    { field: "HistoricalBalance", headerName: "Saldo histórico", width: 150, renderCell: (p) => formatCurrency(p.value) },
    { field: "AdjustedBalance", headerName: "Saldo ajustado", width: 150, renderCell: (p) => formatCurrency(p.value) },
    { field: "AdjustmentAmount", headerName: "Ajuste", width: 140, renderCell: (p) => formatCurrency(p.value) },
  ];

  const handleCalculate = () => {
    if (!calcPeriod || !calcFiscalYear) return;
    calculateMutation.mutate({ periodCode: calcPeriod, fiscalYear: calcFiscalYear });
  };

  const handlePost = () => {
    const id = calcResult?.InflationAdjustmentId ?? calcResult?.id;
    if (!id) return;
    postMutation.mutate(id);
  };

  // ─── Tab 3: Historial ────────────────────────────────────
  const [voidDialogId, setVoidDialogId] = useState<number | null>(null);
  const [voidMotivo, setVoidMotivo] = useState("");
  const voidMutation = useVoidInflation();

  // Reutilizamos la query de indices para obtener historial (ajustes previos)
  const historialQuery = useInflationIndices("VE");
  const historialData = historialQuery.data as any;
  const historialRows = useMemo(() => {
    const raw = historialData?.adjustments ?? historialData?.data ?? [];
    return Array.isArray(raw) ? raw : [];
  }, [historialData]);

  const historialColumns: GridColDef[] = [
    { field: "InflationAdjustmentId", headerName: "ID", width: 70 },
    { field: "PeriodCode", headerName: "Periodo", width: 120 },
    { field: "FiscalYear", headerName: "Ejercicio", width: 100 },
    { field: "CalculatedAt", headerName: "Fecha cálculo", width: 160 },
    { field: "TotalAdjustment", headerName: "Ajuste total", width: 160, renderCell: (p) => formatCurrency(p.value) },
    {
      field: "Status",
      headerName: "Estado",
      width: 130,
      renderCell: (p) => (
        <Chip
          label={p.value}
          size="small"
          color={
            p.value === "POSTED" ? "success" : p.value === "DRAFT" ? "warning" : "default"
          }
        />
      ),
    },
    {
      field: "acciones",
      headerName: "",
      width: 120,
      sortable: false,
      renderCell: (p) =>
        p.row.Status === "POSTED" ? (
          <Button size="small" color="error" onClick={() => setVoidDialogId(p.row.InflationAdjustmentId ?? p.row.id)}>
            Anular
          </Button>
        ) : null,
    },
  ];

  const handleVoid = async () => {
    if (!voidDialogId) return;
    await voidMutation.mutateAsync({ id: voidDialogId, motivo: voidMotivo || undefined });
    setVoidDialogId(null);
    setVoidMotivo("");
  };

  // ─── Render ──────────────────────────────────────────────
  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Ajuste por Inflación" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Stack direction="row" alignItems="center" spacing={1} mb={1}>
          <Chip label="BA VEN-NIF 2 / NIC 29 / DPC-10" color="primary" size="small" variant="outlined" />
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider", px: 2 }}>
            <Tab label="Índices INPC" />
            <Tab label="Clasificación monetaria" />
            <Tab label="Calcular ajuste" />
            <Tab label="Historial" />
          </Tabs>

          {/* ─── Tab 0: Indices INPC ───────────────────────── */}
          <TabPanel value={tab} index={0}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
              <TextField
                label="Año"
                type="number"
                size="small"
                value={indiceYear}
                onChange={(e) => setIndiceYear(Number(e.target.value))}
                sx={{ width: 120 }}
              />
              <Button variant="contained" size="small" onClick={() => setIndiceDialogOpen(true)}>
                Agregar Índice
              </Button>
            </Stack>
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              <ZenttoDataGrid
                rows={indicesRows}
                columns={indicesColumns}
                loading={indicesQuery.isLoading}
                pageSizeOptions={[12, 25]}
                disableRowSelectionOnClick
                getRowId={(row) => row.InflationIndexId ?? row.PeriodCode ?? row.id}
                sx={{ border: "none" }}
                mobileVisibleFields={['PeriodCode', 'IndexValue']}
              />
            </Box>
          </TabPanel>

          {/* ─── Tab 1: Clasificacion Monetaria ────────────── */}
          <TabPanel value={tab} index={1}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
              <TextField
                label="Buscar cuenta"
                size="small"
                value={clasSearch}
                onChange={(e) => setClasSearch(e.target.value)}
                sx={{ minWidth: 240 }}
              />
              <Button
                variant="outlined"
                size="small"
                onClick={() => autoClassifyMutation.mutate()}
                disabled={autoClassifyMutation.isPending}
              >
                {autoClassifyMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}
                Auto-clasificar
              </Button>
            </Stack>
            {autoClassifyMutation.isSuccess && (
              <Alert severity="success" sx={{ mx: 2, mb: 1 }}>
                Clasificación automática completada.
              </Alert>
            )}
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              <ZenttoDataGrid
                rows={clasificacionRows}
                columns={clasificacionColumns}
                loading={clasificacionQuery.isLoading}
                pageSizeOptions={[25, 50]}
                disableRowSelectionOnClick
                getRowId={(row) => row.AccountMonetaryClassId ?? row.AccountId ?? row.id}
                onRowClick={(params) => {
                  const row = params.row as MonetaryClassification;
                  setClasDialogRow(row);
                  setClasNewValue(row.Classification);
                }}
                sx={{ border: "none", cursor: "pointer" }}
                mobileVisibleFields={['AccountCode', 'Classification']}
                smExtraFields={['AccountName', 'AccountType']}
              />
            </Box>
          </TabPanel>

          {/* ─── Tab 2: Calcular Ajuste ────────────────────── */}
          <TabPanel value={tab} index={2}>
            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
              <TextField
                label="Periodo (YYYYMM)"
                size="small"
                value={calcPeriod}
                onChange={(e) => setCalcPeriod(e.target.value)}
                placeholder="202601"
                sx={{ width: 180 }}
              />
              <TextField
                label="Ejercicio fiscal"
                type="number"
                size="small"
                value={calcFiscalYear}
                onChange={(e) => setCalcFiscalYear(Number(e.target.value))}
                sx={{ width: 150 }}
              />
              <Button
                variant="contained"
                size="small"
                onClick={handleCalculate}
                disabled={calculateMutation.isPending || !calcPeriod}
              >
                {calculateMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}
                Calcular
              </Button>
              {calcPreviewRows.length > 0 && (
                <Button
                  variant="contained"
                  color="success"
                  size="small"
                  onClick={handlePost}
                  disabled={postMutation.isPending}
                >
                  {postMutation.isPending ? <CircularProgress size={18} sx={{ mr: 1 }} /> : null}
                  Publicar
                </Button>
              )}
              <Chip label="BA VEN-NIF 2 / NIC 29" size="small" color="secondary" variant="outlined" />
            </Stack>
            {calculateMutation.isError && (
              <Alert severity="error" sx={{ mx: 2, mb: 1 }}>
                Error al calcular: {(calculateMutation.error as any)?.message ?? "Error desconocido"}
              </Alert>
            )}
            {postMutation.isSuccess && (
              <Alert severity="success" sx={{ mx: 2, mb: 1 }}>
                Ajuste publicado exitosamente.
              </Alert>
            )}
            <Box sx={{ flex: 1, minHeight: 0, px: 2, pb: 2 }}>
              {calcPreviewRows.length > 0 ? (
                <ZenttoDataGrid
                  rows={calcPreviewRows}
                  columns={calcPreviewColumns}
                  pageSizeOptions={[25, 50]}
                  disableRowSelectionOnClick
                  getRowId={(row) => row.AccountCode ?? row.AccountId ?? row.id}
                  sx={{ border: "none" }}
                  mobileVisibleFields={['AccountCode', 'AdjustmentAmount']}
                  smExtraFields={['AccountName', 'HistoricalBalance']}
                />
              ) : (
                <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", minHeight: 200 }}>
                  <Typography color="text.secondary">
                    Seleccione periodo y ejercicio fiscal, luego presione "Calcular" para generar la vista previa del ajuste.
                  </Typography>
                </Box>
              )}
            </Box>
          </TabPanel>

          {/* ─── Tab 3: Historial ──────────────────────────── */}
          <TabPanel value={tab} index={3}>
            <Box sx={{ flex: 1, minHeight: 0, p: 2 }}>
              <ZenttoDataGrid
                rows={historialRows}
                columns={historialColumns}
                loading={historialQuery.isLoading}
                pageSizeOptions={[25, 50]}
                disableRowSelectionOnClick
                getRowId={(row) => row.InflationAdjustmentId ?? row.id}
                sx={{ border: "none" }}
                mobileVisibleFields={['PeriodCode', 'Status']}
                smExtraFields={['FiscalYear', 'TotalAdjustment']}
              />
            </Box>
          </TabPanel>
        </Paper>
      </Box>

      {/* ─── Dialog: Agregar Indice INPC ───────────────────── */}
      <Dialog open={indiceDialogOpen} onClose={() => setIndiceDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Agregar Índice INPC</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Periodo (YYYYMM)"
              size="small"
              fullWidth
              value={newIndice.periodCode}
              onChange={(e) => setNewIndice((v) => ({ ...v, periodCode: e.target.value }))}
              placeholder="202601"
            />
            <TextField
              label="Valor del Índice"
              type="number"
              size="small"
              fullWidth
              value={newIndice.indexValue}
              onChange={(e) => setNewIndice((v) => ({ ...v, indexValue: e.target.value }))}
            />
            <TextField
              label="Fuente / Referencia"
              size="small"
              fullWidth
              value={newIndice.sourceReference}
              onChange={(e) => setNewIndice((v) => ({ ...v, sourceReference: e.target.value }))}
              placeholder="Gaceta Oficial N..."
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIndiceDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSaveIndice}
            disabled={upsertIndiceMutation.isPending || !newIndice.periodCode || !newIndice.indexValue}
          >
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Dialog: Cambiar Clasificacion Monetaria ────────── */}
      <Dialog open={clasDialogRow != null} onClose={() => setClasDialogRow(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Clasificación monetaria</DialogTitle>
        <DialogContent>
          {clasDialogRow && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Typography variant="body2">
                <strong>Cuenta:</strong> {clasDialogRow.AccountCode} - {clasDialogRow.AccountName}
              </Typography>
              <Stack direction="row" spacing={1}>
                <Button
                  variant={clasNewValue === "MONETARY" ? "contained" : "outlined"}
                  size="small"
                  onClick={() => setClasNewValue("MONETARY")}
                >
                  Monetaria
                </Button>
                <Button
                  variant={clasNewValue === "NON_MONETARY" ? "contained" : "outlined"}
                  size="small"
                  onClick={() => setClasNewValue("NON_MONETARY")}
                >
                  No monetaria
                </Button>
              </Stack>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setClasDialogRow(null)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleSaveClasificacion}
            disabled={upsertClasMutation.isPending}
          >
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Dialog: Anular Ajuste ──────────────────────────── */}
      <Dialog open={voidDialogId != null} onClose={() => setVoidDialogId(null)}>
        <DialogTitle>Anular ajuste #{voidDialogId}</DialogTitle>
        <DialogContent>
          <TextField
            label="Motivo de anulación"
            fullWidth
            multiline
            rows={3}
            value={voidMotivo}
            onChange={(e) => setVoidMotivo(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setVoidDialogId(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleVoid}
            disabled={voidMutation.isPending}
          >
            Anular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
