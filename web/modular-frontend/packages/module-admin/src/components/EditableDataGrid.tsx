'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Box, Button, Stack } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import type { ColumnDef } from '@zentto/datagrid-core';

type GridRow = Record<string, unknown>;

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

interface EditableDataGridProps {
  rows: GridRow[];
  columns: ColumnDef[];
  loading?: boolean;
  page: number;
  pageSize: number;
  rowCount: number;
  onPageChange: (page: number) => void;
  onAddRow?: () => void;
  onUpdateRow?: (row: GridRow) => Promise<GridRow | void> | GridRow | void;
  onDeleteRow?: (row: GridRow) => Promise<void> | void;
  addButtonText?: string;
  getRowId?: (row: GridRow) => string | number;
  timeZone?: string;
}

function defaultGetRowId(row: GridRow): string | number {
  return String(row.id ?? row.Codigo ?? row.codigo ?? crypto.randomUUID());
}

export default function EditableDataGrid({
  rows,
  columns,
  loading = false,
  page,
  pageSize,
  rowCount,
  onPageChange,
  onAddRow,
  onUpdateRow,
  onDeleteRow,
  addButtonText = 'Nuevo',
  getRowId = defaultGetRowId,
  timeZone,
}: EditableDataGridProps) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [localRows, setLocalRows] = useState<GridRow[]>(rows);

  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    setLocalRows(rows);
  }, [rows]);

  const handleDeleteClick = useCallback(
    async (id: string | number) => {
      const row = localRows.find((r) => String(getRowId(r)) === String(id));
      if (!row) return;
      try {
        if (onDeleteRow) {
          await onDeleteRow(row);
        }
        setLocalRows((prev) => prev.filter((r) => String(getRowId(r)) !== String(id)));
      } catch (error) {
        console.error('Error al eliminar fila', error);
      }
    },
    [getRowId, localRows, onDeleteRow]
  );

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = localRows;
    el.loading = loading;
    el.actionButtons = [
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: SVG_DELETE, label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ];
  }, [columns, localRows, loading, registered]);

  // Listen for action-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      const id = getRowId(row);
      if (action === 'delete') {
        handleDeleteClick(id);
      }
      // edit action could be handled here if needed
    };

    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, getRowId, handleDeleteClick]);

  if (!registered) {
    return null;
  }

  return (
    <Stack spacing={1.5}>
      {onAddRow && (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
          <Button variant="contained" startIcon={<AddIcon />} onClick={onAddRow}>
            {addButtonText}
          </Button>
        </Box>
      )}

      <Box sx={{ width: '100%', minHeight: 420 }}>
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
          enable-editing
          enable-configurator
        ></zentto-grid>
      </Box>
    </Stack>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
