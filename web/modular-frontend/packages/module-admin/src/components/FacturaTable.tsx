"use client";

import { useEffect, useRef, useState } from "react";
import { Box } from "@mui/material";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";

type FacturaRow = {
  NUM_FACT: string;
  FECHA?: string;
  NOMBRE?: string;
  TOTAL?: number;
  COD_USUARIO?: string;
};

const COLUMNS: ColumnDef[] = [
  { field: "NUM_FACT", header: "Numero", flex: 1 },
  { field: "FECHA", header: "Fecha", flex: 1 },
  { field: "NOMBRE", header: "Cliente", flex: 1.5 },
  { field: "TOTAL", header: "Total", flex: 1, type: "number", currency: "VES" },
  { field: "COD_USUARIO", header: "Usuario", flex: 1 },
];

export function FacturaTable({ rows }: { rows: FacturaRow[] }) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r) => ({ id: r.NUM_FACT, ...r }));
    el.loading = false;
  }, [rows, registered]);

  if (!registered) return null;

  return (
    <Box sx={{ width: "100%", minHeight: 300 }}>
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        height="400px"
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
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
