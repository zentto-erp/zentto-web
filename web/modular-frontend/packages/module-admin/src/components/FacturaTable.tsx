"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Box } from "@mui/material";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

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
  const router = useRouter();
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
    el.actionButtons = [
      { icon: SVG_VIEW, label: 'Ver', action: 'view' },
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: SVG_DELETE, label: 'Anular', action: 'delete', color: '#dc2626' },
    ];
  }, [rows, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view') router.push(`/facturas/${row.NUM_FACT}`);
      if (action === 'edit') router.push(`/facturas/${row.NUM_FACT}/edit`);
      if (action === 'delete') router.push(`/facturas/${row.NUM_FACT}`);
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, router]);

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
