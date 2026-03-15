"use client";

import React, { useState, useMemo, useCallback } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Tab,
  Tabs,
  TextField,
  CircularProgress,
  Divider,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Card,
  CardContent,
  Skeleton,
  LinearProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import PrintIcon from "@mui/icons-material/Print";
import FileDownloadIcon from "@mui/icons-material/FileDownload";
import ZoomInIcon from "@mui/icons-material/ZoomIn";
import CloseIcon from "@mui/icons-material/Close";
import { formatCurrency, toDateOnly } from "@datqbox/shared-api";
import { useTimezone } from "@datqbox/shared-auth";
import {
  useLibroMayor,
  useBalanceComprobacion,
  useEstadoResultados,
  useBalanceGeneral,
  useLibroDiario,
} from "../hooks/useContabilidad";
import {
  useCashFlowReport,
  useAgingCxC,
  useAgingCxP,
  useFinancialRatios,
  useTaxSummary,
  useDrillDown,
  useBalanceCompMultiPeriod,
  usePnLMultiPeriod,
  type CashFlowSection,
  type AgingBucket,
  type FinancialRatio,
  type TaxSummaryRow,
  type DrillDownRow,
} from "../hooks/useContabilidadAdvanced";

// ─── Helpers ─────────────────────────────────────────────────

function TabPanel({
  children,
  value,
  index,
}: {
  children: React.ReactNode;
  value: number;
  index: number;
}) {
  return value === index ? (
    <Box pt={2} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {children}
    </Box>
  ) : null;
}

function SectionHeader({ title, total }: { title: string; total?: number }) {
  return (
    <Stack
      direction="row"
      justifyContent="space-between"
      py={1}
      px={1}
      sx={{ bgcolor: "grey.100", borderRadius: 1, mb: 0.5 }}
    >
      <Typography variant="subtitle1" fontWeight={700}>
        {title}
      </Typography>
      {total != null && (
        <Typography variant="subtitle1" fontWeight={700}>
          {formatCurrency(total)}
        </Typography>
      )}
    </Stack>
  );
}

function exportToCSV(rows: any[], columns: { field: string; headerName?: string }[], filename: string) {
  const headers = columns.map((c) => c.headerName).join(",");
  const csvRows = rows.map((row) =>
    columns.map((c) => {
      const val = row[c.field];
      if (val == null) return "";
      const str = String(val);
      return str.includes(",") ? `"${str}"` : str;
    }).join(",")
  );
  const csv = [headers, ...csvRows].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `${filename}.csv`;
  link.click();
}

// ─── Drill Down Dialog ───────────────────────────────────────

