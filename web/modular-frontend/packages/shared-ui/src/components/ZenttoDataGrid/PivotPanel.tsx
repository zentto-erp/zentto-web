'use client';

import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Typography,
  Box,
  Chip,
  Alert,
} from '@mui/material';
import PivotTableChartIcon from '@mui/icons-material/PivotTableChart';
import type { ZenttoColDef, PivotConfig, AggregationType } from './types';

interface PivotPanelProps {
  open: boolean;
  onClose: () => void;
  columns: ZenttoColDef[];
  currentConfig?: PivotConfig | null;
  onApply: (config: PivotConfig) => void;
  onClear: () => void;
}

const AGG_LABELS: Record<AggregationType, string> = {
  sum: 'Suma',
  avg: 'Promedio',
  count: 'Conteo',
  min: 'Minimo',
  max: 'Maximo',
};

export function PivotPanel({
  open,
  onClose,
  columns,
  currentConfig,
  onApply,
  onClear,
}: PivotPanelProps) {
  const [rowField, setRowField] = useState('');
  const [columnField, setColumnField] = useState('');
  const [valueField, setValueField] = useState('');
  const [aggregation, setAggregation] = useState<AggregationType>('sum');

  // Sync state when dialog opens with existing config
  useEffect(() => {
    if (open) {
      setRowField(currentConfig?.rowField ?? '');
      setColumnField(currentConfig?.columnField ?? '');
      setValueField(currentConfig?.valueField ?? '');
      setAggregation(currentConfig?.aggregation ?? 'sum');
    }
  }, [open, currentConfig]);

  const availableFields = columns.filter(
    (c) =>
      !c.field.startsWith('__') &&
      c.field !== 'actions' &&
      c.type !== 'actions'
  );

  const numericFields = availableFields.filter(
    (c) => c.type === 'number' || c.currency
  );

  const canApply = rowField && columnField && valueField;

  const handleApply = () => {
    if (!canApply) return;
    const rowCol = columns.find((c) => c.field === rowField);
    onApply({
      rowField,
      columnField,
      valueField,
      aggregation,
      rowFieldHeader: rowCol?.headerName ?? rowField,
    });
    onClose();
  };

  const handleClear = () => {
    onClear();
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <PivotTableChartIcon color="primary" />
        Tabla Dinamica (Pivot)
      </DialogTitle>

      <DialogContent>
        <Alert severity="info" sx={{ mb: 2, mt: 1 }}>
          Arrastra conceptualmente: elige que campo va en filas, cual genera columnas, y
          que valor se agrega en cada celda.
        </Alert>

        <Stack spacing={3}>
          {/* Row field (Y axis) */}
          <FormControl fullWidth size="small">
            <InputLabel>Filas (eje Y)</InputLabel>
            <Select
              value={rowField}
              onChange={(e) => setRowField(e.target.value)}
              label="Filas (eje Y)"
            >
              {availableFields.map((c) => (
                <MenuItem key={c.field} value={c.field}>
                  {c.headerName ?? c.field}
                </MenuItem>
              ))}
            </Select>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5 }}>
              Cada valor unico de este campo sera una fila en la tabla pivot
            </Typography>
          </FormControl>

          {/* Column field (X axis) */}
          <FormControl fullWidth size="small">
            <InputLabel>Columnas (eje X)</InputLabel>
            <Select
              value={columnField}
              onChange={(e) => setColumnField(e.target.value)}
              label="Columnas (eje X)"
            >
              {availableFields
                .filter((c) => c.field !== rowField)
                .map((c) => (
                  <MenuItem key={c.field} value={c.field}>
                    {c.headerName ?? c.field}
                  </MenuItem>
                ))}
            </Select>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5 }}>
              Cada valor unico de este campo se convierte en una columna
            </Typography>
          </FormControl>

          {/* Value field */}
          <FormControl fullWidth size="small">
            <InputLabel>Valores</InputLabel>
            <Select
              value={valueField}
              onChange={(e) => setValueField(e.target.value)}
              label="Valores"
            >
              {(numericFields.length > 0 ? numericFields : availableFields).map(
                (c) => (
                  <MenuItem key={c.field} value={c.field}>
                    {c.headerName ?? c.field}
                    {c.currency && (
                      <Chip label="$" size="small" sx={{ ml: 1 }} />
                    )}
                    {c.type === 'number' && !c.currency && (
                      <Chip label="#" size="small" sx={{ ml: 1 }} />
                    )}
                  </MenuItem>
                )
              )}
            </Select>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5 }}>
              El valor numerico que se agrega en cada celda del pivot
            </Typography>
          </FormControl>

          {/* Aggregation */}
          <FormControl fullWidth size="small">
            <InputLabel>Agregacion</InputLabel>
            <Select
              value={aggregation}
              onChange={(e) => setAggregation(e.target.value as AggregationType)}
              label="Agregacion"
            >
              {(Object.entries(AGG_LABELS) as [AggregationType, string][]).map(
                ([key, label]) => (
                  <MenuItem key={key} value={key}>
                    {label}
                  </MenuItem>
                )
              )}
            </Select>
          </FormControl>

          {/* Preview of what will happen */}
          {canApply && (
            <Box
              sx={{
                p: 1.5,
                bgcolor: 'action.hover',
                borderRadius: 1,
                border: '1px dashed',
                borderColor: 'divider',
              }}
            >
              <Typography variant="caption" color="text.secondary" fontWeight={600}>
                Vista previa de la estructura:
              </Typography>
              <Box component="div" sx={{ mt: 0.5, display: 'flex', alignItems: 'center', gap: 0.5, typography: 'body2' }}>
                Filas: valores unicos de{' '}
                <Chip label={columns.find((c) => c.field === rowField)?.headerName ?? rowField} size="small" color="primary" />
              </Box>
              <Box component="div" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, typography: 'body2' }}>
                Columnas: valores unicos de{' '}
                <Chip label={columns.find((c) => c.field === columnField)?.headerName ?? columnField} size="small" color="secondary" />
              </Box>
              <Box component="div" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, typography: 'body2' }}>
                Celdas: {AGG_LABELS[aggregation]} de{' '}
                <Chip label={columns.find((c) => c.field === valueField)?.headerName ?? valueField} size="small" color="success" />
              </Box>
            </Box>
          )}
        </Stack>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        {currentConfig && (
          <Button onClick={handleClear} color="error" sx={{ mr: 'auto' }}>
            Quitar Pivot
          </Button>
        )}
        <Button onClick={onClose}>Cancelar</Button>
        <Button
          onClick={handleApply}
          variant="contained"
          disabled={!canApply}
          startIcon={<PivotTableChartIcon />}
        >
          Aplicar Pivot
        </Button>
      </DialogActions>
    </Dialog>
  );
}
