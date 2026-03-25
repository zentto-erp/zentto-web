"use client";

import { useEffect, useRef, useState } from "react";
import { Box, Paper, Typography, IconButton, Tooltip, Stack } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import LinkIcon from "@mui/icons-material/Link";

const COLUMNS: ColumnDef[] = [
  { field: "Fecha", header: "Fecha", width: 100 },
  { field: "Descripcion", header: "Descripcion", flex: 1, minWidth: 180 },
  { field: "Referencia", header: "Referencia", width: 120 },
  { field: "Monto", header: "Monto", width: 130, type: "number", aggregation: "sum" },
  { field: "Tipo", header: "Tipo", width: 100 },
];

interface ExtractoPendienteGridProps {
  extracto: any[];
  hasConciliacion: boolean;
  onSelectionChange?: (id: number | null) => void;
  onConciliar?: () => void;
  canConciliar?: boolean;
  isConciliando?: boolean;
}

export default function ExtractoPendienteGrid({
  extracto, hasConciliacion, onSelectionChange, onConciliar, canConciliar = false, isConciliando = false,
}: ExtractoPendienteGridProps) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => { import("@zentto/datagrid").then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = COLUMNS; el.rows = extracto; el.loading = false;
    el.getRowId = (r: any) => r.ID ?? r.id ?? Math.random();
  }, [extracto, registered]);

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
      <Box sx={{ p: 2, borderBottom: "1px solid", borderColor: "divider", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <Typography variant="h6" fontWeight={600}>Extracto pendiente</Typography>
        {onConciliar && (
          <Stack direction="row" spacing={1}>
            <Tooltip title="Conciliar seleccion">
              <span><IconButton color="success" disabled={!canConciliar || isConciliando} onClick={onConciliar}><LinkIcon /></IconButton></span>
            </Tooltip>
          </Stack>
        )}
      </Box>

      {hasConciliacion && extracto.length > 0 ? (
        <zentto-grid ref={gridRef} height="300px" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
      ) : (
        <Box sx={{ p: 3, textAlign: "center" }}>
          <Typography color="text.secondary">{hasConciliacion ? "Sin extractos pendientes" : "Seleccione una conciliacion"}</Typography>
        </Box>
      )}
    </Paper>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
