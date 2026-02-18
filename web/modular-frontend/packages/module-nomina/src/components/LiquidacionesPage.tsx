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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import CalculateIcon from "@mui/icons-material/Calculate";
import VisibilityIcon from "@mui/icons-material/Visibility";
import IconButton from "@mui/material/IconButton";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useLiquidacionesList,
  useLiquidacionDetalle,
  useCalcularLiquidacion,
  type LiquidacionInput,
} from "../hooks/useNomina";

export default function LiquidacionesPage() {
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [calcularOpen, setCalcularOpen] = useState(false);
  const [form, setForm] = useState<LiquidacionInput>({
    liquidacionId: "",
    cedula: "",
    fechaRetiro: "",
    causaRetiro: "RENUNCIA",
  });

  const { data, isLoading } = useLiquidacionesList({ cedula: cedula || undefined });
  const detalle = useLiquidacionDetalle(selectedId);
  const calcularMutation = useCalcularLiquidacion();

  const rows = data?.data ?? data?.rows ?? [];

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

  const handleCalcular = async () => {
    await calcularMutation.mutateAsync(form);
    setCalcularOpen(false);
    setForm({ liquidacionId: "", cedula: "", fechaRetiro: "", causaRetiro: "RENUNCIA" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<CalculateIcon />} onClick={() => setCalcularOpen(true)}>
          Calcular Liquidación
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField label="Cédula" size="small" value={cedula} onChange={(e) => setCedula(e.target.value)} />
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
                  rows={(detalle.data.detalle ?? []).map((d: any, i: number) => ({ ...d, _id: i }))}
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

      {/* Calcular Dialog */}
      <Dialog open={calcularOpen} onClose={() => setCalcularOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Calcular Liquidación</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="ID Liquidación" fullWidth value={form.liquidacionId} onChange={(e) => setForm((f) => ({ ...f, liquidacionId: e.target.value }))} />
            <TextField label="Cédula" fullWidth value={form.cedula} onChange={(e) => setForm((f) => ({ ...f, cedula: e.target.value }))} />
            <TextField label="Fecha Retiro" type="date" fullWidth InputLabelProps={{ shrink: true }} value={form.fechaRetiro} onChange={(e) => setForm((f) => ({ ...f, fechaRetiro: e.target.value }))} />
            <FormControl fullWidth>
              <InputLabel>Causa de Retiro</InputLabel>
              <Select
                value={form.causaRetiro || "RENUNCIA"}
                label="Causa de Retiro"
                onChange={(e) => setForm((f) => ({ ...f, causaRetiro: e.target.value as any }))}
              >
                <MenuItem value="RENUNCIA">Renuncia</MenuItem>
                <MenuItem value="DESPIDO">Despido</MenuItem>
                <MenuItem value="DESPIDO_JUSTIFICADO">Despido Justificado</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCalcularOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCalcular} disabled={calcularMutation.isPending}>
            Calcular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
