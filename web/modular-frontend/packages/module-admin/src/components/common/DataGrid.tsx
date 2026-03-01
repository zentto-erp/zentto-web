// components/common/DataGrid.tsx
/**
 * COMPONENTE GENÉRICO DE TABLA
 * Reutilizable en TODOS los módulos (Clientes, Proveedores, Artículos, etc.)
 * 
 * Features:
 * - Paginación
 * - Ordenamiento
 * - Búsqueda
 * - Acciones (Ver, Editar, Eliminar)
 * - Exportar CSV
 * - Loading state
 * - Empty state
 */

'use client';

import React, { useState } from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Box,
  Button,
  IconButton,
  Pagination,
  Toolbar,
  Typography,
  TableSortLabel,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';

export interface Column<T> {
  accessor: keyof T;
  header: string;
  type?: 'text' | 'number' | 'date' | 'currency' | 'percentage' | 'status';
  width?: string;
  sortable?: boolean;
  formatFn?: (value: unknown) => string;
}

export interface Action<T> {
  id: string;
  label: string;
  icon?: React.ReactNode;
  color?: 'primary' | 'secondary' | 'error' | 'warning' | 'success';
  onClick: (row: T) => void;
}

interface DataGridProps<T> {
  columns: Column<T>[];
  data: T[];
  totalRecords?: number;
  pageSize?: number;
  currentPage?: number;
  isLoading?: boolean;
  actions?: Action<T>[];
  onPageChange?: (page: number) => void;
  onSortChange?: (accessor: string, order: 'asc' | 'desc') => void;
  onExport?: () => void;
  title?: string;
  emptyText?: string;
}

export default function DataGrid<T extends Record<string, unknown>>({
  columns,
  data,
  totalRecords = 0,
  pageSize = 10,
  currentPage = 1,
  isLoading = false,
  actions = [],
  onPageChange,
  onSortChange,
  onExport,
  title,
  emptyText = 'No hay registros',
}: DataGridProps<T>) {
  const [sortConfig, setSortConfig] = useState<{
    accessor: string;
    order: 'asc' | 'desc';
  } | null>(null);

  const totalPages = Math.ceil(totalRecords / pageSize);

  const handleSort = (accessor: string) => {
    let order: 'asc' | 'desc' = 'asc';
    if (sortConfig?.accessor === accessor && sortConfig.order === 'asc') {
      order = 'desc';
    }
    setSortConfig({ accessor, order });
    onSortChange?.(accessor, order);
  };

  const formatCellValue = (column: Column<T>, value: unknown): string => {
    if (column.formatFn) {
      return column.formatFn(value);
    }

    switch (column.type) {
      case 'date':
        return new Date(value).toLocaleDateString('es-ES');
      case 'currency':
        return new Intl.NumberFormat('es-ES', {
          style: 'currency',
          currency: 'USD',
        }).format(value);
      case 'percentage':
        return `${(value * 100).toFixed(2)}%`;
      case 'status':
        return getStatusBadge(value);
      default:
        return String(value ?? '-');
    }
  };

  if (isLoading) {
    return (
      <Box display="flex" justifyContent="center" p={4}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Paper sx={{ width: '100%', overflow: 'hidden' }}>
      {/* Header */}
      <Toolbar
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          p: 2,
        }}
      >
        <Typography variant="h6">{title}</Typography>
        {onExport && (
          <Button
            startIcon={<DownloadIcon />}
            onClick={onExport}
            variant="outlined"
            size="small"
          >
            Exportar
          </Button>
        )}
      </Toolbar>

      {/* Table */}
      <TableContainer>
        <Table sx={{ minWidth: 650 }}>
          <TableHead>
            <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
              {columns.map((column) => (
                <TableCell
                  key={String(column.accessor)}
                  width={column.width}
                  sortDirection={
                    sortConfig?.accessor === String(column.accessor)
                      ? sortConfig.order
                      : false
                  }
                >
                  {column.sortable ? (
                    <TableSortLabel
                      active={
                        sortConfig?.accessor === String(column.accessor)
                      }
                      direction={
                        sortConfig?.accessor === String(column.accessor)
                          ? sortConfig.order
                          : 'asc'
                      }
                      onClick={() => handleSort(String(column.accessor))}
                    >
                      {column.header}
                    </TableSortLabel>
                  ) : (
                    column.header
                  )}
                </TableCell>
              ))}
              {actions.length > 0 && (
                <TableCell align="center" width="150px">
                  Acciones
                </TableCell>
              )}
            </TableRow>
          </TableHead>
          <TableBody>
            {data.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={columns.length + (actions.length > 0 ? 1 : 0)}
                  align="center"
                  sx={{ py: 3 }}
                >
                  {emptyText}
                </TableCell>
              </TableRow>
            ) : (
              data.map((row, idx) => (
                <TableRow key={idx} hover>
                  {columns.map((column) => (
                    <TableCell key={String(column.accessor)}>
                      {formatCellValue(column, row[column.accessor])}
                    </TableCell>
                  ))}
                  {actions.length > 0 && (
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                        {actions.map((action) => (
                          <IconButton
                            key={action.id}
                            size="small"
                            color={action.color || 'primary'}
                            onClick={() => action.onClick(row)}
                            title={action.label}
                          >
                            {action.icon || getDefaultIcon(action.id)}
                          </IconButton>
                        ))}
                      </Box>
                    </TableCell>
                  )}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={(_, page) => onPageChange?.(page)}
            color="primary"
          />
        </Box>
      )}
    </Paper>
  );
}

// ============================================================================
// HELPERS
// ============================================================================

function getDefaultIcon(actionId: string) {
  switch (actionId) {
    case 'view':
      return <ViewIcon />;
    case 'edit':
      return <EditIcon />;
    case 'delete':
      return <DeleteIcon />;
    default:
      return null;
  }
}

function getStatusBadge(status: string) {
  const statusMap: { [key: string]: string } = {
    activo: '✓ Activo',
    inactivo: '✗ Inactivo',
    pendiente: '⏳ Pendiente',
    completado: '✓ Completado',
    cancelado: '✗ Cancelado',
    pagado: '✓ Pagado',
    vencido: '⚠ Vencido',
  };
  return statusMap[status?.toLowerCase()] || status;
}

