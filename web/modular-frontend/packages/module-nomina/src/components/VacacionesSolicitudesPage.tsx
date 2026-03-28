"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, TextField, Stack, Dialog, DialogTitle, DialogContent, DialogActions,
  Chip, Alert,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import {
  useVacacionSolicitudesList, useAprobarSolicitud, useRechazarSolicitud,
  useCancelarSolicitud, useProcesarPagoVacaciones, type SolicitudFilter,
} from "../hooks/useVacacionesSolicitudes";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const statusColors: Record<string, "warning" | "success" | "error" | "info" | "default"> = {
  PENDIENTE: "warning", APROBADA: "success", RECHAZADA: "error", PROCESADA: "info", CANCELADA: "default",
};

const SVG_APPROVE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>';
const SVG_REJECT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>';
const SVG_PAY = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>';

const COLUMNS: ColumnDef[] = [
  { field: "RequestId", header: "ID", width: 70 },
  { field: "EmployeeCode", header: "Cédula", width: 120, sortable: true },
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 180, sortable: true },
  { field: "RequestDate", header: "Fecha Solicitud", width: 120 },
  { field: "StartDate", header: "Desde", width: 110 },
  { field: "EndDate", header: "Hasta", width: 110 },
  { field: "TotalDays", header: "Días", width: 70, type: "number" },
  { field: "IsPartial", header: "Parcial", width: 80 },
  { field: "Status", header: "Estado", width: 120, statusColors: { PENDIENTE: "warning", APROBADA: "success", RECHAZADA: "error", PROCESADA: "info", CANCELADA: "default" } },
  {
    field: "actions", header: "Acciones", type: "actions", width: 160, pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view" },
      { icon: SVG_APPROVE, label: "Aprobar", action: "approve", color: "#2e7d32" },
      { icon: SVG_REJECT, label: "Rechazar", action: "reject", color: "#dc2626" },
      { icon: SVG_PAY, label: "Generar pago", action: "pay", color: "#1976d2" },
    ],
  },
];

const GRID_ID = buildNominaGridId("vacaciones-solicitudes");

export default function VacacionesSolicitudesPage() {
  const gridRef = useRef<any>(null);
  const [filter, setFilter] = useState<SolicitudFilter>({ page: 1, limit: 50 });
  const [selectedRow, setSelectedRow] = useState<any>(null);
  const [rejectOpen, setRejectOpen] = useState(false);
  const [rejectId, setRejectId] = useState<number | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const { data, isLoading } = useVacacionSolicitudesList(filter);
  const aprobarMut = useAprobarSolicitud();
  const rechazarMut = useRechazarSolicitud();
  const cancelarMut = useCancelarSolicitud();
  const procesarPagoMut = useProcesarPagoVacaciones();
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  useNominaGridId(gridRef, GRID_ID);
  const { registered } = useNominaGridRegistration(layoutReady);

  const rows = data?.rows ?? data?.data ?? [];
  const totalCount = data?.total ?? data?.totalCount ?? rows.length;

  const showSuccess = (msg: string) => { setSuccessMsg(msg); setTimeout(() => setSuccessMsg(""), 4000); };

  const handleAprobar = async (id: number) => { await aprobarMut.mutateAsync(id); showSuccess("Solicitud aprobada exitosamente"); };
  const handleRechazar = async () => {
    if (!rejectId || !rejectReason) return;
    await rechazarMut.mutateAsync({ id: rejectId, reason: rejectReason });
    setRejectOpen(false); setRejectReason(""); setRejectId(null); showSuccess("Solicitud rechazada");
  };
  const handleProcesarPago = async (id: number) => { await procesarPagoMut.mutateAsync(id); showSuccess("Pago de vacaciones generado exitosamente"); };

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.RequestId ?? r.requestId ?? Math.random();
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setSelectedRow(row);
      if (action === "approve" && row.Status === "PENDIENTE") handleAprobar(row.RequestId);
      if (action === "reject" && row.Status === "PENDIENTE") { setRejectId(row.RequestId); setRejectOpen(true); }
      if (action === "pay" && row.Status === "APROBADA") handleProcesarPago(row.RequestId);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Typography variant="h6" fontWeight={600} mb={2}>Solicitudes de Vacaciones</Typography>
      {successMsg && <Alert severity="success" sx={{ mb: 2 }}>{successMsg}</Alert>}

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
      </Box>

      {/* Detail Dialog */}
      <Dialog open={selectedRow != null} onClose={() => setSelectedRow(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle Solicitud #{selectedRow?.RequestId}</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Stack spacing={1.5} mt={1}>
              <Typography variant="body2"><strong>Empleado:</strong> {selectedRow.EmployeeName} ({selectedRow.EmployeeCode})</Typography>
              <Typography variant="body2"><strong>Fecha Solicitud:</strong> {selectedRow.RequestDate}</Typography>
              <Typography variant="body2"><strong>Período:</strong> {selectedRow.StartDate} - {selectedRow.EndDate}</Typography>
              <Typography variant="body2"><strong>Total Días:</strong> {selectedRow.TotalDays}</Typography>
              <Typography variant="body2"><strong>Parcial:</strong> {selectedRow.IsPartial ? "Sí" : "No"}</Typography>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <Typography variant="body2"><strong>Estado:</strong></Typography>
                <Chip label={selectedRow.Status} size="small" color={statusColors[selectedRow.Status] || "default"} />
              </Box>
              {selectedRow.Notes && <Typography variant="body2"><strong>Notas:</strong> {selectedRow.Notes}</Typography>}
              {selectedRow.ApprovedBy && <Typography variant="body2"><strong>Aprobado por:</strong> {selectedRow.ApprovedBy}</Typography>}
              {selectedRow.RejectionReason && <Typography variant="body2"><strong>Motivo de rechazo:</strong> {selectedRow.RejectionReason}</Typography>}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          {selectedRow?.Status === "PENDIENTE" && (
            <>
              <Button color="success" onClick={() => { handleAprobar(selectedRow.RequestId); setSelectedRow(null); }}>Aprobar</Button>
              <Button color="error" onClick={() => { setRejectId(selectedRow.RequestId); setRejectOpen(true); setSelectedRow(null); }}>Rechazar</Button>
            </>
          )}
          {selectedRow?.Status === "APROBADA" && (
            <Button color="primary" onClick={() => { handleProcesarPago(selectedRow.RequestId); setSelectedRow(null); }}>Generar Pago</Button>
          )}
          <Button onClick={() => setSelectedRow(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={rejectOpen} onClose={() => setRejectOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Rechazar Solicitud</DialogTitle>
        <DialogContent>
          <TextField label="Motivo del rechazo" multiline rows={3} fullWidth value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} sx={{ mt: 1 }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setRejectOpen(false); setRejectReason(""); }}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleRechazar} disabled={!rejectReason || rechazarMut.isPending}>Rechazar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
