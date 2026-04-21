"use client";

import React, { useState, useEffect, useRef } from "react";
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
import { ContextActionHeader, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import PrintIcon from "@mui/icons-material/Print";
import { toDateOnly, formatDateTime, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditLogs, useFiscalRecords } from "../hooks/useAuditoria";
import type { ColumnDef } from "@zentto/datagrid-core";
import { buildAuditoriaGridId, useAuditoriaGridId, useAuditoriaGridRegistration } from "./zenttoGridPersistence";

const TAB_LABELS = ["Por Módulo", "Por Usuario", "Registros Fiscales"];
const GRID_ID = buildAuditoriaGridId("auditoria-reportes");

export default function AuditoriaReportesPage() {
  const { timeZone } = useTimezone();
  const [tab, setTab] = useState(0);
  const now = new Date();
  const [fechaDesde, setFechaDesde] = useState(
    toDateOnly(new Date(now.getFullYear(), now.getMonth(), 1), timeZone)
  );
  const [fechaHasta, setFechaHasta] = useState(toDateOnly(now, timeZone));
  const [run, setRun] = useState(false);
  const gridRef = useRef<any>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  useAuditoriaGridId(gridRef, GRID_ID);
  const { registered } = useAuditoriaGridRegistration(layoutReady);


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

  const moduleColumns: ColumnDef[] = [
    { field: "moduleName", header: "Módulo", flex: 1, minWidth: 150 },
    { field: "total", header: "Total", width: 100, type: "number" },
    { field: "creates", header: "Creaciones", width: 110, type: "number" },
    { field: "updates", header: "Actualizaciones", width: 130, type: "number" },
    { field: "deletes", header: "Eliminaciones", width: 120, type: "number" },
  ];

  const userColumns: ColumnDef[] = [
    { field: "userName", header: "Usuario", flex: 1, minWidth: 150 },
    { field: "total", header: "Total", width: 100, type: "number" },
    { field: "creates", header: "Creaciones", width: 110, type: "number" },
    { field: "updates", header: "Actualizaciones", width: 130, type: "number" },
    { field: "deletes", header: "Eliminaciones", width: 120, type: "number" },
  ];

  const fiscalColumns: ColumnDef[] = [
    { field: "FiscalRecordId", header: "ID", width: 70 },
    {
      field: "CreatedAt",
      header: "Fecha",
      width: 160,
      renderCell: (value: unknown) => (value ? formatDateTime(value as string, { timeZone }) : "-"),
    },
    { field: "InvoiceNumber", header: "N° Factura", width: 140 },
    { field: "InvoiceType", header: "Tipo", width: 100 },
    { field: "CountryCode", header: "País", width: 70 },
    {
      field: "SentToAuthority",
      header: "Enviado",
      width: 100,
      renderCell: ((value: unknown) => <Chip label={value ? "Sí" : "No"} size="small" color={value ? "success" : "default"} variant="outlined" />) as unknown as ColumnDef["renderCell"],
    },
    {
      field: "AuthorityStatus",
      header: "Estado",
      width: 120,
      renderCell: ((value: unknown) => <Chip label={(value as string) ?? "N/A"} size="small" color={value === "ACCEPTED" ? "success" : "default"} variant="outlined" />) as unknown as ColumnDef["renderCell"],
    },
  ];

  const isLoading = logsQuery.isLoading || fiscalQuery.isLoading;

  const fiscalRows = (fiscalQuery.data?.data ?? []).map((r: any, i: number) => ({
    id: r.FiscalRecordId ?? i,
    ...r,
  }));

  const rows = tab === 0 ? moduleRows : tab === 1 ? userRows : fiscalRows;
  const columns = tab === 0 ? moduleColumns : tab === 1 ? userColumns : fiscalColumns;

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, columns, isLoading, registered]);


  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Reportes de Auditoría" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filters */}
        <FormGrid spacing={2} sx={{ mb: 2 }} alignItems="center">
          <FormField xs={12} sm={3}>
            <DatePicker
              label="Desde"
              value={fechaDesde ? dayjs(fechaDesde) : null}
              onChange={(v) => { setFechaDesde(v ? v.format('YYYY-MM-DD') : ''); setRun(false); }}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} sm={3}>
            <DatePicker
              label="Hasta"
              value={fechaHasta ? dayjs(fechaHasta) : null}
              onChange={(v) => { setFechaHasta(v ? v.format('YYYY-MM-DD') : ''); setRun(false); }}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={6} sm="auto">
            <Button variant="contained" onClick={handleGenerar}>Generar</Button>
          </FormField>
          <FormField xs={6} sm="auto">
            <Button variant="outlined" startIcon={<PrintIcon />} onClick={() => window.print()}>
              Imprimir
            </Button>
          </FormField>
        </FormGrid>

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
          <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: (t) => `1px solid ${t.palette.divider}` }}>
            {tab === 0 && (
              <zentto-grid
        ref={gridRef}
        export-filename="auditoria-reportes-modulo"
        height="calc(100vh - 280px)"
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
            {tab === 1 && (
              <zentto-grid
        ref={gridRef}
        export-filename="auditoria-reportes-usuario"
        height="calc(100vh - 280px)"
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
            {tab === 2 && (
              <zentto-grid
        ref={gridRef}
        export-filename="auditoria-reportes-fiscal"
        height="calc(100vh - 280px)"
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
          </Paper>
        )}
      </Box>
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
