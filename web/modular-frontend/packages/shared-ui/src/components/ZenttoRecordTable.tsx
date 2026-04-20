/**
 * ZenttoRecordTable — wrapper de alto nivel sobre el web component `<zentto-grid>`.
 *
 * Provee la cáscara visual consistente para listas tipo "records" en todas las
 * apps Zentto (CRM, hotel, medical, tickets, etc.):
 *
 *   ┌─────────────────────────────────────────────────────────────────┐
 *   │  [FilterPanel inyectable]    [SavedViews ▾]  [Density ▢▣▤]       │
 *   ├─────────────────────────────────────────────────────────────────┤
 *   │                                                                 │
 *   │            <zentto-grid>  —  NO se reimplementa                 │
 *   │                                                                 │
 *   └─────────────────────────────────────────────────────────────────┘
 *      [BulkActionBar sticky bottom si hay selección]
 *
 * REGLA CRÍTICA (feedback_zentto_datagrid_standard.md):
 *   Este wrapper **NO** reimplementa el grid — sólo lo envuelve.
 *   Los consumidores deben usar SIEMPRE ZenttoRecordTable (o `<zentto-grid>` directo),
 *   NUNCA `<table>` HTML ni MUI DataGrid.
 *
 * Issue: CRM-103 (#377).
 */
'use client';

