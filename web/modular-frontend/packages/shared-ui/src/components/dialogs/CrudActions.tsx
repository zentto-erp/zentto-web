'use client';

import React from 'react';
import { IconButton, Tooltip, Stack } from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import EditIcon from '@mui/icons-material/Edit';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
/** Local stub — replaces @mui/x-data-grid import (legacy) */
type GridRenderCellParams = { value: any; row: any; field: string };
import type { ZenttoColDef } from '../ZenttoDataGrid/types';

export interface CrudActionHandlers<T = any> {
  /** Show detail/view action */
  onView?: (row: T) => void;
  /** Edit action */
  onEdit?: (row: T) => void;
  /** Delete action (opens confirm dialog) */
  onDelete?: (row: T) => void;
  /** Duplicate/copy action */
  onDuplicate?: (row: T) => void;
  /** Extra custom actions rendered after the standard ones */
  extraActions?: (row: T) => React.ReactNode;
}

interface CrudActionsProps<T = any> extends CrudActionHandlers<T> {
  row: T;
  /** Size of icon buttons. Default: 'small' */
  size?: 'small' | 'medium';
}

/**
 * Standard CRUD action buttons for ZenttoDataGrid rows.
 * Use directly in renderCell or via buildCrudActionsColumn().
 */
export function CrudActions<T = any>({
  row,
  onView,
  onEdit,
  onDelete,
  onDuplicate,
  extraActions,
  size = 'small',
}: CrudActionsProps<T>) {
  return (
    <Stack direction="row" spacing={0.25} alignItems="center">
      {onView && (
        <Tooltip title="Ver detalle">
          <IconButton
            size={size}
            onClick={(e) => { e.stopPropagation(); onView(row); }}
            color="primary"
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
      {onEdit && (
        <Tooltip title="Editar">
          <IconButton
            size={size}
            onClick={(e) => { e.stopPropagation(); onEdit(row); }}
            color="default"
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
      {onDuplicate && (
        <Tooltip title="Duplicar">
          <IconButton
            size={size}
            onClick={(e) => { e.stopPropagation(); onDuplicate(row); }}
            color="default"
          >
            <ContentCopyIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
      {onDelete && (
        <Tooltip title="Eliminar">
          <IconButton
            size={size}
            onClick={(e) => { e.stopPropagation(); onDelete(row); }}
            color="error"
          >
            <DeleteOutlineIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
      {extraActions?.(row)}
    </Stack>
  );
}

/**
 * Builds a standard CRUD actions column definition for ZenttoDataGrid.
 *
 * Usage:
 * ```tsx
 * const columns: ZenttoColDef[] = [
 *   { field: 'nombre', headerName: 'Nombre', flex: 1 },
 *   buildCrudActionsColumn({
 *     onView: (row) => router.push(`/detalle/${row.id}`),
 *     onEdit: (row) => setEditRow(row),
 *     onDelete: (row) => setDeleteRow(row),
 *   }),
 * ];
 * ```
 */
export function buildCrudActionsColumn<T = any>(
  handlers: CrudActionHandlers<T>,
  options?: {
    /** Column width. Auto-calculated based on number of actions if not provided. */
    width?: number;
    /** Column header. Default: 'Acciones' */
    headerName?: string;
  }
): ZenttoColDef {
  // Calculate width based on number of visible actions
  const actionCount = [handlers.onView, handlers.onEdit, handlers.onDelete, handlers.onDuplicate]
    .filter(Boolean).length + (handlers.extraActions ? 1 : 0);
  const autoWidth = Math.max(60, actionCount * 38 + 16);

  return {
    field: 'actions',
    headerName: options?.headerName ?? 'Acciones',
    width: options?.width ?? autoWidth,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    renderCell: (params: GridRenderCellParams) => (
      <CrudActions row={params.row as T} {...handlers} />
    ),
  } as ZenttoColDef;
}
