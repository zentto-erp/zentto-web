'use client';

import React, { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  DataGrid,
  GridColDef,
  GridColumnVisibilityModel,
  GridRowId,
  GridSlots,
  useGridApiRef,
} from '@mui/x-data-grid';
import {
  useTheme,
  useMediaQuery,
  Drawer,
  Box,
  Typography,
  Stack,
  Divider,
  IconButton,
  Tooltip,
  alpha,
  TextField,
  CircularProgress,
  Skeleton,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Chip,
} from '@mui/material';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import CloseIcon from '@mui/icons-material/Close';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import UnfoldMoreIcon from '@mui/icons-material/UnfoldMore';
import UnfoldLessIcon from '@mui/icons-material/UnfoldLess';

import { ZenttoToolbar } from './ZenttoToolbar';
import { PivotPanel } from './PivotPanel';
import { DetailPanelWrapper } from './DetailPanelWrapper';
import { applyColumnTemplates } from './columnTemplates';
import { useGridLayout } from './useGridLayout';
import {
  resolveId,
  injectDetailRows,
  computeTotals,
  applyPivot,
  applyRowGrouping,
  applyTreeData,
  applyHeaderFilters,
  copyRowsToClipboard,
  exportToCsv,
  exportToExcel,
  exportToJson,
  exportToMarkdown,
  applyColumnPinning,
  pinningSx,
} from './utils';
import {
  GridRow,
  ZenttoDataGridProps,
  ZenttoColDef,
  PivotConfig,
  HeaderFilter,
  DETAIL_ROW_KEY,
  TOTALS_ROW_KEY,
  GROUP_ROW_KEY,
  EXPAND_COL_FIELD,
  MOBILE_DETAIL_COL_FIELD,
} from './types';

// ─── Estilos base — mejorados para look profesional tipo AG Grid ────────────

const baseGridSx = {
  border: '1px solid',
  borderColor: 'divider',
  borderRadius: 1,
  bgcolor: 'background.paper',

  // ── Header: fondo solido, tipografia clara ────────────────────────────
  '& .MuiDataGrid-columnHeaders': {
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.common.white, 0.05) : '#f8f9fa',
    borderBottom: '2px solid',
    borderColor: 'divider',
    fontSize: '0.8125rem',
    fontWeight: 700,
    color: 'text.primary',
    letterSpacing: '0.01em',
    minHeight: '42px !important',
    maxHeight: '42px !important',
  },
  '& .MuiDataGrid-columnHeader': {
    '&:focus, &:focus-within': { outline: 'none' },
    '&:not(:last-of-type)': {
      borderRight: '1px solid',
      borderColor: (theme: any) =>
        theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
    },
  },
  '& .MuiDataGrid-columnHeaderTitle': {
    fontWeight: 700,
  },
  '& .MuiDataGrid-columnSeparator': {
    color: (theme: any) =>
      theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)',
  },

  // ── Column Group Headers ──────────────────────────────────────────────
  '& .zentto-column-group-header': {
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.primary.main, 0.12) : alpha(theme.palette.primary.main, 0.06),
    borderBottom: '2px solid',
    borderColor: 'primary.main',
    fontWeight: 800,
    fontSize: '0.75rem',
    textTransform: 'uppercase' as const,
    letterSpacing: '0.05em',
    color: 'primary.main',
  },

  // ── Rows: borders visibles, font legible ──────────────────────────────
  '& .MuiDataGrid-row': {
    transition: 'background-color 0.12s',
    borderBottom: '1px solid',
    borderColor: (theme: any) =>
      theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)',
    '&:hover': {
      bgcolor: (theme: any) =>
        theme.palette.mode === 'dark' ? alpha(theme.palette.primary.main, 0.08) : alpha(theme.palette.primary.main, 0.04),
    },
    '&.Mui-selected': {
      bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.08),
      '&:hover': {
        bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.12),
      },
    },
    // Zebra striping (alternating rows)
    '&:nth-of-type(even)': {
      bgcolor: (theme: any) =>
        theme.palette.mode === 'dark' ? alpha(theme.palette.common.white, 0.02) : 'rgba(0,0,0,0.015)',
    },
  },

  // ── Expanded row → accent border + highlight ──────────────────────────
  '& .zentto-row-expanded': {
    bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.06),
    borderLeft: '3px solid',
    borderColor: 'primary.main',
    '&:hover': {
      bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.1),
    },
  },

  // ── Detail panel row → solid bg, no hover effect ──────────────────────
  '& .zentto-row-detail': {
    bgcolor: 'background.paper',
    borderLeft: '3px solid',
    borderColor: 'primary.main',
    '& .MuiDataGrid-cell': {
      padding: 0,
      overflow: 'hidden',
    },
    '&:hover': {
      bgcolor: 'background.paper !important',
    },
  },

  // ── Totals row → bold + distinct background ──────────────────────────
  '& .zentto-row-totals': {
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.common.white, 0.08) : '#f0f0f0',
    fontWeight: 700,
    borderTop: '2px solid',
    borderColor: 'divider',
    '& .MuiDataGrid-cell': {
      fontWeight: 700,
    },
  },

  // ── Group header row → colored accent ─────────────────────────────────
  '& .zentto-row-group': {
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.primary.main, 0.1) : alpha(theme.palette.primary.main, 0.04),
    fontWeight: 700,
    borderBottom: '1px solid',
    borderColor: 'primary.light',
    '& .MuiDataGrid-cell': {
      fontWeight: 700,
    },
    '&:hover': {
      bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.12),
    },
  },

  // ── Cells: legible font, consistent borders ───────────────────────────
  '& .MuiDataGrid-cell': {
    fontSize: '0.8125rem',
    lineHeight: 1.5,
    borderColor: (theme: any) =>
      theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)',
    '&:focus, &:focus-within': { outline: 'none' },
    // Vertical border between cells
    '&:not(:last-of-type)': {
      borderRight: '1px solid',
      borderColor: (theme: any) =>
        theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.04)',
    },
  },

  // ── Expand column — no padding ────────────────────────────────────────
  [`& .MuiDataGrid-cell[data-field="${EXPAND_COL_FIELD}"]`]: {
    padding: '0 !important',
    overflow: 'hidden',
  },

  // ── Footer ────────────────────────────────────────────────────────────
  '& .MuiDataGrid-footerContainer': {
    borderTop: '2px solid',
    borderColor: 'divider',
    minHeight: 44,
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.common.white, 0.03) : '#fafafa',
    fontSize: '0.8125rem',
  },

  // ── Virtual scroller ──────────────────────────────────────────────────
  '& .MuiDataGrid-virtualScrollerContent': {
    minHeight: 1,
  },

  // ── Header filter row ─────────────────────────────────────────────────
  '& .zentto-header-filter-row': {
    bgcolor: (theme: any) => theme.palette.mode === 'dark' ? alpha(theme.palette.common.white, 0.03) : '#fafbfc',
    borderBottom: '1px solid',
    borderColor: 'divider',
    minHeight: 36,
    display: 'flex',
    alignItems: 'center',
  },

  // ── Row number column ─────────────────────────────────────────────────
  '& .zentto-row-number-cell': {
    color: 'text.secondary',
    fontSize: '0.75rem',
    justifyContent: 'center',
  },

  // ── Drag handle column ────────────────────────────────────────────────
  '& .zentto-drag-handle': {
    cursor: 'grab',
    color: 'text.disabled',
    '&:hover': { color: 'text.secondary' },
    '&:active': { cursor: 'grabbing' },
  },
} as const;

