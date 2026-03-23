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
} from '@mui/material';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import CloseIcon from '@mui/icons-material/Close';

import { ZenttoToolbar } from './ZenttoToolbar';
import { useGridLayout } from './useGridLayout';
import {
  resolveId,
  injectDetailRows,
  computeTotals,
  applyPivot,
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
  DETAIL_ROW_KEY,
  TOTALS_ROW_KEY,
  EXPAND_COL_FIELD,
  MOBILE_DETAIL_COL_FIELD,
} from './types';

// ─── Estilos globales del componente ─────────────────────────────────────────

const baseGridSx = {
  border: 'none',
  borderRadius: 0,
  // Header elegante — usa background.default para adaptarse a dark mode
  '& .MuiDataGrid-columnHeaders': {
    bgcolor: 'background.default',
    borderBottom: '2px solid',
    borderColor: 'divider',
    fontSize: '0.8rem',
    fontWeight: 700,
    color: 'text.secondary',
  },
  '& .MuiDataGrid-columnHeader': {
    '&:focus, &:focus-within': { outline: 'none' },
  },
  // Filas
  '& .MuiDataGrid-row': {
    transition: 'background-color 0.15s',
    '&:hover': {
      bgcolor: 'action.hover',
    },
    '&.Mui-selected': {
      bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.06),
      '&:hover': {
        bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.1),
      },
    },
  },
  // Fila EXPANDIDA → borde izquierdo acento + fondo sutil
  '& .zentto-row-expanded': {
    bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.04),
    borderLeft: '3px solid',
    borderColor: 'primary.main',
    '&:hover': {
      bgcolor: (theme: any) => alpha(theme.palette.primary.main, 0.07),
    },
  },
  // Fila de DETALLE → sin hover, fondo sólido (no transparent)
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
  // Fila de TOTALES → bold + fondo adaptado a dark mode
  '& .zentto-row-totals': {
    bgcolor: 'action.selected',
    fontWeight: 700,
    borderTop: '2px solid',
    borderColor: 'divider',
  },
  // Celdas — un punto menos que el header
  '& .MuiDataGrid-cell': {
    fontSize: '0.75rem',
    borderColor: 'divider',
    '&:focus, &:focus-within': { outline: 'none' },
  },
  // Columna de expand — sin padding
  [`& .MuiDataGrid-cell[data-field="${EXPAND_COL_FIELD}"]`]: {
    padding: '0 !important',
    overflow: 'hidden',
  },
  // Footer
  '& .MuiDataGrid-footerContainer': {
    borderTop: '1px solid',
    borderColor: 'divider',
    minHeight: 48,
  },
  // Quitar sombra de columna virtual
  '& .MuiDataGrid-virtualScrollerContent': {
    minHeight: 1,
  },
} as const;

// ─── Columna de expand/collapse ───────────────────────────────────────────────

