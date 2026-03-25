'use client';
import { useEffect, useRef, useState } from 'react';
import { Box, Typography, Chip, CircularProgress } from '@mui/material';
import type { ColumnDef, GridRow } from '@zentto/datagrid-core';
import { NativeGridConfigurator, DEFAULT_CONFIG, type NativeGridConfig } from '../../components/NativeGridConfigurator';

const COLUMNS: ColumnDef[] = [
  { field: 'codigo', header: 'Codigo', width: 120, sortable: true },
  { field: 'descripcion', header: 'Articulo', flex: 1, minWidth: 200, sortable: true },
  { field: 'categoria', header: 'Categoria', width: 130, sortable: true, groupable: true },
  { field: 'precioCompra', header: 'Costo', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'precioVenta', header: 'Precio', width: 110, type: 'number', currency: 'VES', aggregation: 'sum' },
  { field: 'stock', header: 'Stock', width: 100, type: 'number', aggregation: 'sum' },
  { field: 'estado', header: 'Estado', width: 110, statusColors: { Activo: 'success', Inactivo: 'error' }, statusVariant: 'outlined' },
];

const GROUPABLE = [
  { value: 'categoria', label: 'Categoria' },
  { value: 'estado', label: 'Estado' },
];

export default function NativoArticulosPage() {
  const gridRef = useRef<any>(null);
  const [rows, setRows] = useState<GridRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [registered, setRegistered] = useState(false);
  const [config, setConfig] = useState<NativeGridConfig>({ ...DEFAULT_CONFIG, groupField: 'categoria' });

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

  // Sync all config changes to the web component
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
    el.enableMasterDetail = config.enableMasterDetail;
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
        <Typography variant="h5" fontWeight={600}>Articulos — Web Component Nativo</Typography>
        <Chip label="@zentto/datagrid" color="success" size="small" />
        <Chip label="Lit + Custom Element" variant="outlined" size="small" />
        <Chip label={`${rows.length} registros`} size="small" />
      </Box>

      <NativeGridConfigurator config={config} onChange={setConfig} groupableFields={GROUPABLE}>
        <zentto-grid
          ref={gridRef}
          default-currency="VES"
          export-filename="articulos-nativo"
          height="calc(100vh - 200px)"
          style={({
            '--zg-primary': config.primaryColor,
            '--zg-header-bg': config.headerBg,
            '--zg-border-color': config.borderColor,
            '--zg-row-alt-bg': config.rowAltBg,
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
