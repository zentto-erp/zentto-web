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
  CircularProgress,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import VisibilityIcon from "@mui/icons-material/Visibility";
import IconButton from "@mui/material/IconButton";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useVacacionesList,
  useVacacionDetalle,
  useProcesarVacaciones,
  type VacacionesInput,
} from "../hooks/useNomina";

export default function VacacionesPage() {
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [procesarOpen, setProcesarOpen] = useState(false);
  const [form, setForm] = useState<VacacionesInput>({
    vacacionId: "",
    cedula: "",
    fechaInicio: "",
    fechaHasta: "",
  });

  const { data, isLoading } = useVacacionesList({ cedula: cedula || undefined });
  const detalle = useVacacionDetalle(selectedId);
  const procesarMutation = useProcesarVacaciones();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "vacacionId", headerName: "ID", width: 100 },
    { field: "cedula", headerName: "Cédula", width: 120 },
    { field: "nombre", headerName: "Empleado", flex: 1 },
    { field: "fechaInicio", headerName: "Inicio", width: 110 },
    { field: "fechaHasta", headerName: "Hasta", width: 110 },
    { field: "fechaReintegro", headerName: "Reintegro", width: 110 },
    { field: "diasVacaciones", headerName: "Días", width: 80, type: "number" },
    {
      field: "montoVacaciones",
      headerName: "Monto",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "acciones",
      headerName: "",
      width: 60,
      sortable: false,
      renderCell: (p) => (
        <IconButton size="small" onClick={() => setSelectedId(p.row.vacacionId)}>
          <VisibilityIcon fontSize="small" />
        </IconButton>
      ),
    },
  ];

  const handleProcesar = async () => {
    await procesarMutation.mutateAsync(form);
    setProcesarOpen(false);
    setForm({ vacacionId: "", cedula: "", fechaInicio: "", fechaHasta: "" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<PlayArrowIcon />} onClick={() => setProcesarOpen(true)}>
          Procesar Vacaciones
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Cédula"
          size="small"
          value={cedula}
          onChange={(e) => setCedula(e.target.value)}
        />
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.vacacionId ?? r.id ?? Math.random()}
        />
      </Paper>

      {/* Detalle */}
      <Dialog open={selectedId != null} onClose={() => setSelectedId(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle Vacación #{selectedId}</DialogTitle>
        <DialogContent>
          {detalle.isLoading ? (
            <CircularProgress />
          ) : detalle.data?.cabecera ? (
            <Box>
              <Typography variant="body2"><strong>Empleado:</strong> {detalle.data.cabecera.nombre}</Typography>
              <Typography variant="body2"><strong>Período:</strong> {detalle.data.cabecera.fechaInicio} - {detalle.data.cabecera.fechaHasta}</Typography>
              <Typography variant="body2"><strong>Días:</strong> {detalle.data.cabecera.diasVacaciones}</Typography>
              <Typography variant="body2"><strong>Monto:</strong> {formatCurrency(detalle.data.cabecera.montoVacaciones ?? 0)}</Typography>
            </Box>
          ) : (
            <Typography>No se encontró información</Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Procesar Dialog */}
      <Dialog open={procesarOpen} onClose={() => setProcesarOpen(false)}>
        <DialogTitle>Procesar Vacaciones</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="ID Vacación" fullWidth value={form.vacacionId} onChange={(e) => setForm((f) => ({ ...f, vacacionId: e.target.value }))} />
            <TextField label="Cédula" fullWidth value={form.cedula} onChange={(e) => setForm((f) => ({ ...f, cedula: e.target.value }))} />
            <TextField label="Fecha Inicio" type="date" fullWidth InputLabelProps={{ shrink: true }} value={form.fechaInicio} onChange={(e) => setForm((f) => ({ ...f, fechaInicio: e.target.value }))} />
            <TextField label="Fecha Hasta" type="date" fullWidth InputLabelProps={{ shrink: true }} value={form.fechaHasta} onChange={(e) => setForm((f) => ({ ...f, fechaHasta: e.target.value }))} />
            <TextField label="Fecha Reintegro" type="date" fullWidth InputLabelProps={{ shrink: true }} value={form.fechaReintegro || ""} onChange={(e) => setForm((f) => ({ ...f, fechaReintegro: e.target.value || undefined }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setProcesarOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleProcesar} disabled={procesarMutation.isPending}>
            Procesar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