// ─── Column: expand/collapse for master-detail ──────────────────────────────

function buildExpandColumn(
  expandedIds: Set<GridRowId>,
  onToggle: (id: GridRowId) => void,
  totalColumns: number,
  detailPanelHeight: number | 'auto',
  apiRef: React.MutableRefObject<any>
): ZenttoColDef {
  return ({
    field: EXPAND_COL_FIELD,
    headerName: '',
    width: 44,
    minWidth: 44,
    maxWidth: 44,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    colSpan: (_value: unknown, row: GridRow) => {
      if (row[DETAIL_ROW_KEY]) return totalColumns;
      return 1;
    },
    renderCell: (params) => {
      const row = params.row as GridRow;

      // ── Detail panel row ──────────────────────────────────────────────
      if (row[DETAIL_ROW_KEY]) {
        return (
          <DetailPanelWrapper apiRef={apiRef} height={detailPanelHeight}>
            {row.__content as React.ReactNode}
          </DetailPanelWrapper>
        );
      }

      // ── Group header row — expand/collapse ────────────────────────────
      if (row[GROUP_ROW_KEY]) {
        const isExpanded = row.__groupExpanded as boolean;
        return (
          <IconButton
            size="small"
            onClick={(e) => {
              e.stopPropagation();
              onToggle(params.id);
            }}
            sx={{ width: 28, height: 28, color: 'primary.main' }}
          >
            <ChevronRightIcon
              fontSize="small"
              sx={{
                transition: 'transform 0.2s',
                transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
              }}
            />
          </IconButton>
        );
      }

      // ── Normal row → expand button ────────────────────────────────────
      const isExpanded = expandedIds.has(params.id);
      return (
        <Tooltip title={isExpanded ? 'Colapsar' : 'Ver detalle'} placement="right">
          <IconButton
            size="small"
            onClick={(e) => {
              e.stopPropagation();
              onToggle(params.id);
            }}
            sx={{
              width: 28,
              height: 28,
              color: isExpanded ? 'primary.main' : 'text.secondary',
              transition: 'color 0.15s',
            }}
          >
            <ChevronRightIcon
              fontSize="small"
              sx={{
                transition: 'transform 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
              }}
            />
          </IconButton>
        </Tooltip>
      );
    },
  }) as ZenttoColDef;
}

// ─── Column: mobile info button ─────────────────────────────────────────────

function buildMobileDetailColumn(onOpen: (row: GridRow) => void): ZenttoColDef {
  return ({
    field: MOBILE_DETAIL_COL_FIELD,
    headerName: '',
    width: 44,
    minWidth: 44,
    maxWidth: 44,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    renderCell: (params) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return null;
      return (
        <Tooltip title="Ver detalle del registro">
          <IconButton
            size="small"
            onClick={(e) => {
              e.stopPropagation();
              onOpen(row);
            }}
            sx={{ color: 'primary.main' }}
          >
            <InfoOutlinedIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      );
    },
  }) as ZenttoColDef;
}

// ─── Column: row number ─────────────────────────────────────────────────────

function buildRowNumberColumn(): ZenttoColDef {
  return ({
    field: '__zentto_row_num__',
    headerName: '#',
    width: 50,
    minWidth: 50,
    maxWidth: 60,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    cellClassName: 'zentto-row-number-cell',
    renderCell: (params) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return null;
      // Use the row index from the API (1-based)
      const api = params.api;
      const allIds = api.getSortedRowIds?.() ?? [];
      const idx = allIds.indexOf(params.id);
      return idx >= 0 ? idx + 1 : '';
    },
  }) as ZenttoColDef;
}

// ─── Column: drag handle for row reordering ─────────────────────────────────

function buildDragHandleColumn(): ZenttoColDef {
  return ({
    field: '__zentto_drag__',
    headerName: '',
    width: 36,
    minWidth: 36,
    maxWidth: 36,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    renderCell: (params) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return null;
      return (
        <Box className="zentto-drag-handle" sx={{ display: 'flex', alignItems: 'center' }}>
          <DragIndicatorIcon fontSize="small" />
        </Box>
      );
    },
  }) as ZenttoColDef;
}

// ─── Mobile actions menu (collapses action buttons into MoreVert menu) ───────

function MobileActionsCell({ actions }: { actions: React.ReactNode }) {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  return (
    <>
      <IconButton
        size="small"
        onClick={(e) => { e.stopPropagation(); setAnchorEl(e.currentTarget); }}
        sx={{ color: 'text.secondary' }}
      >
        <MoreVertIcon fontSize="small" />
      </IconButton>
      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={() => setAnchorEl(null)}
        onClick={() => setAnchorEl(null)}
        slotProps={{ paper: { sx: { minWidth: 160 } } }}
      >
        {/* Render each action button as a menu item */}
        <Box sx={{ px: 1, py: 0.5, display: 'flex', gap: 0.5, flexWrap: 'wrap', justifyContent: 'center' }}>
          {actions}
        </Box>
      </Menu>
    </>
  );
}

/**
 * Wraps action columns for mobile: if there are multiple action buttons,
 * collapses them into a single MoreVert (⋮) menu to save horizontal space.
 */
function buildMobileActionColumn(
  originalActionCols: ZenttoColDef[]
): ZenttoColDef {
  return ({
    field: '__zentto_mobile_actions__',
    headerName: '',
    width: 44,
    minWidth: 44,
    maxWidth: 44,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    type: 'actions',
    renderCell: (params) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return null;

      // Render each original action column's cell and collect results
      const actionElements: React.ReactNode[] = [];
      for (const col of originalActionCols) {
        if (col.renderCell) {
          const el = col.renderCell(params as any);
          if (el) actionElements.push(el);
        }
      }

      if (actionElements.length === 0) return null;
      if (actionElements.length === 1) return actionElements[0]; // Single action: show directly

      // Multiple actions: collapse into menu
      return <MobileActionsCell actions={<>{actionElements}</>} />;
    },
  }) as ZenttoColDef;
}