function buildExpandColumn(
  expandedIds: Set<GridRowId>,
  onToggle: (id: GridRowId) => void,
  totalColumns: number,
  detailPanelHeight: number | 'auto'
): ZenttoColDef {
  return {
    field: EXPAND_COL_FIELD,
    headerName: '',
    width: 48,
    minWidth: 48,
    maxWidth: 48,
    sortable: false,
    filterable: false,
    disableColumnMenu: true,
    hideable: false,
    resizable: false,
    // colSpan: en filas de detalle ocupa TODAS las columnas
    colSpan: (_value: unknown, row: GridRow) => {
      if (row[DETAIL_ROW_KEY]) return totalColumns;
      return 1;
    },
    renderCell: (params) => {
      const row = params.row as GridRow;

      // ── Fila de DETALLE ──────────────────────────────────────────────────
      if (row[DETAIL_ROW_KEY]) {
        return (
          <Box
            sx={{
              width: '100%',
              minHeight: typeof detailPanelHeight === 'number' ? detailPanelHeight : undefined,
              display: 'flex',
              flexDirection: 'column',
              bgcolor: 'background.paper',
              // Animación de entrada
              animation: 'zenttoDetailIn 0.22s ease',
              '@keyframes zenttoDetailIn': {
                from: { opacity: 0, transform: 'translateY(-4px)' },
                to: { opacity: 1, transform: 'translateY(0)' },
              },
            }}
          >
            <Box
              sx={{
                display: 'flex',
                flex: 1,
                pl: 2,
                pr: 2,
                py: 1.5,
                bgcolor: 'background.paper',
              }}
            >
              {row.__content as React.ReactNode}
            </Box>
          </Box>
        );
      }

      // ── Fila NORMAL → botón de expand ───────────────────────────────────
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
              width: 30,
              height: 30,
              color: isExpanded ? 'primary.main' : 'text.secondary',
              transition: 'color 0.15s',
            }}
          >
            <ChevronRightIcon
              fontSize="small"
              sx={{
                transition: 'transform 0.22s cubic-bezier(0.4, 0, 0.2, 1)',
                transform: isExpanded ? 'rotate(90deg)' : 'rotate(0deg)',
              }}
            />
          </IconButton>
        </Tooltip>
      );
    },
  };
}

// ─── Columna de info móvil ────────────────────────────────────────────────────

function buildMobileDetailColumn(onOpen: (row: GridRow) => void): ZenttoColDef {
  return {
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
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY]) return null;
      return (
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
      );
    },
  };
}

