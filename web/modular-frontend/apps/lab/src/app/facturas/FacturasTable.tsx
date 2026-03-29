// Facturas — migrado de MUI DataGrid a @zentto/datagrid nativo
"use client";

import { useEffect, useRef, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Typography, Dialog, DialogTitle, DialogContent, DialogActions, CircularProgress } from "@mui/material";
import { Add as AddIcon } from "@mui/icons-material";
import type { ColumnDef, GridRow } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useFacturasList, useDeleteFactura, useDetalleFactura } from "../../hooks/useFacturas";
import { useTimezone } from "../../hooks/useTimezone";
import { LAB_GRID_IDS } from "../../lib/zentto-grid-ids";

// ─── SVG Icons ───────────────────────────────────────

// ─── Columns ─────────────────────────────────────────
const COLUMNS: ColumnDef[] = [
  { field: 'numeroFactura', header: 'Numero', width: 150, sortable: true },
  { field: 'nombreCliente', header: 'Cliente', flex: 1, minWidth: 180, sortable: true, groupable: true },
  { field: 'fecha', header: 'Fecha', width: 120, type: 'date', sortable: true },
  { field: 'tipoDoc', header: 'Tipo', width: 110, sortable: true, groupable: true,
    statusColors: { FACT: 'primary', PRESUP: 'info', PEDIDO: 'warning' }, statusVariant: 'outlined' },
  { field: 'totalFactura', header: 'Total', width: 140, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'estado', header: 'Estado', width: 120, sortable: true, groupable: true,
    statusColors: { Pagada: 'success', Pendiente: 'warning', Emitida: 'info', Anulada: 'error' }, statusVariant: 'outlined' },
  {
    field: 'actions', header: 'Acciones', type: 'actions', width: 130, pin: 'right',
    actions: [
      { icon: 'view', label: 'Ver', action: 'view' },
      { icon: 'edit', label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: 'delete', label: 'Anular', action: 'delete', color: '#dc2626' },
    ],
  },
];

// Detail columns for master-detail (invoice line items)
const DETAIL_COLUMNS: ColumnDef[] = [
  { field: 'codigo', header: 'Codigo', width: 120 },
  { field: 'descripcion', header: 'Descripcion', flex: 1, minWidth: 200 },
  { field: 'cantidad', header: 'Cant.', width: 70, type: 'number' },
  { field: 'precio', header: 'Precio', width: 110, type: 'number', currency: 'VES' },
  { field: 'descuento', header: 'Desc.', width: 90, type: 'number', currency: 'VES' },
  { field: 'total', header: 'Total', width: 120, type: 'number', currency: 'VES', aggregation: 'sum' },
];

const FILTER_PANEL = [
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'tipoDoc', type: 'select', label: 'Tipo' },
  { field: 'totalFactura', type: 'range', label: 'Total' },
  { field: 'nombreCliente', type: 'text', label: 'Cliente', placeholder: 'Nombre...' },
];

export default function FacturasTable() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [anularOpen, setAnularOpen] = useState(false);
  const [selectedFactura, setSelectedFactura] = useState<string | null>(null);
  const { ready: layoutReady } = useGridLayoutSync(LAB_GRID_IDS.facturas);

  // Register web component
  useEffect(() => {
    if (!layoutReady) return;
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, [layoutReady]);

  // Fetch data
  const { data: facturas, isLoading } = useFacturasList({ page: 1, limit: 100 });
  const { mutate: deleteFactura, isPending: isDeleting } = useDeleteFactura();

  // Map API data to grid rows with detail items
  const rows = useMemo(() => {
    return (facturas?.data || []).map((f: any, idx: number) => ({
      id: f.numeroFactura || idx,
      ...f,
      tipoDoc: 'FACT',
      // items will be loaded on expand
      _hasDetail: true,
    }));
  }, [facturas?.data]);

  // Action handlers
  const handleAction = (e: CustomEvent) => {
    const { action, row } = e.detail;
    if (action === 'view') router.push(`/facturas/${row.numeroFactura}`);
    if (action === 'edit') router.push(`/facturas/${row.numeroFactura}/edit`);
    if (action === 'delete') {
      setSelectedFactura(row.numeroFactura);
      setAnularOpen(true);
    }
  };

  const handleConfirmAnular = () => {
    if (selectedFactura) {
      deleteFactura(selectedFactura, {
        onSuccess: () => { setAnularOpen(false); setSelectedFactura(null); },
        onError: (err) => console.error("Error anulando:", err),
      });
    }
  };

  // Detail renderer: HTML string with invoice header info
  const detailRenderer = (row: any) => `
    <div style="display:flex;align-items:center;gap:12px;padding:8px 0;border-bottom:1px solid rgba(0,0,0,0.06);margin-bottom:8px">
      <strong>${row.numeroFactura}</strong>
      <span style="color:#666">${row.nombreCliente || 'Sin cliente'}</span>
      <span style="padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;background:${
        row.estado === 'Pagada' ? '#ecfdf5;color:#059669' :
        row.estado === 'Anulada' ? '#fef2f2;color:#dc2626' :
        '#eff6ff;color:#2563eb'
      }">${row.estado}</span>
      <span style="flex:1"></span>
      <span style="font-weight:700">${new Intl.NumberFormat('es-VE', { minimumFractionDigits: 2 }).format(Number(row.totalFactura || 0))} VES</span>
    </div>
  `;

  // Bind props to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.filterPanel = FILTER_PANEL;
    el.detailRenderer = detailRenderer;
  }, [rows, isLoading, registered]);

  // Listen for action clicks
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.addEventListener('action-click', handleAction);
    return () => el.removeEventListener('action-click', handleAction);
  }, [registered, router]);

  if (!layoutReady || !registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ p: 2, display: "flex", flexDirection: "column", height: "100%" }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
        <Typography variant="h5" fontWeight={600}>Facturas</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/facturas/new")}>
          Nueva Factura
        </Button>
      </Box>

      {/* Grid nativo */}
      <zentto-grid
        ref={gridRef}
        grid-id={LAB_GRID_IDS.facturas}
        enable-configurator
        default-currency="VES"
        export-filename="facturas"
        height="calc(100vh - 180px)"
        show-totals
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-find
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-row-selection
        enable-filter-panel
        enable-master-detail
      ></zentto-grid>

      {/* Anular Confirmation Dialog */}
      <Dialog open={anularOpen} onClose={() => { setAnularOpen(false); setSelectedFactura(null); }}>
        <DialogTitle>Anular Factura</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de que desea anular la factura <strong>{selectedFactura}</strong>? Esta accion no puede deshacerse.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setAnularOpen(false); setSelectedFactura(null); }}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleConfirmAnular} disabled={isDeleting}>
            {isDeleting ? 'Anulando...' : 'Anular'}
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
