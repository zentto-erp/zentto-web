"use client";

import React, { useState } from "react";
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
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useLibroMayor,
  useBalanceComprobacion,
  useEstadoResultados,
  useBalanceGeneral,
} from "../hooks/useContabilidad";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box pt={2}>{children}</Box> : null;
}

export default function ReportesContablesPage() {
  const [tab, setTab] = useState(0);
  const today = new Date().toISOString().slice(0, 10);
  const firstDay = new Date(new Date().getFullYear(), 0, 1).toISOString().slice(0, 10);

  const [fechaDesde, setFechaDesde] = useState(firstDay);
  const [fechaHasta, setFechaHasta] = useState(today);
  const [fechaCorte, setFechaCorte] = useState(today);
  const [run, setRun] = useState(false);

  const libroMayor = useLibroMayor(fechaDesde, fechaHasta, run && tab === 0);
  const balance = useBalanceComprobacion(fechaDesde, fechaHasta, run && tab === 1);
  const resultado = useEstadoResultados(fechaDesde, fechaHasta, run && tab === 2);
  const balanceGral = useBalanceGeneral(fechaCorte, run && tab === 3);

  const fmtCol = (field: string, header: string): GridColDef => ({
    field,
    headerName: header,
    width: 140,
    type: "number",
    renderCell: (p) => (p.value != null ? formatCurrency(p.value) : "-"),
  });

  const libroMayorCols: GridColDef[] = [
    { field: "codCuenta", headerName: "Cuenta", width: 120 },
    { field: "descripcion", headerName: "Descripción", flex: 1 },
    fmtCol("debe", "Debe"),
    fmtCol("haber", "Haber"),
    fmtCol("saldo", "Saldo"),
  ];

  const balanceCols: GridColDef[] = [
    { field: "codCuenta", headerName: "Cuenta", width: 120 },
    { field: "descripcion", headerName: "Descripción", flex: 1 },
    fmtCol("saldoAnterior", "Saldo Ant."),
    fmtCol("debe", "Debe"),
    fmtCol("haber", "Haber"),
    fmtCol("saldoFinal", "Saldo Final"),
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>

      <Tabs value={tab} onChange={(_, v) => { setTab(v); setRun(false); }}>
        <Tab label="Libro Mayor" />
        <Tab label="Balance Comprobación" />
        <Tab label="Estado de Resultados" />
        <Tab label="Balance General" />
      </Tabs>

      <Stack direction="row" spacing={2} mt={2} mb={2} alignItems="center">
        {tab < 3 ? (
          <>
            <TextField label="Desde" type="date" size="small" InputLabelProps={{ shrink: true }} value={fechaDesde} onChange={(e) => setFechaDesde(e.target.value)} />
            <TextField label="Hasta" type="date" size="small" InputLabelProps={{ shrink: true }} value={fechaHasta} onChange={(e) => setFechaHasta(e.target.value)} />
          </>
        ) : (
          <TextField label="Fecha de Corte" type="date" size="small" InputLabelProps={{ shrink: true }} value={fechaCorte} onChange={(e) => setFechaCorte(e.target.value)} />
        )}
        <Button variant="contained" onClick={() => setRun(true)}>
          Generar
        </Button>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        {/* Libro Mayor */}
        <TabPanel value={tab} index={0}>
          {libroMayor.isLoading ? <CircularProgress /> : (
            <DataGrid
              rows={(libroMayor.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={libroMayorCols}
              getRowId={(r) => r._id}
              disableRowSelectionOnClick
            />
          )}
        </TabPanel>

        {/* Balance de Comprobación */}
        <TabPanel value={tab} index={1}>
          {balance.isLoading ? <CircularProgress /> : (
            <DataGrid
              rows={(balance.data?.rows ?? []).map((r: any, i: number) => ({ ...r, _id: i }))}
              columns={balanceCols}
              getRowId={(r) => r._id}
              disableRowSelectionOnClick
            />
          )}
        </TabPanel>

        {/* Estado de Resultados */}
        <TabPanel value={tab} index={2}>
          {resultado.isLoading ? <CircularProgress /> : resultado.data ? (
            <Box p={2}>
              {(resultado.data.rows ?? resultado.data.data ?? []).map((item: any, i: number) => (
                <Stack key={i} direction="row" justifyContent="space-between" py={0.5} borderBottom="1px solid #eee">
                  <Typography variant="body2" fontWeight={item.nivel === 1 ? 700 : 400} pl={item.nivel * 2}>
                    {item.descripcion || item.codCuenta}
                  </Typography>
                  <Typography variant="body2" fontWeight={item.nivel === 1 ? 700 : 400}>
                    {formatCurrency(item.saldo ?? item.monto ?? 0)}
                  </Typography>
                </Stack>
              ))}
              {resultado.data.utilidadNeta != null && (
                <Stack direction="row" justifyContent="space-between" py={1} mt={1} borderTop="2px solid #333">
                  <Typography variant="h6" fontWeight={700}>Utilidad Neta</Typography>
                  <Typography variant="h6" fontWeight={700}>{formatCurrency(resultado.data.utilidadNeta)}</Typography>
                </Stack>
              )}
            </Box>
          ) : (
            <Alert severity="info">Presione &quot;Generar&quot; para ver el reporte</Alert>
          )}
        </TabPanel>

        {/* Balance General */}
        <TabPanel value={tab} index={3}>
          {balanceGral.isLoading ? <CircularProgress /> : balanceGral.data ? (
            <Box p={2}>
              {["activo", "pasivo", "patrimonio"].map((section) => {
                const items = balanceGral.data[section] ?? [];
                return (
                  <Box key={section} mb={2}>
                    <Typography variant="h6" fontWeight={700} textTransform="capitalize" mb={1}>
                      {section}
                    </Typography>
                    {items.map((item: any, i: number) => (
                      <Stack key={i} direction="row" justifyContent="space-between" py={0.3} pl={2}>
                        <Typography variant="body2">{item.descripcion || item.codCuenta}</Typography>
                        <Typography variant="body2">{formatCurrency(item.saldo ?? 0)}</Typography>
                      </Stack>
                    ))}
                  </Box>
                );
              })}
            </Box>
          ) : (
            <Alert severity="info">Presione &quot;Generar&quot; para ver el balance</Alert>
          )}
        </TabPanel>
      </Paper>
    </Box>
  );
}
