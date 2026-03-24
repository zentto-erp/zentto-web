"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
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
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatDateTime } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditLogs, useAuditLogDetail, type AuditLogFilter } from "../hooks/useAuditoria";

const ACTION_TYPES = ["", "CREATE", "UPDATE", "DELETE", "VOID", "LOGIN"];
const ACTION_COLORS: Record<string, "success" | "info" | "warning" | "error" | "default"> = {
  CREATE: "success",
  UPDATE: "info",
  DELETE: "error",
  VOID: "warning",
  LOGIN: "default",
};

export default function AuditLogPage() {
  const { timeZone } = useTimezone();
  const [filter, setFilter] = useState<AuditLogFilter>({ page: 1, limit: 25 });
  const [selectedId, setSelectedId] = useState<number | null>(null);

  const { data, isLoading } = useAuditLogs(filter);
  const detalle = useAuditLogDetail(selectedId);

  const rows = data?.data ?? [];
  const total = data?.total ?? 0;

  const columns: ZenttoColDef[] = [
    { field: "AuditLogId", headerName: "ID", width: 70 },
    {
      field: "CreatedAt",
      headerName: "Fecha",
      width: 160,
      renderCell: (p) => (p.value ? formatDateTime(p.value as string, { timeZone }) : "-"),
    },
    { field: "UserName", headerName: "Usuario", width: 120 },
    { field: "ModuleName", headerName: "Módulo", width: 120 },
    {
      field: "ActionType",
      headerName: "Acción",
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
    { field: "EntityName", headerName: "Entidad", width: 130 },
    { field: "EntityId", headerName: "ID Entidad", width: 90 },
    { field: "Summary", headerName: "Descripción", flex: 1, minWidth: 200 },
    {
      field: "acciones",
      headerName: "",
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

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Bitácora de Auditoría" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        {/* Filters */}
        <FormGrid spacing={2} sx={{ mb: 2 }}>
          <FormField xs={12} sm={4} md={2}>
            <DatePicker
              label="Desde"
              value={filter.fechaDesde ? dayjs(filter.fechaDesde) : null}
              onChange={(v) => updateFilter("fechaDesde", v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} sm={4} md={2}>
            <DatePicker
              label="Hasta"
              value={filter.fechaHasta ? dayjs(filter.fechaHasta) : null}
              onChange={(v) => updateFilter("fechaHasta", v ? v.format('YYYY-MM-DD') : '')}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} sm={4} md={2}>
            <TextField
              label="Módulo"
             
              fullWidth
              value={filter.moduleName || ""}
              onChange={(e) => updateFilter("moduleName", e.target.value)}
            />
          </FormField>
          <FormField xs={12} sm={4} md={2}>
            <TextField
              label="Usuario"
             
              fullWidth
              value={filter.userName || ""}
              onChange={(e) => updateFilter("userName", e.target.value)}
            />
          </FormField>
          <FormField xs={12} sm={4} md={2}>
            <TextField
              label="Acción"
              select
             
              fullWidth
              value={filter.actionType || ""}
              onChange={(e) => updateFilter("actionType", e.target.value)}
            >
              <MenuItem value="">Todas</MenuItem>
              {ACTION_TYPES.filter(Boolean).map((a) => (
                <MenuItem key={a} value={a}>{a}</MenuItem>
              ))}
            </TextField>
          </FormField>
          <FormField xs={12} sm={4} md={2}>
            <TextField
              label="Buscar"
             
              fullWidth
              value={filter.search || ""}
              onChange={(e) => updateFilter("search", e.target.value)}
            />
          </FormField>
        </FormGrid>

        {/* Grid */}
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            rowCount={total}
            pageSizeOptions={[25, 50, 100]}
            paginationMode="server"
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            disableRowSelectionOnClick
            getRowId={(row) => row.AuditLogId}
            sx={{ border: "none" }}
            mobileVisibleFields={['CreatedAt', 'ActionType']}
            smExtraFields={['UserName', 'ModuleName']}
          />
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
