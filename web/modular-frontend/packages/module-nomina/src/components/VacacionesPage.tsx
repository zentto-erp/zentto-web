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
  IconButton,
  Tooltip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import VisibilityIcon from "@mui/icons-material/Visibility";
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

  const rawRows: any[] = data?.data ?? data?.rows ?? [];
  // Mapear campos del SP a los que espera el DataGrid
  const rows = rawRows.map((r: any, i: number) => {
    const inicio = r.inicio ?? r.fechaInicio;
    const hasta = r.hasta ?? r.fechaHasta;
    let dias = 0;
    if (inicio && hasta) {
      dias = Math.round((new Date(hasta).getTime() - new Date(inicio).getTime()) / 86400000);
    }
    return {
      _id: r.vacacion ?? r.vacacionId ?? i,
      vacacion: r.vacacion ?? r.vacacionId ?? "",
      cedula: r.cedula ?? "",
      nombreEmpleado: r.nombreEmpleado ?? r.nombre ?? "",
      inicio: inicio ? new Date(inicio).toLocaleDateString() : "",
      hasta: hasta ? new Date(hasta).toLocaleDateString() : "",
      reintegro: r.reintegro ?? r.fechaReintegro ? new Date(r.reintegro ?? r.fechaReintegro).toLocaleDateString() : "",
      dias,
      total: r.total ?? r.totalCalculado ?? r.montoVacaciones ?? 0,
    };
  });

  const columns: GridColDef[] = [
    { field: "vacacion", headerName: "ID", width: 160 },
    { field: "cedula", headerName: "Cédula", width: 120 },
    { field: "nombreEmpleado", headerName: "Empleado", flex: 1 },
    { field: "inicio", headerName: "Inicio", width: 110 },
    { field: "hasta", headerName: "Hasta", width: 110 },
    { field: "reintegro", headerName: "Reintegro", width: 110 },
    { field: "dias", headerName: "Días", width: 80, type: "number" },
    {
      field: "total",
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
        <Tooltip title="Ver detalle">
          <IconButton size="small" onClick={() => setSelectedId(p.row.vacacion)}>
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
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
         
          value={cedula}
          onChange={(e) => setCedula(e.target.value)}
        />
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r._id}
          mobileVisibleFields={['cedula', 'nombreEmpleado']}
          smExtraFields={['inicio', 'total']}
        />
      </Paper>

      {/* Detalle */}
      <Dialog open={selectedId != null} onClose={() => setSelectedId(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Detalle Vacación #{selectedId}</DialogTitle>
        <DialogContent>
          {detalle.isLoading ? (
            <CircularProgress />
          ) : detalle.data ? (
            <Box>
              <Typography variant="body2"><strong>Empleado:</strong> {detalle.data.cabecera?.nombreEmpleado ?? detalle.data.nombreEmpleado ?? detalle.data.cedula}</Typography>
              <Typography variant="body2"><strong>Período:</strong> {detalle.data.cabecera?.inicio ?? detalle.data.inicio} - {detalle.data.cabecera?.hasta ?? detalle.data.hasta}</Typography>
              <Typography variant="body2"><strong>Monto:</strong> {formatCurrency(detalle.data.cabecera?.total ?? detalle.data.total ?? 0)}</Typography>
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
