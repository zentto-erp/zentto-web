'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Paper,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
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
import { ContextActionHeader } from '@zentto/shared-ui';

export type CatalogField = {
  name: string;
  label?: string;
  required?: boolean;
  hidden?: boolean;
  readOnly?: boolean;
};

export type CatalogRow = Record<string, unknown>;

export type CatalogResponse = {
  rows?: CatalogRow[];
  total?: number;
  page?: number;
  limit?: number;
};

export type CatalogMetadataColumn = {
  columnName: string;
  dataType: string;
  isNullable: boolean;
  isIdentity: boolean;
  isComputed: boolean;
  isRowVersion: boolean;
};

export type CatalogTableMetadata = {
  schema: string;
  table: string;
  fullName?: string;
  primaryKeys: string[];
  columns: CatalogMetadataColumn[];
};

export interface CatalogoCrudApiClient {
  list: (endpoint: string, params: { page: number; limit: number; search?: string }) => Promise<CatalogResponse>;
  create: (endpoint: string, payload: Record<string, unknown>) => Promise<unknown>;
  update: (endpoint: string, key: string | number, payload: Record<string, unknown>) => Promise<unknown>;
  remove: (endpoint: string, key: string | number) => Promise<unknown>;
  describe?: (table: string, schema?: string) => Promise<CatalogTableMetadata | null>;
}

interface CatalogoCrudBaseProps {
  endpoint: string;
  title: string;
  apiClient: CatalogoCrudApiClient;
  fields?: CatalogField[];
  tableName?: string;
  schema?: string;
  timeZone?: string;
}

type GridRow = Record<string, unknown>;

const PAGE_SIZE = 20;
const FALLBACK_KEY_CANDIDATES = ['Codigo', 'codigo', 'Id', 'id'];

function normalizeFieldName(name: string): string {
  return name.replace(/[\s_]/g, '').toLowerCase();
}

function isExcludedField(name: string): boolean {
  return normalizeFieldName(name) === 'upsizets';
}

