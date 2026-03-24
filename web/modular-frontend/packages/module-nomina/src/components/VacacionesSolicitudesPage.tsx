"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  Alert,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import CancelIcon from "@mui/icons-material/Cancel";
import VisibilityIcon from "@mui/icons-material/Visibility";
import PaymentIcon from "@mui/icons-material/Payment";
import {
  useVacacionSolicitudesList,
  useAprobarSolicitud,
  useRechazarSolicitud,
  useCancelarSolicitud,
  useProcesarPagoVacaciones,
  type SolicitudFilter,
} from "../hooks/useVacacionesSolicitudes";

const statusColors: Record<string, "warning" | "success" | "error" | "info" | "default"> = {
  PENDIENTE: "warning",
  APROBADA: "success",
  RECHAZADA: "error",
  PROCESADA: "info",
  CANCELADA: "default",
};

export default function VacacionesSolicitudesPage() {
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

  const rows = data?.rows ?? data?.data ?? [];
  const totalCount = data?.total ?? data?.totalCount ?? rows.length;

  const showSuccess = (msg: string) => {
    setSuccessMsg(msg);
    setTimeout(() => setSuccessMsg(""), 4000);
  };

  const handleAprobar = async (id: number) => {
    await aprobarMut.mutateAsync(id);
    showSuccess("Solicitud aprobada exitosamente");
  };

  const handleRechazar = async () => {
    if (!rejectId || !rejectReason) return;
    await rechazarMut.mutateAsync({ id: rejectId, reason: rejectReason });
    setRejectOpen(false);
    setRejectReason("");
    setRejectId(null);
    showSuccess("Solicitud rechazada");
  };

  const handleCancelar = async (id: number) => {
    await cancelarMut.mutateAsync(id);
    showSuccess("Solicitud cancelada");
  };

  const handleProcesarPago = async (id: number) => {
    await procesarPagoMut.mutateAsync(id);
    showSuccess("Pago de vacaciones generado exitosamente");
  };

  const columns: ZenttoColDef[] = [
    { field: "RequestId", headerName: "ID", width: 70 },
    { field: "EmployeeCode", headerName: "Cédula", width: 120 },
    { field: "EmployeeName", headerName: "Empleado", flex: 1, minWidth: 180 },
    { field: "RequestDate", headerName: "Fecha Solicitud", width: 120 },
    { field: "StartDate", headerName: "Desde", width: 110 },
    { field: "EndDate", headerName: "Hasta", width: 110 },
    { field: "TotalDays", headerName: "Días", width: 70, type: "number" },
    {
      field: "IsPartial", headerName: "Parcial", width: 80,
      renderCell: (p) => p.value ? <Chip label="Sí" size="small" color="info" /> : null,
    },
    {
      field: "Status", headerName: "Estado", width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value}
          size="small"
          color={statusColors[p.value as string] || "default"}
        />
      ),
      statusColors: { 'PENDIENTE': 'warning', 'APROBADA': 'success', 'RECHAZADA': 'error', 'PROCESADA': 'info', 'CANCELADA': 'default' },
    },
    {
      field: "acciones", headerName: "Acciones", width: 200, sortable: false,
      renderCell: (p) => {
        const status = p.row.Status;
        const id = p.row.RequestId;
        return (
          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Ver detalle">
              <IconButton size="small" onClick={() => setSelectedRow(p.row)}>
                <VisibilityIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            {status === "PENDIENTE" && (
              <>
                <Tooltip title="Aprobar solicitud">
                  <span>
                    <IconButton
                      size="small"
                      color="success"
                      onClick={() => handleAprobar(id)}
                      disabled={aprobarMut.isPending}
                    >
                      <CheckCircleIcon fontSize="small" />
                    </IconButton>
                  </span>
                </Tooltip>
                <Tooltip title="Rechazar solicitud">
                  <IconButton
                    size="small"
                    color="error"
                    onClick={() => { setRejectId(id); setRejectOpen(true); }}
                  >
                    <CancelIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </>
            )}
            {status === "APROBADA" && (
              <Tooltip title="Generar pago">
                <span>
                  <IconButton
                    size="small"
                    color="primary"
                    onClick={() => handleProcesarPago(id)}
                    disabled={procesarPagoMut.isPending}
                  >
                    <PaymentIcon fontSize="small" />
                  </IconButton>
                </span>
              </Tooltip>
            )}
          </Stack>
        );
      },
    },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Typography variant="h6" fontWeight={600} mb={2}>
        Solicitudes de Vacaciones
      </Typography>

      {successMsg && <Alert severity="success" sx={{ mb: 2 }}>{successMsg}</Alert>}

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Cédula Empleado"
         
          value={filter.employeeCode || ""}
          onChange={(e) => setFilter((f) => ({ ...f, employeeCode: e.target.value || undefined }))}
        />
        <FormControl sx={{ minWidth: 150 }}>
          <InputLabel>Estado</InputLabel>
          <Select
            value={filter.status || ""}
            label="Estado"
            onChange={(e) => setFilter((f) => ({ ...f, status: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="PENDIENTE">Pendiente</MenuItem>
            <MenuItem value="APROBADA">Aprobada</MenuItem>
            <MenuItem value="RECHAZADA">Rechazada</MenuItem>
            <MenuItem value="PROCESADA">Procesada</MenuItem>
            <MenuItem value="CANCELADA">Cancelada</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <ZenttoDataGrid
            gridId="nomina-vacaciones-solicitudes-list"
          rows={rows}
          columns={columns}
          loading={isLoading}
          rowCount={totalCount}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.RequestId ?? r.requestId ?? Math.random()}
          enableGrouping
          enableClipboard
          enableHeaderFilters
          mobileVisibleFields={['EmployeeCode', 'EmployeeName']}
          smExtraFields={['StartDate', 'Status']}
        />
      </Paper>

      {/* Detail Dialog */}
      <Dialog open={selectedRow != null} onClose={() => setSelectedRow(null)} maxWidth="sm" fullWidth>
        <DialogTitle>
          Detalle Solicitud #{selectedRow?.RequestId}
        </DialogTitle>
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
              {selectedRow.Notes && (
                <Typography variant="body2"><strong>Notas:</strong> {selectedRow.Notes}</Typography>
              )}
              {selectedRow.ApprovedBy && (
                <Typography variant="body2"><strong>Aprobado por:</strong> {selectedRow.ApprovedBy}</Typography>
              )}
              {selectedRow.RejectionReason && (
                <Typography variant="body2"><strong>Motivo de rechazo:</strong> {selectedRow.RejectionReason}</Typography>
              )}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          {selectedRow?.Status === "PENDIENTE" && (
            <>
              <Button color="success" onClick={() => { handleAprobar(selectedRow.RequestId); setSelectedRow(null); }}>
                Aprobar
              </Button>
              <Button color="error" onClick={() => { setRejectId(selectedRow.RequestId); setRejectOpen(true); setSelectedRow(null); }}>
                Rechazar
              </Button>
            </>
          )}
          {selectedRow?.Status === "APROBADA" && (
            <Button color="primary" onClick={() => { handleProcesarPago(selectedRow.RequestId); setSelectedRow(null); }}>
              Generar Pago
            </Button>
          )}
          <Button onClick={() => setSelectedRow(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={rejectOpen} onClose={() => setRejectOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Rechazar Solicitud</DialogTitle>
        <DialogContent>
          <TextField
            label="Motivo del rechazo"
            multiline
            rows={3}
            fullWidth
            value={rejectReason}
            onChange={(e) => setRejectReason(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setRejectOpen(false); setRejectReason(""); }}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleRechazar}
            disabled={!rejectReason || rechazarMut.isPending}
          >
            Rechazar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
