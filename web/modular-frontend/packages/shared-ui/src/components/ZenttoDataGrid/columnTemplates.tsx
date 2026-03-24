'use client';

/**
 * columnTemplates.tsx
 *
 * Rich cell rendering templates for ZenttoDataGrid.
 * These auto-apply based on column configuration (avatarField, statusColors, etc.)
 * so users don't need to write custom renderCell functions.
 *
 * Inspired by AG Grid's rich cell renderers but built from scratch.
 */

import React from 'react';
import {
  Avatar,
  Box,
  Chip,
  LinearProgress,
  Link,
  Rating,
  Tooltip,
  Typography,
} from '@mui/material';
import type { GridRenderCellParams } from '@mui/x-data-grid';
import type { ZenttoColDef, GridRow } from './types';
import { DETAIL_ROW_KEY, TOTALS_ROW_KEY, GROUP_ROW_KEY } from './types';

// ─── Country code → emoji flag ──────────────────────────────────────────────

function countryCodeToFlag(code: string): string {
  if (!code || code.length !== 2) return '';
  const upper = code.toUpperCase();
  // Regional indicator symbols: A=0x1F1E6, B=0x1F1E7, etc.
  return String.fromCodePoint(
    ...upper.split('').map((c) => 0x1f1e6 + c.charCodeAt(0) - 65)
  );
}

// ─── Avatar + Name + Subtitle ───────────────────────────────────────────────

function renderAvatarCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const imgUrl = col.avatarField ? String(row[col.avatarField] ?? '') : '';
  const name = String(params.value ?? '');
  const subtitle = col.subtitleField ? String(row[col.subtitleField] ?? '') : '';
  const variant = col.avatarVariant ?? 'circular';

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, py: 0.5 }}>
      <Avatar
        src={imgUrl || undefined}
        variant={variant}
        sx={{
          width: 36,
          height: 36,
          fontSize: '0.8rem',
          bgcolor: imgUrl ? 'transparent' : 'primary.main',
        }}
      >
        {!imgUrl && name ? name.charAt(0).toUpperCase() : null}
      </Avatar>
      <Box sx={{ minWidth: 0 }}>
        <Typography
          variant="body2"
          fontWeight={600}
          sx={{ lineHeight: 1.3, fontSize: '0.8125rem' }}
          noWrap
        >
          {name}
        </Typography>
        {subtitle && (
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{ lineHeight: 1.2, fontSize: '0.7rem' }}
            noWrap
          >
            {subtitle}
          </Typography>
        )}
      </Box>
    </Box>
  );
}

// ─── Image/Thumbnail ────────────────────────────────────────────────────────

function renderImageCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) return null;

  const imgUrl = col.imageField
    ? String(row[col.imageField] ?? '')
    : String(params.value ?? '');
  const w = col.imageWidth ?? 40;
  const h = col.imageHeight ?? 40;

  if (!imgUrl) return null;

  return (
    <Box
      component="img"
      src={imgUrl}
      alt=""
      sx={{
        width: w,
        height: h,
        objectFit: 'cover',
        borderRadius: 1,
        border: '1px solid',
        borderColor: 'divider',
      }}
      onError={(e: any) => {
        e.target.style.display = 'none';
      }}
    />
  );
}

// ─── Status Badge/Chip ──────────────────────────────────────────────────────

function renderStatusCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const value = String(params.value ?? '');
  if (!value) return '';

  const colorMap = col.statusColors ?? {};
  const color = colorMap[value] ?? 'default';
  const variant = col.statusVariant ?? 'filled';

  // Check if it's a standard MUI color or a custom hex
  const isStandardColor = [
    'default',
    'primary',
    'secondary',
    'error',
    'info',
    'success',
    'warning',
  ].includes(color);

  return (
    <Chip
      label={value}
      size="small"
      variant={variant}
      color={isStandardColor ? (color as any) : 'default'}
      sx={{
        fontWeight: 600,
        fontSize: '0.7rem',
        height: 24,
        ...(isStandardColor
          ? {}
          : {
              bgcolor: variant === 'filled' ? color : 'transparent',
              color: variant === 'filled' ? '#fff' : color,
              borderColor: color,
            }),
      }}
    />
  );
}

