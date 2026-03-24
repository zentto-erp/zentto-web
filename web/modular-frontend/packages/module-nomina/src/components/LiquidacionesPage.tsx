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
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import CalculateIcon from "@mui/icons-material/Calculate";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import {
  useLiquidacionesList,
  useLiquidacionDetalle,
} from "../hooks/useNomina";
import EmployeeSelector from "./EmployeeSelector";

type LiquidacionDetalleItem = Record<string, any>;

function LiquidacionDetailPanel({ liquidacionId }: { liquidacionId: string }) {
  const detalle = useLiquidacionDetalle(liquidacionId);

  if (detalle.isLoading) {
    return (
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
        <CircularProgress size={16} />
        <Typography variant="caption" color="text.secondary">Cargando...</Typography>
      </Box>
    );
  }

  const rows = (detalle.data?.detalle ?? []).map((d: any, i: number) => ({ ...d, _id: i }));

  const cols: ZenttoColDef[] = [
    { field: 'concepto', headerName: 'Concepto', flex: 1, minWidth: 200 },
    { field: 'monto', headerName: 'Monto', width: 160, type: 'number',
      aggregation: 'sum',
      renderCell: (p: any) => formatCurrency(p.value ?? 0) },
  ];

  return (
    <Box sx={{ px: 2, py: 1.5 }}>
      <Stack direction="row" spacing={3} sx={{ mb: 1 }}>
        <Typography variant="caption" color="text.secondary">
          Empleado: <strong>{detalle.data?.nombre ?? '—'}</strong>
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Fecha retiro: <strong>{detalle.data?.fechaRetiro ? String(detalle.data.fechaRetiro).slice(0, 10) : '—'}</strong>
        </Typography>
        <Typography variant="caption" color="text.secondary">
          Causa: <strong>{detalle.data?.causaRetiro ?? '—'}</strong>
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
        totalsLabel="Total liquidación"
        sx={{ border: '1px solid', borderColor: 'divider', borderRadius: 1 }}
      />
    </Box>
  );
}

export default function LiquidacionesPage() {
  const router = useRouter();
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { data, isLoading } = useLiquidacionesList({ cedula: cedula || undefined });
  const detalle = useLiquidacionDetalle(selectedId);

  const rows = Array.isArray(data) ? data : data?.rows ?? [];

  const columns: ZenttoColDef[] = [
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
      currency: true,
      aggregation: 'sum',
    },
    {
      field: "acciones",
      headerName: "",
      width: 60,
      sortable: false,
      renderCell: (p) => (
        <Tooltip title="Ver liquidacion">
          <IconButton size="small" onClick={() => setSelectedId(p.row.liquidacionId)}>
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
        <Box sx={{ minWidth: 320 }}>
          <EmployeeSelector
            value={cedula}
            onChange={(code) => setCedula(code)}
            label="Filtrar por empleado"
            size="small"
          />
        </Box>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%" }}>
        <ZenttoDataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.liquidacionId ?? r.id ?? Math.random()}
          showTotals
          totalsLabel="Total"
          enableClipboard
          mobileVisibleFields={['cedula', 'nombre']}
          smExtraFields={['fechaRetiro', 'montoTotal']}
          getDetailContent={(row: any) => <LiquidacionDetailPanel liquidacionId={row.liquidacionId} />}
          detailPanelHeight="auto"
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
                <ZenttoDataGrid
                  rows={((detalle.data.detalle ?? []) as LiquidacionDetalleItem[]).map((d: LiquidacionDetalleItem, i: number) => ({ ...d, _id: i }))}
                  columns={[
                    { field: "concepto", headerName: "Concepto", flex: 1 },
                    { field: "monto", headerName: "Monto", width: 140, renderCell: (p) => formatCurrency(p.value) },
                  ]}
                  autoHeight
                  getRowId={(r) => r._id}
                  disableRowSelectionOnClick
                  hideFooter
                  hideToolbar
                  mobileDetailDrawer={false}
                  density="compact"
                  mobileVisibleFields={['concepto', 'monto']}
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
