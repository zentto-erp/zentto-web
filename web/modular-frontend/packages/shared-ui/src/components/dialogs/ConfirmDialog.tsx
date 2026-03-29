'use client';

import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Button,
  CircularProgress,
  Box,
  Typography,
  alpha,
} from '@mui/material';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';

type DialogVariant = 'danger' | 'warning' | 'info' | 'success';

export interface ConfirmDialogProps {
  /** Controls visibility */
  open: boolean;
  /** Called when the dialog is closed (cancel or backdrop click) */
  onClose: () => void;
  /** Called when the user confirms. Can be async — shows loading spinner. */
  onConfirm: () => void | Promise<void>;
  /** Dialog title. Default: 'Confirmar accion' */
  title?: string;
  /** Description/message body */
  message?: string | React.ReactNode;
  /** Label for confirm button. Default: 'Confirmar' */
  confirmLabel?: string;
  /** Label for cancel button. Default: 'Cancelar' */
  cancelLabel?: string;
  /** Visual variant. Default: 'warning' */
  variant?: DialogVariant;
  /** True while the confirm action is in progress (disables buttons, shows spinner) */
  loading?: boolean;
  /** Max width of the dialog. Default: 'xs' */
  maxWidth?: 'xs' | 'sm' | 'md';
}

const VARIANT_CONFIG: Record<DialogVariant, { icon: React.ReactNode; color: string; btnColor: any }> = {
  danger: {
    icon: <DeleteOutlineIcon sx={{ fontSize: 40 }} />,
    color: 'error.main',
    btnColor: 'error',
  },
  warning: {
    icon: <WarningAmberIcon sx={{ fontSize: 40 }} />,
    color: 'warning.main',
    btnColor: 'warning',
  },
  info: {
    icon: <InfoOutlinedIcon sx={{ fontSize: 40 }} />,
    color: 'info.main',
    btnColor: 'info',
  },
  success: {
    icon: <CheckCircleOutlineIcon sx={{ fontSize: 40 }} />,
    color: 'success.main',
    btnColor: 'success',
  },
};

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title = 'Confirmar accion',
  message,
  confirmLabel = 'Confirmar',
  cancelLabel = 'Cancelar',
  variant = 'warning',
  loading = false,
  maxWidth = 'xs',
}: ConfirmDialogProps) {
  const config = VARIANT_CONFIG[variant];

  const handleConfirm = async () => {
    await onConfirm();
  };

  return (
    <Dialog
      open={open}
      onClose={loading ? undefined : onClose}
      maxWidth={maxWidth}
      fullWidth
      PaperProps={{ sx: { borderRadius: 3 } }}
    >
      <DialogTitle sx={{ pb: 1, pt: 3, textAlign: 'center' }}>
        {/* Icon circle */}
        <Box
          sx={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            bgcolor: (t) => alpha((t.palette as any)[config.btnColor]?.main ?? t.palette.grey[500], 0.1),
            color: config.color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            mx: 'auto',
            mb: 1.5,
          }}
        >
          {config.icon}
        </Box>
        <Typography variant="h6" fontWeight={700} sx={{ fontSize: '1.1rem' }}>
          {title}
        </Typography>
      </DialogTitle>

      {message && (
        <DialogContent sx={{ textAlign: 'center', pb: 1 }}>
          {typeof message === 'string' ? (
            <DialogContentText sx={{ fontSize: '0.9rem' }}>{message}</DialogContentText>
          ) : (
            message
          )}
        </DialogContent>
      )}

      <DialogActions sx={{ px: 3, pb: 2.5, pt: 1, gap: 1, justifyContent: 'center' }}>
        <Button
          onClick={onClose}
          disabled={loading}
          variant="outlined"
          color="inherit"
          sx={{ minWidth: 100, borderRadius: 2 }}
        >
          {cancelLabel}
        </Button>
        <Button
          onClick={handleConfirm}
          disabled={loading}
          variant="contained"
          color={config.btnColor}
          sx={{ minWidth: 100, borderRadius: 2 }}
          startIcon={loading ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          {loading ? 'Procesando...' : confirmLabel}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Convenience: DeleteDialog (pre-configured ConfirmDialog) ───────────────

export interface DeleteDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void | Promise<void>;
  /** What is being deleted. Ej: 'el empleado Juan Perez', 'este registro' */
  itemName?: string;
  loading?: boolean;
}

export function DeleteDialog({
  open,
  onClose,
  onConfirm,
  itemName = 'este registro',
  loading = false,
}: DeleteDialogProps) {
  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={onConfirm}
      title="Eliminar registro"
      message={`¿Estas seguro de que deseas eliminar ${itemName}? Esta accion no se puede deshacer.`}
      confirmLabel="Eliminar"
      variant="danger"
      loading={loading}
    />
  );
}