import React, {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import {
  Box,
  Button,
  IconButton,
  Menu,
  MenuItem,
  Paper,
  Skeleton,
  Stack,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  Typography,
} from '@mui/material';
import {
  ViewCompact as ViewCompactIcon,
  ViewAgenda as ViewAgendaIcon,
  ViewStream as ViewStreamIcon,
  KeyboardArrowDown as ArrowDownIcon,
  Save as SaveIcon,
  Settings as SettingsIcon,
  Inbox as InboxIcon,
  ErrorOutline as ErrorIcon,
  Close as CloseIcon,
} from '@mui/icons-material';

import { token, type DensityMode } from '../theme';

// ─── Types ──────────────────────────────────────────────────────────

/**
 * Descripción minimalista de columna aceptada por `<zentto-grid>`.
 *
 * Es un subset permisivo compatible con `ColumnDef` de `@zentto/datagrid-core`.
 * Se mantiene local para no forzar la dependencia (shared-ui no debe depender
 * de datagrid-core directamente).
 */
export interface ColumnSpec {
  field: string;
  header?: string;
  width?: number;
  flex?: number;
  minWidth?: number;
  type?: string;
  sortable?: boolean;
  filterable?: boolean;
  resizable?: boolean;
  pin?: 'left' | 'right';
  [extra: string]: unknown;
}

export interface SavedView {
  id: string | number;
  label: string;
  description?: string;
  /** Marca opcional para identificar views del sistema vs. del usuario. */
  kind?: 'system' | 'user' | string;
}

export interface BulkAction {
  id: string;
  label: string;
  icon?: ReactNode;
  /** `primary` → botón coloreado; `danger` → rojo; default → texto. */
  variant?: 'primary' | 'danger' | 'default';
  onClick: (ids: Array<string | number>) => void | Promise<void>;
  disabled?: boolean;
}

export interface PaginationProps {
  page: number;
  pageSize: number;
  totalCount?: number;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
}

export interface EmptyStateSpec {
  illustration?: ReactNode;
  title: string;
  description?: string;
  primaryAction?: { label: string; onClick: () => void };
  secondaryAction?: { label: string; href?: string; onClick?: () => void };
}

export interface ZenttoRecordTableProps<T extends Record<string, unknown> = Record<string, unknown>> {
  /** Tipo de registro (ej. `lead`, `contact`, `deal`). Usado para scoping de
   *  persistencia (densidad, layout, vista activa). */
  recordType: string;
  /** Datos a renderizar. */
  rows: T[];
  /** Columnas. */
  columns: ColumnSpec[];
  /** Estado loading — renderiza skeleton de 10 filas. */
  loading?: boolean;
  /** Mensaje de error — renderiza estado de error con botón retry. */
  error?: string | null;
  onRetry?: () => void;
  /** Click sobre una fila → ID del registro. */
  onOpenRecord?: (id: string | number, row: T) => void;
  // ─── Saved views ────────
  savedViews?: SavedView[];
  currentViewId?: string | number | null;
  onSavedViewChange?: (viewId: string | number | null) => void;
  onSaveCurrentView?: () => void;
  onManageViews?: () => void;
  // ─── Bulk actions ───────
  bulkActions?: BulkAction[];
  selection?: Array<string | number>;
  onSelectionChange?: (ids: Array<string | number>, rows: T[]) => void;
  // ─── Density ────────────
  density?: DensityMode;
  onDensityChange?: (d: DensityMode) => void;
  /** Persistir densidad por recordType en localStorage (default `true`). */
  persistDensity?: boolean;
  // ─── Empty state ────────
  emptyState?: EmptyStateSpec;
  // ─── Paging ─────────────
  totalCount?: number;
  pagination?: PaginationProps;
  // ─── Extras ─────────────
  /** Panel de filtros inyectable (típicamente `<ZenttoFilterPanel />`). */
  filterPanel?: ReactNode;
  /** Identificador único para persistencia (`useGridLayoutSync`). Si no se
   *  pasa, se deriva como `recordtable:<recordType>`. */
  gridId?: string;
  /** Props extra que se reenvían como attrs al `<zentto-grid>`. Útil para
   *  banderas feature (ej. `enable-grouping`). */
  gridAttrs?: Record<string, string | boolean | number>;
  /** Altura CSS del grid interno (default `calc(100vh - 240px)`). */
  height?: string;
  /** Label CTA del header del grid (si `enableCreate`). */
  createLabel?: string;
  onCreate?: () => void;
  /** Clave primaria de las filas (default `id`). */
  rowKey?: string;
}

// ─── Subcomponent: DensityToggle ────────────────────────────────────

interface DensityToggleProps {
  value: DensityMode;
  onChange: (d: DensityMode) => void;
}

function DensityToggle({ value, onChange }: DensityToggleProps) {
  return (
    <ToggleButtonGroup
      size="small"
      value={value}
      exclusive
      onChange={(_e, v) => v && onChange(v as DensityMode)}
      aria-label="Densidad de tabla"
    >
      <ToggleButton value="compact" aria-label="Compacto">
        <Tooltip title={`Compacto (${token.density.rowHeight.compact}px)`}>
          <ViewCompactIcon fontSize="small" />
        </Tooltip>
      </ToggleButton>
      <ToggleButton value="default" aria-label="Estándar">
        <Tooltip title={`Estándar (${token.density.rowHeight.default}px)`}>
          <ViewStreamIcon fontSize="small" />
        </Tooltip>
      </ToggleButton>
      <ToggleButton value="comfortable" aria-label="Cómodo">
        <Tooltip title={`Cómodo (${token.density.rowHeight.comfortable}px)`}>
          <ViewAgendaIcon fontSize="small" />
        </Tooltip>
      </ToggleButton>
    </ToggleButtonGroup>
  );
}

// ─── Subcomponent: SavedViewsMenu ───────────────────────────────────

interface SavedViewsMenuProps {
  views: SavedView[];
  currentId?: string | number | null;
  onChange: (id: string | number | null) => void;
  onSave?: () => void;
  onManage?: () => void;
}

function SavedViewsMenu({ views, currentId, onChange, onSave, onManage }: SavedViewsMenuProps) {
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const open = Boolean(anchorEl);
  const current = useMemo(() => views.find((v) => v.id === currentId), [views, currentId]);

  return (
    <>
      <Button
        size="small"
        variant="outlined"
        endIcon={<ArrowDownIcon />}
        onClick={(e) => setAnchorEl(e.currentTarget)}
        sx={{ textTransform: 'none' }}
      >
        {current?.label ?? 'Todas las vistas'}
      </Button>
      <Menu anchorEl={anchorEl} open={open} onClose={() => setAnchorEl(null)}>
        <MenuItem
          selected={currentId == null}
          onClick={() => {
            onChange(null);
            setAnchorEl(null);
          }}
        >
          <em>Todas</em>
        </MenuItem>
        {views.map((v) => (
          <MenuItem
            key={String(v.id)}
            selected={v.id === currentId}
            onClick={() => {
              onChange(v.id);
              setAnchorEl(null);
            }}
          >
            <Stack>
              <Typography variant="body2">{v.label}</Typography>
              {v.description && (
                <Typography variant="caption" color="text.secondary">
                  {v.description}
                </Typography>
              )}
            </Stack>
          </MenuItem>
        ))}
        {(onSave || onManage) && <Box sx={{ borderTop: 1, borderColor: 'divider', my: 0.5 }} />}
        {onSave && (
          <MenuItem
            onClick={() => {
              onSave();
              setAnchorEl(null);
            }}
          >
            <SaveIcon fontSize="small" sx={{ mr: 1 }} />
            Guardar vista actual
          </MenuItem>
        )}
        {onManage && (
          <MenuItem
            onClick={() => {
              onManage();
              setAnchorEl(null);
            }}
          >
            <SettingsIcon fontSize="small" sx={{ mr: 1 }} />
            Gestionar vistas
          </MenuItem>
        )}
      </Menu>
    </>
  );
}

// ─── Subcomponent: BulkActionBar ────────────────────────────────────

interface BulkActionBarProps {
  count: number;
  actions: BulkAction[];
  ids: Array<string | number>;
  onCancel: () => void;
}

function BulkActionBar({ count, actions, ids, onCancel }: BulkActionBarProps) {
  if (count === 0) return null;
  return (
    <Paper
      elevation={6}
      sx={{
        position: 'sticky',
        bottom: 16,
        left: 0,
        right: 0,
        mx: 'auto',
        px: 2,
        py: 1.25,
        display: 'flex',
        alignItems: 'center',
        gap: 1.5,
        maxWidth: 'fit-content',
        borderRadius: 999,
        zIndex: 10,
        bgcolor: 'background.paper',
        border: 1,
        borderColor: 'divider',
      }}
      role="toolbar"
      aria-label={`${count} registros seleccionados`}
    >
      <Typography variant="body2" sx={{ fontWeight: 600 }}>
        {count} seleccionado{count === 1 ? '' : 's'}
      </Typography>
      <Box sx={{ width: 1, height: 20, bgcolor: 'divider' }} />
      <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
        {actions.map((a) => (
          <Button
            key={a.id}
            size="small"
            variant={a.variant === 'primary' ? 'contained' : 'text'}
            color={a.variant === 'danger' ? 'error' : a.variant === 'primary' ? 'primary' : 'inherit'}
            startIcon={a.icon}
            disabled={a.disabled}
            onClick={() => a.onClick(ids)}
            sx={{ textTransform: 'none' }}
          >
            {a.label}
          </Button>
        ))}
      </Stack>
      <Tooltip title="Limpiar selección">
        <IconButton size="small" onClick={onCancel} aria-label="Cancelar selección">
          <CloseIcon fontSize="small" />
        </IconButton>
      </Tooltip>
    </Paper>
  );
}

// ─── Subcomponent: EmptyState ───────────────────────────────────────

interface EmptyStateProps extends EmptyStateSpec {}

function EmptyState({
  illustration,
  title,
  description,
  primaryAction,
  secondaryAction,
}: EmptyStateProps) {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        py: 8,
        px: 3,
        gap: 1.5,
      }}
      role="status"
      aria-live="polite"
    >
      <Box sx={{ mb: 1, color: 'text.disabled' }}>
        {illustration ?? <InboxIcon sx={{ fontSize: 72 }} />}
      </Box>
      <Typography variant="h6" sx={{ fontWeight: 600 }}>
        {title}
      </Typography>
      {description && (
        <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 420 }}>
          {description}
        </Typography>
      )}
      <Stack direction="row" spacing={1.5} sx={{ mt: 1.5 }}>
        {primaryAction && (
          <Button variant="contained" onClick={primaryAction.onClick}>
            {primaryAction.label}
          </Button>
        )}
        {secondaryAction && (
          <Button
            variant="text"
            href={secondaryAction.href}
            onClick={secondaryAction.onClick}
            target={secondaryAction.href ? '_blank' : undefined}
            rel={secondaryAction.href ? 'noopener noreferrer' : undefined}
          >
            {secondaryAction.label}
          </Button>
        )}
      </Stack>
    </Box>
  );
}