// ─── ZenttoDataGrid ───────────────────────────────────────────────────────────

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
  pivotConfig,
  // Aggregation
  showTotals = false,
  totalsLabel = 'Total',
  // Pinned columns
  pinnedColumns,
  // Fechas y monedas
  dateLocale,
  defaultCurrency,
  // Export
  exportFilename = 'zentto-export',
  showExportCsv = true,
  showExportExcel = true,
  showExportJson = true,
  showExportMarkdown = false,
  // Layout persistente
  gridId,
  // Toolbar
  toolbarTitle,
  toolbarActions,
  hideToolbar = false,
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

  // ── Estado ──────────────────────────────────────────────────────────────────
  const [expandedIds, setExpandedIds] = useState<Set<GridRowId>>(new Set());
  const [mobileDrawerRow, setMobileDrawerRow] = useState<GridRow | null>(null);
  const apiRef = useGridApiRef();
  const lastExpandedId = useRef<GridRowId | null>(null);

  // ── Resolver ID ─────────────────────────────────────────────────────────────
  const getRowIdFn = useCallback(
    (row: GridRow) => resolveId(row, getRowId as ((r: GridRow) => GridRowId) | undefined),
    [getRowId]
  );

  // ── Toggle expand ───────────────────────────────────────────────────────────
  const toggleExpand = useCallback((id: GridRowId) => {
    // Scroll el padre cerca del top ANTES de inyectar el detalle.
    // Esto garantiza que la fila de detalle (inyectada justo debajo) quede dentro
    // del viewport de virtualización y MUI la pueda medir correctamente.
    // Sin esto, filas al fondo del DataGrid no se miden (altura=0 permanente).
    try {
      const allIds = apiRef.current?.getSortedRowIds?.() ?? [];
      const rowIndex = allIds.findIndex(rid => rid === id);
      if (rowIndex >= 0) {
        apiRef.current?.scrollToIndexes?.({ rowIndex: Math.max(0, rowIndex - 3) });
      }
    } catch { /* noop */ }

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

  // ── Fix render + scroll del panel de detalle ─────────────────────────────
  // Problema 1: getRowHeight:'auto' mide asíncronamente → height=0 en primera expansión.
  // Problema 2: scrollToIndexes mueve al TOP de la fila, pero el panel puede ser alto.
  // Problema 3: el id del panel era calculado incorrectamente (formato no coincidía).
  //
  // Solución:
  //   - resetRowHeights() fuerza nueva medición (inmediato + tras doble rAF)
  //   - getRowElement(detailRowId) + scrollIntoView({ block:'nearest' }) mueve el
  //     panel al viewport sin pasarse del top ni cortar el bottom
  useEffect(() => {
    if (!getDetailContent || !lastExpandedId.current) return;
    const expandedId = lastExpandedId.current;
    // CORRECTO: injectDetailRows crea las filas con id `__detail__${id}`
    const detailRowId = `__detail__${String(expandedId)}`;

    const reset = () => {
      try { apiRef.current?.resetRowHeights?.(); } catch { /* noop */ }
    };

    // Reset inmediato
    reset();

    // Doble rAF para esperar que el DOM haya pintado con la nueva altura
    const t1 = setTimeout(() => {
      reset();
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          reset();
          try {
            // Intentar scroll via DOM element (más preciso que scrollToIndexes)
            const el = (apiRef.current as any)?.getRowElement?.(detailRowId);
            if (el) {
              el.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
            } else {
              // Fallback: scroll al índice del padre + 1
              const parentIdx = apiRef.current?.getRowIndexRelativeToVisibleRows?.(expandedId);
              if (parentIdx != null && parentIdx >= 0) {
                apiRef.current?.scrollToIndexes?.({ rowIndex: parentIdx + 1 });
              }
            }
          } catch { /* noop */ }
        });
      });
    }, 80);

    return () => clearTimeout(t1);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [expandedIds, getDetailContent]);

  // ── Pivot: transforma rows y columns ────────────────────────────────────────
  const { rows: pivotedRows, columns: pivotedColumns } = useMemo(() => {
    if (pivotConfig) return applyPivot(rows, pivotConfig);
    return { rows, columns };
  }, [rows, columns, pivotConfig]);

  // ── Master-detail: inyectar filas de detalle ─────────────────────────────────
  const processedRows = useMemo(
    () => injectDetailRows(pivotedRows, expandedIds, getDetailContent, getRowIdFn),
    [pivotedRows, expandedIds, getDetailContent, getRowIdFn]
  );

  // ── Totales ──────────────────────────────────────────────────────────────────
  const hasTotals = showTotals && pivotedColumns.some((c) => c.aggregation);
  const totalsRow = useMemo(
    () => (hasTotals ? computeTotals(pivotedRows, pivotedColumns as ZenttoColDef[], totalsLabel) : null),
    [hasTotals, pivotedRows, pivotedColumns, totalsLabel]
  );

  // ── Normalizar columnas de fecha / moneda (debe ir ANTES de dataColumns) ─────
  const resolvedDateLocale = dateLocale
    ?? (typeof navigator !== 'undefined' ? navigator.language : 'es');

  const normalizedColumns = useMemo(() => {
    return (pivotedColumns as ZenttoColDef[]).map((col) => {
      let result = col;

      // ── Auto-formato de fechas ────────────────────────────────────────────
      if ((col.type === 'date' || col.type === 'dateTime') && !col.valueFormatter) {
        const isDateTime = col.type === 'dateTime';
        result = {
          ...result,
          valueGetter: col.valueGetter ?? ((value: unknown) => {
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

      // ── Auto-formato de moneda ────────────────────────────────────────────
      if (col.currency && !col.valueFormatter) {
        const currencyCode = col.currency === true ? (defaultCurrency ?? 'USD') : col.currency;
        result = {
          ...result,
          align: result.align ?? 'right',
          headerAlign: result.headerAlign ?? 'right',
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

  // ── Layout persistente (orden, anchos, visibilidad, densidad) ─────────────────
  const layout = useGridLayout(gridId, normalizedColumns);

  // ── Columnas responsive (visibilidad) ────────────────────────────────────────
  const dataColumns = useMemo(
    () =>
      layout.processedColumns.filter(
        (c) =>
          c.field !== 'actions' &&
          c.type !== 'actions' &&
          !c.field.startsWith('__')
      ),
    [layout.processedColumns]
  );

  const effectiveMobileFields = useMemo(() => {
    if (mobileVisibleFields) return mobileVisibleFields;
    return dataColumns
      .filter((c) => !c.mobileHide)
      .slice(0, 2)
      .map((c) => c.field);
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
      // Desktop: preferencias del usuario del layout + overrides del desarrollador
      return { ...layout.columnVisibilityModel, ...(externalVisibilityModel ?? {}) };
    }
    // Móvil/Tablet: control responsivo (anula preferencias de layout)
    const visible = isMobile ? effectiveMobileFields : effectiveSmFields;
    const model: GridColumnVisibilityModel = {};
    dataColumns.forEach((col) => {
      model[col.field] = visible.includes(col.field);
    });
    return { ...model, ...(externalVisibilityModel ?? {}) };
  }, [isSmall, isMobile, effectiveMobileFields, effectiveSmFields, dataColumns, externalVisibilityModel, layout.columnVisibilityModel]);

  // ── Handler visibilidad unificado (layout + external callback) ────────────────
  const handleColumnVisibilityChange = useCallback(
    (model: GridColumnVisibilityModel, details: any) => {
      if (!isSmall) layout.onColumnVisibilityModelChange(model);
      onColumnVisibilityModelChange?.(model, details);
    },
    [isSmall, layout, onColumnVisibilityModelChange]
  );

  // ── Construir columnas finales ────────────────────────────────────────────────
  const finalColumns = useMemo<ZenttoColDef[]>(() => {
    let cols = layout.processedColumns;

    // Aplicar column pinning CSS
    if (pinnedColumns) cols = applyColumnPinning(cols, pinnedColumns);

    // Separar acciones
    const actionCols = cols.filter((c) => c.field === 'actions' || c.type === 'actions');
    const dataCols = cols.filter((c) => c.field !== 'actions' && c.type !== 'actions');

    const result: ZenttoColDef[] = [];

    // 1. Columna de expand (master-detail) — solo si hay getDetailContent
    if (getDetailContent) {
      const totalCols = dataCols.length + actionCols.length + 1; // +1 por sí misma
      result.push(buildExpandColumn(expandedIds, toggleExpand, totalCols, detailPanelHeight));
    }

    // 2. Columnas de datos
    result.push(...dataCols);

    // 3. Columna de info móvil (responsive drawer) — solo si no hay master-detail
    if (!getDetailContent && mobileDetailDrawer && isSmall) {
      result.push(buildMobileDetailColumn(setMobileDrawerRow));
    }

    // 4. Columnas de acciones al final
    result.push(...actionCols);

    return result;
  }, [layout.processedColumns, getDetailContent, expandedIds, toggleExpand, detailPanelHeight, pinnedColumns, mobileDetailDrawer, isSmall]);

  // ── Export ───────────────────────────────────────────────────────────────────
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

  // ── getRowHeight ──────────────────────────────────────────────────────────────
  const resolvedGetRowHeight = useCallback(
    (params: any) => {
      const row = params.model as GridRow;
      if (row[DETAIL_ROW_KEY]) {
        return typeof detailPanelHeight === 'number' ? detailPanelHeight : 'auto';
      }
      return getRowHeight ? getRowHeight(params) : null;
    },
    [detailPanelHeight, getRowHeight]
  );

  // ── getRowClassName ───────────────────────────────────────────────────────────
  const resolvedGetRowClassName = useCallback(
    (params: any) => {
      const row = params.row as GridRow;
      const external = getRowClassName ? getRowClassName(params) : '';
      if (row[DETAIL_ROW_KEY]) return `${external} zentto-row-detail`.trim();
      if (row[TOTALS_ROW_KEY]) return `${external} zentto-row-totals`.trim();
      if (expandedIds.has(params.id)) return `${external} zentto-row-expanded`.trim();
      return external;
    },
    [getRowClassName, expandedIds]
  );

  // ── isRowSelectable ───────────────────────────────────────────────────────────
  const resolvedIsRowSelectable = useCallback(
    (params: any) => {
      const row = params.row as GridRow;
      if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY]) return false;
      return isRowSelectable ? isRowSelectable(params) : true;
    },
    [isRowSelectable]
  );

  // ── sx final ─────────────────────────────────────────────────────────────────
  const finalSx = useMemo(
    () => ({
      ...baseGridSx,
      ...(pinnedColumns ? pinningSx : {}),
      ...(sx ?? {}),
    }),
    [pinnedColumns, sx]
  );

  // ─────────────────────────────────────────────────────────────────────────────
  return (
    <>
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
          if (cols) layout.onColumnOrderChange(cols.map(c => c.field).filter(f => !f.startsWith('__')));
        }}
        onColumnWidthChange={(params) => layout.onColumnWidthChange(params.colDef.field, params.width)}
        getRowHeight={getDetailContent ? resolvedGetRowHeight : getRowHeight ?? (() => null)}
        getRowClassName={resolvedGetRowClassName}
        isRowSelectable={resolvedIsRowSelectable}
        pinnedRows={hasTotals && totalsRow ? { bottom: [totalsRow as any] } : undefined}
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
                } as any,
              }
        }
        sx={finalSx}
        disableRowSelectionOnClick
      />

      {/* ── Mobile Detail Drawer ─────────────────────────────────────────────── */}
      {mobileDetailDrawer && !getDetailContent && (
        <Drawer
          anchor="bottom"
          open={Boolean(mobileDrawerRow)}
          onClose={() => setMobileDrawerRow(null)}
          PaperProps={{
            sx: {
              borderTopLeftRadius: 20,
              borderTopRightRadius: 20,
              maxHeight: '80vh',
            },
          }}
        >
          <Box sx={{ p: 2.5, overflowY: 'auto' }}>
            {/* Handle */}
            <Box
              sx={{
                width: 36,
                height: 4,
                bgcolor: 'grey.300',
                borderRadius: 2,
                mx: 'auto',
                mb: 2.5,
              }}
            />

            {/* Header */}
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1.5 }}>
              <Typography variant="h6" fontWeight={700} sx={{ flex: 1, fontSize: '1.05rem' }}>
                Detalle del registro
              </Typography>
              <IconButton size="small" onClick={() => setMobileDrawerRow(null)}>
                <CloseIcon fontSize="small" />
              </IconButton>
            </Box>

            <Divider sx={{ mb: 2 }} />

            {/* Campos */}
            <Stack spacing={2} sx={{ pb: 3 }}>
              {mobileDrawerRow &&
                (pivotedColumns as ZenttoColDef[])
                  .filter(
                    (c) =>
                      c.field !== 'actions' &&
                      c.type !== 'actions' &&
                      !c.field.startsWith('__')
                  )
                  .map((col) => {
                    const val = mobileDrawerRow[col.field];
                    let display = '-';
                    if (col.valueFormatter && typeof col.valueFormatter === 'function') {
                      try {
                        const f = col.valueFormatter(val as never, mobileDrawerRow as never, col, {} as never);
                        display = f != null ? String(f) : val != null ? String(val) : '-';
                      } catch {
                        display = val != null ? String(val) : '-';
                      }
                    } else if (val != null && val !== '') {
                      display = typeof val === 'boolean' ? (val ? 'Sí' : 'No') : String(val);
                    }

                    return (
                      <Box key={col.field}>
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          sx={{
                            fontSize: '0.68rem',
                            textTransform: 'uppercase',
                            letterSpacing: '0.07em',
                            fontWeight: 600,
                            display: 'block',
                            mb: 0.25,
                          }}
                        >
                          {col.headerName ?? col.field}
                        </Typography>
                        <Typography variant="body2" fontWeight={500} sx={{ wordBreak: 'break-word' }}>
                          {display}
                        </Typography>
                      </Box>
                    );
                  })}
            </Stack>
          </Box>
        </Drawer>
      )}
    </>
  );
}
