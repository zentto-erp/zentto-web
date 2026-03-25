'use client';
import { useEffect, useRef, useState } from 'react';
import { Box, Typography, Chip, CircularProgress } from '@mui/material';
import type { ColumnDef, GridRow } from '@zentto/datagrid-core';

const COLUMNS: ColumnDef[] = [
  { field: 'codigo', header: 'Codigo', width: 120, sortable: true },
  { field: 'descripcion', header: 'Articulo', flex: 1, minWidth: 200, sortable: true },
  { field: 'categoria', header: 'Categoria', width: 130, sortable: true, groupable: true },
  { field: 'precioCompra', header: 'Costo', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'precioVenta', header: 'Precio', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'stock', header: 'Stock', width: 100, type: 'number', aggregation: 'sum' },
  { field: 'estado', header: 'Estado', width: 110, groupable: true, statusColors: { Activo: 'success', Inactivo: 'error' }, statusVariant: 'outlined' },
];

const FILTER_PANEL = [
  { field: 'categoria', type: 'select', label: 'Categoria' },
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'precioVenta', type: 'range', label: 'Precio' },
  { field: 'descripcion', type: 'text', label: 'Buscar', placeholder: 'Nombre del articulo...' },
];

const DETAIL_RENDERER = (row: any) => `
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;padding:8px 0">
    <div><strong>Codigo:</strong> ${row.codigo}</div>
    <div><strong>Categoria:</strong> ${row.categoria}</div>
    <div><strong>Stock:</strong> ${row.stock}</div>
    <div><strong>Costo:</strong> ${row.precioCompra}</div>
    <div><strong>Precio:</strong> ${row.precioVenta}</div>
    <div><strong>Estado:</strong> ${row.estado}</div>
  </div>
`;

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>';

export default function NativoArticulosPage() {
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
        const res = await fetch('/api/v1/inventario/articulos?page=1&limit=100', {
          headers: {
            'Authorization': `Bearer ${session.accessToken}`,
            'x-company-id': String(session.company?.companyId || 1),
            'x-branch-id': String(session.company?.branchId || 1),
          },
        });
        const data = await res.json();
        const mapped = (data.rows || data.data || []).map((item: any, idx: number) => ({
          id: item.CODIGO || idx,
          codigo: item.CODIGO,
          descripcion: item.DESCRIPCION,
          categoria: item.Categoria || '',
          precioCompra: Number(item.PRECIO_COMPRA || 0),
          precioVenta: Number(item.PRECIO_VENTA || 0),
          stock: Number(item.EXISTENCIA || 0),
          estado: item.Eliminado ? 'Inactivo' : 'Activo',
        }));
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
    el.detailRenderer = DETAIL_RENDERER;
    el.actionButtons = [
      { icon: SVG_VIEW, label: 'Ver', action: 'view' },
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: SVG_DELETE, label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ];
  }, [rows, loading, registered]);

  if (!registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2, flexWrap: 'wrap' }}>
        <Typography variant="h5" fontWeight={600} sx={{ fontSize: { xs: 16, sm: 24 } }}>Articulos — Web Component Nativo</Typography>
        <Chip label="@zentto/datagrid" color="success" size="small" />
        <Chip label="Lit + Custom Element" variant="outlined" size="small" />
        <Chip label={`${rows.length} registros`} size="small" />
      </Box>

      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="articulos-nativo"
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
        enable-drag-drop
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
