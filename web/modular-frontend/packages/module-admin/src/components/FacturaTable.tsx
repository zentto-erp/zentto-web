"use client";

import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Box } from "@mui/material";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useAdminGridRegistration } from "../lib/zentto-grid";


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
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 130, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "delete", label: "Anular", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

export function FacturaTable({ rows }: { rows: FacturaRow[] }) {
  const gridRef = useRef<any>(null);
  const router = useRouter();
  const gridId = useScopedGridId('factura-table');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows.map((r) => ({ id: r.NUM_FACT, ...r }));
    el.loading = false;
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
        grid-id={gridId}
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