// ─── Subcomponent: ErrorState ───────────────────────────────────────

function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        py: 8,
        px: 3,
        gap: 1.5,
      }}
      role="alert"
    >
      <ErrorIcon sx={{ fontSize: 64, color: 'error.main' }} />
      <Typography variant="h6" sx={{ fontWeight: 600 }}>
        No pudimos cargar los datos
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 420 }}>
        {message}
      </Typography>
      {onRetry && (
        <Button variant="outlined" onClick={onRetry} sx={{ mt: 1 }}>
          Reintentar
        </Button>
      )}
    </Box>
  );
}

// ─── Subcomponent: SkeletonRows ─────────────────────────────────────

function SkeletonRows({ rows = 10, density }: { rows?: number; density: DensityMode }) {
  const h = token.density.rowHeight[density];
  return (
    <Stack spacing={0.5} sx={{ p: 1 }} aria-hidden="true">
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} variant="rectangular" height={h} sx={{ borderRadius: 1 }} />
      ))}
    </Stack>
  );
}

// ─── Helpers ────────────────────────────────────────────────────────

function densityStorageKey(recordType: string) {
  return `zentto:recordtable:density:${recordType}`;
}

function readPersistedDensity(recordType: string): DensityMode | null {
  if (typeof window === 'undefined') return null;
  try {
    const v = window.localStorage.getItem(densityStorageKey(recordType));
    if (v === 'compact' || v === 'default' || v === 'comfortable') return v;
  } catch {
    // ignore (storage disabled)
  }
  return null;
}

