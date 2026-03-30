"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import { useRouter } from "next/navigation";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import {
  useVacacionesList,
  useVacacionDetalle,
} from "../hooks/useNomina";
import { buildNominaGridId, useNominaGridId, useNominaGridRegistration } from "./zenttoGridPersistence";

const COLUMNS: ColumnDef[] = [
  { field: "vacacion", header: "ID", width: 160, sortable: true },
  { field: "cedula", header: "Cédula", width: 120, sortable: true },
  { field: "nombreEmpleado", header: "Empleado", flex: 1, sortable: true },
  { field: "inicio", header: "Inicio", width: 110 },
  { field: "hasta", header: "Hasta", width: 110 },
  { field: "reintegro", header: "Reintegro", width: 110 },
  { field: "dias", header: "Días", width: 80, type: "number", aggregation: "sum" },
  { field: "total", header: "Monto", width: 130, type: "number", aggregation: "sum" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
    actions: [
      { icon: "view", label: "Ver detalle", action: "view" },
    ],
  },
];

const GRID_ID = buildNominaGridId("vacaciones");



export default function VacacionesPage() {
  const gridRef = useRef<any>(null);
  const router = useRouter();
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);
  const { registered } = useNominaGridRegistration(layoutReady);

  const { data, isLoading } = useVacacionesList({ cedula: cedula || undefined });
  const detalle = useVacacionDetalle(selectedId);

  const rawRows: any[] = data?.data ?? data?.rows ?? [];
  useNominaGridId(gridRef, GRID_ID);
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

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r._id;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setSelectedId(row.vacacion);
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6" fontWeight={600}>
          Vacaciones
        </Typography>
        <Button
          variant="contained"
          startIcon={<PlayArrowIcon />}
          onClick={() => router.push("/vacaciones/procesar")}
        >
          Procesar Vacaciones
        </Button>
      </Stack>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          height="calc(100vh - 200px)"
          show-totals
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
          enable-grouping
          enable-pivot
        />
      </Box>

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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
