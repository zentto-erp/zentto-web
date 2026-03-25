"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  Stack,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  IconButton,
  Alert,
  Tooltip,
  CircularProgress,
} from "@mui/material";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import { formatDateTime } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditLogs, useAuditLogDetail, type AuditLogFilter } from "../hooks/useAuditoria";
import type { ColumnDef } from "@zentto/datagrid-core";

const ACTION_COLORS: Record<string, "success" | "info" | "warning" | "error" | "default"> = {
  CREATE: "success",
  UPDATE: "info",
  DELETE: "error",
  VOID: "warning",
  LOGIN: "default",
};

const AUDIT_FILTERS: FilterFieldDef[] = [
  {
    field: "actionType", label: "Accion", type: "select",
    options: [
      { value: "CREATE", label: "CREATE" },
      { value: "UPDATE", label: "UPDATE" },
      { value: "DELETE", label: "DELETE" },
      { value: "VOID", label: "VOID" },
      { value: "LOGIN", label: "LOGIN" },
    ],
  },
  { field: "userName", label: "Usuario", type: "text" },
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
];

export default function AuditLogPage() {
  const { timeZone } = useTimezone();
  const [filter, setFilter] = useState<AuditLogFilter>({ page: 1, limit: 25 });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

const { data, isLoading } = useAuditLogs(filter);
  const detalle = useAuditLogDetail(selectedId);

  const rows = data?.data ?? [];
  const total = data?.total ?? 0;

  const columns: ColumnDef[] = [
    { field: "AuditLogId", header: "ID", width: 70 },
    {
      field: "CreatedAt",
      header: "Fecha",
      width: 160,
      renderCell: (p) => (p.value ? formatDateTime(p.value as string, { timeZone }) : "-"),
    },
    { field: "UserName", header: "Usuario", width: 120 },
    { field: "ModuleName", header: "Módulo", width: 120 },
    {
      field: "ActionType",
      header: "Acción",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value}
          size="small"
          color={ACTION_COLORS[p.value] ?? "default"}
          variant="outlined"
        />
      ),
    },
    { field: "EntityName", header: "Entidad", width: 130 },
    { field: "EntityId", header: "ID Entidad", width: 90 },
    { field: "Summary", header: "Descripción", flex: 1, minWidth: 200 },
    {
      field: "acciones",
      header: "",
      width: 60,
      sortable: false,
      renderCell: (p) => (
        <Tooltip title="Ver detalle">
          <IconButton size="small" onClick={() => setSelectedId(p.row.AuditLogId)}>
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ];

  const updateFilter = (key: string, value: string) => {
    setFilter((f) => ({ ...f, [key]: value || undefined, page: 1 }));
  };

  // Bind data to zentto-grid web component

  useEffect(() => {

    const el = gridRef.current;

    if (!el || !registered) return;

    el.columns = columns;

    el.rows = rows;

    el.loading = isLoading;

  }, [rows, isLoading, registered, columns]);


  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Bitácora de Auditoría" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filters */}
        <ZenttoFilterPanel
          filters={AUDIT_FILTERS}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              actionType: vals.actionType || undefined,
              userName: vals.userName || undefined,
              fechaDesde: vals.fechaDesde || undefined,
              fechaHasta: vals.fechaHasta || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar por modulo, entidad..."
          searchValue={filter.search || ""}
          onSearchChange={(v) => updateFilter("search", v)}
          defaultOpen
        />

        {/* Grid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
        ref={gridRef}
        export-filename="auditoria-audit-log-list"
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
        </Paper>
      </Box>

      {/* Detail Dialog */}
      <Dialog open={selectedId != null} onClose={() => setSelectedId(null)} maxWidth="md" fullWidth>
        <DialogTitle>Detalle de Auditoría #{selectedId}</DialogTitle>
        <DialogContent>
          {detalle.isLoading ? (
            <Typography>Cargando...</Typography>
          ) : detalle.data ? (
            <Stack spacing={2} mt={1}>
              <Stack direction="row" spacing={4}>
                <InfoField label="Fecha" value={detalle.data.CreatedAt ? formatDateTime(detalle.data.CreatedAt, { timeZone }) : "-"} />
                <InfoField label="Usuario" value={detalle.data.UserName ?? "-"} />
                <InfoField label="IP" value={detalle.data.IpAddress ?? "-"} />
              </Stack>
              <Stack direction="row" spacing={4}>
                <InfoField label="Módulo" value={detalle.data.ModuleName} />
                <InfoField label="Entidad" value={detalle.data.EntityName} />
                <InfoField label="ID Entidad" value={detalle.data.EntityId ?? "-"} />
                <InfoField label="Acción" value={detalle.data.ActionType} />
              </Stack>
              {detalle.data.Summary && <InfoField label="Descripción" value={detalle.data.Summary} />}
              {detalle.data.OldValues && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary">Valores Anteriores</Typography>
                  <Paper variant="outlined" sx={{ p: 1.5, fontFamily: "monospace", fontSize: "0.8rem", whiteSpace: "pre-wrap", maxHeight: 200, overflow: "auto", bgcolor: "#FFF3E0" }}>
                    {tryFormatJson(detalle.data.OldValues)}
                  </Paper>
                </Box>
              )}
              {detalle.data.NewValues && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary">Valores Nuevos</Typography>
                  <Paper variant="outlined" sx={{ p: 1.5, fontFamily: "monospace", fontSize: "0.8rem", whiteSpace: "pre-wrap", maxHeight: 200, overflow: "auto", bgcolor: "#E8F5E9" }}>
                    {tryFormatJson(detalle.data.NewValues)}
                  </Paper>
                </Box>
              )}
            </Stack>
          ) : (
            <Alert severity="info">No se encontraron datos</Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

function InfoField({ label, value }: { label: string; value: string }) {
  return (
    <Box>
      <Typography variant="caption" color="text.secondary">{label}</Typography>
      <Typography variant="body2" fontWeight={500}>{value}</Typography>
    </Box>
  );
}

function tryFormatJson(str: string): string {
  try {
    return JSON.stringify(JSON.parse(str), null, 2);
  } catch {
    return str;
  }
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
