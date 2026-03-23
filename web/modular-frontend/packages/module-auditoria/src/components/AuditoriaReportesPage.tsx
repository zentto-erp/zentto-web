"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Stack,
  Tabs,
  Tab,
  Alert,
  CircularProgress,
  Chip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ContextActionHeader, ZenttoDataGrid } from "@zentto/shared-ui";
import PrintIcon from "@mui/icons-material/Print";
import { toDateOnly, formatDateTime } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditLogs, useFiscalRecords } from "../hooks/useAuditoria";

const TAB_LABELS = ["Por Módulo", "Por Usuario", "Registros Fiscales"];

export default function AuditoriaReportesPage() {
  const { timeZone } = useTimezone();
  const [tab, setTab] = useState(0);
  const now = new Date();
  const [fechaDesde, setFechaDesde] = useState(
    toDateOnly(new Date(now.getFullYear(), now.getMonth(), 1), timeZone)
  );
  const [fechaHasta, setFechaHasta] = useState(toDateOnly(now, timeZone));
  const [run, setRun] = useState(false);

  const logsQuery = useAuditLogs(
    run ? { fechaDesde, fechaHasta, limit: 500 } : undefined
  );
  const fiscalQuery = useFiscalRecords(
    run && tab === 2 ? { fechaDesde, fechaHasta, limit: 500 } : undefined
  );

  const handleGenerar = () => setRun(true);

  const allLogs: any[] = logsQuery.data?.data ?? [];

  // Agrupar por módulo
  const byModule: Record<string, { total: number; creates: number; updates: number; deletes: number }> = {};
  allLogs.forEach((l) => {
    if (!byModule[l.ModuleName]) byModule[l.ModuleName] = { total: 0, creates: 0, updates: 0, deletes: 0 };
    byModule[l.ModuleName].total++;
    if (l.ActionType === "CREATE") byModule[l.ModuleName].creates++;
    if (l.ActionType === "UPDATE") byModule[l.ModuleName].updates++;
    if (l.ActionType === "DELETE") byModule[l.ModuleName].deletes++;
  });
  const moduleRows = Object.entries(byModule)
    .map(([mod, v], i) => ({ id: i, moduleName: mod, ...v }))
    .sort((a, b) => b.total - a.total);

  // Agrupar por usuario
  const byUser: Record<string, { total: number; creates: number; updates: number; deletes: number }> = {};
  allLogs.forEach((l) => {
    const u = l.UserName ?? "Sistema";
    if (!byUser[u]) byUser[u] = { total: 0, creates: 0, updates: 0, deletes: 0 };
    byUser[u].total++;
    if (l.ActionType === "CREATE") byUser[u].creates++;
    if (l.ActionType === "UPDATE") byUser[u].updates++;
    if (l.ActionType === "DELETE") byUser[u].deletes++;
  });
  const userRows = Object.entries(byUser)
    .map(([user, v], i) => ({ id: i, userName: user, ...v }))
    .sort((a, b) => b.total - a.total);

  const moduleColumns: GridColDef[] = [
    { field: "moduleName", headerName: "Módulo", flex: 1, minWidth: 150 },
    { field: "total", headerName: "Total", width: 100, type: "number" },
    { field: "creates", headerName: "Creaciones", width: 110, type: "number" },
    { field: "updates", headerName: "Actualizaciones", width: 130, type: "number" },
    { field: "deletes", headerName: "Eliminaciones", width: 120, type: "number" },
  ];

  const userColumns: GridColDef[] = [
    { field: "userName", headerName: "Usuario", flex: 1, minWidth: 150 },
    { field: "total", headerName: "Total", width: 100, type: "number" },
    { field: "creates", headerName: "Creaciones", width: 110, type: "number" },
    { field: "updates", headerName: "Actualizaciones", width: 130, type: "number" },
    { field: "deletes", headerName: "Eliminaciones", width: 120, type: "number" },
  ];

  const fiscalColumns: GridColDef[] = [
    { field: "FiscalRecordId", headerName: "ID", width: 70 },
    {
      field: "CreatedAt",
      headerName: "Fecha",
      width: 160,
      renderCell: (p) => (p.value ? formatDateTime(p.value as string, { timeZone }) : "-"),
    },
    { field: "InvoiceNumber", headerName: "N° Factura", width: 140 },
    { field: "InvoiceType", headerName: "Tipo", width: 100 },
    { field: "CountryCode", headerName: "País", width: 70 },
    {
      field: "SentToAuthority",
      headerName: "Enviado",
      width: 100,
      renderCell: (p) => <Chip label={p.value ? "Sí" : "No"} size="small" color={p.value ? "success" : "default"} variant="outlined" />,
    },
    {
      field: "AuthorityStatus",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => <Chip label={p.value ?? "N/A"} size="small" color={p.value === "ACCEPTED" ? "success" : "default"} variant="outlined" />,
    },
  ];

  const isLoading = logsQuery.isLoading || fiscalQuery.isLoading;

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Reportes de Auditoría" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filters */}
        <Stack direction="row" spacing={2} mb={2} alignItems="center">
          <TextField
            label="Desde"
            type="date"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={fechaDesde}
            onChange={(e) => { setFechaDesde(e.target.value); setRun(false); }}
          />
          <TextField
            label="Hasta"
            type="date"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={fechaHasta}
            onChange={(e) => { setFechaHasta(e.target.value); setRun(false); }}
          />
          <Button variant="contained" onClick={handleGenerar}>Generar</Button>
          <Button variant="outlined" startIcon={<PrintIcon />} onClick={() => window.print()}>
            Imprimir
          </Button>
        </Stack>

        {/* Tabs */}
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
          {TAB_LABELS.map((l, i) => (
            <Tab key={i} label={l} />
          ))}
        </Tabs>

        {!run ? (
          <Alert severity="info">Seleccione un rango de fechas y presione Generar</Alert>
        ) : isLoading ? (
          <Box display="flex" justifyContent="center" py={4}><CircularProgress /></Box>
        ) : (
          <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
            {tab === 0 && (
              <ZenttoDataGrid
                rows={moduleRows}
                columns={moduleColumns}
                disableRowSelectionOnClick
                hideFooter={moduleRows.length <= 25}
                sx={{ border: "none" }}
                mobileVisibleFields={['moduleName', 'total']}
                smExtraFields={['creates', 'updates']}
              />
            )}
            {tab === 1 && (
              <ZenttoDataGrid
                rows={userRows}
                columns={userColumns}
                disableRowSelectionOnClick
                hideFooter={userRows.length <= 25}
                sx={{ border: "none" }}
                mobileVisibleFields={['userName', 'total']}
                smExtraFields={['creates', 'updates']}
              />
            )}
            {tab === 2 && (
              <ZenttoDataGrid
                rows={fiscalQuery.data?.data ?? []}
                columns={fiscalColumns}
                getRowId={(r) => r.FiscalRecordId}
                disableRowSelectionOnClick
                hideFooter={(fiscalQuery.data?.data ?? []).length <= 25}
                sx={{ border: "none" }}
                mobileVisibleFields={['CreatedAt', 'InvoiceNumber']}
                smExtraFields={['InvoiceType', 'AuthorityStatus']}
              />
            )}
          </Paper>
        )}
      </Box>
    </Box>
  );
}
