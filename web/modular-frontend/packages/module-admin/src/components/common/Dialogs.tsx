// components/common/Dialogs.tsx
/**
 * DIÁLOGOS GENÉRICOS REUSABLES
 * - ConfirmDialog: Confirmación genérica
 * - DeleteDialog: Confirmación de eliminación
 * - DateRangeDialog: Selector de rango de fechas
 */

'use client';

import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Button,
  Box,
  TextField,
  FormControlLabel,
  Checkbox,
} from '@mui/material';
import { toDateOnly } from '@zentto/shared-api';
import { useTimezone } from '@zentto/shared-auth';

// ============================================================================
// CONFIRM DIALOG
// ============================================================================

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  isLoading?: boolean;
  variant?: 'default' | 'warning' | 'error';
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmText = 'Confirmar',
  cancelText = 'Cancelar',
  onConfirm,
  onCancel,
  isLoading,
  variant = 'default',
}: ConfirmDialogProps) {
  const getButtonColor = () => {
    switch (variant) {
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      default:
        return 'primary';
    }
  };

  return (
    <Dialog open={open} onClose={onCancel} maxWidth="sm" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <DialogContentText>{message}</DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel} disabled={isLoading}>
          {cancelText}
        </Button>
        <Button
          onClick={onConfirm}
          color={getButtonColor()}
          variant="contained"
          disabled={isLoading}
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ============================================================================
// DELETE DIALOG
// ============================================================================

interface DeleteDialogProps {
  open: boolean;
  itemName: string;
  onConfirm: () => void;
  onCancel: () => void;
  isLoading?: boolean;
  confirmText?: string;
}

export function DeleteDialog({
  open,
  itemName,
  onConfirm,
  onCancel,
  isLoading,
  confirmText = 'Eliminar',
}: DeleteDialogProps) {
  const [confirmed, setConfirmed] = React.useState(false);

  const handleClose = () => {
    setConfirmed(false);
    onCancel();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Eliminar Registro</DialogTitle>
      <DialogContent>
        <DialogContentText sx={{ color: 'warning.main', mb: 2 }}>
          ⚠️ Esta acción no se puede deshacer
        </DialogContentText>
        <DialogContentText>
          ¿Estás seguro que deseas eliminar: <strong>{itemName}</strong>?
        </DialogContentText>
        <FormControlLabel
          sx={{ mt: 2 }}
          control={
            <Checkbox
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
            />
          }
          label="Confirmo que deseo eliminar este registro"
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={isLoading}>
          Cancelar
        </Button>
        <Button
          onClick={onConfirm}
          color="error"
          variant="contained"
          disabled={!confirmed || isLoading}
        >
          {confirmText}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ============================================================================
// DATE RANGE DIALOG
// ============================================================================

interface DateRangeDialogProps {
  open: boolean;
  onConfirm: (from: Date, to: Date) => void;
  onCancel: () => void;
  title?: string;
  initialFrom?: Date;
  initialTo?: Date;
}

export function DateRangeDialog({
  open,
  onConfirm,
  onCancel,
  title = 'Seleccionar Período',
  initialFrom,
  initialTo,
}: DateRangeDialogProps) {
  const { timeZone } = useTimezone();
  const [from, setFrom] = React.useState<string>(
    initialFrom ? toDateOnly(initialFrom, timeZone) : ''
  );
  const [to, setTo] = React.useState<string>(
    initialTo ? toDateOnly(initialTo, timeZone) : ''
  );

  const handleConfirm = () => {
    if (from && to) {
      onConfirm(new Date(from), new Date(to));
    }
  };

  return (
    <Dialog open={open} onClose={onCancel} maxWidth="sm" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
          <TextField
            label="Desde"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
          <TextField
            label="Hasta"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel}>Cancelar</Button>
        <Button
          onClick={handleConfirm}
          variant="contained"
          disabled={!from || !to}
        >
          Confirmar
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ============================================================================
// SEARCH DIALOG / PICKER
// ============================================================================

interface SearchDialogProps<T> {
  open: boolean;
  title: string;
  items: T[];
  displayKey: keyof T;
  valueKey: keyof T;
  isLoading?: boolean;
  onSelect: (item: T) => void;
  onCancel: () => void;
  onSearch?: (query: string) => void;
}

export function SearchDialog<T extends Record<string, unknown>>({
  open,
  title,
  items,
  displayKey,
  valueKey,
  isLoading,
  onSelect,
  onCancel,
  onSearch,
}: SearchDialogProps<T>) {
  const [searchQuery, setSearchQuery] = React.useState('');

  const filtered = items.filter((item) =>
    String(item[displayKey])
      .toLowerCase()
      .includes(searchQuery.toLowerCase())
  );

  return (
    <Dialog open={open} onClose={onCancel} maxWidth="sm" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <TextField
          autoFocus
          placeholder="Buscar..."
          fullWidth
          value={searchQuery}
          onChange={(e) => {
            setSearchQuery(e.target.value);
            onSearch?.(e.target.value);
          }}
          sx={{ mt: 2, mb: 2 }}
        />
        <Box
          sx={{
            maxHeight: 300,
            overflowY: 'auto',
            border: '1px solid #ddd',
            borderRadius: 1,
          }}
        >
          {filtered.length === 0 ? (
            <Box sx={{ p: 2, textAlign: 'center', color: 'text.secondary' }}>
              No hay resultados
            </Box>
          ) : (
            filtered.map((item) => (
              <Button
                key={String(item[valueKey])}
                fullWidth
                sx={{
                  justifyContent: 'flex-start',
                  textTransform: 'none',
                  borderRadius: 0,
                  borderBottom: '1px solid #eee',
                  '&:hover': { backgroundColor: '#f5f5f5' },
                }}
                onClick={() => onSelect(item)}
              >
                {String(item[displayKey])}
              </Button>
            ))
          )}
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel}>Cerrar</Button>
      </DialogActions>
    </Dialog>
  );
}

