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
import CalculateIcon from "@mui/icons-material/Calculate";
import VisibilityIcon from "@mui/icons-material/Visibility";
import IconButton from "@mui/material/IconButton";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useLiquidacionesList,
  useLiquidacionDetalle,
} from "../hooks/useNomina";

type LiquidacionDetalleItem = Record<string, any>;

export default function LiquidacionesPage() {
  const router = useRouter();
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { data, isLoading } = useLiquidacionesList({ cedula: cedula || undefined });
  const detalle = useLiquidacionDetalle(selectedId);

  const rows = Array.isArray(data) ? data : data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "liquidacionId", headerName: "ID", width: 100 },
    { field: "cedula", headerName: "Cédula", width: 120 },
    { field: "nombre", headerName: "Empleado", flex: 1 },
    { field: "fechaRetiro", headerName: "Fecha Retiro", width: 120 },
    { field: "causaRetiro", headerName: "Causa", width: 140 },
    {
      field: "montoTotal",
      headerName: "Total",
      width: 140,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "acciones",
      headerName: "",
      width: 60,
      sortable: false,
      renderCell: (p) => (
        <IconButton size="small" onClick={() => setSelectedId(p.row.liquidacionId)}>
          <VisibilityIcon fontSize="small" />
        </IconButton>
      ),
    },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6" fontWeight={600}>
          Liquidaciones
        </Typography>
        <Button
          variant="contained"
          startIcon={<CalculateIcon />}
          onClick={() => router.push("/nomina/liquidaciones/nueva")}
        >
          Nueva Liquidación
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField label="Buscar por Cédula" size="small" value={cedula} onChange={(e) => setCedula(e.target.value)} />
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.liquidacionId ?? r.id ?? Math.random()}
        />
      </Paper>

      {/* Detalle */}
      <Dialog open={selectedId != null} onClose={() => setSelectedId(null)} maxWidth="md" fullWidth>
        <DialogTitle>Detalle Liquidación #{selectedId}</DialogTitle>
        <DialogContent>
          {detalle.isLoading ? <CircularProgress /> : detalle.data ? (
            <Box>
              <Typography variant="body2"><strong>Empleado:</strong> {detalle.data.nombre} ({detalle.data.cedula})</Typography>
              <Typography variant="body2"><strong>Fecha Retiro:</strong> {detalle.data.fechaRetiro}</Typography>
              <Typography variant="body2"><strong>Causa:</strong> {detalle.data.causaRetiro}</Typography>
              {detalle.data.detalle && (
                <DataGrid
                  rows={((detalle.data.detalle ?? []) as LiquidacionDetalleItem[]).map((d: LiquidacionDetalleItem, i: number) => ({ ...d, _id: i }))}
                  columns={[
                    { field: "concepto", headerName: "Concepto", flex: 1 },
                    { field: "monto", headerName: "Monto", width: 140, renderCell: (p) => formatCurrency(p.value) },
                  ]}
                  autoHeight
                  getRowId={(r) => r._id}
                  disableRowSelectionOnClick
                  hideFooter
                  sx={{ mt: 2 }}
                />
              )}
            </Box>
          ) : <Typography>No se encontró información</Typography>}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
