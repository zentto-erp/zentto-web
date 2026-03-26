"use client";

import React, { useState, useEffect, useRef } from "react";
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
  Tooltip,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { ContextActionHeader, ZenttoFilterPanel, type FilterFieldDef } from "@zentto/shared-ui";
import {
  useAsientosList,
  useAsientoDetalle,
  useAnularAsiento,
  type AsientoFilter,
} from "../hooks/useContabilidad";

const ASIENTOS_FILTERS: FilterFieldDef[] = [
  { field: "fechaDesde", label: "Fecha desde", type: "date" },
  { field: "fechaHasta", label: "Fecha hasta", type: "date" },
  { field: "tipoAsiento", label: "Tipo", type: "select", options: [
    { value: "APERTURA", label: "Apertura" },
    { value: "DIARIO", label: "Diario" },
    { value: "AJUSTE", label: "Ajuste" },
    { value: "CIERRE", label: "Cierre" },
  ]},
  { field: "estado", label: "Estado", type: "select", options: [
    { value: "BORRADOR", label: "Borrador" },
    { value: "APROBADO", label: "Aprobado" },
    { value: "ANULADO", label: "Anulado" },
  ]},
];

const COLUMNS: ColumnDef[] = [
  { field: "id", header: "ID", width: 70, sortable: true },
  { field: "fecha", header: "Fecha", width: 120, type: "date", sortable: true },
  { field: "tipoAsiento", header: "Tipo", width: 100, sortable: true, groupable: true },
  { field: "concepto", header: "Concepto", flex: 1, minWidth: 200, sortable: true },
  { field: "referencia", header: "Ref.", width: 100, sortable: true },
  { field: "totalDebe", header: "Debe", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "totalHaber", header: "Haber", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "estado", header: "Estado", width: 110, sortable: true, groupable: true,
    statusColors: { APPROVED: "success", VOIDED: "error", DRAFT: "default", APROBADO: "success", ANULADO: "error", BORRADOR: "default" },
    statusVariant: "outlined",
  },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 80,
    pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view" },
    ],
  },
];

const DETAIL_COLUMNS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 120 },
  { field: "descripcion", header: "Descripcion", flex: 1, minWidth: 180 },
  { field: "debe", header: "Debe", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "centroCosto", header: "C. Costo", width: 100 },
];

export default function AsientosListPage() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const detailGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<AsientoFilter>({ page: 1, limit: 25 });
  const [search, setSearch] = useState("");
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [anularId, setAnularId] = useState<number | null>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState("");

  const { data, isLoading } = useAsientosList(filter);
  const detalle = useAsientoDetalle(selectedId);
  const anularMutation = useAnularAsiento();

  const rows = data?.data ?? data?.rows ?? [];

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r: any) => ({ ...r, id: r.asientoId ?? r.id ?? r.Id }));
    el.loading = isLoading;
    // Master-detail: show journal entry lines
    el.detailColumns = DETAIL_COLUMNS;
    el.detailRowsAccessor = (row: any) => (row.lineas || row.detalle || []).map((d: any, i: number) => ({ ...d, id: i }));
  }, [rows, isLoading, registered]);

  // Listen for action clicks
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view') setSelectedId(row.id);
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered]);

  useEffect(() => {
    const el = detailGridRef.current;
    if (!el || !registered || !detalle.data) return;
    const detRows = (detalle.data.detalle ?? []).map((d: any, i: number) => ({ ...d, id: i }));
    el.columns = DETAIL_COLUMNS;
    el.rows = detRows;
    el.loading = detalle.isLoading;
  }, [detalle.data, detalle.isLoading, registered]);

  const handleAnular = async () => {
    if (!anularId || !motivoAnulacion) return;
    await anularMutation.mutateAsync({ id: anularId, motivo: motivoAnulacion });
    setAnularId(null);
    setMotivoAnulacion("");
  };

  if (!registered) {
    return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Asientos contables"
        primaryAction={{
          label: "Nuevo asiento",
          onClick: () => router.push("/contabilidad/asientos/new")
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <ZenttoFilterPanel
          filters={ASIENTOS_FILTERS}
          values={filterValues}
          onChange={(vals) => {
            setFilterValues(vals);
            setFilter((f) => ({
              ...f,
              fechaDesde: vals.fechaDesde || undefined,
              fechaHasta: vals.fechaHasta || undefined,
              tipoAsiento: vals.tipoAsiento || undefined,
              estado: vals.estado || undefined,
              page: 1,
            }));
          }}
          searchPlaceholder="Buscar asiento..."
          searchValue={search}
          onSearchChange={(v) => {
            setSearch(v);
            setFilter((f) => ({ ...f, search: v || undefined, page: 1 }));
          }}
        />

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 400, width: "100%", elevation: 0, border: '1px solid #E5E7EB', overflow: 'auto' }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="asientos-contables"
            height="100%"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-master-detail
          ></zentto-grid>
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
              <Box sx={{ height: 300 }}>
                <zentto-grid
                  ref={detailGridRef}
                  default-currency="VES"
                  height="100%"
                  show-totals
                  enable-toolbar
                  enable-header-menu
                  enable-header-filters
                  enable-clipboard
                  enable-quick-search
                  enable-context-menu
                  enable-status-bar
                  enable-configurator
                ></zentto-grid>
              </Box>
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
            label="Motivo de anulacion"
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
          <Button variant="contained" color="error" onClick={handleAnular} disabled={!motivoAnulacion || anularMutation.isPending}>
            Anular
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
