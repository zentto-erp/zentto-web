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
import { type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField, ContextActionHeader } from "@zentto/shared-ui";
import dayjs from "dayjs";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LockIcon from "@mui/icons-material/Lock";
import { formatCurrency } from "@zentto/shared-api";
import {
  useNominasList,
  useNominaDetalle,
  useProcesarNominaCompleta,
  useCerrarNomina,
  type NominaFilter,
} from "../hooks/useNomina";
import NominaBatchWizard from "./NominaBatchWizard";

type NominaDetalleItem = Record<string, unknown>;

function NominaDetailPanel({ nomina, cedula }: { nomina: string; cedula: string }) {
  const detalle = useNominaDetalle(nomina, cedula);

  if (detalle.isLoading) {
    return (
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
        <CircularProgress size={16} />
        <Typography variant="caption" color="text.secondary">Cargando conceptos...</Typography>
      </Box>
    );
  }

  const rows = (detalle.data?.detalle ?? []).map((d: any, i: number) => ({ ...d, _id: i }));

  const cols: ZenttoColDef[] = [
    { field: 'concepto', headerName: 'Concepto', flex: 1, minWidth: 200 },
    { field: 'tipo', headerName: 'Tipo', width: 110,
      renderCell: (p: any) => (
        <Chip
          label={p.value}
          size="small"
          color={p.value === 'ASIGNACION' ? 'success' : p.value === 'DEDUCCION' ? 'error' : 'default'}
          variant="outlined"
        />
      ),
    },
    { field: 'monto', headerName: 'Monto', width: 150, type: 'number',
      aggregation: 'sum',
      renderCell: (p: any) => (
        <Typography
          variant="body2"
          fontWeight={600}
          color={p.row?.tipo === 'DEDUCCION' ? 'error.main' : 'success.main'}
        >
          {formatCurrency(p.value ?? 0)}
        </Typography>
      ),
    },
  ];

  return (
    <Box sx={{ px: 2, py: 1.5 }}>
      <Stack direction="row" spacing={3} sx={{ mb: 1 }}>
        <Typography variant="caption" color="text.secondary">
          Empleado: <strong>{detalle.data?.cabecera?.nombre ?? '—'}</strong>
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Período: <strong>{detalle.data?.cabecera?.fechaInicio ? String(detalle.data.cabecera.fechaInicio).slice(0, 10) : '—'} — {detalle.data?.cabecera?.fechaHasta ? String(detalle.data.cabecera.fechaHasta).slice(0, 10) : '—'}</strong>
        </Typography>
      </Stack>
      <ZenttoDataGrid
        rows={rows}
        columns={cols}
        getRowId={(r: any) => r._id}
        hideToolbar
        mobileDetailDrawer={false}
        density="compact"
        hideFooter={rows.length < 5}
        autoHeight
        showTotals
        totalsLabel="Neto"
        sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 1 }}
      />
    </Box>
  );
}

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
    { field: "nombreEmpleado", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "fechaInicio", headerName: "Desde", width: 110, renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "" },
    { field: "fechaHasta", headerName: "Hasta", width: 110, renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "" },
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
      field: "totalNeto",
      headerName: "Neto",
      width: 130,
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "cerrada",
      headerName: "Estado",
      width: 100,
      renderCell: (p) => (
        <Chip
          label={p.value ? "CERRADA" : "ABIERTA"}
          size="small"
          color={p.value ? "default" : "success"}
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
        <FormGrid spacing={2} sx={{ mb: 2 }}>
          <FormField xs={12} sm={6} md={3}>
            <DatePicker
              label="Desde"
              value={filter.fechaDesde ? dayjs(filter.fechaDesde) : null}
              onChange={(v) => setFilter((f) => ({ ...f, fechaDesde: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
          <FormField xs={12} sm={6} md={3}>
            <DatePicker
              label="Hasta"
              value={filter.fechaHasta ? dayjs(filter.fechaHasta) : null}
              onChange={(v) => setFilter((f) => ({ ...f, fechaHasta: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
          </FormField>
        </FormGrid>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", elevation: 0, border: '1px solid #E5E7EB' }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => `${r.nomina}-${r.cedula}-${r.fechaInicio ?? Math.random()}`}
            mobileVisibleFields={['cedula', 'nombreEmpleado']}
            smExtraFields={['totalNeto', 'cerrada']}
            getDetailContent={(row: any) => <NominaDetailPanel nomina={row.nomina} cedula={row.cedula} />}
            detailPanelHeight="auto"
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
                <ZenttoDataGrid
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
                  hideToolbar
                  mobileDetailDrawer={false}
                  density="compact"
                  mobileVisibleFields={['concepto', 'monto']}
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
              <DatePicker
                label="Fecha Inicio"
                value={procesarData.fechaInicio ? dayjs(procesarData.fechaInicio) : null}
                onChange={(v) => setProcesarData((d) => ({ ...d, fechaInicio: v ? v.format('YYYY-MM-DD') : '' }))}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
              <DatePicker
                label="Fecha Hasta"
                value={procesarData.fechaHasta ? dayjs(procesarData.fechaHasta) : null}
                onChange={(v) => setProcesarData((d) => ({ ...d, fechaHasta: v ? v.format('YYYY-MM-DD') : '' }))}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
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
