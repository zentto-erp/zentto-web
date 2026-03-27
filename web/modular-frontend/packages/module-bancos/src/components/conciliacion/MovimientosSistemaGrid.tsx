"use client";

import { useEffect, useRef, useState } from "react";
import { Box, Paper, Typography, CircularProgress } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import { useGridLayoutSync } from "@zentto/shared-api";

const COLUMNS: ColumnDef[] = [
  { field: "Fecha", header: "Fecha", width: 100 },
  { field: "Tipo", header: "Tipo", width: 80 },
  { field: "Nro_Ref", header: "Referencia", width: 120 },
  { field: "Concepto", header: "Concepto", flex: 1, minWidth: 180 },
  { field: "Monto", header: "Monto", width: 130, type: "number", aggregation: "sum" },
  { field: "Estado", header: "Estado", width: 120, statusColors: { CONCILIADO: "success", PENDIENTE: "warning" } },
];

interface MovimientosSistemaGridProps {
  movimientos: any[];
  isLoading: boolean;
  hasConciliacion: boolean;
  onSelectionChange?: (id: number | null) => void;
}

const GRID_ID = "module-bancos:conciliacion:movimientos-sistema";

export default function MovimientosSistemaGrid({ movimientos, isLoading, hasConciliacion, onSelectionChange }: MovimientosSistemaGridProps) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const { ready: layoutReady } = useGridLayoutSync(GRID_ID);

  useEffect(() => {
    if (!layoutReady) return;
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, [layoutReady]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = movimientos; el.loading = isLoading;
    el.getRowId = (r: any) => r.ID ?? r.id ?? Math.random();
  }, [movimientos, isLoading, registered]);

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
      <Box sx={{ p: 2, borderBottom: "1px solid", borderColor: "divider", display: "flex", alignItems: "center", gap: 1 }}>
        <AccountBalanceIcon color="primary" />
        <Typography variant="h6" fontWeight={600}>Movimientos del Sistema</Typography>
      </Box>

      {!hasConciliacion ? (
        <Box sx={{ p: 4, textAlign: "center" }}><Typography color="text.secondary">Seleccione una conciliacion para ver los movimientos</Typography></Box>
      ) : isLoading ? (
        <Box sx={{ p: 4, textAlign: "center" }}><CircularProgress /></Box>
      ) : (
        <zentto-grid ref={gridRef} grid-id={GRID_ID} height="400px" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      )}
    </Paper>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
