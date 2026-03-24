'use client';

import React from 'react';
import {
  GridToolbarContainer,
  GridToolbarFilterButton,
  GridToolbarColumnsButton,
  GridToolbarQuickFilter,
  GridToolbarDensitySelector,
} from '@mui/x-data-grid';
import {
  Box,
  Button,
  Divider,
  Typography,
  Tooltip,
  Stack,
  IconButton,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
} from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import TableChartIcon from '@mui/icons-material/TableChart';
import DataObjectIcon from '@mui/icons-material/DataObject';
import ArticleIcon from '@mui/icons-material/Article';
import LayersClearIcon from '@mui/icons-material/LayersClear';
import PivotTableChartIcon from '@mui/icons-material/PivotTableChart';
import GroupWorkIcon from '@mui/icons-material/GroupWork';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import FilterListIcon from '@mui/icons-material/FilterList';

interface ZenttoToolbarProps {
  title?: string;
  toolbarActions?: React.ReactNode;
  // Export
  onExportCsv?: () => void;
  onExportExcel?: () => void;
  onExportJson?: () => void;
  onExportMarkdown?: () => void;
  showExportCsv?: boolean;
  showExportExcel?: boolean;
  showExportJson?: boolean;
  showExportMarkdown?: boolean;
  // Layout
  hideColumnsButton?: boolean;
  hideDensityButton?: boolean;
  hideQuickFilter?: boolean;
  hasCustomLayout?: boolean;
  onResetLayout?: () => void;
  // Pivot
  enablePivot?: boolean;
  isPivotActive?: boolean;
  onOpenPivot?: () => void;
  // Row Grouping
  enableGrouping?: boolean;
  groupByField?: string | null;
  groupableFields?: Array<{ field: string; headerName: string }>;
  onGroupByChange?: (field: string | null) => void;
  // Header Filters
  enableHeaderFilters?: boolean;
  headerFiltersVisible?: boolean;
  onToggleHeaderFilters?: () => void;
  // Clipboard
  enableClipboard?: boolean;
  onCopyAll?: () => void;
  // Row count
  rowCount?: number;
}

