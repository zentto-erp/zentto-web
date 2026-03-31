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
  Alert,
  CircularProgress,
} from "@mui/material";
import { ContextActionHeader } from "@zentto/shared-ui";
import { formatDateTime, useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditLogs, useAuditLogDetail, type AuditLogFilter } from "../hooks/useAuditoria";
import type { ColumnDef } from "@zentto/datagrid-core";
import { buildAuditoriaGridId, useAuditoriaGridRegistration } from "./zenttoGridPersistence";


const ACTION_COLORS: Record<string, "success" | "info" | "warning" | "error" | "default"> = {
  CREATE: "success",
  UPDATE: "info",
  DELETE: "error",
  VOID: "warning",
  LOGIN: "default",
};

const GRID_ID = buildAuditoriaGridId("audit-log", "list");

export default function AuditLogPage() {
  const { timeZone } = useTimezone();
  const [filter] = useState<AuditLogFilter>({ page: 1, limit: 25 });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const gridRef = useRef<any>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useAuditoriaGridRegistration(layoutReady);

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
      renderCell: (value: unknown) => (value ? formatDateTime(value as string, { timeZone }) : "-"),
    },
    { field: "UserName", header: "Usuario", width: 120 },
    { field: "ModuleName", header: "Módulo", width: 120 },
    {
      field: "ActionType",
      header: "Acción",
      width: 110,
      renderCell: ((value: unknown) => (
        <Chip
          label={value as string}
          size="small"
          color={ACTION_COLORS[value as string] ?? "default"}
          variant="outlined"
        />
      )) as unknown as ColumnDef["renderCell"],
    },
    { field: "EntityName", header: "Entidad", width: 130 },
    { field: "EntityId", header: "ID Entidad", width: 90 },
    { field: "Summary", header: "Descripción", flex: 1, minWidth: 200 },
    {
      field: "actions",
      header: "Acciones",
      type: "actions",
      width: 80,
      pin: "right",
      actions: [
        { icon: "view", label: "Ver detalle", action: "view", color: "#6b7280" },
      ],
    },
  ];

  // Bind data to zentto-grid web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setSelectedId(row.AuditLogId);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Bitácora de Auditoría" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Grid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
          <zentto-grid
        grid-id={GRID_ID}
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
