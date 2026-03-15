'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { Box, Button, Stack } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/DeleteOutline';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Close';
import {
  DataGrid,
  GridActionsCellItem,
  GridColDef,
  GridEventListener,
  GridFilterModel,
  GridPaginationModel,
  GridRowEditStopReasons,
  GridRowId,
  GridRowModel,
  GridRowModes,
  GridRowModesModel,
  GridRowsProp,
  GridToolbarContainer,
  GridToolbarFilterButton,
  GridToolbarQuickFilter,
} from '@mui/x-data-grid';

type GridRow = Record<string, unknown>;

interface EditableDataGridProps {
  rows: GridRowsProp;
  columns: GridColDef[];
  loading?: boolean;
  page: number;
  pageSize: number;
  rowCount: number;
  onPageChange: (page: number) => void;
  onAddRow?: () => void;
  onUpdateRow?: (row: GridRow) => Promise<GridRow | void> | GridRow | void;
  onDeleteRow?: (row: GridRow) => Promise<void> | void;
  addButtonText?: string;
  getRowId?: (row: GridRow) => GridRowId;
  filterModel?: GridFilterModel;
  onFilterModelChange?: (model: GridFilterModel) => void;
  filterMode?: 'client' | 'server';
  timeZone?: string;
}

function defaultGetRowId(row: GridRow): GridRowId {
  return String(row.id ?? row.Codigo ?? row.codigo ?? crypto.randomUUID());
}

