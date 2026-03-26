'use client';
import { useEffect, useRef, useState } from 'react';
import { Box, Typography, Chip, CircularProgress } from '@mui/material';
import type { ColumnDef, GridRow } from '@zentto/datagrid-core';

const COLUMNS: ColumnDef[] = [
  { field: 'numeroFactura', header: 'N. Factura', width: 140, sortable: true },
  { field: 'nombreCliente', header: 'Cliente', flex: 1, minWidth: 200, sortable: true, groupable: true },
  { field: 'fecha', header: 'Fecha', width: 130, type: 'date', sortable: true },
  { field: 'tipo', header: 'Tipo', width: 110, sortable: true, groupable: true },
  { field: 'totalFactura', header: 'Total', width: 130, type: 'number', currency: 'VES', aggregation: 'sum' },
  {
    field: 'estado', header: 'Estado', width: 120, sortable: true, groupable: true,
    statusColors: { Emitida: 'info', Pagada: 'success', Anulada: 'error' },
    statusVariant: 'outlined',
  },
  {
    field: 'actions', header: 'Acciones', type: 'actions', width: 130, pin: 'right',
    actions: [
      { icon: 'view', label: 'Ver', action: 'view' },
      { icon: 'edit', label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: 'delete', label: 'Anular', action: 'delete', color: '#dc2626' },
    ],
  },
];

// Columnas del detalle (articulos de la factura)
const DETAIL_COLUMNS: ColumnDef[] = [
  { field: 'codigo', header: 'Codigo', width: 100 },
  { field: 'descripcion', header: 'Articulo', flex: 1, minWidth: 180 },
  { field: 'cantidad', header: 'Cant.', width: 70, type: 'number' },
  { field: 'precioUnitario', header: 'P. Unit.', width: 110, type: 'number', currency: 'VES' },
  { field: 'descuento', header: 'Desc. %', width: 80, type: 'number' },
  { field: 'subtotal', header: 'Subtotal', width: 120, type: 'number', currency: 'VES', aggregation: 'sum' },
];

const FILTER_PANEL = [
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'tipo', type: 'select', label: 'Tipo' },
  { field: 'totalFactura', type: 'range', label: 'Total' },
  { field: 'nombreCliente', type: 'text', label: 'Cliente', placeholder: 'Nombre...' },
];

// Catalogo de articulos para generar detalles realistas
const ARTICULOS_CATALOGO = [
  { codigo: 'ALI-001', descripcion: 'Arroz Premium 1kg', precio: 45.00 },
  { codigo: 'ALI-002', descripcion: 'Aceite de Oliva Extra Virgen 500ml', precio: 120.00 },
  { codigo: 'ALI-003', descripcion: 'Harina de Trigo Todo Uso 1kg', precio: 35.00 },
  { codigo: 'ALI-004', descripcion: 'Azucar Refinada 1kg', precio: 38.00 },
  { codigo: 'ALI-005', descripcion: 'Pasta Larga Espagueti 500g', precio: 28.00 },
  { codigo: 'BEB-001', descripcion: 'Agua Mineral 1.5L (Pack 6)', precio: 65.00 },
  { codigo: 'BEB-002', descripcion: 'Jugo de Naranja Natural 1L', precio: 55.00 },
  { codigo: 'LAC-001', descripcion: 'Leche Completa UHT 1L', precio: 42.00 },
  { codigo: 'LAC-002', descripcion: 'Queso Blanco Llanero 500g', precio: 85.00 },
  { codigo: 'LAC-003', descripcion: 'Yogurt Natural 500ml', precio: 48.00 },
  { codigo: 'CAR-001', descripcion: 'Pechuga de Pollo 1kg', precio: 95.00 },
  { codigo: 'CAR-002', descripcion: 'Carne Molida Premium 1kg', precio: 150.00 },
  { codigo: 'LIM-001', descripcion: 'Detergente Liquido 2L', precio: 75.00 },
  { codigo: 'LIM-002', descripcion: 'Jabon de Manos Antibacterial 400ml', precio: 35.00 },
  { codigo: 'PAP-001', descripcion: 'Papel Higienico (Pack 12)', precio: 95.00 },
  { codigo: 'VER-001', descripcion: 'Tomate Perita 1kg', precio: 32.00 },
  { codigo: 'VER-002', descripcion: 'Cebolla Blanca 1kg', precio: 25.00 },
  { codigo: 'VER-003', descripcion: 'Papa 1kg', precio: 28.00 },
];