function prettifyLabel(name: string): string {
  return name
    .replace(/_/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function getValueByField(row: CatalogRow, field: string): unknown {
  if (row[field] !== undefined) return row[field];
  const lookup = field.toLowerCase();
  const key = Object.keys(row).find((k) => k.toLowerCase() === lookup);
  return key ? row[key] : undefined;
}

function asString(value: unknown): string {
  if (value === undefined || value === null) return '';
  return String(value);
}

function resolveKeyField(rows: CatalogRow[], metadata?: CatalogTableMetadata | null): string {
  if (metadata?.primaryKeys?.length) return metadata.primaryKeys[0];
  const first = rows[0];
  if (first) {
    const keys = Object.keys(first);
    const match = FALLBACK_KEY_CANDIDATES.find((candidate) => keys.some((k) => k.toLowerCase() === candidate.toLowerCase()));
    if (match) {
      const keyName = keys.find((k) => k.toLowerCase() === match.toLowerCase());
      if (keyName) return keyName;
    }
  }
  return 'Codigo';
}

function resolveFields(input: {
  explicitFields?: CatalogField[];
  rows: CatalogRow[];
  keyField: string;
  metadata?: CatalogTableMetadata | null;
}): CatalogField[] {
  const { explicitFields, rows, keyField, metadata } = input;

  if (explicitFields && explicitFields.length > 0) {
    return explicitFields
      .filter((f) => !isExcludedField(f.name))
      .filter((f) => f.name.toLowerCase() !== keyField.toLowerCase())
      .map((f) => ({ ...f, label: f.label || prettifyLabel(f.name) }));
  }

  if (metadata?.columns?.length) {
    return metadata.columns
      .filter((col) => !col.isComputed && !col.isRowVersion && !col.isIdentity)
      .filter((col) => !isExcludedField(col.columnName))
      .filter((col) => col.columnName.toLowerCase() !== keyField.toLowerCase())
      .map((col) => ({
        name: col.columnName,
        label: prettifyLabel(col.columnName),
        required: !col.isNullable,
      }));
  }

  const first = rows[0];
  if (!first) return [];
  return Object.keys(first)
    .filter((k) => !isExcludedField(k))
    .filter((k) => k.toLowerCase() !== keyField.toLowerCase())
    .map((k) => ({ name: k, label: prettifyLabel(k), required: false }));
}

function extractErrorMessage(error: unknown): string {
  if (!(error instanceof Error)) return 'No se pudo completar la operacion.';
  return error.message || 'No se pudo completar la operacion.';
}

function isLegacyOkError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const message = error.message.trim().toLowerCase();
  return message === 'ok' || message === '"ok"' || message === "'ok'";
}

function buildPayload(values: Record<string, string>, fields: CatalogField[]): Record<string, unknown> {
  const payload: Record<string, unknown> = {};
  for (const field of fields) {
    if (field.readOnly || field.hidden || isExcludedField(field.name)) continue;
    const raw = values[field.name] ?? '';
    const value = raw.trim();
    if (value.length > 0 || field.required) {
      payload[field.name] = value;
    }
  }
  return payload;
}

function buildPayloadFromRow(row: CatalogRow, fields: CatalogField[]): Record<string, unknown> {
  const payload: Record<string, unknown> = {};
  for (const field of fields) {
    if (field.readOnly || field.hidden || isExcludedField(field.name)) continue;
    payload[field.name] = getValueByField(row, field.name);
  }
  return payload;
}

function resolveRowKey(row: CatalogRow, keyField: string): string | number | null {
  const value = getValueByField(row, keyField);
  if (value === undefined || value === null || value === '') return null;
  if (typeof value === 'number' || typeof value === 'string') return value;
  return String(value);
}

function mapDataGridType(sqlType?: string): GridColDef['type'] {
  const t = (sqlType || '').toLowerCase();
  if (['int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].includes(t)) {
    return 'number';
  }
  if (['bit'].includes(t)) return 'boolean';
  if (['date'].includes(t)) return 'date';
  if (['datetime', 'datetime2', 'smalldatetime', 'datetimeoffset', 'time'].includes(t)) return 'dateTime';
  return 'string';
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

export default function CatalogoCrudBase({ endpoint, title, apiClient, fields, tableName, schema, timeZone }: CatalogoCrudBaseProps) {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [createValues, setCreateValues] = useState<Record<string, string>>({});
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // ── Editable DataGrid state ──
  const [localRows, setLocalRows] = useState<GridRowsProp>([]);
  const [rowModesModel, setRowModesModel] = useState<GridRowModesModel>({});

  const metadataQuery = useQuery<CatalogTableMetadata | null>({
    queryKey: [endpoint, 'catalog-meta', tableName || endpoint, schema || 'dbo'],
    enabled: !!apiClient.describe,
    retry: false,
    queryFn: async () => {
      if (!apiClient.describe) return null;
      try {
        return await apiClient.describe(tableName || endpoint, schema);
      } catch {
        return null;
      }
    },
  });

  const listQuery = useQuery<CatalogResponse>({
    queryKey: [endpoint, 'catalog-list', search, page, PAGE_SIZE],
    queryFn: async () =>
      apiClient.list(endpoint, {
        page,
        limit: PAGE_SIZE,
        search: search.trim() || undefined,
      }),
    placeholderData: (previous) => previous,
  });

  const rows = useMemo(() => listQuery.data?.rows ?? [], [listQuery.data]);
  const total = Number(listQuery.data?.total ?? rows.length);
  const limit = Number(listQuery.data?.limit ?? PAGE_SIZE);

  const keyField = useMemo(() => resolveKeyField(rows, metadataQuery.data), [metadataQuery.data, rows]);
  const resolvedFields = useMemo(
    () => resolveFields({ explicitFields: fields, rows, keyField, metadata: metadataQuery.data }),
    [fields, keyField, metadataQuery.data, rows]
  );

  const metadataByColumn = useMemo(() => {
    const map = new Map<string, CatalogMetadataColumn>();
    for (const col of metadataQuery.data?.columns ?? []) {
      map.set(col.columnName.toLowerCase(), col);
    }
    return map;
  }, [metadataQuery.data?.columns]);

  const gridRows = useMemo(
    () =>
      rows.map((row) => {
        const keyValue = resolveRowKey(row, keyField);
        const normalized: Record<string, unknown> = {
          ...row,
          id: keyValue ?? crypto.randomUUID(),
          [keyField]: keyValue ?? '',
        };
        for (const field of resolvedFields) {
          normalized[field.name] = getValueByField(row, field.name);
        }
        return normalized;
      }),
    [keyField, resolvedFields, rows]
  );

  // Sync localRows when gridRows change
  useEffect(() => {
    setLocalRows(gridRows);
  }, [gridRows]);

  const gridColumns = useMemo<GridColDef[]>(
    () => [
      {
        field: keyField,
        headerName: prettifyLabel(keyField),
        width: 120,
        editable: false,
      },
      ...resolvedFields
        .filter((f) => !f.hidden)
        .map((f) => {
          const meta = metadataByColumn.get(f.name.toLowerCase());
          return {
            field: f.name,
            headerName: f.label || prettifyLabel(f.name),
            flex: 1,
            minWidth: 160,
            editable: !f.readOnly,
            type: mapDataGridType(meta?.dataType),
          } as GridColDef;
        }),
    ],
    [keyField, metadataByColumn, resolvedFields]
  );

  // Auto-convert string dates to Date objects and format in company timezone
  const normalizedColumns = useMemo(() => {
    return gridColumns.map((col) => {
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
  }, [gridColumns, timeZone]);

  const createMutation = useMutation({
    mutationFn: async () => {
      const payload = buildPayload(createValues, resolvedFields);
      try {
        return await apiClient.create(endpoint, payload);
      } catch (error) {
        if (!isLegacyOkError(error)) throw error;
        return { ok: true };
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [endpoint, 'catalog-list'] });
      setCreateDialogOpen(false);
      setCreateValues({});
      setFeedback({ type: 'success', message: 'Registro creado correctamente.' });
    },
    onError: (error) => {
      setFeedback({ type: 'error', message: extractErrorMessage(error) });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (row: CatalogRow) => {
      const key = resolveRowKey(row, keyField);
      if (key === null) throw new Error(`No se encontro llave primaria (${keyField}) para editar.`);
      const payload = buildPayloadFromRow(row, resolvedFields);
      try {
        await apiClient.update(endpoint, key, payload);
      } catch (error) {
        if (!isLegacyOkError(error)) throw error;
      }
      return row;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [endpoint, 'catalog-list'] });
    },
    onError: (error) => {
      setFeedback({ type: 'error', message: extractErrorMessage(error) });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (target: CatalogRow) => {
      const key = resolveRowKey(target, keyField);
      if (key === null) throw new Error(`No se encontro llave primaria (${keyField}) para eliminar.`);
      try {
        await apiClient.remove(endpoint, key);
      } catch (error) {
        if (!isLegacyOkError(error)) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [endpoint, 'catalog-list'] });
      setFeedback({ type: 'success', message: 'Registro eliminado correctamente.' });
    },
    onError: (error) => {
      setFeedback({ type: 'error', message: extractErrorMessage(error) });
    },
  });

  const isCreateDisabled = resolvedFields.some((f) => f.required && !asString(createValues[f.name]).trim());

  // ── Inline-editable DataGrid handlers ──

  const getRowId = useCallback(
    (row: GridRow): GridRowId => {
      return String(resolveRowKey(row as CatalogRow, keyField) ?? row.id ?? crypto.randomUUID());
    },
    [keyField]
  );

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
        await deleteMutation.mutateAsync(row as CatalogRow);
        setLocalRows((prev) => prev.filter((r) => String(getRowId(r as GridRow)) !== String(id)));
      } catch (error) {
        console.error('Error al eliminar fila', error);
      }
    },
    [deleteMutation, getRowId, localRows]
  );

  const processRowUpdate = useCallback(
    async (newRow: GridRowModel) => {
      let updatedRow: GridRow = { ...(newRow as GridRow) };
      const serverRow = await updateMutation.mutateAsync(updatedRow as CatalogRow);
      if (serverRow) {
        updatedRow = serverRow as GridRow;
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
    [getRowId, updateMutation]
  );

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
    pageSize: limit,
  };

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <ContextActionHeader
        title={title}
        primaryAction={{
          label: 'Nuevo',
          onClick: () => {
            setCreateValues({});
            setCreateDialogOpen(true);
          }
        }}
        onSearch={(v) => {
          setSearch(v);
          setPage(1);
        }}
        searchPlaceholder="Buscar registros..."
      />

      <Box sx={{ p: { xs: 1, md: 3 }, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        {feedback && <Alert severity={feedback.type} sx={{ mb: 2 }}>{feedback.message}</Alert>}

        <Box sx={{ mt: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          <Stack spacing={1.5}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  setCreateValues({});
                  setCreateDialogOpen(true);
                }}
              >
                Nuevo
              </Button>
            </Box>

            <Box sx={{ width: '100%', minHeight: 420 }}>
              <DataGrid
                rows={localRows}
                columns={columnsWithActions}
                loading={listQuery.isLoading || metadataQuery.isLoading || updateMutation.isPending || deleteMutation.isPending}
                getRowId={getRowId}
                paginationMode="server"
                rowCount={total}
                paginationModel={paginationModel}
                onPaginationModelChange={(model) => setPage(model.page + 1)}
                pageSizeOptions={[limit]}
                filterMode="client"
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
        </Box>
      </Box>

      <Dialog open={createDialogOpen} onClose={() => !createMutation.isPending && setCreateDialogOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Nuevo {title}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            {resolvedFields
              .filter((field) => !field.hidden)
              .filter((field) => !field.readOnly)
              .map((field) => (
                <TextField
                  key={field.name}
                  label={field.label || prettifyLabel(field.name)}
                  required={field.required}
                  value={createValues[field.name] ?? ''}
                  onChange={(e) => setCreateValues((prev) => ({ ...prev, [field.name]: e.target.value }))}
                />
              ))}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)} disabled={createMutation.isPending}>
            Cancelar
          </Button>
          <Button variant="contained" onClick={() => createMutation.mutate()} disabled={createMutation.isPending || isCreateDisabled}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