function CrudToolbar() {
  return (
    <GridToolbarContainer>
      <GridToolbarFilterButton />
      <Box sx={{ flexGrow: 1 }} />
      <GridToolbarQuickFilter debounceMs={300} />
    </GridToolbarContainer>
  );
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
  filterModel,
  onFilterModelChange,
  filterMode = 'client',
  timeZone,
}: EditableDataGridProps) {
  const [localRows, setLocalRows] = useState<GridRowsProp>(rows);
  const [rowModesModel, setRowModesModel] = useState<GridRowModesModel>({});
  const [internalFilterModel, setInternalFilterModel] = useState<GridFilterModel>(() => ({ items: [] }));

  useEffect(() => {
    setLocalRows(rows);
  }, [rows]);

  const handleRowEditStop: GridEventListener<'rowEditStop'> = (params, event) => {
    if (params.reason === GridRowEditStopReasons.rowFocusOut) {
      event.defaultMuiPrevented = true;
    }
  };

  const handleEditClick = useCallback((id: GridRowId) => {
    setRowModesModel((prev) => ({ ...prev, [id]: { mode: GridRowModes.Edit } }));
  }, []);

  const handleSaveClick = useCallback((id: GridRowId) => {
    setRowModesModel((prev) => ({ ...prev, [id]: { mode: GridRowModes.View } }));
  }, []);

  const handleCancelClick = useCallback((id: GridRowId) => {
    setRowModesModel((prev) => ({ ...prev, [id]: { mode: GridRowModes.View, ignoreModifications: true } }));
  }, []);

  const handleDeleteClick = useCallback(
    async (id: GridRowId) => {
      const row = localRows.find((r) => String(getRowId(r as GridRow)) === String(id)) as GridRow | undefined;
      if (!row) return;
      try {
        if (onDeleteRow) {
          await onDeleteRow(row);
        }
        setLocalRows((prev) => prev.filter((r) => String(getRowId(r as GridRow)) !== String(id)));
      } catch (error) {
        console.error('Error al eliminar fila', error);
      }
    },
    [getRowId, localRows, onDeleteRow]
  );

  const processRowUpdate = useCallback(
    async (newRow: GridRowModel) => {
      let updatedRow: GridRow = { ...(newRow as GridRow) };
      if (onUpdateRow) {
        const serverRow = await onUpdateRow(updatedRow);
        if (serverRow) {
          updatedRow = serverRow;
        }
      }

      setLocalRows((prev) =>
        prev.map((row) => {
          const currentId = getRowId(row as GridRow);
          const editedId = getRowId(newRow as GridRow);
          return String(currentId) === String(editedId) ? { ...(row as GridRow), ...updatedRow } : row;
        })
      );

      return updatedRow;
    },
    [getRowId, onUpdateRow]
  );

  // Auto-convert string dates to Date objects and format in company timezone
  const normalizedColumns = useMemo(() => {
    return columns.map((col) => {
      if ((col.type === 'date' || col.type === 'dateTime') && !col.valueGetter) {
        return {
          ...col,
          valueGetter: (value: unknown) => {
            if (value == null || value === '') return null;
            if (value instanceof Date) return value;
            const d = new Date(value as string);
            return isNaN(d.getTime()) ? null : d;
          },
          valueFormatter: (value: unknown) => {
            if (value == null) return '';
            const d = value instanceof Date ? value : new Date(String(value));
            if (isNaN(d.getTime())) return '';
            const opts: Intl.DateTimeFormatOptions = col.type === 'dateTime'
              ? { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }
              : { year: 'numeric', month: '2-digit', day: '2-digit' };
            if (timeZone) opts.timeZone = timeZone;
            return d.toLocaleString('es', opts);
          },
        };
      }
      return col;
    });
  }, [columns, timeZone]);

  const columnsWithActions = useMemo(() => {
    if (normalizedColumns.some((col) => col.field === 'actions')) return normalizedColumns;

    const actionsColumn: GridColDef = {
      field: 'actions',
      type: 'actions',
      headerName: 'Acciones',
      width: 120,
      getActions: (params) => {
        const isInEditMode = rowModesModel[params.id]?.mode === GridRowModes.Edit;

        if (isInEditMode) {
          return [
            <GridActionsCellItem
              key="save"
              icon={<SaveIcon fontSize="small" />}
              label="Guardar"
              onClick={() => handleSaveClick(params.id)}
            />,
            <GridActionsCellItem
              key="cancel"
              icon={<CancelIcon fontSize="small" />}
              label="Cancelar"
              onClick={() => handleCancelClick(params.id)}
            />,
          ];
        }

        return [
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon fontSize="small" />}
            label="Editar"
            onClick={() => handleEditClick(params.id)}
          />,
          <GridActionsCellItem
            key="delete"
            icon={<DeleteIcon fontSize="small" />}
            label="Eliminar"
            onClick={() => handleDeleteClick(params.id)}
          />,
        ];
      },
    };

    return [...normalizedColumns, actionsColumn];
  }, [normalizedColumns, handleCancelClick, handleDeleteClick, handleEditClick, handleSaveClick, rowModesModel]);

  const paginationModel: GridPaginationModel = {
    page: Math.max(page - 1, 0),
    pageSize,
  };
  const effectiveFilterModel = filterModel ?? internalFilterModel;

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
        <DataGrid
          rows={localRows}
          columns={columnsWithActions}
          loading={loading}
          getRowId={getRowId}
          paginationMode="server"
          rowCount={rowCount}
          paginationModel={paginationModel}
          onPaginationModelChange={(model) => onPageChange(model.page + 1)}
          pageSizeOptions={[pageSize]}
          filterMode={filterMode}
          filterModel={effectiveFilterModel}
          onFilterModelChange={(model) => {
            if (onFilterModelChange) {
              onFilterModelChange(model);
              return;
            }
            setInternalFilterModel(model);
          }}
          ignoreDiacritics
          slots={{
            toolbar: CrudToolbar,
          }}
          editMode="row"
          rowModesModel={rowModesModel}
          onRowModesModelChange={setRowModesModel}
          onRowEditStop={handleRowEditStop}
          processRowUpdate={processRowUpdate}
          onProcessRowUpdateError={(error) => {
            console.error('Error al actualizar fila', error);
          }}
          disableRowSelectionOnClick
        />
      </Box>
    </Stack>
  );
}