// ─── ZenttoDataGrid ─────────────────────────────────────────────────────────

export function ZenttoDataGrid({
  columns,
  rows = [],
  // Responsive
  mobileVisibleFields,
  smExtraFields,
  mobileDetailDrawer = true,
  // Master-detail
  getDetailContent,
  detailPanelHeight = 'auto',
  getDetailExportData,
  detailExportKey = 'detalles',
  // Pivot
  pivotConfig: externalPivotConfig,
  enablePivot = false,
  // Aggregation
  showTotals = false,
  totalsLabel = 'Total',
  // Pinned columns
  pinnedColumns,
  // Column groups
  columnGroups,
  // Row grouping
  enableGrouping = false,
  rowGroupingConfig,
  // Tree data
  treeDataConfig,
  // Row pinning
  pinnedRowsTop,
  pinnedRowsBottom,
  // Row reordering
  onRowReorder,
  // Header filters
  enableHeaderFilters = false,
  // Clipboard
  enableClipboard = false,
  // Cell selection
  enableCellSelection = false,
  // Lazy loading
  onLoadMore,
  loadingMore = false,
  serverRowCount,
  // Dates and currencies
  dateLocale,
  defaultCurrency,
  // Export
  exportFilename = 'zentto-export',
  showExportCsv = true,
  showExportExcel = true,
  showExportJson = true,
  showExportMarkdown = false,
  // Layout
  gridId,
  // Toolbar
  toolbarTitle,
  toolbarActions,
  hideToolbar = false,
  hideColumnsButton = false,
  hideDensityButton = false,
  hideQuickFilter = false,
  // DataGrid passthrough
  getRowId,
  columnVisibilityModel: externalVisibilityModel,
  onColumnVisibilityModelChange,
  sx,
  getRowHeight,
  getRowClassName,
  isRowSelectable,
  ...props
}: ZenttoDataGridProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'));
  const isSmall = isMobile || isTablet;

  // ── State ─────────────────────────────────────────────────────────────────
  const [expandedIds, setExpandedIds] = useState<Set<GridRowId>>(new Set());
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());
  const [expandedTreeNodes, setExpandedTreeNodes] = useState<Set<string>>(new Set());
  const [mobileDrawerRow, setMobileDrawerRow] = useState<GridRow | null>(null);
  const [headerFilters, setHeaderFilters] = useState<HeaderFilter[]>([]);
  const [headerFiltersVisible, setHeaderFiltersVisible] = useState(false);
  const [pivotDialogOpen, setPivotDialogOpen] = useState(false);
  const [dynamicPivotConfig, setDynamicPivotConfig] = useState<PivotConfig | null>(null);
  const [groupByField, setGroupByField] = useState<string | null>(
    rowGroupingConfig?.field ?? null
  );
  const apiRef = useGridApiRef();
  const lastExpandedId = useRef<GridRowId | null>(null);

  // Active pivot config: external prop takes priority, then dynamic (interactive)
  const activePivotConfig = externalPivotConfig ?? dynamicPivotConfig;

  // ── Resolve ID ────────────────────────────────────────────────────────────
  const getRowIdFn = useCallback(
    (row: GridRow) => resolveId(row, getRowId as ((r: GridRow) => GridRowId) | undefined),
    [getRowId]
  );

  // ── Toggle master-detail expand (CLEAN — no pre-scroll hack) ──────────────
  const toggleExpand = useCallback((id: GridRowId) => {
    setExpandedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        lastExpandedId.current = null;
      } else {
        next.add(id);
        lastExpandedId.current = id;
      }
      return next;
    });
  }, []);

  // ── Toggle group expand ───────────────────────────────────────────────────
  const toggleGroup = useCallback((groupKey: string) => {
    setExpandedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(groupKey)) next.delete(groupKey);
      else next.add(groupKey);
      return next;
    });
  }, []);

  // ── Toggle tree node expand ───────────────────────────────────────────────
  const toggleTreeNode = useCallback((nodeId: string) => {
    setExpandedTreeNodes((prev) => {
      const next = new Set(prev);
      if (next.has(nodeId)) next.delete(nodeId);
      else next.add(nodeId);
      return next;
    });
  }, []);

  // ── Post-expand scroll — smooth, SINGLE scroll via ResizeObserver ─────────
  // The DetailPanelWrapper handles resetRowHeights via ResizeObserver.
  // We only need a simple delayed scroll to bring the detail panel into view.
  useEffect(() => {
    if (!getDetailContent || !lastExpandedId.current) return;
    const expandedId = lastExpandedId.current;
    const detailRowId = `__detail__${String(expandedId)}`;

    const timer = setTimeout(() => {
      try {
        const el = (apiRef.current as any)?.getRowElement?.(detailRowId);
        if (el) {
          el.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
      } catch { /* noop */ }
    }, 200); // wait for ResizeObserver to fire first

    return () => clearTimeout(timer);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [expandedIds, getDetailContent]);

  // ── Header filter change ──────────────────────────────────────────────────
  const handleHeaderFilterChange = useCallback(
    (field: string, value: string) => {
      setHeaderFilters((prev) => {
        const existing = prev.filter((f) => f.field !== field);
        if (!value) return existing;
        return [...existing, { field, value, operator: 'contains' as const }];
      });
    },
    []
  );

  // ── Apply header filters to rows ──────────────────────────────────────────
  const filteredRows = useMemo(() => {
    return applyHeaderFilters(rows, headerFilters);
  }, [rows, headerFilters]);

  // ── Pivot: transform rows and columns ─────────────────────────────────────
  const { rows: pivotedRows, columns: pivotedColumns } = useMemo(() => {
    if (activePivotConfig) return applyPivot(filteredRows, activePivotConfig);
    return { rows: filteredRows, columns };
  }, [filteredRows, columns, activePivotConfig]);

  // ── Row Grouping ──────────────────────────────────────────────────────────
  const groupedRows = useMemo(() => {
    if (!groupByField || activePivotConfig) return pivotedRows;
    return applyRowGrouping(
      pivotedRows,
      {
        field: groupByField,
        showSubtotals: true,
        sortGroups: rowGroupingConfig?.sortGroups ?? 'asc',
      },
      pivotedColumns as ZenttoColDef[],
      expandedGroups,
      getRowIdFn
    );
  }, [pivotedRows, groupByField, activePivotConfig, pivotedColumns, expandedGroups, getRowIdFn, rowGroupingConfig]);

  // ── Tree Data ─────────────────────────────────────────────────────────────
  const treeRows = useMemo(() => {
    if (!treeDataConfig || activePivotConfig || groupByField) return groupedRows;
    return applyTreeData(groupedRows, treeDataConfig, expandedTreeNodes, getRowIdFn);
  }, [groupedRows, treeDataConfig, activePivotConfig, groupByField, expandedTreeNodes, getRowIdFn]);

  // ── Master-detail: inject detail rows ─────────────────────────────────────
  const processedRows = useMemo(
    () => injectDetailRows(treeRows, expandedIds, getDetailContent, getRowIdFn),
    [treeRows, expandedIds, getDetailContent, getRowIdFn]
  );

  // ── Totals ────────────────────────────────────────────────────────────────
  const hasTotals = showTotals && pivotedColumns.some((c) => (c as ZenttoColDef).aggregation);
  const totalsRow = useMemo(
    () => (hasTotals ? computeTotals(pivotedRows, pivotedColumns as ZenttoColDef[], totalsLabel) : null),
    [hasTotals, pivotedRows, pivotedColumns, totalsLabel]
  );

  // ── Normalize date/currency columns ───────────────────────────────────────
  const resolvedDateLocale = dateLocale ?? (typeof navigator !== 'undefined' ? navigator.language : 'es');

  const normalizedColumns = useMemo(() => {
    // First apply column templates (rich rendering: avatar, status, flag, etc.)
    const templated = applyColumnTemplates(pivotedColumns as ZenttoColDef[]);

    return templated.map((col) => {
      let result = col;

      // Access type/valueFormatter safely using 'in' to avoid union type issues
      const colType = 'type' in col ? (col as any).type : undefined;
      const colVF = 'valueFormatter' in col ? (col as any).valueFormatter : undefined;

      // Auto-format dates
      if ((colType === 'date' || colType === 'dateTime') && !colVF) {
        const isDateTime = colType === 'dateTime';
        result = {
          ...result,
          valueGetter:
            col.valueGetter ??
            ((value: unknown) => {
              if (value == null || value === '') return null;
              if (value instanceof Date) return value;
              const d = new Date(value as string);
              return isNaN(d.getTime()) ? null : d;
            }),
          valueFormatter: (value: unknown) => {
            if (value == null) return '';
            const d = value instanceof Date ? value : new Date(String(value));
            if (isNaN(d.getTime())) return '';
            const opts: Intl.DateTimeFormatOptions = isDateTime
              ? { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }
              : { day: '2-digit', month: '2-digit', year: 'numeric' };
            return d.toLocaleDateString(resolvedDateLocale, opts);
          },
        } as ZenttoColDef;
      }

      // Auto-format currency
      if (col.currency && !colVF) {
        const currencyCode = col.currency === true ? (defaultCurrency ?? 'USD') : col.currency;
        result = {
          ...result,
          align: (result as any).align ?? 'right',
          headerAlign: (result as any).headerAlign ?? 'right',
          valueFormatter: (value: unknown) => {
            if (value == null || value === '') return '';
            const num = Number(value);
            if (isNaN(num)) return String(value);
            try {
              return new Intl.NumberFormat(resolvedDateLocale, {
                style: 'currency',
                currency: currencyCode,
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              }).format(num);
            } catch {
              return num.toFixed(2);
            }
          },
        } as ZenttoColDef;
      }

      return result;
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pivotedColumns, resolvedDateLocale, defaultCurrency]);

  // ── Layout persistence (order, widths, visibility, density) ───────────────
  const layout = useGridLayout(gridId, normalizedColumns);

  // ── Responsive columns (visibility) ───────────────────────────────────────
  const dataColumns = useMemo(
    () =>
      layout.processedColumns.filter(
        (c) => c.field !== 'actions' && c.type !== 'actions' && !c.field.startsWith('__')
      ),
    [layout.processedColumns]
  );

  // ── Smart mobile field selection ──────────────────────────────────────────
  // Priority: ID/code → name/description → amount/total → status
  // This ensures mobile shows the most meaningful data, not just the first 2 columns.
  const effectiveMobileFields = useMemo(() => {
    if (mobileVisibleFields) return mobileVisibleFields;

    const candidates = dataColumns.filter((c) => !c.mobileHide);
    if (candidates.length <= 3) return candidates.map((c) => c.field);

    const selected: string[] = [];
    const fieldLower = (c: ZenttoColDef) => (c.field + ' ' + (c.headerName ?? '')).toLowerCase();

    // 1. Find ID/code column (short identifier)
    const idCol = candidates.find((c) => {
      const fl = fieldLower(c);
      return fl.includes('codigo') || fl.includes('code') || fl.includes('id') ||
             fl.includes('numero') || fl.includes('number') || fl.includes('ref');
    });
    if (idCol) selected.push(idCol.field);

    // 2. Find name/description column (main text)
    const nameCol = candidates.find((c) => {
      if (selected.includes(c.field)) return false;
      const fl = fieldLower(c);
      return fl.includes('nombre') || fl.includes('name') || fl.includes('descrip') ||
             fl.includes('articulo') || fl.includes('title') || fl.includes('producto') ||
             fl.includes('concepto') || fl.includes('razon') || fl.includes('cliente') ||
             fl.includes('proveedor') || fl.includes('empleado');
    });
    if (nameCol) selected.push(nameCol.field);

    // 3. Find amount/total column (monetary value)
    const amountCol = candidates.find((c) => {
      if (selected.includes(c.field)) return false;
      const fl = fieldLower(c);
      return c.currency || fl.includes('monto') || fl.includes('total') ||
             fl.includes('precio') || fl.includes('amount') || fl.includes('saldo') ||
             fl.includes('balance') || fl.includes('costo') || fl.includes('valor');
    });
    if (amountCol) selected.push(amountCol.field);

    // 4. Find status column
    const statusCol = candidates.find((c) => {
      if (selected.includes(c.field)) return false;
      const fl = fieldLower(c);
      return c.statusColors || fl.includes('estado') || fl.includes('status') ||
             fl.includes('activo') || fl.includes('tipo');
    });
    if (statusCol) selected.push(statusCol.field);

    // Fallback: if we found < 2, fill with first available columns
    if (selected.length < 2) {
      for (const c of candidates) {
        if (!selected.includes(c.field)) {
          selected.push(c.field);
          if (selected.length >= 3) break;
        }
      }
    }

    return selected;
  }, [mobileVisibleFields, dataColumns]);

  const effectiveSmFields = useMemo(() => {
    const extra =
      smExtraFields ??
      dataColumns
        .filter((c) => !c.tabletHide && !effectiveMobileFields.includes(c.field))
        .slice(0, 2)
        .map((c) => c.field);
    return [...effectiveMobileFields, ...extra];
  }, [effectiveMobileFields, smExtraFields, dataColumns]);

  const responsiveVisibilityModel = useMemo<GridColumnVisibilityModel>(() => {
    if (!isSmall) {
      return { ...layout.columnVisibilityModel, ...(externalVisibilityModel ?? {}) };
    }
    const visible = isMobile ? effectiveMobileFields : effectiveSmFields;
    const model: GridColumnVisibilityModel = {};
    dataColumns.forEach((col) => {
      model[col.field] = visible.includes(col.field);
    });

    // In mobile: hide original action columns if they've been collapsed into the ⋮ menu
    const actionColCount = layout.processedColumns.filter(
      (c) => c.field === 'actions' || (c as any).type === 'actions'
    ).length;
    if (isSmall && actionColCount > 1) {
      layout.processedColumns.forEach((c) => {
        if (c.field === 'actions' || (c as any).type === 'actions') {
          model[c.field] = false; // hide original action columns
        }
      });
    }

    return { ...model, ...(externalVisibilityModel ?? {}) };
  }, [isSmall, isMobile, effectiveMobileFields, effectiveSmFields, dataColumns, externalVisibilityModel, layout.columnVisibilityModel, layout.processedColumns]);

  // ── Visibility change handler ─────────────────────────────────────────────
  const handleColumnVisibilityChange = useCallback(
    (model: GridColumnVisibilityModel, details: any) => {
      if (!isSmall) layout.onColumnVisibilityModelChange(model);
      onColumnVisibilityModelChange?.(model, details);
    },
    [isSmall, layout, onColumnVisibilityModelChange]
  );

  // ── Build final columns ───────────────────────────────────────────────────
  const finalColumns = useMemo<ZenttoColDef[]>(() => {
    let cols = layout.processedColumns;

    // Apply column pinning CSS
    if (pinnedColumns) cols = applyColumnPinning(cols, pinnedColumns);

    // Separate action columns
    const actionCols = cols.filter((c) => c.field === 'actions' || c.type === 'actions');
    const dataCols = cols.filter((c) => c.field !== 'actions' && c.type !== 'actions');

    const result: ZenttoColDef[] = [];

    // 1. Row number column (hidden on mobile to save space)
    if (!isSmall) {
      result.push(buildRowNumberColumn());
    }

    // 2. Drag handle column (hidden on mobile — no drag on touch)
    if (onRowReorder && !isSmall) {
      result.push(buildDragHandleColumn());
    }

    // 3. Expand column (master-detail or row grouping)
    if (getDetailContent || groupByField) {
      const totalCols = dataCols.length + actionCols.length + 2; // +row num +expand
      result.push(buildExpandColumn(expandedIds, toggleExpand, totalCols, detailPanelHeight, apiRef));
    }

    // 4. Data columns
    result.push(...dataCols);

    // 5. Mobile detail column (responsive drawer) — only if no master-detail
    if (!getDetailContent && mobileDetailDrawer && isSmall) {
      result.push(buildMobileDetailColumn(setMobileDrawerRow));
    }

    // 6. Action columns — in mobile, collapse multiple actions into a single ⋮ menu
    if (isSmall && actionCols.length > 1) {
      // Multiple action columns → collapse into one compact menu
      result.push(buildMobileActionColumn(actionCols));
    } else {
      // Desktop or single action → show normally
      result.push(...actionCols);
    }

    return result;
  }, [layout.processedColumns, getDetailContent, groupByField, expandedIds, toggleExpand, detailPanelHeight, pinnedColumns, mobileDetailDrawer, isSmall, onRowReorder, apiRef]);

  // ── Export handlers ───────────────────────────────────────────────────────
  const handleExportCsv = useCallback(() => {
    exportToCsv(processedRows, finalColumns, exportFilename);
  }, [processedRows, finalColumns, exportFilename]);

  const handleExportExcel = useCallback(() => {
    exportToExcel(processedRows, finalColumns, exportFilename);
  }, [processedRows, finalColumns, exportFilename]);

  const handleExportJson = useCallback(() => {
    exportToJson(processedRows, finalColumns, exportFilename, getDetailExportData, detailExportKey);
  }, [processedRows, finalColumns, exportFilename, getDetailExportData, detailExportKey]);

  const handleExportMarkdown = useCallback(() => {
    exportToMarkdown(processedRows, finalColumns, exportFilename);
  }, [processedRows, finalColumns, exportFilename]);

  // ── Clipboard ─────────────────────────────────────────────────────────────
  const handleCopyAll = useCallback(() => {
    const dataRows = (processedRows as GridRow[]).filter(
      (r) => !r[DETAIL_ROW_KEY] && !r[GROUP_ROW_KEY]
    );
    copyRowsToClipboard(dataRows, finalColumns);
  }, [processedRows, finalColumns]);

  // Ctrl+C keyboard handler
  useEffect(() => {
    if (!enableClipboard) return;
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'c') {
        // Only if focus is within the grid
        const gridEl = apiRef.current?.rootElementRef?.current;
        if (gridEl?.contains(document.activeElement)) {
          handleCopyAll();
        }
      }
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [enableClipboard, handleCopyAll, apiRef]);

  // ── Infinite scroll / lazy loading ────────────────────────────────────────
  useEffect(() => {
    if (!onLoadMore) return;
    const handleScroll = () => {
      try {
        const scrollEl = apiRef.current?.rootElementRef?.current?.querySelector(
          '.MuiDataGrid-virtualScroller'
        );
        if (!scrollEl) return;
        const { scrollTop, scrollHeight, clientHeight } = scrollEl;
        if (scrollHeight - scrollTop - clientHeight < 200 && !loadingMore) {
          onLoadMore();
        }
      } catch { /* noop */ }
    };

    const scrollEl = apiRef.current?.rootElementRef?.current?.querySelector(
      '.MuiDataGrid-virtualScroller'
    );
    if (scrollEl) {
      scrollEl.addEventListener('scroll', handleScroll, { passive: true });
      return () => scrollEl.removeEventListener('scroll', handleScroll);
    }
  }, [onLoadMore, loadingMore, apiRef]);

  // ── getRowHeight ──────────────────────────────────────────────────────────
  const resolvedGetRowHeight = useCallback(
    (params: any) => {
      const row = params.model as GridRow;
      if (row[DETAIL_ROW_KEY]) {
        return typeof detailPanelHeight === 'number' ? detailPanelHeight : 'auto';
      }
      if (row[GROUP_ROW_KEY]) return 40;
      return getRowHeight ? getRowHeight(params) : null;
    },
    [detailPanelHeight, getRowHeight]
  );

  // ── getEstimatedRowHeight — prevents height=0 flash for detail rows ───────
  const resolvedGetEstimatedRowHeight = useCallback(
    (params: any) => {
      const row = params.model as GridRow;
      if (row?.[DETAIL_ROW_KEY]) {
        return typeof detailPanelHeight === 'number' ? detailPanelHeight : 200;
      }
      return undefined;
    },
    [detailPanelHeight]
  );

  // ── getRowClassName ───────────────────────────────────────────────────────
  const resolvedGetRowClassName = useCallback(
    (params: any) => {
      const row = params.row as GridRow;
      const external = getRowClassName ? getRowClassName(params) : '';
      if (row[DETAIL_ROW_KEY]) return `${external} zentto-row-detail`.trim();
      if (row[TOTALS_ROW_KEY]) return `${external} zentto-row-totals`.trim();
      if (row[GROUP_ROW_KEY]) return `${external} zentto-row-group`.trim();
      if (expandedIds.has(params.id)) return `${external} zentto-row-expanded`.trim();
      return external;
    },
    [getRowClassName, expandedIds]
  );

  // ── isRowSelectable ───────────────────────────────────────────────────────
  const resolvedIsRowSelectable = useCallback(
    (params: any) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return false;
      return isRowSelectable ? isRowSelectable(params) : true;
    },
    [isRowSelectable]
  );

  // ── Groupable fields for toolbar dropdown ─────────────────────────────────
  const groupableFields = useMemo(() => {
    return dataColumns
      .filter((c) => c.type !== 'number' || c.groupable !== false)
      .map((c) => ({ field: c.field, headerName: (c.headerName ?? c.field) as string }));
  }, [dataColumns]);

  // ── Final sx ──────────────────────────────────────────────────────────────
  const finalSx = useMemo(
    () => ({
      ...baseGridSx,
      ...(pinnedColumns ? pinningSx : {}),
      ...(sx ?? {}),
    }),
    [pinnedColumns, sx]
  );

  // ── Pinned rows (top/bottom) ──────────────────────────────────────────────
  const resolvedPinnedRows = useMemo(() => {
    const result: { top?: any[]; bottom?: any[] } = {};

    if (pinnedRowsTop?.length) {
      result.top = (processedRows as GridRow[]).filter((r) =>
        pinnedRowsTop.includes(getRowIdFn(r))
      );
    }

    const bottomRows: any[] = [];
    if (pinnedRowsBottom?.length) {
      bottomRows.push(
        ...(processedRows as GridRow[]).filter((r) =>
          pinnedRowsBottom.includes(getRowIdFn(r))
        )
      );
    }
    if (hasTotals && totalsRow) {
      bottomRows.push(totalsRow);
    }
    if (bottomRows.length) result.bottom = bottomRows;

    return Object.keys(result).length ? result : undefined;
  }, [pinnedRowsTop, pinnedRowsBottom, processedRows, getRowIdFn, hasTotals, totalsRow]);

  // ── Wait for layout to load before rendering (fixes IndexedDB race) ───────
  if (!layout.loaded) {
    return (
      <Box sx={{ width: '100%', p: 2 }}>
        <Stack spacing={1}>
          <Skeleton variant="rectangular" height={42} />
          <Skeleton variant="rectangular" height={300} />
        </Stack>
      </Box>
    );
  }

  // ── Row count for toolbar ─────────────────────────────────────────────────
  const displayRowCount = (processedRows as GridRow[]).filter(
    (r) => !r[DETAIL_ROW_KEY] && !r[GROUP_ROW_KEY] && !r[TOTALS_ROW_KEY]
  ).length;

  // ─────────────────────────────────────────────────────────────────────────
  return (
    <>
      {/* Header filter row (inline filters below headers) */}
      {enableHeaderFilters && headerFiltersVisible && (
        <Box
          className="zentto-header-filter-row"
          sx={{
            display: 'flex',
            gap: 0.5,
            px: 1,
            py: 0.5,
            bgcolor: (t: any) => t.palette.mode === 'dark' ? alpha(t.palette.common.white, 0.03) : '#fafbfc',
            borderBottom: '1px solid',
            borderColor: 'divider',
            overflowX: 'auto',
          }}
        >
          {dataColumns.map((col) => (
            <TextField
              key={col.field}
              placeholder={`${col.headerName ?? col.field}...`}
              size="small"
              variant="outlined"
              onChange={(e) => handleHeaderFilterChange(col.field, e.target.value)}
              sx={{
                minWidth: 100,
                flex: 1,
                '& .MuiInputBase-root': { fontSize: '0.75rem', height: 28 },
                '& .MuiOutlinedInput-notchedOutline': { borderColor: 'divider' },
              }}
            />
          ))}
        </Box>
      )}

      <DataGrid
        {...props}
        apiRef={apiRef}
        rows={processedRows}
        columns={finalColumns as GridColDef[]}
        getRowId={getRowIdFn as any}
        density={layout.density}
        onDensityChange={(d) => layout.onDensityChange(d as any)}
        columnVisibilityModel={responsiveVisibilityModel}
        onColumnVisibilityModelChange={handleColumnVisibilityChange}
        onColumnOrderChange={() => {
          const cols = apiRef.current?.getAllColumns?.();
          if (cols) layout.onColumnOrderChange(cols.map((c) => c.field).filter((f) => !f.startsWith('__')));
        }}
        onColumnWidthChange={(params) => layout.onColumnWidthChange(params.colDef.field, params.width)}
        getRowHeight={getDetailContent || groupByField ? resolvedGetRowHeight : getRowHeight ?? (() => null)}
        // Note: getEstimatedRowHeight is not in Community Edition.
        // The DetailPanelWrapper's ResizeObserver handles height measurement instead.
        {...(getDetailContent ? { getEstimatedRowHeight: resolvedGetEstimatedRowHeight } as any : {})}
        getRowClassName={resolvedGetRowClassName}
        isRowSelectable={resolvedIsRowSelectable}
        pinnedRows={resolvedPinnedRows}
        rowCount={serverRowCount}
        slots={
          hideToolbar
            ? props.slots
            : {
                ...(props.slots ?? {}),
                toolbar: ZenttoToolbar as GridSlots['toolbar'],
              }
        }
        slotProps={
          hideToolbar
            ? props.slotProps
            : {
                ...(props.slotProps ?? {}),
                toolbar: {
                  title: toolbarTitle,
                  toolbarActions,
                  onExportCsv: showExportCsv ? handleExportCsv : undefined,
                  onExportExcel: showExportExcel ? handleExportExcel : undefined,
                  onExportJson: showExportJson ? handleExportJson : undefined,
                  onExportMarkdown: showExportMarkdown ? handleExportMarkdown : undefined,
                  showExportCsv,
                  showExportExcel,
                  showExportJson,
                  showExportMarkdown,
                  hasCustomLayout: layout.hasCustomLayout,
                  onResetLayout: layout.resetLayout,
                  hideColumnsButton,
                  hideDensityButton,
                  hideQuickFilter,
                  // Pivot
                  enablePivot,
                  isPivotActive: !!activePivotConfig,
                  onOpenPivot: () => setPivotDialogOpen(true),
                  // Row Grouping
                  enableGrouping,
                  groupByField,
                  groupableFields,
                  onGroupByChange: (field: string | null) => {
                    setGroupByField(field);
                    setExpandedGroups(new Set());
                  },
                  // Header Filters
                  enableHeaderFilters,
                  headerFiltersVisible,
                  onToggleHeaderFilters: () => setHeaderFiltersVisible((v) => !v),
                  // Clipboard
                  enableClipboard,
                  onCopyAll: handleCopyAll,
                  // Row count
                  rowCount: displayRowCount,
                } as any,
              }
        }
        sx={finalSx}
        disableRowSelectionOnClick
        // Handle row clicks:
        // - Group headers: toggle expand
        // - Mobile: open detail drawer on tap (feels like native app)
        // - Desktop: pass through to user handler
        onRowClick={(params, event, details) => {
          const row = params.row as GridRow;
          if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY]) return;
          if (row[GROUP_ROW_KEY]) {
            toggleGroup(row.__groupKey as string);
            return;
          }
          // Mobile: open bottom sheet detail on any row tap
          if (isSmall && mobileDetailDrawer && !getDetailContent) {
            setMobileDrawerRow(row);
            return;
          }
          (props.onRowClick as any)?.(params, event, details);
        }}
      />

      {/* Loading more indicator (infinite scroll) */}
      {loadingMore && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 1 }}>
          <CircularProgress size={24} />
        </Box>
      )}

      {/* Pivot Panel Dialog */}
      {enablePivot && (
        <PivotPanel
          open={pivotDialogOpen}
          onClose={() => setPivotDialogOpen(false)}
          columns={columns}
          currentConfig={activePivotConfig ?? null}
          onApply={(config) => setDynamicPivotConfig(config)}
          onClear={() => setDynamicPivotConfig(null)}
        />
      )}

      {/* ── Mobile Detail Drawer (Bottom Sheet) ──────────────────────────── */}
      {/* Redesigned as a modern card-like experience.                       */}
      {/* Layout:                                                            */}
      {/*   1. Drag handle + close button                                    */}
      {/*   2. Hero: primary field (name/description) large + ID/code small  */}
      {/*   3. Key metrics row: amount, status, date in a compact grid       */}
      {/*   4. All fields in a clean 2-column grid                           */}
      {/*   5. Action buttons at the bottom                                  */}
      {mobileDetailDrawer && (
        <Drawer
          anchor="bottom"
          open={Boolean(mobileDrawerRow)}
          onClose={() => setMobileDrawerRow(null)}
          PaperProps={{
            sx: {
              borderTopLeftRadius: 16,
              borderTopRightRadius: 16,
              maxHeight: '85vh',
              bgcolor: 'background.default',
            },
          }}
        >
          {mobileDrawerRow && (() => {
            // Classify columns for smart layout
            const allCols = (pivotedColumns as ZenttoColDef[]).filter(
              (c) => c.field !== 'actions' && (c as any).type !== 'actions' && !c.field.startsWith('__')
            );
            const actionCols = (pivotedColumns as ZenttoColDef[]).filter(
              (c) => c.field === 'actions' || (c as any).type === 'actions'
            );
            const fl = (c: ZenttoColDef) => (c.field + ' ' + (c.headerName ?? '')).toLowerCase();

            // Find hero fields
            const nameCol = allCols.find((c) => {
              const f = fl(c);
              return f.includes('nombre') || f.includes('name') || f.includes('descrip') ||
                     f.includes('articulo') || f.includes('title') || f.includes('concepto') ||
                     f.includes('razon') || f.includes('cliente') || f.includes('empleado');
            });
            const idCol = allCols.find((c) => {
              const f = fl(c);
              return f.includes('codigo') || f.includes('code') || (f.includes('id') && !f.includes('descrip')) ||
                     f.includes('numero') || f.includes('number') || f.includes('ref');
            });

            // Find key metric fields
            const amountCol = allCols.find((c) => {
              const f = fl(c);
              return c.currency || f.includes('monto') || f.includes('total') ||
                     f.includes('precio') || f.includes('amount') || f.includes('saldo');
            });
            const statusCol = allCols.find((c) => c.statusColors || fl(c).includes('estado') || fl(c).includes('status'));
            const dateCol = allCols.find((c) => (c as any).type === 'date' || (c as any).type === 'dateTime');

            const heroFields = new Set([nameCol?.field, idCol?.field].filter(Boolean));
            const metricFields = new Set([amountCol?.field, statusCol?.field, dateCol?.field].filter(Boolean));
            const restCols = allCols.filter((c) => !heroFields.has(c.field) && !metricFields.has(c.field));

            // Format a cell value
            const fmt = (col: ZenttoColDef): string => {
              const val = mobileDrawerRow[col.field];
              if (col.valueFormatter && typeof col.valueFormatter === 'function') {
                try {
                  const f = (col.valueFormatter as Function)(val, mobileDrawerRow, col, {});
                  return f != null ? String(f) : val != null ? String(val) : '-';
                } catch { return val != null ? String(val) : '-'; }
              }
              if (val == null || val === '') return '-';
              if (typeof val === 'boolean') return val ? 'Si' : 'No';
              return String(val);
            };

            return (
              <Box sx={{ overflowY: 'auto', pb: 2 }}>
                {/* Drag handle */}
                <Box sx={{ pt: 1.5, pb: 1, display: 'flex', justifyContent: 'center' }}>
                  <Box sx={{ width: 40, height: 4, bgcolor: 'grey.400', borderRadius: 2 }} />
                </Box>

                {/* Hero section */}
                <Box sx={{ px: 2.5, pb: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      {idCol && (
                        <Typography
                          variant="caption"
                          color="primary.main"
                          fontWeight={700}
                          sx={{ fontSize: '0.7rem', letterSpacing: '0.05em', textTransform: 'uppercase' }}
                        >
                          {fmt(idCol)}
                        </Typography>
                      )}
                      <Typography
                        variant="h6"
                        fontWeight={700}
                        sx={{ fontSize: '1.1rem', lineHeight: 1.3, mt: 0.25, wordBreak: 'break-word' }}
                      >
                        {nameCol ? fmt(nameCol) : (idCol ? fmt(idCol) : 'Detalle')}
                      </Typography>
                    </Box>
                    <IconButton size="small" onClick={() => setMobileDrawerRow(null)} sx={{ ml: 1 }}>
                      <CloseIcon fontSize="small" />
                    </IconButton>
                  </Box>
                </Box>

                {/* Key metrics — compact cards in a row */}
                {(amountCol || statusCol || dateCol) && (
                  <Box
                    sx={{
                      display: 'flex',
                      gap: 1,
                      px: 2.5,
                      pb: 2,
                      overflowX: 'auto',
                      '&::-webkit-scrollbar': { display: 'none' },
                    }}
                  >
                    {amountCol && (
                      <Box
                        sx={{
                          flex: 1,
                          minWidth: 90,
                          bgcolor: 'background.paper',
                          borderRadius: 2,
                          p: 1.5,
                          border: '1px solid',
                          borderColor: 'divider',
                        }}
                      >
                        <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.65rem', textTransform: 'uppercase', fontWeight: 600 }}>
                          {amountCol.headerName ?? amountCol.field}
                        </Typography>
                        <Typography variant="body1" fontWeight={700} color="primary.main" sx={{ fontSize: '1rem', mt: 0.25 }}>
                          {fmt(amountCol)}
                        </Typography>
                      </Box>
                    )}
                    {statusCol && (
                      <Box
                        sx={{
                          flex: 1,
                          minWidth: 80,
                          bgcolor: 'background.paper',
                          borderRadius: 2,
                          p: 1.5,
                          border: '1px solid',
                          borderColor: 'divider',
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.65rem', textTransform: 'uppercase', fontWeight: 600, mb: 0.5 }}>
                          {statusCol.headerName ?? statusCol.field}
                        </Typography>
                        {statusCol.statusColors ? (() => {
                          const val = String(mobileDrawerRow[statusCol.field] ?? '');
                          const color = statusCol.statusColors?.[val] ?? 'default';
                          const isStd = ['default','primary','secondary','error','info','success','warning'].includes(color);
                          return <Chip label={val || '-'} size="small" color={isStd ? color as any : 'default'} sx={{ fontWeight: 600, fontSize: '0.7rem' }} />;
                        })() : (
                          <Typography variant="body2" fontWeight={600}>{fmt(statusCol)}</Typography>
                        )}
                      </Box>
                    )}
                    {dateCol && (
                      <Box
                        sx={{
                          flex: 1,
                          minWidth: 80,
                          bgcolor: 'background.paper',
                          borderRadius: 2,
                          p: 1.5,
                          border: '1px solid',
                          borderColor: 'divider',
                        }}
                      >
                        <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.65rem', textTransform: 'uppercase', fontWeight: 600 }}>
                          {dateCol.headerName ?? dateCol.field}
                        </Typography>
                        <Typography variant="body2" fontWeight={600} sx={{ mt: 0.25 }}>
                          {fmt(dateCol)}
                        </Typography>
                      </Box>
                    )}
                  </Box>
                )}

                {/* Divider */}
                <Divider sx={{ mx: 2.5 }} />

                {/* All other fields — 2-column grid layout */}
                <Box
                  sx={{
                    display: 'grid',
                    gridTemplateColumns: restCols.length > 4 ? '1fr 1fr' : '1fr',
                    gap: 0,
                    px: 2.5,
                    py: 1.5,
                  }}
                >
                  {restCols.map((col, i) => (
                    <Box
                      key={col.field}
                      sx={{
                        py: 1.25,
                        px: 0.5,
                        borderBottom: '1px solid',
                        borderColor: 'divider',
                        // Alternate background for readability
                        bgcolor: i % 2 === 0 ? 'transparent' : (t: any) =>
                          t.palette.mode === 'dark' ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.015)',
                      }}
                    >
                      <Typography
                        variant="caption"
                        color="text.secondary"
                        sx={{
                          fontSize: '0.65rem',
                          textTransform: 'uppercase',
                          letterSpacing: '0.06em',
                          fontWeight: 600,
                          display: 'block',
                          mb: 0.25,
                        }}
                      >
                        {col.headerName ?? col.field}
                      </Typography>
                      {col.statusColors ? (() => {
                        const val = String(mobileDrawerRow[col.field] ?? '');
                        const color = col.statusColors?.[val] ?? 'default';
                        const isStd = ['default','primary','secondary','error','info','success','warning'].includes(color);
                        return <Chip label={val || '-'} size="small" color={isStd ? color as any : 'default'} sx={{ fontWeight: 600, fontSize: '0.7rem' }} />;
                      })() : (
                        <Typography variant="body2" fontWeight={500} sx={{ wordBreak: 'break-word', fontSize: '0.85rem' }}>
                          {fmt(col)}
                        </Typography>
                      )}
                    </Box>
                  ))}
                </Box>

                {/* Action buttons — full width at bottom */}
                {actionCols.length > 0 && (
                  <Box sx={{ px: 2.5, pt: 2, pb: 1, display: 'flex', gap: 1, flexWrap: 'wrap', justifyContent: 'center' }}>
                    {/* Re-render the action columns' cells for this row */}
                    {actionCols.map((col) => {
                      if (!col.renderCell) return null;
                      const mockParams = {
                        row: mobileDrawerRow,
                        id: getRowIdFn(mobileDrawerRow),
                        field: col.field,
                        value: mobileDrawerRow[col.field],
                        api: apiRef.current,
                        colDef: col,
                        hasFocus: false,
                        tabIndex: -1,
                        cellMode: 'view' as const,
                        isEditable: false,
                        rowNode: { id: getRowIdFn(mobileDrawerRow), type: 'leaf' as const, depth: 0, parent: null, children: [] as any },
                        formattedValue: mobileDrawerRow[col.field],
                      };
                      return <Box key={col.field}>{col.renderCell(mockParams as any)}</Box>;
                    })}
                  </Box>
                )}
              </Box>
            );
          })()}
        </Drawer>
      )}
    </>
  );
}
