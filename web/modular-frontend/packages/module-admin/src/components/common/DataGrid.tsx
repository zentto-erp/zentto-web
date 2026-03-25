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

const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

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

  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

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

  // Build action buttons
  const actionButtons = useMemo(() => {
    if (actions.length === 0) return [];
    const iconMap: Record<string, string> = {
      view: SVG_VIEW,
      edit: SVG_EDIT,
      delete: SVG_DELETE,
    };
    const colorMap: Record<string, string> = {
      error: '#dc2626',
      warning: '#e67e22',
      success: '#16a34a',
    };
    return actions.map((a) => ({
      icon: iconMap[a.id] || SVG_VIEW,
      label: a.label,
      action: a.id,
      color: a.color ? colorMap[a.color] : undefined,
    }));
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
    el.columns = gridColumns;
    el.rows = gridRows;
    el.loading = isLoading;
    if (actionButtons.length > 0) {
      el.actionButtons = actionButtons;
    }
  }, [gridColumns, gridRows, isLoading, registered, actionButtons]);

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

  if (isLoading && !registered) {
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
