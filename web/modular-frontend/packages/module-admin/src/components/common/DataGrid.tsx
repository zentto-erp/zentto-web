// components/common/DataGrid.tsx
/**
 * COMPONENTE GENERICO DE TABLA
 * Reutilizable en TODOS los modulos (Clientes, Proveedores, Articulos, etc.)
 *
 * Migrado de MUI Table HTML nativo a @zentto/datagrid (web component).
 */

'use client';

import React, { useEffect, useRef, useState, useMemo } from 'react';
import { Box, CircularProgress } from '@mui/material';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import { useScopedGridId } from '../../lib/zentto-grid';


export interface Column<T> {
  accessor: keyof T;
  header: string;
  type?: 'text' | 'number' | 'date' | 'currency' | 'percentage' | 'status';
  width?: string;
  sortable?: boolean;
  formatFn?: (value: unknown) => string;
}

export interface Action<T> {
  id: string;
  label: string;
  icon?: React.ReactNode;
  color?: 'primary' | 'secondary' | 'error' | 'warning' | 'success';
  onClick: (row: T) => void;
}

interface DataGridProps<T> {
  columns: Column<T>[];
  data: T[];
  gridId?: string;
  totalRecords?: number;
  pageSize?: number;
  currentPage?: number;
  isLoading?: boolean;
  actions?: Action<T>[];
  onPageChange?: (page: number) => void;
  onSortChange?: (accessor: string, order: 'asc' | 'desc') => void;
  onExport?: () => void;
  title?: string;
  emptyText?: string;
  timeZone?: string;
}

export default function DataGrid<T extends Record<string, unknown>>({
  columns,
  data,
  gridId,
  totalRecords = 0,
  pageSize = 10,
  currentPage = 1,
  isLoading = false,
  actions = [],
  onPageChange,
  onSortChange,
  onExport,
  title,
  emptyText = 'No hay registros',
  timeZone,
}: DataGridProps<T>) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const scopedGridId = useScopedGridId(
    gridId || `${title || 'data-grid'}-${columns.map((column) => String(column.accessor)).join('-')}`
  );
  const { ready: layoutReady } = useGridLayoutSync(scopedGridId);

  useEffect(() => {
    if (!layoutReady) return;
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, [layoutReady]);

  // Map Column<T> to ColumnDef[]
  const gridColumns = useMemo<ColumnDef[]>(() => {
    return columns.map((col) => {
      const def: ColumnDef = {
        field: String(col.accessor),
        header: col.header,
        sortable: col.sortable ?? false,
      };
      if (col.width) def.width = parseInt(col.width, 10) || 150;
      else def.flex = 1;

      if (col.type === 'number') def.type = 'number';
      else if (col.type === 'date') def.type = 'date';
      else if (col.type === 'currency') {
        def.type = 'number';
        def.currency = 'USD';
      }

      return def;
    });
  }, [columns]);

  // Build actions column for zentto-grid v0.3.3+
  const actionsColumn = useMemo<ColumnDef | null>(() => {
    if (actions.length === 0) return null;
    const colorMap: Record<string, string> = {
      error: '#dc2626',
      warning: '#e67e22',
      success: '#16a34a',
    };
    const width = actions.length === 1 ? 80 : actions.length === 2 ? 100 : actions.length === 3 ? 130 : 160;
    return {
      field: 'actions',
      header: 'Acciones',
      type: 'actions' as any,
      width,
      pin: 'right',
      actions: actions.map((a) => ({
        icon: a.id,
        label: a.label,
        action: a.id,
        color: a.color ? colorMap[a.color] : undefined,
      })),
    } as ColumnDef;
  }, [actions]);

  // Map data to rows with id
  const gridRows = useMemo(() => {
    return data.map((row, idx) => ({
      id: idx,
      ...row,
    }));
  }, [data]);

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = actionsColumn ? [...gridColumns, actionsColumn] : gridColumns;
    el.rows = gridRows;
    el.loading = isLoading;
  }, [gridColumns, gridRows, isLoading, registered, actionsColumn]);

  // Listen for action-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered || actions.length === 0) return;

    const handler = (e: CustomEvent) => {
      const { action: actionId, row } = e.detail || {};
      if (!row) return;
      const idx = row.id as number;
      const originalRow = data[idx];
      if (!originalRow) return;
      const matchedAction = actions.find((a) => a.id === actionId);
      if (matchedAction) matchedAction.onClick(originalRow);
    };

    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, actions, data]);

  if ((isLoading || !layoutReady) && !registered) {
    return (
      <Box display="flex" justifyContent="center" p={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (!registered) return null;

  return (
    <Box sx={{ width: '100%', minHeight: 400 }}>
      <zentto-grid
        ref={gridRef}
        grid-id={scopedGridId}
        default-currency="USD"
        export-filename={title || 'export'}
        height="500px"
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