/** Generate realistic detail items for an invoice based on its total */
function generateDetailItems(factura: GridRow): GridRow[] {
  const total = Number(factura.totalFactura) || 0;
  if (total <= 0) return [];

  // Seed from factura number for consistent results
  const seed = String(factura.numeroFactura || '').split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  const rng = (i: number) => ((seed * 13 + i * 37) % 100) / 100;

  const numItems = Math.max(2, Math.min(8, Math.floor(rng(0) * 6) + 2));
  const items: GridRow[] = [];
  let remaining = total;

  for (let i = 0; i < numItems; i++) {
    const art = ARTICULOS_CATALOGO[(seed + i * 7) % ARTICULOS_CATALOGO.length];
    const cantidad = Math.floor(rng(i + 1) * 10) + 1;
    const descuento = rng(i + 2) > 0.7 ? Math.floor(rng(i + 3) * 15) : 0;
    const isLast = i === numItems - 1;

    let precioUnitario = art.precio * (1 + rng(i + 4) * 2);
    let subtotal = precioUnitario * cantidad * (1 - descuento / 100);

    if (isLast) {
      // Adjust last item so detail totals match invoice total
      subtotal = Math.max(0, remaining);
      precioUnitario = cantidad > 0 ? subtotal / cantidad / (1 - descuento / 100) : 0;
    }

    remaining -= subtotal;

    items.push({
      id: `${factura.numeroFactura}-${i + 1}`,
      codigo: art.codigo,
      descripcion: art.descripcion,
      cantidad,
      precioUnitario: Math.round(precioUnitario * 100) / 100,
      descuento,
      subtotal: Math.round(subtotal * 100) / 100,
    });
  }

  return items;
}


export default function NativoFacturasPage() {
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<GridRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    async function fetchData() {
      try {
        const sessionRes = await fetch('/api/auth/session');
        const session = await sessionRes.json();
        const res = await fetch('/api/v1/documentos-venta?tipoOperacion=FACT&page=1&limit=50', {
          headers: {
            'Authorization': `Bearer ${session.accessToken}`,
            'x-company-id': String(session.company?.companyId || 1),
            'x-branch-id': String(session.company?.branchId || 1),
          },
        });
        const data = await res.json();
        if (data.error) console.warn('API warning:', data.error);
        const mapped = (data.rows || []).map((item: any, idx: number) => {
          const factura: GridRow = {
            id: item.DocumentNumber || idx,
            numeroFactura: item.DocumentNumber,
            nombreCliente: item.CustomerName || '',
            fecha: item.DocumentDate,
            tipo: item.OperationType,
            totalFactura: Number(item.TotalAmount || 0),
            estado: item.IsVoided ? 'Anulada' : item.IsPaid === 'S' ? 'Pagada' : 'Emitida',
          };
          // Generate detail items for master-detail
          factura.items = generateDetailItems(factura);
          return factura;
        });
        setRows(mapped);
      } catch (err) {
        console.error('Error fetching:', err);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = loading;
    el.filterPanel = FILTER_PANEL;
    // Master-detail: child grid with invoice line items
    el.detailColumns = DETAIL_COLUMNS;
    el.detailRowsAccessor = (row: GridRow) => (row.items as GridRow[]) || [];
    // Actions now defined as type:'actions' column in COLUMNS — no need for el.actionButtons
  }, [rows, loading, registered]);

  if (!registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2, flexWrap: 'wrap' }}>
        <Typography variant="h5" fontWeight={600} sx={{ fontSize: { xs: 16, sm: 24 } }}>Facturas — Web Component Nativo</Typography>
        <Chip label="@zentto/datagrid" color="success" size="small" />
        <Chip label="Lit + Custom Element" variant="outlined" size="small" />
        <Chip label={`${rows.length} registros`} size="small" />
      </Box>

      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="facturas-nativo"
        height="calc(100vh - 160px)"
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
        enable-import
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
