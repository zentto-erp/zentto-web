'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, TextField, Typography } from '@mui/material';
import { ModulePageShell } from '@zentto/shared-ui';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import { useScopedGridId, useAdminGridRegistration } from '../../../lib/zentto-grid';


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

function mapColumnType(sqlType?: string): string | undefined {
  const t = (sqlType || '').toLowerCase();
  if (['int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].includes(t)) {
    return 'number';
  }
  if (['bit'].includes(t)) return 'boolean';
  if (['date'].includes(t)) return 'date';
  if (['datetime', 'datetime2', 'smalldatetime', 'datetimeoffset', 'time'].includes(t)) return 'date';
  return undefined;
}

export default function CatalogoCrudBase({ endpoint, title, apiClient, fields, tableName, schema, timeZone }: CatalogoCrudBaseProps) {
  const queryClient = useQueryClient();
  const gridRef = useRef<any>(null);
  const gridId = useScopedGridId(`${endpoint || title}-catalogo`);
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);
  const [page, setPage] = useState(1);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [createValues, setCreateValues] = useState<Record<string, string>>({});
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

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
    queryKey: [endpoint, 'catalog-list', page, PAGE_SIZE],
    queryFn: async () =>
      apiClient.list(endpoint, {
        page,
        limit: PAGE_SIZE,
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

  const gridColumns = useMemo<ColumnDef[]>(
    () => [
      {
        field: keyField,
        header: prettifyLabel(keyField),
        width: 120,
      },
      ...resolvedFields
        .filter((f) => !f.hidden)
        .map((f) => {
          const meta = metadataByColumn.get(f.name.toLowerCase());
          const colDef: ColumnDef = {
            field: f.name,
            header: f.label || prettifyLabel(f.name),
            flex: 1,
            minWidth: 160,
          };
          const colType = mapColumnType(meta?.dataType);
          if (colType) colDef.type = colType as any;
          return colDef;
        }),
      {
        field: 'actions',
        header: 'Acciones',
        type: 'actions' as any,
        width: 100,
        pin: 'right',
        actions: [
          { icon: "edit", label: 'Editar', action: 'edit', color: '#e67e22' },
          { icon: "delete", label: 'Eliminar', action: 'delete', color: '#dc2626' },
        ],
      } as ColumnDef,
    ],
    [keyField, metadataByColumn, resolvedFields]
  );

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

  // Bind data to web component
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = gridColumns;
    el.rows = gridRows;
    el.loading = listQuery.isLoading || metadataQuery.isLoading || updateMutation.isPending || deleteMutation.isPending;
  }, [gridColumns, gridRows, listQuery.isLoading, metadataQuery.isLoading, updateMutation.isPending, deleteMutation.isPending, registered]);

  // Listen for action-click and create-click events
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const actionHandler = async (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === 'delete') {
        await deleteMutation.mutateAsync(row as CatalogRow);
      }
      // edit could be handled here if needed
    };
    const createHandler = () => {
      setCreateValues({});
      setCreateDialogOpen(true);
    };

    el.addEventListener('action-click', actionHandler);
    el.addEventListener('create-click', createHandler);
    return () => {
      el.removeEventListener('action-click', actionHandler);
      el.removeEventListener('create-click', createHandler);
    };
  }, [registered, deleteMutation]);

  const isCreateDisabled = resolvedFields.some((f) => f.required && !asString(createValues[f.name]).trim());

  return (
    <>
      <ModulePageShell sx={{ display: 'flex', flexDirection: 'column', minHeight: 500 }}>
        {feedback && <Alert severity={feedback.type} sx={{ mb: 2 }}>{feedback.message}</Alert>}

        <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 500 }}>
          {registered && (
            <zentto-grid
              ref={gridRef}
              grid-id={gridId}
              default-currency="VES"
              height="100%"
              enable-toolbar
              enable-header-menu
              enable-header-filters
              enable-clipboard
              enable-quick-search
              enable-context-menu
              enable-status-bar
              enable-editing
              enable-configurator
              enable-create
              create-label="Nuevo"
            ></zentto-grid>
          )}
        </Box>
      </ModulePageShell>

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
    </>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
