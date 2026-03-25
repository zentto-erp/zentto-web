'use client';
import { useEffect, useRef, useState } from 'react';
import { Box, Typography, Chip, CircularProgress } from '@mui/material';
import type { ColumnDef, GridRow } from '@zentto/datagrid-core';
import { NativeGridConfigurator, DEFAULT_CONFIG, type NativeGridConfig } from '../../components/NativeGridConfigurator';

const COLUMNS: ColumnDef[] = [
  { field: 'numeroFactura', header: 'N. Factura', width: 140, sortable: true },
  { field: 'nombreCliente', header: 'Cliente', flex: 1, minWidth: 200, sortable: true },
  { field: 'fecha', header: 'Fecha', width: 130, type: 'date', sortable: true },
  { field: 'tipo', header: 'Tipo', width: 110, sortable: true },
  { field: 'totalFactura', header: 'Total', width: 130, type: 'number', currency: 'VES', aggregation: 'sum' },
  {
    field: 'estado', header: 'Estado', width: 120, sortable: true, groupable: true,
    statusColors: { Emitida: 'info', Pagada: 'success', Anulada: 'error' },
    statusVariant: 'outlined',
  },
];

const GROUPABLE = [
  { value: 'estado', label: 'Estado' },
  { value: 'tipo', label: 'Tipo' },
  { value: 'nombreCliente', label: 'Cliente' },
];

const PIVOTABLE = [
  { value: 'nombreCliente', label: 'Cliente' },
  { value: 'estado', label: 'Estado' },
  { value: 'tipo', label: 'Tipo' },
  { value: 'totalFactura', label: 'Total', type: 'number' },
];

const FILTER_PANEL = [
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'tipo', type: 'select', label: 'Tipo' },
  { field: 'totalFactura', type: 'range', label: 'Total' },
  { field: 'fecha', type: 'date-range', label: 'Fecha' },
  { field: 'nombreCliente', type: 'text', label: 'Cliente', placeholder: 'Nombre...' },
];

const DETAIL_RENDERER = (row: any) => `
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;padding:8px 0">
    <div><strong>Factura:</strong> ${row.numeroFactura}</div>
    <div><strong>Cliente:</strong> ${row.nombreCliente}</div>
    <div><strong>Fecha:</strong> ${row.fecha}</div>
    <div><strong>Tipo:</strong> ${row.tipo}</div>
    <div><strong>Total:</strong> ${row.totalFactura}</div>
    <div><strong>Estado:</strong> ${row.estado}</div>
  </div>
`;

export default function NativoFacturasPage() {
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<GridRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [registered, setRegistered] = useState(false);
  const [config, setConfig] = useState<NativeGridConfig>({
    ...DEFAULT_CONFIG,
    groupField: 'estado',
    pivotRowField: 'nombreCliente',
    pivotColField: 'estado',
    pivotValueField: 'totalFactura',
  });
  const [configOpen, setConfigOpen] = useState(false);

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
        const mapped = (data.rows || []).map((item: any, idx: number) => ({
          id: item.DocumentNumber || idx,
          numeroFactura: item.DocumentNumber,
          nombreCliente: item.CustomerName || '',
          fecha: item.DocumentDate,
          tipo: item.OperationType,
          totalFactura: Number(item.TotalAmount || 0),
          estado: item.IsVoided ? 'Anulada' : item.IsPaid === 'S' ? 'Pagada' : 'Emitida',
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

  // Listen for settings-click from grid toolbar
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setConfigOpen(prev => !prev);
    el.addEventListener('settings-click', handler);
    return () => el.removeEventListener('settings-click', handler);
  }, [registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = loading;
    el.showTotals = config.showTotals;
    el.enableHeaderFilters = config.enableHeaderFilters;
    el.enableClipboard = config.enableClipboard;
    el.enableFind = config.enableFind;
    el.enableContextMenu = config.enableContextMenu;
    el.enableStatusBar = config.enableStatusBar;
    el.enableGrouping = config.enableGrouping;
    el.groupField = config.groupField;
    el.groupSort = config.groupSort;
    el.groupSubtotals = config.groupSubtotals;
    el.enableMasterDetail = config.enableMasterDetail;
    el.enableGroupDropZone = config.enableGroupDropZone;
    el.enablePivot = config.enablePivot;
    el.enableImport = config.enableImport;
    el.enableQuickSearch = config.enableQuickSearch;
    if (config.enablePivot && config.pivotRowField && config.pivotColField && config.pivotValueField) {
      el.pivotConfig = {
        rowField: config.pivotRowField,
        columnField: config.pivotColField,
        valueField: config.pivotValueField,
        aggregation: config.pivotAggregation || 'sum',
        showGrandTotals: config.pivotGrandTotals,
      };
    } else {
      el.pivotConfig = undefined;
    }
    el.enableToolbar = true;
    el.enableHeaderMenu = true;
    el.enableSettings = true;
    el.enableFilterPanel = true;
    el.enableRowSelection = true;
    el.filterPanel = FILTER_PANEL;
    el.detailRenderer = DETAIL_RENDERER;
    el.actionButtons = [
      { icon: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>', label: 'Ver', action: 'view' },
      { icon: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>', label: 'Editar', action: 'edit', color: '#e67e22' },
    ];
    el.theme = config.theme;
    el.density = config.density;
    el.locale = config.locale;
  }, [rows, loading, registered, config]);

  if (!registered) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
        <Typography variant="h5" fontWeight={600}>Facturas — Web Component Nativo</Typography>
        <Chip label="@zentto/datagrid" color="success" size="small" />
        <Chip label="Lit + Custom Element" variant="outlined" size="small" />
        <Chip label={`${rows.length} registros`} size="small" />
      </Box>

      <NativeGridConfigurator config={config} onChange={setConfig} groupableFields={GROUPABLE} pivotableFields={PIVOTABLE} open={configOpen} onToggle={setConfigOpen}>
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="facturas-nativo"
          height="calc(100vh - 200px)"
          style={({
            '--zg-primary': config.primaryColor,
            '--zg-header-bg': config.headerBg,
            '--zg-border': config.borderColor,
            '--zg-row-stripe': config.rowAltBg,
            '--zg-font-family': config.fontFamily,
            '--zg-font-size': config.fontSize,
          }) as any}
        ></zentto-grid>
      </NativeGridConfigurator>
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
