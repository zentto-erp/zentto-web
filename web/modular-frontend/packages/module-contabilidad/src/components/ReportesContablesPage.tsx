"use client";

import React, { useState, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Stack,
  Tab,
  Tabs,
  CircularProgress,
  Alert,
  Divider,
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import dayjs from "dayjs";
import PrintIcon from "@mui/icons-material/Print";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import {
  useLibroMayor,
  useBalanceComprobacion,
  useEstadoResultados,
  useBalanceGeneral,
  useLibroDiario,
} from "../hooks/useContabilidad";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box pt={2} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

function SectionHeader({ title, total }: { title: string; total?: number }) {
  return (
    <Stack direction="row" justifyContent="space-between" py={1} px={1} sx={{ bgcolor: "grey.100", borderRadius: 1, mb: 0.5 }}>
      <Typography variant="subtitle1" fontWeight={700}>{title}</Typography>
      {total != null && <Typography variant="subtitle1" fontWeight={700}>{formatCurrency(total)}</Typography>}
    </Stack>
  );
}

export default function ReportesContablesPage() {
  const { timeZone } = useTimezone();
  const [tab, setTab] = useState(0);
  const [reportSearch, setReportSearch] = useState("");
  const today = toDateOnly(new Date(), timeZone);
  const firstDay = toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone);
  const printRef = useRef<HTMLDivElement>(null);

  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [run, setRun] = useState(false);

  const libroDiario = useLibroDiario(fechaDesde, fechaHasta, run && tab === 0);
  const libroMayor = useLibroMayor(fechaDesde, fechaHasta, run && tab === 1);
  const balance = useBalanceComprobacion(fechaDesde, fechaHasta, run && tab === 2);
  const resultado = useEstadoResultados(fechaDesde, fechaHasta, run && tab === 3);
  const balanceGral = useBalanceGeneral(fechaCorte, run && tab === 4);

  const handlePrint = () => {
    window.print();
  };

  const fmtCol = (field: string, header: string, width = 140): ZenttoColDef => ({
    field,
    headerName: header,
    width,
    type: "number",
    aggregation: "sum",
    currency: "VES",
    renderCell: (p) => (p.value != null ? formatCurrency(p.value) : "-"),
  });

  // Libro Diario columns
  const libroDiarioCols: ZenttoColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "numeroAsiento", headerName: "N\u00B0 Asiento", width: 150 },
    { field: "tipoAsiento", headerName: "Tipo", width: 90 },
    { field: "concepto", headerName: "Concepto", width: 200 },
    { field: "codCuenta", headerName: "Cuenta", width: 110, cellClassName: () => "monospace-cell" },
    { field: "descripcionCuenta", headerName: "Descripci\u00F3n", flex: 1, minWidth: 180 },
    fmtCol("debe", "Debe", 130),
    fmtCol("haber", "Haber", 130),
  ];

  // Libro Mayor columns
  const libroMayorCols: ZenttoColDef[] = [
    { field: "codCuenta", headerName: "Cuenta", width: 120 },
    { field: "descripcion", headerName: "Descripci\u00F3n", flex: 1 },
    fmtCol("debe", "Debe"),
    fmtCol("haber", "Haber"),
    fmtCol("saldo", "Saldo"),
  ];

  // Balance Comprobacion columns
  const balanceCols: ZenttoColDef[] = [
    { field: "codCuenta", headerName: "Cuenta", width: 120 },
    { field: "descripcion", headerName: "Descripci\u00F3n", flex: 1 },
    fmtCol("totalDebe", "Debe"),
    fmtCol("totalHaber", "Haber"),
    fmtCol("saldo", "Saldo"),
  ];

  // Determine if we need date range or single date
  const needsRange = tab < 4;

  return (
    <Box ref={printRef} sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>

      <ZenttoFilterPanel
        filters={[] as FilterFieldDef[]}
        values={{}}
        onChange={() => {}}
        searchPlaceholder="Buscar en reportes..."
        searchValue={reportSearch}
        onSearchChange={setReportSearch}
      />

      <Stack direction="row" alignItems="center" justifyContent="space-between" mb={1}>
        <Tabs value={tab} onChange={(_, v) => { setTab(v); setRun(false); }} variant="scrollable" scrollButtons="auto">
          <Tab label="Libro diario" />
          <Tab label="Libro mayor" />
          <Tab label="Balance comprobación" />
          <Tab label="Estado de resultados" />
          <Tab label="Balance general" />
        </Tabs>
        {run && (
          <Tooltip title="Imprimir reporte">
            <IconButton onClick={handlePrint} sx={{ "@media print": { display: "none" } }}>
              <PrintIcon />
            </IconButton>
          </Tooltip>
        )}
      </Stack>

      <FormGrid spacing={2} sx={{ mt: 1, mb: 2, "@media print": { display: "none" } }} alignItems="center">
        {needsRange ? (
          <>
            <FormField xs={12} sm={4} md={3}>
              <DatePicker label="Desde" value={fechaDesde ? dayjs(fechaDesde) : null} onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            </FormField>
            <FormField xs={12} sm={4} md={3}>
              <DatePicker label="Hasta" value={fechaHasta ? dayjs(fechaHasta) : null} onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            </FormField>
          </>
        ) : (
          <FormField xs={12} sm={4} md={3}>
            <DatePicker label="Fecha de Corte" value={fechaCorte ? dayjs(fechaCorte) : null} onChange={(v) => setFechaCorte(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
          </FormField>
        )}
        <FormField xs={12} sm="auto">
          <Button variant="contained" onClick={() => setRun(true)}>
            Generar
          </Button>
        </FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>

        {/* Libro Diario */}
        <TabPanel value={tab} index={0}>
          {!run ? (
            <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          ) : libroDiario.isLoading ? (
            <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          ) : libroDiario.error ? (
            <Alert severity="error">Error al cargar libro diario: {String(libroDiario.error)}</Alert>
          ) : (
            <ZenttoDataGrid
            gridId="contabilidad-reportes-contables-diario"
              rows={(libroDiario.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={libroDiarioCols}
              getRowId={(r) => r._id}
              enableHeaderFilters
              disableRowSelectionOnClick
              initialState={{ sorting: { sortModel: [{ field: "fecha", sort: "asc" }] } }}
              sx={{
                "& .monospace-cell": { fontFamily: "monospace" },
                flex: 1,
              }}
              mobileVisibleFields={['fecha', 'concepto']}
              smExtraFields={['codCuenta', 'debe']}
              showTotals
              enableClipboard
            />
          )}
        </TabPanel>

        {/* Libro Mayor */}
        <TabPanel value={tab} index={1}>
          {!run ? (
            <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          ) : libroMayor.isLoading ? (
            <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          ) : (
            <ZenttoDataGrid
              gridId="contabilidad-reportes-contables-mayor"
              rows={(libroMayor.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={libroMayorCols}
              getRowId={(r) => r._id}
              enableHeaderFilters
              disableRowSelectionOnClick
              sx={{ flex: 1 }}
              mobileVisibleFields={['codCuenta', 'saldo']}
              smExtraFields={['descripcion', 'debe']}
              showTotals
              enableClipboard
            />
          )}
        </TabPanel>

        {/* Balance de Comprobaci\u00F3n */}
        <TabPanel value={tab} index={2}>
          {!run ? (
            <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          ) : balance.isLoading ? (
            <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          ) : (
            <ZenttoDataGrid
              gridId="contabilidad-reportes-contables-balance"
              rows={(balance.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={balanceCols}
              getRowId={(r) => r._id}
              enableHeaderFilters
              disableRowSelectionOnClick
              sx={{ flex: 1 }}
              mobileVisibleFields={['codCuenta', 'saldo']}
              smExtraFields={['descripcion', 'totalDebe']}
              showTotals
              enableClipboard
            />
          )}
        </TabPanel>

        {/* Estado de Resultados */}
        <TabPanel value={tab} index={3}>
          {!run ? (
            <Alert severity="info">Seleccione rango de fechas y presione &quot;Generar&quot;</Alert>
          ) : resultado.isLoading ? (
            <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          ) : resultado.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              {/* Ingresos Section */}
              <SectionHeader title="INGRESOS" total={resultado.data.resumen?.ingresos} />
              {(resultado.data.detalle ?? [])
                .filter((item: any) => item.tipo === "I")
                .map((item: any, i: number) => (
                  <Stack key={`i-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatCurrency(item.monto ?? item.saldo ?? 0)}
                    </Typography>
                  </Stack>
                ))}

              <Box my={2} />

              {/* Gastos Section */}
              <SectionHeader title="COSTOS Y GASTOS" total={resultado.data.resumen?.gastos} />
              {(resultado.data.detalle ?? [])
                .filter((item: any) => item.tipo === "G")
                .map((item: any, i: number) => (
                  <Stack key={`g-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
                    <Typography variant="body2" sx={{ fontFamily: "monospace", mr: 2, color: "text.secondary", minWidth: 80 }}>
                      {item.codCuenta}
                    </Typography>
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {item.cuenta || item.descripcion}
                    </Typography>
                    <Typography variant="body2" fontWeight={500}>
                      {formatCurrency(item.monto ?? item.saldo ?? 0)}
                    </Typography>
                  </Stack>
                ))}

              <Divider sx={{ my: 2, borderWidth: 2 }} />

              {/* Resultado */}
              <Stack direction="row" justifyContent="space-between" py={1.5} px={1} sx={{ bgcolor: resultado.data.resumen?.resultado >= 0 ? "success.light" : "error.light", borderRadius: 1 }}>
                <Typography variant="h6" fontWeight={700}>
                  {(resultado.data.resumen?.resultado ?? 0) >= 0 ? "UTILIDAD NETA" : "P\u00C9RDIDA NETA"}
                </Typography>
                <Typography variant="h6" fontWeight={700}>
                  {formatCurrency(Math.abs(resultado.data.resumen?.resultado ?? 0))}
                </Typography>
              </Stack>
            </Box>
          ) : (
            <Alert severity="info">Presione &quot;Generar&quot; para ver el reporte</Alert>
          )}
        </TabPanel>

        {/* Balance General */}
        <TabPanel value={tab} index={4}>
          {!run ? (
            <Alert severity="info">Seleccione fecha de corte y presione &quot;Generar&quot;</Alert>
          ) : balanceGral.isLoading ? (
            <Box display="flex" justifyContent="center" p={4}><CircularProgress /></Box>
          ) : balanceGral.data ? (
            <Box p={2} sx={{ overflow: "auto" }}>
              {/* Activos */}
              <SectionHeader title="ACTIVOS" total={balanceGral.data.resumen?.totalActivo} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "A")
                .map((item: any, i: number) => (
                  <Stack key={`a-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
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

              {/* Pasivos */}
              <SectionHeader title="PASIVOS" total={balanceGral.data.resumen?.totalPasivo} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "P")
                .map((item: any, i: number) => (
                  <Stack key={`p-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
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

              {/* Patrimonio */}
              <SectionHeader title="PATRIMONIO" total={balanceGral.data.resumen?.totalPatrimonio} />
              {(balanceGral.data.detalle ?? [])
                .filter((item: any) => item.tipo === "C")
                .map((item: any, i: number) => (
                  <Stack key={`c-${i}`} direction="row" justifyContent="space-between" py={0.4} px={2} borderBottom="1px solid #f0f0f0">
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

              {/* Totals */}
              <Stack spacing={1}>
                <Stack direction="row" justifyContent="space-between" px={1}>
                  <Typography variant="subtitle1" fontWeight={700}>Total Activos</Typography>
                  <Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalActivo ?? 0)}</Typography>
                </Stack>
                <Stack direction="row" justifyContent="space-between" px={1}>
                  <Typography variant="subtitle1" fontWeight={700}>Total Pasivo + Patrimonio</Typography>
                  <Typography variant="subtitle1" fontWeight={700}>{formatCurrency(balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0)}</Typography>
                </Stack>
                <Box sx={{ bgcolor: "primary.light", borderRadius: 1, p: 1 }}>
                  <Stack direction="row" justifyContent="space-between">
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">
                      Diferencia (debe ser 0)
                    </Typography>
                    <Typography variant="subtitle1" fontWeight={700} color="primary.contrastText">
                      {formatCurrency((balanceGral.data.resumen?.totalActivo ?? 0) - (balanceGral.data.resumen?.totalPasivoPatrimonio ?? 0))}
                    </Typography>
                  </Stack>
                </Box>
              </Stack>
            </Box>
          ) : (
            <Alert severity="info">Presione &quot;Generar&quot; para ver el balance</Alert>
          )}
        </TabPanel>
      </Paper>
    </Box>
  );
}
