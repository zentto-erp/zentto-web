"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Stack,
  CircularProgress,
  Switch,
  FormControlLabel,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LockIcon from "@mui/icons-material/Lock";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useNominasList,
  useNominaDetalle,
  useProcesarNominaCompleta,
  useCerrarNomina,
  type NominaFilter,
} from "../hooks/useNomina";
import NominaBatchWizard from "./NominaBatchWizard";

type NominaDetalleItem = Record<string, unknown>;

export default function NominasPage() {
  const [filter, setFilter] = useState<NominaFilter>({ page: 1, limit: 25 });
  const [selectedNomina, setSelectedNomina] = useState<string | null>(null);
  const [selectedCedula, setSelectedCedula] = useState<string | null>(null);
  const [procesarOpen, setProcesarOpen] = useState(false);
  const [view, setView] = useState<"list" | "batch">("list");
  const [procesarData, setProcesarData] = useState({ nomina: "", fechaInicio: "", fechaHasta: "", soloActivos: true });

  const { data, isLoading } = useNominasList(filter);
  const detalle = useNominaDetalle(selectedNomina, selectedCedula);
  const procesarMutation = useProcesarNominaCompleta();
  const cerrarMutation = useCerrarNomina();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "nomina", headerName: "Nómina", width: 120 },
    { field: "cedula", headerName: "Cédula", width: 120 },
    { field: "nombre", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "fechaInicio", headerName: "Desde", width: 110 },
    { field: "fechaHasta", headerName: "Hasta", width: 110 },
    {
      field: "totalAsignaciones",
      headerName: "Asignaciones",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "totalDeducciones",
      headerName: "Deducciones",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "netoAPagar",
      headerName: "Neto",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "estado",
      headerName: "Estado",
      width: 100,
      renderCell: (p) => (
        <Chip
          label={p.value || "ABIERTA"}
          size="small"
          color={p.value === "CERRADA" ? "default" : "success"}
        />
      ),
    },
    {
      field: "acciones",
      headerName: "",
      width: 100,
      sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <IconButton
            size="small"
            onClick={() => {
              setSelectedNomina(p.row.nomina);
              setSelectedCedula(p.row.cedula);
            }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
          {p.row.estado !== "CERRADA" && (
            <IconButton
              size="small"
              color="warning"
              onClick={() => cerrarMutation.mutate({ nomina: p.row.nomina, cedula: p.row.cedula })}
            >
              <LockIcon fontSize="small" />
            </IconButton>
          )}
        </Stack>
      ),
    },
  ];

  const handleProcesar = async () => {
    await procesarMutation.mutateAsync(procesarData);
    setProcesarOpen(false);
  };

  if (view === "batch") {
    return <NominaBatchWizard onBack={() => setView("list")} />;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Procesos de Nómina"
        primaryAction={{
          label: "Nómina Masiva",
          onClick: () => setView("batch"),
        }}
        secondaryActions={[
          {
            label: "Procesar Individual",
            onClick: () => setProcesarOpen(true),
          },
        ]}
        searchPlaceholder="Buscar nóminas..."
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Stack direction="row" spacing={2} mb={2}>
          <TextField
            label="Desde"
            type="date"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={filter.fechaDesde || ""}
            onChange={(e) => setFilter((f) => ({ ...f, fechaDesde: e.target.value }))}
          />
          <TextField
            label="Hasta"
            type="date"
            size="small"
            InputLabelProps={{ shrink: true }}
            value={filter.fechaHasta || ""}
            onChange={(e) => setFilter((f) => ({ ...f, fechaHasta: e.target.value }))}
          />
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: '1px solid #E5E7EB' }}>
          <DataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => `${r.nomina}-${r.cedula}-${r.fechaInicio ?? Math.random()}`}
          />
        </Paper>

        {/* Detalle Dialog */}
        <Dialog
          open={selectedNomina != null}
          onClose={() => { setSelectedNomina(null); setSelectedCedula(null); }}
          maxWidth="md"
          fullWidth
        >
          <DialogTitle>Detalle de Nómina</DialogTitle>
          <DialogContent>
            {detalle.isLoading ? (
              <CircularProgress />
            ) : detalle.data?.cabecera ? (
              <Box>
                <Typography variant="body2" mb={1}>
                  <strong>Empleado:</strong> {detalle.data.cabecera.nombre} ({detalle.data.cabecera.cedula})
                </Typography>
                <Typography variant="body2" mb={2}>
                  <strong>Período:</strong> {detalle.data.cabecera.fechaInicio} - {detalle.data.cabecera.fechaHasta}
                </Typography>
                <DataGrid
                  rows={((detalle.data.detalle ?? []) as NominaDetalleItem[]).map((d, i: number) => ({ ...d, _id: i }))}
                  columns={[
                    { field: "concepto", headerName: "Concepto", flex: 1 },
                    { field: "tipo", headerName: "Tipo", width: 120 },
                    { field: "monto", headerName: "Monto", width: 130, renderCell: (p) => formatCurrency(p.value) },
                  ]}
                  autoHeight
                  getRowId={(r) => r._id}
                  disableRowSelectionOnClick
                  hideFooter
                />
              </Box>
            ) : (
              <Typography>No se encontró información</Typography>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => { setSelectedNomina(null); setSelectedCedula(null); }}>Cerrar</Button>
          </DialogActions>
        </Dialog>

        {/* Procesar Dialog */}
        <Dialog open={procesarOpen} onClose={() => setProcesarOpen(false)}>
          <DialogTitle>Procesar Nómina Completa</DialogTitle>
          <DialogContent>
            <Stack spacing={2} mt={1}>
              <TextField
                label="Código Nómina"
                fullWidth
                value={procesarData.nomina}
                onChange={(e) => setProcesarData((d) => ({ ...d, nomina: e.target.value }))}
              />
              <TextField
                label="Fecha Inicio"
                type="date"
                fullWidth
                InputLabelProps={{ shrink: true }}
                value={procesarData.fechaInicio}
                onChange={(e) => setProcesarData((d) => ({ ...d, fechaInicio: e.target.value }))}
              />
              <TextField
                label="Fecha Hasta"
                type="date"
                fullWidth
                InputLabelProps={{ shrink: true }}
                value={procesarData.fechaHasta}
                onChange={(e) => setProcesarData((d) => ({ ...d, fechaHasta: e.target.value }))}
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={procesarData.soloActivos}
                    onChange={(e) => setProcesarData((d) => ({ ...d, soloActivos: e.target.checked }))}
                  />
                }
                label="Solo empleados activos"
              />
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
    </Box>
  );
}