export function ZenttoToolbar({
  title,
  toolbarActions,
  onExportCsv,
  onExportExcel,
  onExportJson,
  onExportMarkdown,
  showExportCsv,
  showExportExcel,
  showExportJson,
  showExportMarkdown,
  hideColumnsButton,
  hideDensityButton,
  hideQuickFilter,
  hasCustomLayout,
  onResetLayout,
  enablePivot,
  isPivotActive,
  onOpenPivot,
  enableGrouping,
  groupByField,
  groupableFields,
  onGroupByChange,
  enableHeaderFilters,
  headerFiltersVisible,
  onToggleHeaderFilters,
  enableClipboard,
  onCopyAll,
  rowCount,
}: ZenttoToolbarProps) {
  return (
    <GridToolbarContainer
      sx={{
        px: 1.5,
        py: 0.75,
        gap: 0.5,
        borderBottom: '1px solid',
        borderColor: 'divider',
        bgcolor: 'background.paper',
        flexWrap: 'wrap',
        minHeight: 44,
      }}
    >
      {/* Title */}
      {title && (
        <>
          <Typography
            variant="subtitle2"
            fontWeight={700}
            color="text.primary"
            sx={{ mr: 1, fontSize: '0.85rem' }}
          >
            {title}
          </Typography>
          <Divider orientation="vertical" flexItem />
        </>
      )}

      {/* Filter button — native dropdown OR header-filters toggle */}
      {enableHeaderFilters ? (
        <Tooltip title={headerFiltersVisible ? 'Ocultar filtros de columna' : 'Mostrar filtros de columna'}>
          <Button
            size="small"
            startIcon={<FilterListIcon fontSize="small" />}
            onClick={onToggleHeaderFilters}
            color="primary"
            sx={{ textTransform: 'none', fontSize: '0.8125rem' }}
          >
            Filtros
          </Button>
        </Tooltip>
      ) : (
        <GridToolbarFilterButton />
      )}
      {!hideColumnsButton && <GridToolbarColumnsButton />}
      {!hideDensityButton && <GridToolbarDensitySelector />}

      {/* Reset layout */}
      {hasCustomLayout && (
        <Tooltip title="Restablecer vista (orden, anchos y visibilidad)">
          <IconButton size="small" onClick={onResetLayout} color="default" sx={{ opacity: 0.6 }}>
            <LayersClearIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}

      {/* Row Grouping selector */}
      {enableGrouping && groupableFields && groupableFields.length > 0 && (
        <>
          <Divider orientation="vertical" flexItem />
          <FormControl size="small" sx={{ minWidth: 140 }}>
            <InputLabel sx={{ fontSize: '0.8rem' }}>Agrupar por</InputLabel>
            <Select
              value={groupByField ?? ''}
              onChange={(e) => onGroupByChange?.(e.target.value || null)}
              label="Agrupar por"
              sx={{ fontSize: '0.8rem', height: 32 }}
            >
              <MenuItem value="">
                <em>Sin agrupar</em>
              </MenuItem>
              {groupableFields.map((f) => (
                <MenuItem key={f.field} value={f.field}>
                  {f.headerName}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          {groupByField && (
            <Chip
              label={`Agrupado: ${groupableFields.find((f) => f.field === groupByField)?.headerName ?? groupByField}`}
              size="small"
              onDelete={() => onGroupByChange?.(null)}
              color="primary"
              variant="outlined"
            />
          )}
        </>
      )}

      {/* Pivot button */}
      {enablePivot && (
        <>
          <Divider orientation="vertical" flexItem />
          <Tooltip title={isPivotActive ? 'Pivot activo — click para configurar' : 'Tabla Dinamica (Pivot)'}>
            <Button
              size="small"
              startIcon={<PivotTableChartIcon fontSize="small" />}
              onClick={onOpenPivot}
              color={isPivotActive ? 'primary' : 'inherit'}
              variant={isPivotActive ? 'contained' : 'text'}
              sx={{ textTransform: 'none', fontSize: '0.8rem' }}
            >
              Pivot
            </Button>
          </Tooltip>
        </>
      )}

      {/* Spacer */}
      <Box sx={{ flex: 1 }} />

      {/* Row count */}
      {rowCount != null && (
        <Typography variant="caption" color="text.secondary" sx={{ mr: 1, fontSize: '0.75rem' }}>
          {rowCount} filas
        </Typography>
      )}

      {/* Custom actions */}
      {toolbarActions && (
        <>
          <Stack direction="row" spacing={0.5} alignItems="center">
            {toolbarActions}
          </Stack>
          <Divider orientation="vertical" flexItem />
        </>
      )}

      {/* Clipboard */}
      {enableClipboard && (
        <Tooltip title="Copiar todo (Ctrl+C)">
          <IconButton size="small" onClick={onCopyAll}>
            <ContentCopyIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}

      {/* Export CSV */}
      {showExportCsv && (
        <Tooltip title="Exportar CSV">
          <Button
            size="small"
            startIcon={<DownloadIcon fontSize="small" />}
            onClick={onExportCsv}
            sx={{ textTransform: 'none', fontSize: '0.8rem' }}
          >
            CSV
          </Button>
        </Tooltip>
      )}

      {/* Export Excel */}
      {showExportExcel && (
        <Tooltip title="Exportar Excel">
          <Button
            size="small"
            startIcon={<TableChartIcon fontSize="small" />}
            onClick={onExportExcel}
            sx={{ textTransform: 'none', fontSize: '0.8rem', color: 'success.main' }}
          >
            Excel
          </Button>
        </Tooltip>
      )}

      {/* Export JSON */}
      {showExportJson && (
        <Tooltip title="Exportar JSON (legible por IA)">
          <Button
            size="small"
            startIcon={<DataObjectIcon fontSize="small" />}
            onClick={onExportJson}
            sx={{ textTransform: 'none', fontSize: '0.8rem', color: 'warning.main' }}
          >
            JSON
          </Button>
        </Tooltip>
      )}

      {/* Export Markdown */}
      {showExportMarkdown && (
        <Tooltip title="Exportar Markdown">
          <Button
            size="small"
            startIcon={<ArticleIcon fontSize="small" />}
            onClick={onExportMarkdown}
            sx={{ textTransform: 'none', fontSize: '0.8rem', color: 'info.main' }}
          >
            MD
          </Button>
        </Tooltip>
      )}

      {/* Quick filter */}
      {!hideQuickFilter && (
        <GridToolbarQuickFilter
          debounceMs={300}
          size="small"
          sx={{
            '& .MuiInputBase-root': { fontSize: '0.85rem' },
            '& .MuiOutlinedInput-notchedOutline': { border: 'none' },
            bgcolor: 'action.hover',
            borderRadius: 1,
            px: 0.5,
          }}
        />
      )}
    </GridToolbarContainer>
  );
}
