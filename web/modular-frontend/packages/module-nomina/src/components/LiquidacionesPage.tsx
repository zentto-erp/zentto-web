"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box, Typography, Button, Stack, Dialog, DialogTitle, DialogContent, DialogActions, CircularProgress,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import CalculateIcon from "@mui/icons-material/Calculate";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { useLiquidacionesList, useLiquidacionDetalle } from "../hooks/useNomina";

const COLUMNS: ColumnDef[] = [
  { field: "liquidacionId", header: "ID", width: 100 },
  { field: "cedula", header: "Cédula", width: 120, sortable: true },
  { field: "nombre", header: "Empleado", flex: 1, sortable: true },
  { field: "fechaRetiro", header: "Fecha Retiro", width: 120 },
  { field: "causaRetiro", header: "Causa", width: 140 },
  { field: "montoTotal", header: "Total", width: 140, type: "number", aggregation: "sum" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 80, pin: "right",
    actions: [
      { icon: "view", label: "Ver liquidacion", action: "view" },
    ],
  },
];

const DETAIL_COLUMNS: ColumnDef[] = [
  { field: "concepto", header: "Concepto", flex: 1, minWidth: 200 },
  { field: "monto", header: "Monto", width: 140, type: "number" },
];



export default function LiquidacionesPage() {
  const gridRef = useRef<any>(null);
  const detalleGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const router = useRouter();
  const [cedula, setCedula] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { data, isLoading } = useLiquidacionesList({ cedula: cedula || undefined });
  const detalle = useLiquidacionDetalle(selectedId);

  const rows = Array.isArray(data) ? data : data?.rows ?? [];

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = rows; el.loading = isLoading;
    el.getRowId = (r: any) => r.liquidacionId ?? r.id ?? Math.random();
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => { if (e.detail.action === "view") setSelectedId(e.detail.row.liquidacionId); };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  // Detail dialog grid
  useEffect(() => {
    const el = detalleGridRef.current; if (!el || !registered || !selectedId) return;
    const dRows = ((detalle.data?.detalle ?? []) as any[]).map((d: any, i: number) => ({ ...d, _id: i }));
    el.columns = DETAIL_COLUMNS; el.rows = dRows; el.loading = detalle.isLoading;
    el.getRowId = (r: any) => r._id;
  }, [detalle.data, detalle.isLoading, registered, selectedId]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6" fontWeight={600}>Liquidaciones</Typography>
        <Button variant="contained" startIcon={<CalculateIcon />} onClick={() => router.push("/nomina/liquidaciones/nueva")}>Nueva Liquidación</Button>
      </Stack>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid ref={gridRef} height="calc(100vh - 200px)" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
      </Box>

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
                <Box sx={{ height: 300, mt: 2 }}>
                  <zentto-grid ref={detalleGridRef} height="100%" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator enable-grouping enable-pivot />
                </Box>
              )}
            </Box>
          ) : <Typography>No se encontró información</Typography>}
        </DialogContent>
        <DialogActions><Button onClick={() => setSelectedId(null)}>Cerrar</Button></DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
