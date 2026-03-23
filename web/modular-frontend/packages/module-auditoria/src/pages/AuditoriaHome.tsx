"use client";

import React from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Paper,
  Typography,
  Skeleton,
  Stack,
  Chip,
  Card,
  CardActionArea,
  CardContent,
} from "@mui/material";
import ListAltIcon from "@mui/icons-material/ListAlt";
import SettingsIcon from "@mui/icons-material/Settings";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import AssessmentIcon from "@mui/icons-material/Assessment";
import AddCircleOutlineIcon from "@mui/icons-material/AddCircleOutline";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import BlockIcon from "@mui/icons-material/Block";
import LoginIcon from "@mui/icons-material/Login";
import { formatCurrency, toDateOnly, formatDateTime } from "@zentto/shared-api";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import { useTimezone } from "@zentto/shared-auth";
import { useAuditDashboard } from "../hooks/useAuditoria";
import { brandColors } from "@zentto/shared-ui";

const ACTION_COLORS: Record<string, "success" | "info" | "warning" | "error" | "default"> = {
  CREATE: "success",
  UPDATE: "info",
  DELETE: "error",
  VOID: "warning",
  LOGIN: "default",
};

const ACTION_ICONS: Record<string, React.ReactElement> = {
  CREATE: <AddCircleOutlineIcon fontSize="small" />,
  UPDATE: <EditIcon fontSize="small" />,
  DELETE: <DeleteIcon fontSize="small" />,
  VOID: <BlockIcon fontSize="small" />,
  LOGIN: <LoginIcon fontSize="small" />,
};

const logColumns: ZenttoColDef[] = [
  { field: "CreatedAt", headerName: "Fecha", flex: 1.2, renderCell: (p) => p.value ? formatDateTime(p.value, {}) : "-" },
  { field: "UserName", headerName: "Usuario", flex: 1, renderCell: (p) => p.value ?? "-" },
  { field: "ModuleName", headerName: "Módulo", flex: 1 },
  {
    field: "ActionType",
    headerName: "Acción",
    flex: 1,
    renderCell: (p) => (
      <Chip
        icon={ACTION_ICONS[p.value as string]}
        label={p.value}
        size="small"
        color={ACTION_COLORS[p.value as string] ?? "default"}
        variant="outlined"
      />
    ),
  },
  { field: "Summary", headerName: "Descripción", flex: 2, renderCell: (p) => p.value ?? `${p.row.EntityName} ${p.row.EntityId ?? ""}` },
];

export default function AuditoriaHome() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const now = new Date();
  const fechaDesde = toDateOnly(new Date(now.getFullYear(), 0, 1), timeZone);
  const fechaHasta = toDateOnly(now, timeZone);

  const { data, isLoading } = useAuditDashboard(fechaDesde, fechaHasta);

  const stats = [
    { label: "Logs (24h)", value: data?.logsUltimas24h ?? 0, color: brandColors.statBlue },
    { label: "Creaciones", value: data?.totalCreates ?? 0, color: brandColors.success },
    { label: "Actualizaciones", value: data?.totalUpdates ?? 0, color: brandColors.statOrange },
    { label: "Eliminaciones", value: data?.totalDeletes ?? 0, color: brandColors.statRed },
  ];

  const shortcuts = [
    { label: "Bitácora", icon: <ListAltIcon />, path: "/auditoria/bitacora" },
    { label: "Config. Fiscal", icon: <SettingsIcon />, path: "/auditoria/fiscal" },
    { label: "Registros Fiscales", icon: <ReceiptLongIcon />, path: "/auditoria/fiscal-records" },
    { label: "Reportes", icon: <AssessmentIcon />, path: "/auditoria/reportes" },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Auditoría Fiscal" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, overflow: "auto" }}>
        {/* Stats Cards */}
        <Stack direction="row" spacing={2} mb={3} flexWrap="wrap" useFlexGap>
          {stats.map((s) => (
            <Paper
              key={s.label}
              sx={{ p: 2, minWidth: 160, flex: "1 1 160px", borderTop: `3px solid ${s.color}` }}
            >
              <Typography variant="body2" color="text.secondary">{s.label}</Typography>
              {isLoading ? (
                <Skeleton width={60} height={36} />
              ) : (
                <Typography variant="h5" fontWeight={700}>{s.value}</Typography>
              )}
            </Paper>
          ))}
        </Stack>

        <Stack direction={{ xs: "column", md: "row" }} spacing={3}>
          {/* Left: shortcuts + últimos logs */}
          <Box sx={{ flex: 2 }}>
            {/* Shortcuts */}
            <Typography variant="subtitle2" color="text.secondary" mb={1}>
              Accesos Rápidos
            </Typography>
            <Stack direction="row" spacing={2} mb={3} flexWrap="wrap" useFlexGap>
              {shortcuts.map((sc) => (
                <Card key={sc.label} variant="outlined" sx={{ flex: "1 1 140px" }}>
                  <CardActionArea onClick={() => router.push(sc.path)} sx={{ p: 2, textAlign: "center" }}>
                    <CardContent sx={{ p: 0 }}>
                      <Box sx={{ color: "primary.main", mb: 1 }}>{sc.icon}</Box>
                      <Typography variant="body2" fontWeight={600}>{sc.label}</Typography>
                    </CardContent>
                  </CardActionArea>
                </Card>
              ))}
            </Stack>

            {/* Últimos Logs */}
            <Typography variant="subtitle2" color="text.secondary" mb={1}>
              Últimas Acciones
            </Typography>
            <Paper variant="outlined" sx={{ overflow: "hidden" }}>
              {isLoading ? (
                <Box p={2}><Skeleton /><Skeleton /><Skeleton /></Box>
              ) : (data?.ultimosLogs ?? []).length === 0 ? (
                <Box p={2}>
                  <Typography variant="body2" color="text.secondary">
                    No hay registros de auditoría aún
                  </Typography>
                </Box>
              ) : (
                <ZenttoDataGrid
                  rows={(data?.ultimosLogs ?? []).slice(0, 10)}
                  columns={logColumns}
                  getRowId={(row: any) => row.AuditLogId ?? Math.random()}
                  hideToolbar
                  autoHeight
                />
              )}
            </Paper>
          </Box>

          {/* Right: Resumen */}
          <Box sx={{ flex: 1, minWidth: 240 }}>
            <Typography variant="subtitle2" color="text.secondary" mb={1}>
              Resumen del Período
            </Typography>
            <Paper variant="outlined" sx={{ p: 2 }}>
              {isLoading ? (
                <><Skeleton /><Skeleton /><Skeleton /></>
              ) : (
                <Stack spacing={1.5}>
                  <Row label="Total Registros" value={data?.totalLogs ?? 0} />
                  <Row label="Creaciones" value={data?.totalCreates ?? 0} />
                  <Row label="Actualizaciones" value={data?.totalUpdates ?? 0} />
                  <Row label="Eliminaciones" value={data?.totalDeletes ?? 0} />
                  <Row label="Anulaciones" value={data?.totalVoids ?? 0} />
                  <Row label="Logins" value={data?.totalLogins ?? 0} />
                </Stack>
              )}
            </Paper>
          </Box>
        </Stack>
      </Box>
    </Box>
  );
}

function Row({ label, value }: { label: string; value: number | string }) {
  return (
    <Stack direction="row" justifyContent="space-between">
      <Typography variant="body2" color="text.secondary">{label}</Typography>
      <Typography variant="body2" fontWeight={600}>{value}</Typography>
    </Stack>
  );
}