function writePersistedDensity(recordType: string, d: DensityMode) {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(densityStorageKey(recordType), d);
  } catch {
    // ignore
  }
}

/** Mapea la densidad semántica de Zentto al enum que espera `<zentto-grid>`. */
function mapDensityToGrid(d: DensityMode): 'compact' | 'standard' | 'comfortable' {
  return d === 'default' ? 'standard' : d;
}

function getRowId(row: unknown, rowKey: string): string | number | undefined {
  if (!row || typeof row !== 'object') return undefined;
  const v = (row as Record<string, unknown>)[rowKey];
  if (typeof v === 'string' || typeof v === 'number') return v;
  return undefined;
}

// ─── Main component ─────────────────────────────────────────────────

export function ZenttoRecordTable<T extends Record<string, unknown> = Record<string, unknown>>(
  props: ZenttoRecordTableProps<T>,
) {
  const {
    recordType,
    rows,
    columns,
    loading = false,
    error = null,
    onRetry,
    onOpenRecord,
    savedViews,
    currentViewId,
    onSavedViewChange,
    onSaveCurrentView,
    onManageViews,
    bulkActions,
    selection: selectionProp,
    onSelectionChange,
    density: densityProp,
    onDensityChange,
    persistDensity = true,
    emptyState,
    totalCount,
    pagination,
    filterPanel,
    gridId,
    gridAttrs,
    height = 'calc(100vh - 240px)',
    createLabel,
    onCreate,
    rowKey = 'id',
  } = props;

  const gridRef = useRef<HTMLElement & Record<string, unknown>>(null);

  // ─── Density state (controlled + persisted) ──────────────────────
  const [densityInternal, setDensityInternal] = useState<DensityMode>(() => {
    if (densityProp) return densityProp;
    if (persistDensity) {
      const persisted = readPersistedDensity(recordType);
      if (persisted) return persisted;
    }
    return 'default';
  });
  const density = densityProp ?? densityInternal;

  const handleDensityChange = useCallback(
    (d: DensityMode) => {
      if (densityProp === undefined) setDensityInternal(d);
      if (persistDensity) writePersistedDensity(recordType, d);
      onDensityChange?.(d);
    },
    [densityProp, persistDensity, recordType, onDensityChange],
  );

  // ─── Selection state (controlled or uncontrolled) ────────────────
  const [selectionInternal, setSelectionInternal] = useState<Array<string | number>>([]);
  const selection = selectionProp ?? selectionInternal;
  const selectionCount = selection.length;

  const clearSelection = useCallback(() => {
    if (selectionProp === undefined) setSelectionInternal([]);
    onSelectionChange?.([], []);
    // Limpiar también la selección visual del grid
    const el = gridRef.current as unknown as { clearSelection?: () => void } | null;
    el?.clearSelection?.();
  }, [selectionProp, onSelectionChange]);

  // ─── Registrar custom element zentto-grid (si aún no está definido) ──
  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!customElements.get('zentto-grid')) {
      import('@zentto/datagrid').catch(() => {});
    }
  }, []);

  // ─── Bind data → web component ────────────────────────────────────
  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    (el as unknown as { columns: unknown }).columns = columns;
  }, [columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    // Durante loading mantenemos rows vacío para no mostrar data stale mezclado
    // con el skeleton externo.
    (el as unknown as { rows: unknown }).rows = loading ? [] : rows;
  }, [rows, loading]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    (el as unknown as { loading: boolean }).loading = loading;
  }, [loading]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    // Map semántico → enum interno del grid ('default' → 'standard')
    (el as unknown as { density: string }).density = mapDensityToGrid(density);
  }, [density]);

  // ─── Event listeners (row-click, selection-change) ───────────────
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !onOpenRecord) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { row?: T } | undefined;
      const row = detail?.row;
      if (!row) return;
      const id = getRowId(row, rowKey);
      if (id === undefined) return;
      onOpenRecord(id, row);
    };
    el.addEventListener('row-click', handler);
    return () => el.removeEventListener('row-click', handler);
  }, [onOpenRecord, rowKey]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as
        | { selectedRows?: T[]; count?: number }
        | undefined;
      const selectedRows = (detail?.selectedRows ?? []) as T[];
      const ids = selectedRows
        .map((r) => getRowId(r, rowKey))
        .filter((id): id is string | number => id !== undefined);
      if (selectionProp === undefined) setSelectionInternal(ids);
      onSelectionChange?.(ids, selectedRows);
    };
    el.addEventListener('selection-change', handler);
    return () => el.removeEventListener('selection-change', handler);
  }, [onSelectionChange, rowKey, selectionProp]);

  useEffect(() => {
    if (!onCreate) return;
    const el = gridRef.current;
    if (!el) return;
    const handler = () => onCreate();
    el.addEventListener('create-click', handler);
    return () => el.removeEventListener('create-click', handler);
  }, [onCreate]);

  // ─── Derivado: gridId (para persistencia externa) ────────────────
  const effectiveGridId = gridId ?? `recordtable:${recordType}`;

  // ─── Render states ───────────────────────────────────────────────
  const showEmpty = !loading && !error && rows.length === 0 && !!emptyState;
  const showError = !loading && !!error;
  const enableSelection = !!bulkActions && bulkActions.length > 0;

  return (
    <Box
      data-record-type={recordType}
      data-density={density}
      sx={{
        display: 'flex',
        flexDirection: 'column',
        flex: 1,
        minHeight: 0,
        // Permite a los consumidores leer el rowHeight en CSS si lo necesitan.
        '--zentto-row-height': `${token.density.rowHeight[density]}px`,
        gap: `${token.layout.sectionGap / 2}px`,
      }}
    >
      {/* ─── Header: filter panel + saved views + density ─────────── */}
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        spacing={1.5}
        sx={{
          alignItems: { xs: 'stretch', sm: 'flex-start' },
          justifyContent: 'space-between',
        }}
      >
        <Box sx={{ flex: 1, minWidth: 0 }}>{filterPanel}</Box>
        <Stack direction="row" spacing={1} sx={{ alignItems: 'center', flexShrink: 0 }}>
          {savedViews && savedViews.length > 0 && (
            <SavedViewsMenu
              views={savedViews}
              currentId={currentViewId ?? null}
              onChange={(id) => onSavedViewChange?.(id)}
              onSave={onSaveCurrentView}
              onManage={onManageViews}
            />
          )}
          <DensityToggle value={density} onChange={handleDensityChange} />
        </Stack>
      </Stack>

      {/* ─── Body: grid / skeleton / error / empty ────────────────── */}
      <Box sx={{ flex: 1, minHeight: 0, position: 'relative' }}>
        {loading && <SkeletonRows density={density} />}
        {showError && <ErrorState message={error!} onRetry={onRetry} />}
        {showEmpty && emptyState && <EmptyState {...emptyState} />}
        <Box sx={{ display: loading || showError || showEmpty ? 'none' : 'block', height: '100%' }}>
          {/* @ts-expect-error — web component registrado globalmente */}
          <zentto-grid
            ref={gridRef as React.Ref<HTMLElement>}
            grid-id={effectiveGridId}
            height={height}
            enable-toolbar
            enable-quick-search
            enable-header-filters
            enable-clipboard
            enable-status-bar
            {...(enableSelection ? { 'enable-row-selection': true } : {})}
            {...(onCreate ? { 'enable-create': true, 'create-label': createLabel ?? 'Nuevo' } : {})}
            {...(gridAttrs ?? {})}
          />
        </Box>
      </Box>

      {/* ─── Footer: total count hint ─────────────────────────────── */}
      {totalCount !== undefined && !loading && !showError && rows.length > 0 && (
        <Typography variant="caption" color="text.secondary" sx={{ px: 0.5 }}>
          {rows.length} de {totalCount}
          {pagination ? ` · Página ${pagination.page}` : ''}
        </Typography>
      )}

      {/* ─── Pagination (bridge si el grid interno lo trae) ───────── */}
      {pagination && !loading && !showError && pagination.totalCount && (
        <Stack
          direction="row"
          spacing={1}
          sx={{ alignItems: 'center', justifyContent: 'flex-end', px: 0.5 }}
        >
          <Button
            size="small"
            disabled={pagination.page <= 1}
            onClick={() => pagination.onPageChange?.(pagination.page - 1)}
          >
            Anterior
          </Button>
          <Typography variant="caption" color="text.secondary">
            Página {pagination.page}
          </Typography>
          <Button
            size="small"
            disabled={
              !!pagination.totalCount &&
              pagination.page * pagination.pageSize >= pagination.totalCount
            }
            onClick={() => pagination.onPageChange?.(pagination.page + 1)}
          >
            Siguiente
          </Button>
        </Stack>
      )}

      {/* ─── Bulk action bar sticky bottom ────────────────────────── */}
      {bulkActions && bulkActions.length > 0 && (
        <BulkActionBar
          count={selectionCount}
          actions={bulkActions}
          ids={selection}
          onCancel={clearSelection}
        />
      )}

    </Box>
  );
}

export default ZenttoRecordTable;
