"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
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
  Alert,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import BlockIcon from "@mui/icons-material/Block";
import VisibilityIcon from "@mui/icons-material/Visibility";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader } from "@zentto/shared-ui";
import {
  useAsientosList,
  useAsientoDetalle,
  useAnularAsiento,
  type AsientoFilter,
} from "../hooks/useContabilidad";

export default function AsientosListPage() {
  const router = useRouter();
  const [filter, setFilter] = useState<AsientoFilter>({ page: 1, limit: 25 });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [anularId, setAnularId] = useState<number | null>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState("");

  const { data, isLoading } = useAsientosList(filter);
  const detalle = useAsientoDetalle(selectedId);
  const anularMutation = useAnularAsiento();

  const rows = data?.data ?? data?.rows ?? [];

  const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "fecha", headerName: "Fecha", width: 110 },
    { field: "tipoAsiento", headerName: "Tipo", width: 100 },
    { field: "concepto", headerName: "Concepto", flex: 1, minWidth: 200 },
    { field: "referencia", headerName: "Ref.", width: 100 },
    {
      field: "totalDebe",
      headerName: "Debe",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "totalHaber",
      headerName: "Haber",
      width: 130,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "estado",
      headerName: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value}
          size="small"
          color={p.value === "APROBADO" ? "success" : p.value === "ANULADO" ? "error" : "default"}
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
          <IconButton size="small" onClick={() => setSelectedId(p.row.id)}>
            <VisibilityIcon fontSize="small" />
          </IconButton>
          {p.row.estado !== "ANULADO" && (
            <IconButton size="small" color="error" onClick={() => setAnularId(p.row.id)}>
              <BlockIcon fontSize="small" />
            </IconButton>
          )}
        </Stack>
      ),
    },
  ];

  const handleAnular = async () => {
    if (!anularId || !motivoAnulacion) return;
    await anularMutation.mutateAsync({ id: anularId, motivo: motivoAnulacion });
    setAnularId(null);
    setMotivoAnulacion("");
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Asientos Contables"
        primaryAction={{
          label: "Nuevo Asiento",
          onClick: () => router.push("/contabilidad/asientos/new")
        }}
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
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            disableRowSelectionOnClick
            getRowId={(row) => row.asientoId ?? row.id ?? row.Id}
            sx={{ border: 'none' }}
          />
        </Paper>
      </Box>

      {/* Detail Dialog */}
      <Dialog open={selectedId != null} onClose={() => setSelectedId(null)} maxWidth="md" fullWidth>
        <DialogTitle>Detalle del Asiento #{selectedId}</DialogTitle>
        <DialogContent>
          {detalle.isLoading ? (
            <CircularProgress />
          ) : detalle.data ? (
            <Box>
              <Typography variant="body2" mb={1}>
                <strong>Concepto:</strong> {detalle.data.cabecera?.concepto}
              </Typography>
              <Typography variant="body2" mb={2}>
                <strong>Fecha:</strong> {detalle.data.cabecera?.fecha} &nbsp;|&nbsp;
                <strong>Estado:</strong> {detalle.data.cabecera?.estado}
              </Typography>
              <DataGrid
                rows={(detalle.data.detalle ?? []).map((d: any, i: number) => ({ ...d, _id: i }))}
                columns={[
                  { field: "codCuenta", headerName: "Cuenta", width: 120 },
                  { field: "descripcion", headerName: "Descripción", flex: 1 },
                  { field: "debe", headerName: "Debe", width: 130, renderCell: (p) => formatCurrency(p.value) },
                  { field: "haber", headerName: "Haber", width: 130, renderCell: (p) => formatCurrency(p.value) },
                  { field: "centroCosto", headerName: "C. Costo", width: 100 },
                ]}
                autoHeight
                getRowId={(r) => r._id}
                disableRowSelectionOnClick
                hideFooter
              />
            </Box>
          ) : (
            <Alert severity="info">No se encontraron datos</Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Anular Dialog */}
      <Dialog open={anularId != null} onClose={() => setAnularId(null)}>
        <DialogTitle>Anular Asiento #{anularId}</DialogTitle>
        <DialogContent>
          <TextField
            label="Motivo de anulación"
            fullWidth
            multiline
            rows={3}
            value={motivoAnulacion}
            onChange={(e) => setMotivoAnulacion(e.target.value)}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAnularId(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleAnular}
            disabled={!motivoAnulacion || anularMutation.isPending}
          >
            Anular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
