'use client';

import React from 'react';
import {
  GridToolbarContainer,
  GridToolbarFilterButton,
  GridToolbarColumnsButton,
  GridToolbarQuickFilter,
} from '@mui/x-data-grid';
import { Box, Button, Divider, Typography, Tooltip, Stack } from '@mui/material';
import DownloadIcon from '@mui/icons-material/Download';
import TableChartIcon from '@mui/icons-material/TableChart';
import DataObjectIcon from '@mui/icons-material/DataObject';
import ArticleIcon from '@mui/icons-material/Article';

interface ZenttoToolbarProps {
  title?: string;
  toolbarActions?: React.ReactNode;
  onExportCsv?: () => void;
  onExportExcel?: () => void;
  onExportJson?: () => void;
  onExportMarkdown?: () => void;
  showExportCsv?: boolean;
  showExportExcel?: boolean;
  showExportJson?: boolean;
  showExportMarkdown?: boolean;
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
      }}
    >
      {/* Título opcional */}
      {title && (
        <>
          <Typography variant="subtitle2" fontWeight={600} color="text.primary" sx={{ mr: 1 }}>
            {title}
          </Typography>
          <Divider orientation="vertical" flexItem />
        </>
      )}

      {/* Herramientas nativas MUI */}
      <GridToolbarFilterButton />
      <GridToolbarColumnsButton />

      {/* Spacer */}
      <Box sx={{ flex: 1 }} />

      {/* Acciones custom del usuario */}
      {toolbarActions && (
        <>
          <Stack direction="row" spacing={0.5} alignItems="center">
            {toolbarActions}
          </Stack>
          <Divider orientation="vertical" flexItem />
        </>
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
        <Tooltip title="Exportar Markdown (tabla renderizable)">
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

      {/* Búsqueda rápida */}
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
    </GridToolbarContainer>
  );
}
