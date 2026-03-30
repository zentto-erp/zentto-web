"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  Alert,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { ContextActionHeader } from "@zentto/shared-ui";
import { ReportViewer } from "@zentto/shared-reports";
import type { ReportLayout, DataSet } from "@zentto/report-core";
import {
  useAsientosList,
  useAsientoDetalle,
  useAnularAsiento,
  type AsientoFilter,
} from "../hooks/useContabilidad";
import { ASIENTOS_LIST_LAYOUT } from "@zentto/shared-reports";

import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";

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

const GRID_IDS = {
  gridRef: buildContabilidadGridId("asientos-list", "main"),
  detailGridRef: buildContabilidadGridId("asientos-list", "detail"),
} as const;

export default function AsientosListPage() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const detailGridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  const { ready: detailGridLayoutReady } = useGridLayoutSync(GRID_IDS.detailGridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  useContabilidadGridId(detailGridRef, GRID_IDS.detailGridRef);
  const layoutReady = gridLayoutReady && detailGridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const [filter, setFilter] = useState<AsientoFilter>({ page: 1, limit: 25 });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [anularId, setAnularId] = useState<number | null>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState("");
  const [reportOpen, setReportOpen] = useState(false);

  const { data, isLoading } = useAsientosList(filter);
  const detalle = useAsientoDetalle(selectedId);
  const anularMutation = useAnularAsiento();

  const rows = data?.data ?? data?.rows ?? [];

  // ── Report: build data from grid's current rows (filtered/sorted) ──
  const buildReportData = useCallback((): DataSet => {
    const el = gridRef.current;
    // Prefer grid's filtered/sorted rows; fall back to raw API rows
    const gridRows: any[] = el?._filteredRows ?? el?._sortedRows ?? el?.rows ?? rows ?? [];
    if (!gridRows.length) return {} as DataSet;

    let sumDebe = 0;
    let sumHaber = 0;
    const mapped = gridRows
      .filter((r: any) => !r._isTotals) // exclude totals row
      .map((r: any, i: number) => {
        const debe = Number(r.totalDebe ?? r.debe ?? 0);
        const haber = Number(r.totalHaber ?? r.haber ?? 0);
        sumDebe += debe;
        sumHaber += haber;
        return {
          num: i + 1,
          id: r.asientoId ?? r.id ?? r.Id,
          fecha: r.fecha ? new Date(r.fecha).toLocaleDateString("es", { day: "2-digit", month: "2-digit", year: "numeric" }) : "",
          tipoAsiento: r.tipoAsiento ?? "",
          concepto: r.concepto ?? "",
          referencia: r.referencia ?? "",
          totalDebe: debe,
          totalHaber: haber,
          estado: r.estado ?? "",
        };
      });

    return {
      header: {
        empresa: "Zentto ERP",
        fechaDesde: filter.fechaDesde ?? "—",
        fechaHasta: filter.fechaHasta ?? "—",
        totalDebe: sumDebe,
        totalHaber: sumHaber,
        totalRegistros: mapped.length,
      },
      asientos: mapped,
    };
  }, [rows, filter.fechaDesde, filter.fechaHasta]);

  const [reportData, setReportData] = useState<DataSet>({} as DataSet);

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
    const createHandler = () => router.push("/asientos/new");
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
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
        secondaryActions={[
          { label: "Reporte", onClick: () => { setReportData(buildReportData()); setReportOpen(true); }, disabled: !rows.length },
        ]}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 400, width: "100%", elevation: 0, border: '1px solid #E5E7EB', overflow: 'auto' }}>
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="asientos-contables"
            height="100%"
            show-totals
            enable-create
            create-label="Nuevo asiento"
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

      {/* Report Dialog */}
      <Dialog open={reportOpen} onClose={() => setReportOpen(false)} maxWidth={false} fullWidth PaperProps={{ sx: { height: "90vh", maxWidth: "95vw" } }}>
        <DialogTitle sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <Typography variant="h6">Listado de Asientos Contables</Typography>
          <IconButton onClick={() => setReportOpen(false)} size="small">
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent sx={{ p: 0, overflow: "hidden" }}>
          <ReportViewer
            layout={ASIENTOS_LIST_LAYOUT as unknown as ReportLayout}
            data={reportData}
            showToolbar
            viewMode="all"
            style={{ height: "100%" }}
          />
        </DialogContent>
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
