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
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import {
  useVacacionesList,
  useVacacionDetalle,
} from "../hooks/useNomina";

export default function VacacionesPage() {
  const router = useRouter();
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { data, isLoading } = useVacacionesList({ cedula: cedula || undefined });
  const detalle = useVacacionDetalle(selectedId);

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

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6" fontWeight={600}>
          Vacaciones
        </Typography>
        <Button
          variant="contained"
          startIcon={<PlayArrowIcon />}
          onClick={() => router.push("/nomina/vacaciones/procesar")}
        >
          Procesar Vacaciones
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar por Cédula"
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
    </Box>
  );
}
