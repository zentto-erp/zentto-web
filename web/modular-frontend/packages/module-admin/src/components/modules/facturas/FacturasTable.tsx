// components/modules/facturas/FacturasTable.tsx
"use client";

import { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Typography,
} from "@mui/material";
import { ConfirmDialog } from "@zentto/shared-ui";
import {
  useFacturasList,
  useDeleteFactura,
  useDetalleFactura,
} from "../../../hooks/useFacturas";
import { useTimezone } from "@zentto/shared-auth";
import { toDateOnly, useGridLayoutSync } from "@zentto/shared-api";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";


// ============ Master-detail: renglones de factura ============
const DETAIL_COLUMNS: ColumnDef[] = [
  { field: "lineNumber", header: "#", width: 50 },
  { field: "codigo", header: "Codigo", width: 130 },
  { field: "descripcion", header: "Descripcion", flex: 1, minWidth: 200 },
  { field: "cantidad", header: "Cantidad", width: 100, type: "number" },
  { field: "precio", header: "Precio", width: 120, type: "number", currency: "VES" },
  { field: "descuento", header: "Descuento", width: 110, type: "number", currency: "VES" },
  { field: "total", header: "Total", width: 120, type: "number", currency: "VES", aggregation: "sum" },
];

// ============ Columnas principales ============
const COLUMNS: ColumnDef[] = [
  { field: "numeroFactura", header: "Numero", width: 150, sortable: true },
  { field: "nombreCliente", header: "Cliente", flex: 1, minWidth: 180, sortable: true },
  { field: "fecha", header: "Fecha", width: 120, type: "date", sortable: true },
  {
    field: "tipoDoc", header: "Tipo", width: 110,
    statusColors: { FACT: "primary", PRESUP: "info", PEDIDO: "warning" },
    statusVariant: "outlined",
  },
  { field: "totalFactura", header: "Total", width: 140, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "estado", header: "Estado", width: 120,
    statusColors: { Pagada: "success", Pendiente: "warning", Emitida: "info", Anulada: "error", Cancelada: "default" },
    statusVariant: "outlined",
  },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "delete", label: "Anular", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const gridId = useScopedGridId('facturas-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(10);
  const [anularOpen, setAnularOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);

  const { data: facturas, isLoading } = useFacturasList({
    page: page + 1,
    limit: pageSize,
  });

  const { mutate: deleteFactura, isPending: isDeleting } = useDeleteFactura();

  const handleAnularClick = (numero: string) => {
    setSelectedFactura(numero);
    setAnularOpen(true);
  };

  const handleConfirmAnular = () => {
    if (selectedFactura) {
      deleteFactura(selectedFactura, {
        onSuccess: () => {
          setAnularOpen(false);
          setSelectedFactura(null);
        },
        onError: (err) => {
          console.error("Error anulando:", err);
        },
      });
    }
  };

  const rows = useMemo(
    () =>
      (facturas?.data || []).map((f: any, idx: number) => ({
        id: f.numeroFactura || idx,
        ...f,
        fecha: f.fecha ? toDateOnly(f.fecha, timeZone) : "",
      })),
    [facturas?.data, timeZone]
  );

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.detailColumns = DETAIL_COLUMNS;
    el.detailRowsAccessor = (row: GridRow) => {
      // Detail rows will be populated via action-click -> view
      // For now, return empty — master-detail requires items on the row
      return (row._detailRows as GridRow[]) || [];
    };
  }, [rows, isLoading, registered]);

  // Listen for action-click and create-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`/facturas/${row.numeroFactura}`);
      if (action === "delete") handleAnularClick(row.numeroFactura);
    };
    const createHandler = () => router.push("/facturas/new");

    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, router]);

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 2 }}>
        Facturas
      </Typography>

      {/* zentto-grid con master-detail */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            default-currency="VES"
            export-filename="facturas"
            height="100%"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-master-detail
            enable-configurator
            enable-create
            create-label="Nueva Factura"
          ></zentto-grid>
        )}
      </Box>

      {/* Anular Confirmation Dialog */}
      <ConfirmDialog
        open={anularOpen}
        title="Anular Factura"
        message={`Esta seguro de que desea anular la factura ${selectedFactura || ""}? Esta accion no puede deshacerse.`}
        confirmLabel={isDeleting ? "Anulando..." : "Anular"}
        variant="danger"
        onConfirm={handleConfirmAnular}
        onClose={() => {
          setAnularOpen(false);
          setSelectedFactura(null);
        }}
        loading={isDeleting}
      />
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
