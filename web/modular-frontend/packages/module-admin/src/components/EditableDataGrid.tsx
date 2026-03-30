'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Box, Button, Stack } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import { useScopedGridId, useAdminGridRegistration } from '../lib/zentto-grid';

type GridRow = Record<string, unknown>;


interface EditableDataGridProps {
  rows: GridRow[];
  columns: ColumnDef[];
  gridId?: string;
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
  gridId,
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
  const [localRows, setLocalRows] = useState<GridRow[]>(rows);
  const scopedGridId = useScopedGridId(
    gridId || `editable-grid-${columns.map((column) => column.field).join('-')}`
  );
  const { ready: layoutReady } = useGridLayoutSync(scopedGridId);
  const { registered } = useAdminGridRegistration(layoutReady);

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
    const actionsCol: ColumnDef = {
      field: 'actions',
      header: 'Acciones',
      type: 'actions' as any,
      width: 100,
      pin: 'right',
      actions: [
        { icon: "edit", label: 'Editar', action: 'edit', color: '#e67e22' },
        { icon: "delete", label: 'Eliminar', action: 'delete', color: '#dc2626' },
      ],
    } as ColumnDef;
    el.columns = [...columns, actionsCol];
    el.rows = localRows;
    el.loading = loading;
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
          grid-id={scopedGridId}
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