// ─── Country Flag + Name ────────────────────────────────────────────────────

function renderFlagCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const code = col.flagField
    ? String(row[col.flagField] ?? '')
    : String(params.value ?? '');
  const displayName = String(params.value ?? code);
  const flag = countryCodeToFlag(code);

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      {flag && (
        <Tooltip title={code.toUpperCase()}>
          <Typography sx={{ fontSize: '1.2rem', lineHeight: 1 }}>{flag}</Typography>
        </Tooltip>
      )}
      <Typography variant="body2" sx={{ fontSize: '0.8125rem' }}>
        {displayName}
      </Typography>
    </Box>
  );
}

// ─── Progress Bar ───────────────────────────────────────────────────────────

function renderProgressCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const value = Number(params.value ?? 0);
  const max = col.progressMax ?? 100;
  const pct = Math.min(100, Math.max(0, (value / max) * 100));
  const color = col.progressColor ?? 'primary';

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, width: '100%' }}>
      <LinearProgress
        variant="determinate"
        value={pct}
        color={color}
        sx={{ flex: 1, height: 6, borderRadius: 3 }}
      />
      <Typography variant="caption" color="text.secondary" sx={{ minWidth: 32 }}>
        {Math.round(pct)}%
      </Typography>
    </Box>
  );
}

// ─── Rating Stars ───────────────────────────────────────────────────────────

function renderRatingCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const value = Number(params.value ?? 0);
  const max = col.ratingMax ?? 5;

  return <Rating value={value} max={max} readOnly size="small" />;
}

// ─── Link ───────────────────────────────────────────────────────────────────

function renderLinkCell(
  params: GridRenderCellParams,
  col: ZenttoColDef
): React.ReactNode {
  const row = params.row as GridRow;
  if (row[DETAIL_ROW_KEY] || row[TOTALS_ROW_KEY] || row[GROUP_ROW_KEY]) {
    return params.value ?? '';
  }

  const url = col.linkField ? String(row[col.linkField] ?? '') : String(params.value ?? '');
  const display = String(params.value ?? url);
  const target = col.linkTarget ?? '_blank';

  if (!url) return display;

  return (
    <Link
      href={url}
      target={target}
      rel="noopener noreferrer"
      sx={{ fontSize: '0.8125rem', textDecoration: 'none', '&:hover': { textDecoration: 'underline' } }}
      onClick={(e: React.MouseEvent) => e.stopPropagation()}
    >
      {display}
    </Link>
  );
}

// ─── Apply Column Templates ─────────────────────────────────────────────────

/**
 * Processes columns and auto-applies renderCell for columns that have
 * template configurations (avatarField, statusColors, imageField, etc.)
 *
 * Only applies if the column doesn't already have a custom renderCell.
 */
export function applyColumnTemplates(columns: ZenttoColDef[]): ZenttoColDef[] {
  return columns.map((col) => {
    // Skip if column already has a custom renderCell
    if (col.renderCell) return col;

    // Avatar template
    if (col.avatarField || col.subtitleField) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderAvatarCell(params, col),
        // Ensure adequate row height for avatar content
        minWidth: col.minWidth ?? 160,
      };
    }

    // Image/thumbnail template
    if (col.imageField || (col.imageWidth && col.imageHeight)) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderImageCell(params, col),
      };
    }

    // Status badge template
    if (col.statusColors) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderStatusCell(params, col),
      };
    }

    // Country flag template
    if (col.flagField != null) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderFlagCell(params, col),
      };
    }

    // Progress bar template
    if (col.progressMax != null || col.progressColor != null) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderProgressCell(params, col),
      };
    }

    // Rating stars template
    if (col.ratingMax != null) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderRatingCell(params, col),
      };
    }

    // Link template
    if (col.linkField != null || col.linkTarget != null) {
      return {
        ...col,
        renderCell: (params: GridRenderCellParams) => renderLinkCell(params, col),
      };
    }

    return col;
  });
}
