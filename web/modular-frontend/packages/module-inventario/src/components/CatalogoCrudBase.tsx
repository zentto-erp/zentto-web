'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle,
  Paper, Stack, TextField, Typography,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import type { ColumnDef } from '@zentto/datagrid-core';
import { ContextActionHeader } from '@zentto/shared-ui';

export type CatalogField = { name: string; label?: string; required?: boolean; hidden?: boolean; readOnly?: boolean; };
export type CatalogRow = Record<string, unknown>;
export type CatalogResponse = { rows?: CatalogRow[]; total?: number; page?: number; limit?: number; };
export type CatalogMetadataColumn = { columnName: string; dataType: string; isNullable: boolean; isIdentity: boolean; isComputed: boolean; isRowVersion: boolean; };
export type CatalogTableMetadata = { schema: string; table: string; fullName?: string; primaryKeys: string[]; columns: CatalogMetadataColumn[]; };

export interface CatalogoCrudApiClient {
  list: (endpoint: string, params: { page: number; limit: number; search?: string }) => Promise<CatalogResponse>;
  create: (endpoint: string, payload: Record<string, unknown>) => Promise<unknown>;
  update: (endpoint: string, key: string | number, payload: Record<string, unknown>) => Promise<unknown>;
  remove: (endpoint: string, key: string | number) => Promise<unknown>;
  describe?: (table: string, schema?: string) => Promise<CatalogTableMetadata | null>;
}

interface CatalogoCrudBaseProps {
  endpoint: string; title: string; apiClient: CatalogoCrudApiClient;
  fields?: CatalogField[]; tableName?: string; schema?: string; timeZone?: string;
}

const PAGE_SIZE = 20;
const FALLBACK_KEY_CANDIDATES = ['Codigo', 'codigo', 'Id', 'id'];

function normalizeFieldName(name: string): string { return name.replace(/[\s_]/g, '').toLowerCase(); }
function isExcludedField(name: string): boolean { return normalizeFieldName(name) === 'upsizets'; }
function prettifyLabel(name: string): string { return name.replace(/_/g, ' ').replace(/([a-z])([A-Z])/g, '$1 $2').replace(/\s+/g, ' ').trim().replace(/\b\w/g, (c) => c.toUpperCase()); }
function getValueByField(row: CatalogRow, field: string): unknown { if (row[field] !== undefined) return row[field]; const lookup = field.toLowerCase(); const key = Object.keys(row).find((k) => k.toLowerCase() === lookup); return key ? row[key] : undefined; }
function asString(value: unknown): string { if (value === undefined || value === null) return ''; return String(value); }

function resolveKeyField(rows: CatalogRow[], metadata?: CatalogTableMetadata | null): string {
  if (metadata?.primaryKeys?.length) return metadata.primaryKeys[0];
  const first = rows[0];
  if (first) { const keys = Object.keys(first); const match = FALLBACK_KEY_CANDIDATES.find((candidate) => keys.some((k) => k.toLowerCase() === candidate.toLowerCase())); if (match) { const keyName = keys.find((k) => k.toLowerCase() === match.toLowerCase()); if (keyName) return keyName; } }
  return 'Codigo';
}

function resolveFields(input: { explicitFields?: CatalogField[]; rows: CatalogRow[]; keyField: string; metadata?: CatalogTableMetadata | null; }): CatalogField[] {
  const { explicitFields, rows, keyField, metadata } = input;
  if (explicitFields && explicitFields.length > 0) return explicitFields.filter((f) => !isExcludedField(f.name)).filter((f) => f.name.toLowerCase() !== keyField.toLowerCase()).map((f) => ({ ...f, label: f.label || prettifyLabel(f.name) }));
  if (metadata?.columns?.length) return metadata.columns.filter((col) => !col.isComputed && !col.isRowVersion && !col.isIdentity).filter((col) => !isExcludedField(col.columnName)).filter((col) => col.columnName.toLowerCase() !== keyField.toLowerCase()).map((col) => ({ name: col.columnName, label: prettifyLabel(col.columnName), required: !col.isNullable }));
  const first = rows[0];
  if (!first) return [];
  return Object.keys(first).filter((k) => !isExcludedField(k)).filter((k) => k.toLowerCase() !== keyField.toLowerCase()).map((k) => ({ name: k, label: prettifyLabel(k), required: false }));
}