function DrillDownDialog({
  open,
  onClose,
  accountCode,
  accountName,
  fechaDesde,
  fechaHasta,
}: {
  open: boolean;
  onClose: () => void;
  accountCode: string;
  accountName?: string;
  fechaDesde: string;
  fechaHasta: string;
}) {
  const { data, isLoading } = useDrillDown(accountCode, fechaDesde, fechaHasta, open && !!accountCode);

  const rows: DrillDownRow[] = useMemo(() => {
    const items = data?.data ?? data?.rows ?? [];
    return items.map((r: any, i: number) => ({ ...r, _id: i }));
  }, [data]);

  const columns: GridColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "numeroAsiento", headerName: "N Asiento", width: 120 },
    { field: "tipoAsiento", headerName: "Tipo", width: 90 },
    { field: "concepto", headerName: "Concepto", flex: 1, minWidth: 200 },
    {
      field: "debe",
      headerName: "Debe",
      width: 130,
      type: "number",
      renderCell: (p) => (p.value ? formatCurrency(p.value) : "-"),
    },
    {
      field: "haber",
      headerName: "Haber",
      width: 130,
      type: "number",
      renderCell: (p) => (p.value ? formatCurrency(p.value) : "-"),
    },
    {
      field: "saldoAcum",
      headerName: "Saldo Acum.",
      width: 140,
      type: "number",
      renderCell: (p) => (
        <Typography variant="body2" fontWeight={600}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
  ];

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Stack direction="row" alignItems="center" justifyContent="space-between">
          <Typography variant="h6" fontWeight={600}>
            Drill-Down: {accountCode} {accountName ? `- ${accountName}` : ""}
          </Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Stack>
        <Typography variant="body2" color="text.secondary">
          {fechaDesde} a {fechaHasta}
        </Typography>
      </DialogTitle>
      <DialogContent>
        {isLoading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : rows.length === 0 ? (
          <Alert severity="info">No hay movimientos para esta cuenta en el periodo</Alert>
        ) : (
          <DataGrid
            rows={rows}
            columns={columns}
            getRowId={(r) => r._id}
            autoHeight
            disableRowSelectionOnClick
            initialState={{
              pagination: { paginationModel: { pageSize: 15 } },
            }}
            pageSizeOptions={[15, 50]}
          />
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cerrar</Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Financial Ratio Gauge ───────────────────────────────────

function RatioGauge({ ratio }: { ratio: FinancialRatio }) {
  // Simple gauge: linear progress capped at 200%
  const maxDisplay = ratio.unit === "%" ? 100 : 5;
  const progress = Math.min((Math.abs(ratio.value) / maxDisplay) * 100, 100);
  const isGood =
    ratio.name.toLowerCase().includes("liquidez")
      ? ratio.value >= 1
      : ratio.name.toLowerCase().includes("endeudamiento")
        ? ratio.value < 0.6
        : ratio.value > 0;

  return (
    <Card sx={{ borderRadius: 2, height: "100%" }}>
      <CardContent>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
          {ratio.name}
        </Typography>
        <Typography variant="h4" fontWeight={700} sx={{ color: isGood ? "success.main" : "error.main" }}>
          {ratio.value.toFixed(2)}{ratio.unit === "%" ? "%" : "x"}
        </Typography>
        <LinearProgress
          variant="determinate"
          value={progress}
          sx={{
            mt: 1,
            height: 8,
            borderRadius: 4,
            bgcolor: "grey.200",
            "& .MuiLinearProgress-bar": {
              bgcolor: isGood ? "success.main" : "error.main",
              borderRadius: 4,
            },
          }}
        />
        {ratio.benchmark != null && (
          <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: "block" }}>
            Benchmark: {ratio.benchmark.toFixed(2)}
          </Typography>
        )}
        <Chip
          label={ratio.category}
          size="small"
          variant="outlined"
          sx={{ mt: 1, fontSize: "0.7rem" }}
        />
      </CardContent>
    </Card>
  );
}

// ─── Main Component ──────────────────────────────────────────

export default function ReportesAvanzadosPage() {
  const { timeZone } = useTimezone();
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);

  const [tab, setTab] = useState(0);
  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [run, setRun] = useState(false);
  const [agingSubTab, setAgingSubTab] = useState(0);

  // Drill down state
  const [drillDown, setDrillDown] = useState<{
    accountCode: string;
    accountName?: string;
  } | null>(null);

  // Existing report hooks
  const libroDiario = useLibroDiario(fechaDesde, fechaHasta, run && tab === 0);
  const libroMayor = useLibroMayor(fechaDesde, fechaHasta, run && tab === 1);
  const balance = useBalanceComprobacion(fechaDesde, fechaHasta, run && tab === 2);
  const resultado = useEstadoResultados(fechaDesde, fechaHasta, run && tab === 3);
  const balanceGral = useBalanceGeneral(fechaCorte, run && tab === 4);

  // Advanced report hooks
  const cashFlow = useCashFlowReport(fechaDesde, fechaHasta, run && tab === 5);
  const agingCxC = useAgingCxC(fechaCorte, run && tab === 6 && agingSubTab === 0);
  const agingCxP = useAgingCxP(fechaCorte, run && tab === 6 && agingSubTab === 1);
  const ratios = useFinancialRatios(fechaCorte, run && tab === 7);
  const taxSummary = useTaxSummary(fechaDesde, fechaHasta, run && tab === 8);

  // Date range or single date needed
  const needsRange = [0, 1, 2, 3, 5, 8].includes(tab);
  const needsCorte = [4, 6, 7].includes(tab);

  const handlePrint = () => window.print();

  const fmtCol = (field: string, header: string, width = 140): GridColDef => ({
    field,
    headerName: header,
    width,
    type: "number",
    renderCell: (p) => (p.value != null ? formatCurrency(p.value) : "-"),
  });

  // ─── Libro Diario ───────────────────────────────────────
  const libroDiarioCols: GridColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "numeroAsiento", headerName: "N Asiento", width: 130 },
    { field: "tipoAsiento", headerName: "Tipo", width: 90 },
    { field: "concepto", headerName: "Concepto", width: 200 },
    { field: "codCuenta", headerName: "Cuenta", width: 110 },
    { field: "descripcionCuenta", headerName: "Descripcion", flex: 1, minWidth: 180 },
    fmtCol("debe", "Debe", 130),
    fmtCol("haber", "Haber", 130),
  ];

  // ─── Libro Mayor ────────────────────────────────────────
  const libroMayorCols: GridColDef[] = [
    {
      field: "codCuenta",
      headerName: "Cuenta",
      width: 120,
      renderCell: (p) => (
        <Tooltip title="Click para drill-down">
          <Typography
            variant="body2"
            sx={{
              fontFamily: "monospace",
              cursor: "pointer",
              color: "primary.main",
              textDecoration: "underline",
              "&:hover": { color: "primary.dark" },
            }}
            onClick={() =>
              setDrillDown({
                accountCode: p.value,
                accountName: p.row.descripcion,
              })
            }
          >
            {p.value}
          </Typography>
        </Tooltip>
      ),
    },
    { field: "descripcion", headerName: "Descripcion", flex: 1 },
    fmtCol("debe", "Debe"),
    fmtCol("haber", "Haber"),
    fmtCol("saldo", "Saldo"),
  ];

  // ─── Balance Comprobacion ───────────────────────────────
  const balanceCols: GridColDef[] = [
    {
      field: "codCuenta",
      headerName: "Cuenta",
      width: 120,
      renderCell: (p) => (
        <Typography
          variant="body2"
          sx={{
            fontFamily: "monospace",
            cursor: "pointer",
            color: "primary.main",
            "&:hover": { textDecoration: "underline" },
          }}
          onClick={() =>
            setDrillDown({
              accountCode: p.value,
              accountName: p.row.descripcion,
            })
          }
        >
          {p.value}
        </Typography>
      ),
    },
    { field: "descripcion", headerName: "Descripcion", flex: 1 },
    fmtCol("totalDebe", "Debe"),
    fmtCol("totalHaber", "Haber"),
    fmtCol("saldo", "Saldo"),
  ];

  // ─── Aging columns ─────────────────────────────────────
  const agingCols: GridColDef[] = [
    { field: "entity", headerName: "Codigo", width: 120 },
    { field: "entityName", headerName: "Nombre", flex: 1, minWidth: 180 },
    fmtCol("current", "Corriente", 120),
    fmtCol("days30", "1-30 dias", 120),
    fmtCol("days60", "31-60 dias", 120),
    fmtCol("days90", "61-90 dias", 120),
    fmtCol("over90", ">90 dias", 120),
    {
      field: "total",
      headerName: "Total",
      width: 140,
      type: "number",
      renderCell: (p) => (
        <Typography variant="body2" fontWeight={700}>
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
  ];

  // ─── Tax columns ───────────────────────────────────────
  const taxCols: GridColDef[] = [
    { field: "taxType", headerName: "Tipo", width: 100 },
    { field: "taxName", headerName: "Impuesto", flex: 1, minWidth: 200 },
    fmtCol("base", "Base Imponible", 150),
    fmtCol("taxAmount", "Monto Impuesto", 150),
    fmtCol("total", "Total", 150),
  ];

  // Generic report data render
  const renderNotRun = () => (
    <Alert severity="info">Seleccione el rango y presione &quot;Generar&quot;</Alert>
  );

  const renderLoading = () => (
    <Box display="flex" justifyContent="center" p={4}>
      <CircularProgress />
    </Box>
  );

  const renderError = (err: unknown) => (
    <Alert severity="error">Error: {String(err)}</Alert>
  );

  // Export helpers
  const getExportFilename = () => {
    const names = [
      "libro-diario", "libro-mayor", "balance-comprobacion",
      "estado-resultados", "balance-general", "flujo-efectivo",
      "aging", "ratios", "impuestos",
    ];
    return `${names[tab] || "reporte"}_${fechaDesde}_${fechaHasta}`;
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Tab Header */}
      <Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
        <Tabs
          value={tab}
          onChange={(_, v) => {
            setTab(v);
            setRun(false);
          }}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ "& .MuiTab-root": { minWidth: "auto", px: 1.5 } }}
        >
          <Tab label="Libro Diario" />
          <Tab label="Libro Mayor" />
          <Tab label="Balance Comp." />
          <Tab label="Estado Result." />
          <Tab label="Balance General" />
          <Tab label="Flujo Efectivo" />
          <Tab label="Aging CxC/CxP" />
          <Tab label="Ratios" />
          <Tab label="Fiscal" />
        </Tabs>
        {run && (
          <Stack direction="row" spacing={0.5} sx={{ "@media print": { display: "none" } }}>
            <Tooltip title="Exportar CSV">
              <IconButton onClick={() => {
                // Get current tab data for export
                const tabDataMap: Record<number, any> = {
                  0: libroDiario.data?.rows,
                  1: libroMayor.data?.rows,
                  2: balance.data?.rows,
                };
                const exportData = tabDataMap[tab];
                if (exportData) {
                  const cols = tab === 0 ? libroDiarioCols : tab === 1 ? libroMayorCols : balanceCols;
                  exportToCSV(exportData, cols, getExportFilename());
                }
              }}>
                <FileDownloadIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Imprimir">
              <IconButton onClick={handlePrint}>
                <PrintIcon />
              </IconButton>
            </Tooltip>
          </Stack>
        )}
      </Stack>

      {/* Date Controls */}
      <Stack
        direction="row"
        spacing={2}
        mt={1}
        mb={2}
        alignItems="center"
        sx={{ "@media print": { display: "none" } }}
      >
        {needsRange && (
          <>
            <TextField
              label="Desde"
              type="date"
              size="small"
              InputLabelProps={{ shrink: true }}
              value={fechaDesde}
              onChange={(e) => setFechaDesde(e.target.value)}
            />
            <TextField
              label="Hasta"
              type="date"
              size="small"
              InputLabelProps={{ shrink: true }}
              value={fechaHasta}
              onChange={(e) => setFechaHasta(e.target.value)}
            />
          </>
        )}
        {needsCorte && (
          <TextField
            label="Fecha de Corte"
            type="date"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={fechaCorte}
            onChange={(e) => setFechaCorte(e.target.value)}
          />
        )}
        <Button variant="contained" onClick={() => setRun(true)}>
          Generar
        </Button>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        {/* Tab 0: Libro Diario */}
        <TabPanel value={tab} index={0}>
          {!run ? renderNotRun() : libroDiario.isLoading ? renderLoading() : libroDiario.error ? renderError(libroDiario.error) : (
            <DataGrid
              rows={(libroDiario.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={libroDiarioCols}
              getRowId={(r) => r._id}
              disableRowSelectionOnClick
              sx={{ flex: 1 }}
            />
          )}
        </TabPanel>

        {/* Tab 1: Libro Mayor */}
        <TabPanel value={tab} index={1}>
          {!run ? renderNotRun() : libroMayor.isLoading ? renderLoading() : (
            <DataGrid
              rows={(libroMayor.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={libroMayorCols}
              getRowId={(r) => r._id}
              disableRowSelectionOnClick
              sx={{ flex: 1 }}
            />
          )}
        </TabPanel>

        {/* Tab 2: Balance de Comprobacion */}
        <TabPanel value={tab} index={2}>
          {!run ? renderNotRun() : balance.isLoading ? renderLoading() : (
            <DataGrid
              rows={(balance.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={balanceCols}
              getRowId={(r) => r._id}
              disableRowSelectionOnClick
              sx={{ flex: 1 }}
            />
          )}
        </TabPanel>

        {/* Tab 3: Estado de Resultados */}
        <TabPanel value={tab} index={3}>
          {!run ? renderNotRun() : resultado.isLoading ? renderLoading() : resultado.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              <SectionHeader title="INGRESOS" total={resultado.data.resumen?.ingresos} />
              {(resultado.data.detalle ?? [])
                .filter((item: any) => item.tipo === "I")
                .map((item: any, i: number) => (
                  <Stack
                    key={`i-${i}`}
                    direction="row"
                    justifyContent="space-between"
                    py={0.4}
                    px={2}
                    borderBottom="1px solid #f0f0f0"
                    sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                    onClick={() =>
                      setDrillDown({
                        accountCode: item.codCuenta,
                        accountName: item.cuenta || item.descripcion,
                      })
                    }
                  >
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Stack direction="row" alignItems="center" spacing={0.5}>
                      <Typography variant="body2" fontWeight={500}>
                        {formatCurrency(item.monto ?? item.saldo ?? 0)}
                      </Typography>
                      <ZoomInIcon sx={{ fontSize: 14, color: "text.secondary" }} />
                    </Stack>
                  </Stack>
                ))}

              <Box my={2} />

              <SectionHeader title="COSTOS Y GASTOS" total={resultado.data.resumen?.gastos} />
              {(resultado.data.detalle ?? [])
                .filter((item: any) => item.tipo === "G")
                .map((item: any, i: number) => (
                  <Stack
                    key={`g-${i}`}
                    direction="row"
                    justifyContent="space-between"
                    py={0.4}
                    px={2}
                    borderBottom="1px solid #f0f0f0"
                    sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                    onClick={() =>
                      setDrillDown({
                        accountCode: item.codCuenta,
                        accountName: item.cuenta || item.descripcion,
                      })
                    }
                  >
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Stack direction="row" alignItems="center" spacing={0.5}>
                      <Typography variant="body2" fontWeight={500}>
                        {formatCurrency(item.monto ?? item.saldo ?? 0)}
                      </Typography>
                      <ZoomInIcon sx={{ fontSize: 14, color: "text.secondary" }} />
                    </Stack>
                  </Stack>
                ))}

              <Divider sx={{ my: 2, borderWidth: 2 }} />

              <Stack
                direction="row"
                justifyContent="space-between"
                py={1.5}
                px={1}
                sx={{
                  bgcolor: (resultado.data.resumen?.resultado ?? 0) >= 0 ? "success.light" : "error.light",
                  borderRadius: 1,
                }}
              >
                <Typography variant="h6" fontWeight={700}>
                  {(resultado.data.resumen?.resultado ?? 0) >= 0 ? "UTILIDAD NETA" : "PERDIDA NETA"}
                </Typography>
                <Typography variant="h6" fontWeight={700}>
                  {formatCurrency(Math.abs(resultado.data.resumen?.resultado ?? 0))}
                </Typography>
              </Stack>
            </Box>
          ) : renderNotRun()}
        </TabPanel>

        {/* Tab 4: Balance General */}
        <TabPanel value={tab} index={4}>
          {!run ? renderNotRun() : balanceGral.isLoading ? renderLoading() : balanceGral.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              <SectionHeader title="ACTIVOS" total={balanceGral.data.resumen?.totalActivo} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "A")
                .map((item: any, i: number) => (
                  <Stack
                    key={`a-${i}`}
                    direction="row"
                    justifyContent="space-between"
                    py={0.4}
                    px={2}
                    borderBottom="1px solid #f0f0f0"
                    sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                    onClick={() =>
                      setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })
                    }
                  >
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatCurrency(item.saldo ?? 0)}
                    </Typography>
                  </Stack>
                ))}

              <Box my={2} />

              <SectionHeader title="PASIVOS" total={balanceGral.data.resumen?.totalPasivo} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "P")
                .map((item: any, i: number) => (
                  <Stack
                    key={`p-${i}`}
                    direction="row"
                    justifyContent="space-between"
                    py={0.4}
                    px={2}
                    borderBottom="1px solid #f0f0f0"
                    sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                    onClick={() =>
                      setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })
                    }
                  >
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatCurrency(item.saldo ?? 0)}
                    </Typography>
                  </Stack>
                ))}

              <Box my={2} />

              <SectionHeader title="PATRIMONIO" total={balanceGral.data.resumen?.totalPatrimonio} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "C")
                .map((item: any, i: number) => (
                  <Stack
                    key={`c-${i}`}
                    direction="row"
                    justifyContent="space-between"
                    py={0.4}
                    px={2}
                    borderBottom="1px solid #f0f0f0"
                    sx={{ cursor: "pointer", "&:hover": { bgcolor: "action.hover" } }}
                    onClick={() =>
                      setDrillDown({ accountCode: item.codCuenta, accountName: item.cuenta || item.descripcion })
                    }
                  >
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatCurrency(item.saldo ?? 0)}
                    </Typography>
                  </Stack>
                ))}

              <Divider sx={{ my: 2, borderWidth: 2 }} />

              <Stack spacing={1}>
                <Stack direction="row" justifyContent="space-between" px={1}>
                  <Typography variant="subtitle1" fontWeight={700}>Total Activos</Typography>
                  <Typography variant="subtitle1" fontWeight={700}>
                    {formatCurrency(balanceGral.data.resumen?.totalActivo ?? 0)}
                  </Typography>
                </Stack>
                <Stack direction="row" justifyContent="space-between" px={1}>
                  <Typography variant="subtitle1" fontWeight={700}>Total Pasivo + Patrimonio</Typography>
                  <Typography variant="subtitle1" fontWeight={700}>
                    {formatCurrency(balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0)}
                  </Typography>
                </Stack>
                <Box sx={{ bgcolor: "primary.light", borderRadius: 1, p: 1 }}>
                  <Stack direction="row" justifyContent="space-between">
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">
                      Diferencia (debe ser 0)
                    </Typography>
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">
                      {formatCurrency(
                        (balanceGral.data.resumen?.totalActivo ?? 0) -
                          (balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0)
                      )}
                    </Typography>
                  </Stack>
                </Box>
              </Stack>
            </Box>
          ) : renderNotRun()}
        </TabPanel>

        {/* Tab 5: Flujo de Efectivo */}
        <TabPanel value={tab} index={5}>
          {!run ? renderNotRun() : cashFlow.isLoading ? renderLoading() : cashFlow.error ? renderError(cashFlow.error) : (
            <Box p={2} sx={{ overflow: "auto" }}>
              {(() => {
                const sections: CashFlowSection[] =
                  cashFlow.data?.data ?? cashFlow.data?.sections ?? cashFlow.data?.rows ?? [];
                if (sections.length === 0) {
                  return <Alert severity="info">No hay datos de flujo de efectivo</Alert>;
                }

                let grandTotal = 0;
                return (
                  <>
                    {sections.map((section, idx) => {
                      grandTotal += section.total ?? 0;
                      return (
                        <Box key={idx} sx={{ mb: 3 }}>
                          <SectionHeader title={section.section} total={section.total} />
                          {(section.items ?? []).map((item, i) => (
                            <Stack
                              key={i}
                              direction="row"
                              justifyContent="space-between"
                              py={0.4}
                              px={2}
                              borderBottom="1px solid #f0f0f0"
                            >
                              <Typography variant="body2">{item.description}</Typography>
                              <Typography
                                variant="body2"
                                fontWeight={500}
                                sx={{ color: item.amount >= 0 ? "success.main" : "error.main" }}
                              >
                                {formatCurrency(item.amount)}
                              </Typography>
                            </Stack>
                          ))}
                        </Box>
                      );
                    })}

                    <Divider sx={{ my: 2, borderWidth: 2 }} />
                    <Stack direction="row" justifyContent="space-between" px={1}>
                      <Typography variant="h6" fontWeight={700}>
                        Variacion Neta de Efectivo
                      </Typography>
                      <Typography
                        variant="h6"
                        fontWeight={700}
                        sx={{ color: grandTotal >= 0 ? "success.main" : "error.main" }}
                      >
                        {formatCurrency(grandTotal)}
                      </Typography>
                    </Stack>
                  </>
                );
              })()}
            </Box>
          )}
        </TabPanel>

        {/* Tab 6: Aging CxC/CxP */}
        <TabPanel value={tab} index={6}>
          {!run ? renderNotRun() : (
            <Box>
              <Tabs
                value={agingSubTab}
                onChange={(_, v) => setAgingSubTab(v)}
                sx={{ mb: 2 }}
              >
                <Tab label="Cuentas por Cobrar" />
                <Tab label="Cuentas por Pagar" />
              </Tabs>

              {agingSubTab === 0 && (
                agingCxC.isLoading ? renderLoading() : agingCxC.error ? renderError(agingCxC.error) : (
                  <DataGrid
                    rows={((agingCxC.data?.data ?? agingCxC.data?.rows ?? []) as AgingBucket[]).map(
                      (r, i) => ({ ...r, _id: i })
                    )}
                    columns={agingCols}
                    getRowId={(r) => r._id}
                    autoHeight
                    disableRowSelectionOnClick
                  />
                )
              )}

              {agingSubTab === 1 && (
                agingCxP.isLoading ? renderLoading() : agingCxP.error ? renderError(agingCxP.error) : (
                  <DataGrid
                    rows={((agingCxP.data?.data ?? agingCxP.data?.rows ?? []) as AgingBucket[]).map(
                      (r, i) => ({ ...r, _id: i })
                    )}
                    columns={agingCols}
                    getRowId={(r) => r._id}
                    autoHeight
                    disableRowSelectionOnClick
                  />
                )
              )}
            </Box>
          )}
        </TabPanel>

        {/* Tab 7: Ratios Financieros */}
        <TabPanel value={tab} index={7}>
          {!run ? renderNotRun() : ratios.isLoading ? renderLoading() : ratios.error ? renderError(ratios.error) : (
            <Box p={2}>
              {(() => {
                const ratioList: FinancialRatio[] =
                  ratios.data?.data ?? ratios.data?.rows ?? [];
                if (ratioList.length === 0) {
                  return <Alert severity="info">No hay datos de ratios financieros</Alert>;
                }

                // Group by category
                const categories = new Map<string, FinancialRatio[]>();
                for (const r of ratioList) {
                  const cat = r.category || "General";
                  if (!categories.has(cat)) categories.set(cat, []);
                  categories.get(cat)!.push(r);
                }

                return Array.from(categories.entries()).map(([cat, items]) => (
                  <Box key={cat} sx={{ mb: 3 }}>
                    <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1.5 }}>
                      {cat}
                    </Typography>
                    <Grid container spacing={2}>
                      {items.map((ratio, i) => (
                        <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }} key={i}>
                          <RatioGauge ratio={ratio} />
                        </Grid>
                      ))}
                    </Grid>
                  </Box>
                ));
              })()}
            </Box>
          )}
        </TabPanel>

        {/* Tab 8: Reporte Fiscal */}
        <TabPanel value={tab} index={8}>
          {!run ? renderNotRun() : taxSummary.isLoading ? renderLoading() : taxSummary.error ? renderError(taxSummary.error) : (
            <Box>
              {(() => {
                const rows: TaxSummaryRow[] = (
                  taxSummary.data?.data ?? taxSummary.data?.rows ?? []
                ).map((r: any, i: number) => ({ ...r, _id: i }));

                if (rows.length === 0) {
                  return <Alert severity="info">No hay datos fiscales para este periodo</Alert>;
                }

                const totalBase = rows.reduce((s, r) => s + (r.base ?? 0), 0);
                const totalTax = rows.reduce((s, r) => s + (r.taxAmount ?? 0), 0);
                const totalTotal = rows.reduce((s, r) => s + (r.total ?? 0), 0);

                return (
                  <>
                    {/* Summary cards */}
                    <Grid container spacing={2} sx={{ mb: 3 }}>
                      <Grid size={{ xs: 4 }}>
                        <Card sx={{ borderRadius: 2, borderTop: "3px solid #1565c0" }}>
                          <CardContent>
                            <Typography variant="h5" fontWeight={700} color="primary.main">
                              {formatCurrency(totalBase)}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Base Imponible Total
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                      <Grid size={{ xs: 4 }}>
                        <Card sx={{ borderRadius: 2, borderTop: "3px solid #e65100" }}>
                          <CardContent>
                            <Typography variant="h5" fontWeight={700} sx={{ color: "#e65100" }}>
                              {formatCurrency(totalTax)}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Total Impuestos
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                      <Grid size={{ xs: 4 }}>
                        <Card sx={{ borderRadius: 2, borderTop: "3px solid #2e7d32" }}>
                          <CardContent>
                            <Typography variant="h5" fontWeight={700} color="success.main">
                              {formatCurrency(totalTotal)}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Total con Impuesto
                            </Typography>
                          </CardContent>
                        </Card>
                      </Grid>
                    </Grid>

                    <DataGrid
                      rows={rows}
                      columns={taxCols}
                      getRowId={(r) => r._id}
                      autoHeight
                      disableRowSelectionOnClick
                    />
                  </>
                );
              })()}
            </Box>
          )}
        </TabPanel>
      </Paper>

      {/* Drill Down Dialog */}
      {drillDown && (
        <DrillDownDialog
          open={!!drillDown}
          onClose={() => setDrillDown(null)}
          accountCode={drillDown.accountCode}
          accountName={drillDown.accountName}
          fechaDesde={fechaDesde}
          fechaHasta={fechaHasta}
        />
      )}
    </Box>
  );
}