function extractErrorMessage(error: unknown): string { if (!(error instanceof Error)) return 'No se pudo completar la operacion.'; return error.message || 'No se pudo completar la operacion.'; }
function isLegacyOkError(error: unknown): boolean { if (!(error instanceof Error)) return false; const message = error.message.trim().toLowerCase(); return message === 'ok' || message === '"ok"' || message === "'ok'"; }
function buildPayload(values: Record<string, string>, fields: CatalogField[]): Record<string, unknown> { const payload: Record<string, unknown> = {}; for (const field of fields) { if (field.readOnly || field.hidden || isExcludedField(field.name)) continue; const raw = values[field.name] ?? ''; const value = raw.trim(); if (value.length > 0 || field.required) payload[field.name] = value; } return payload; }
function resolveRowKey(row: CatalogRow, keyField: string): string | number | null { const value = getValueByField(row, keyField); if (value === undefined || value === null || value === '') return null; if (typeof value === 'number' || typeof value === 'string') return value; return String(value); }

function mapColumnType(sqlType?: string): ColumnDef['type'] {
  const t = (sqlType || '').toLowerCase();
  if (['int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].includes(t)) return 'number';
  if (['date', 'datetime', 'datetime2', 'smalldatetime', 'datetimeoffset'].includes(t)) return 'date';
  return undefined;
}

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

export default function CatalogoCrudBase({ endpoint, title, apiClient, fields, tableName, schema, timeZone }: CatalogoCrudBaseProps) {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editKey, setEditKey] = useState<string | number | null>(null);
  const [formValues, setFormValues] = useState<Record<string, string>>({});
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const metadataQuery = useQuery<CatalogTableMetadata | null>({
    queryKey: [endpoint, 'catalog-meta', tableName || endpoint, schema || 'dbo'],
    enabled: !!apiClient.describe, retry: false,
    queryFn: async () => { if (!apiClient.describe) return null; try { return await apiClient.describe(tableName || endpoint, schema); } catch { return null; } },
  });

  const listQuery = useQuery<CatalogResponse>({
    queryKey: [endpoint, 'catalog-list', search, page, PAGE_SIZE],
    queryFn: async () => apiClient.list(endpoint, { page, limit: PAGE_SIZE, search: search.trim() || undefined }),
    placeholderData: (previous) => previous,
  });

  const rows = useMemo(() => listQuery.data?.rows ?? [], [listQuery.data]);
  const total = Number(listQuery.data?.total ?? rows.length);
  const limit = Number(listQuery.data?.limit ?? PAGE_SIZE);

  const keyField = useMemo(() => resolveKeyField(rows, metadataQuery.data), [metadataQuery.data, rows]);
  const resolvedFields = useMemo(() => resolveFields({ explicitFields: fields, rows, keyField, metadata: metadataQuery.data }), [fields, keyField, metadataQuery.data, rows]);

  const metadataByColumn = useMemo(() => { const map = new Map<string, CatalogMetadataColumn>(); for (const col of metadataQuery.data?.columns ?? []) map.set(col.columnName.toLowerCase(), col); return map; }, [metadataQuery.data?.columns]);

  const gridRows = useMemo(() => rows.map((row) => {
    const keyValue = resolveRowKey(row, keyField);
    const normalized: Record<string, unknown> = { ...row, id: keyValue ?? crypto.randomUUID(), [keyField]: keyValue ?? '' };
    for (const field of resolvedFields) normalized[field.name] = getValueByField(row, field.name);
    return normalized;
  }), [keyField, resolvedFields, rows]);

  const gridColumns = useMemo<ColumnDef[]>(() => [
    { field: keyField, header: prettifyLabel(keyField), width: 120, sortable: true },
    ...resolvedFields.filter((f) => !f.hidden).map((f) => {
      const meta = metadataByColumn.get(f.name.toLowerCase());
      return { field: f.name, header: f.label || prettifyLabel(f.name), flex: 1, minWidth: 160, type: mapColumnType(meta?.dataType), sortable: true } as ColumnDef;
    }),
  ], [keyField, metadataByColumn, resolvedFields]);

  useEffect(() => { import('@zentto/datagrid').then(() => setRegistered(true)); }, []);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    el.columns = gridColumns; el.rows = gridRows;
    el.loading = listQuery.isLoading || metadataQuery.isLoading;
    el.getRowId = (row: any) => String(resolveRowKey(row as CatalogRow, keyField) ?? row.id ?? crypto.randomUUID());
    el.actionButtons = [
      { icon: SVG_EDIT, label: 'Editar', action: 'edit', color: '#1976d2' },
      { icon: SVG_DELETE, label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ];
  }, [gridColumns, gridRows, listQuery.isLoading, metadataQuery.isLoading, registered, keyField]);

  const createMutation = useMutation({
    mutationFn: async () => {
      const payload = buildPayload(formValues, resolvedFields);
      try { return await (editKey != null ? apiClient.update(endpoint, editKey, payload) : apiClient.create(endpoint, payload)); }
      catch (error) { if (!isLegacyOkError(error)) throw error; return { ok: true }; }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [endpoint, 'catalog-list'] });
      setDialogOpen(false); setFormValues({}); setEditKey(null);
      setFeedback({ type: 'success', message: editKey != null ? 'Registro actualizado correctamente.' : 'Registro creado correctamente.' });
    },
    onError: (error) => setFeedback({ type: 'error', message: extractErrorMessage(error) }),
  });

  const deleteMutation = useMutation({
    mutationFn: async (key: string | number) => { try { await apiClient.remove(endpoint, key); } catch (error) { if (!isLegacyOkError(error)) throw error; } },
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: [endpoint, 'catalog-list'] }); setFeedback({ type: 'success', message: 'Registro eliminado correctamente.' }); },
    onError: (error) => setFeedback({ type: 'error', message: extractErrorMessage(error) }),
  });

  const handleEdit = useCallback((row: CatalogRow) => {
    const key = resolveRowKey(row, keyField);
    if (key === null) return;
    setEditKey(key);
    const values: Record<string, string> = {};
    for (const field of resolvedFields) {
      if (field.readOnly || field.hidden) continue;
      values[field.name] = asString(getValueByField(row, field.name));
    }
    setFormValues(values);
    setDialogOpen(true);
  }, [keyField, resolvedFields]);

  const handleDelete = useCallback(async (row: CatalogRow) => {
    const key = resolveRowKey(row, keyField);
    if (key === null) return;
    await deleteMutation.mutateAsync(key);
  }, [keyField, deleteMutation]);

  useEffect(() => {
    const el = gridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === 'edit') handleEdit(row);
      if (action === 'delete') handleDelete(row);
    };
    el.addEventListener('action-click', handler);
    return () => el.removeEventListener('action-click', handler);
  }, [registered, gridRows, handleEdit, handleDelete]);

  const isFormDisabled = resolvedFields.some((f) => f.required && !asString(formValues[f.name]).trim());

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <ContextActionHeader title={title}
        primaryAction={{ label: 'Nuevo', onClick: () => { setFormValues({}); setEditKey(null); setDialogOpen(true); } }}
        onSearch={(v) => { setSearch(v); setPage(1); }}
        searchPlaceholder="Buscar registros..."
      />

      <Box sx={{ p: { xs: 1, md: 3 }, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        {feedback && <Alert severity={feedback.type} sx={{ mb: 2 }}>{feedback.message}</Alert>}

        <Box sx={{ mt: 0, flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          <Stack spacing={1.5}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={() => { setFormValues({}); setEditKey(null); setDialogOpen(true); }}>Nuevo</Button>
            </Box>

            <Box sx={{ width: '100%', minHeight: 420 }}>
              <zentto-grid ref={gridRef} height="420px"
                enable-toolbar enable-header-menu enable-header-filters enable-clipboard
                enable-quick-search enable-context-menu enable-status-bar enable-configurator
              />
            </Box>
          </Stack>
        </Box>
      </Box>

      <Dialog open={dialogOpen} onClose={() => !createMutation.isPending && setDialogOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>{editKey != null ? `Editar ${title}` : `Nuevo ${title}`}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            {editKey != null && (
              <TextField label={prettifyLabel(keyField)} value={String(editKey)} disabled />
            )}
            {resolvedFields
              .filter((field) => !field.hidden)
              .filter((field) => !field.readOnly)
              .map((field) => (
                <TextField
                  key={field.name}
                  label={field.label || prettifyLabel(field.name)}
                  required={field.required}
                  value={formValues[field.name] ?? ''}
                  onChange={(e) => setFormValues((prev) => ({ ...prev, [field.name]: e.target.value }))}
                />
              ))}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)} disabled={createMutation.isPending}>Cancelar</Button>
          <Button variant="contained" onClick={() => createMutation.mutate()} disabled={createMutation.isPending || isFormDisabled}>Guardar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
