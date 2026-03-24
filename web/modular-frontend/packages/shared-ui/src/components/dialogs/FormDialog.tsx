'use client';

import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  CircularProgress,
  IconButton,
  Typography,
  Box,
  Divider,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import SaveIcon from '@mui/icons-material/Save';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';

export interface FormDialogProps {
  /** Controls visibility */
  open: boolean;
  /** Called on close (cancel, X, backdrop) */
  onClose: () => void;
  /** Called when save/submit is clicked. Can be async. */
  onSave?: () => void | Promise<void>;
  /** Dialog title */
  title: string;
  /** Subtitle below title (optional) */
  subtitle?: string;
  /** Form content (children) */
  children: React.ReactNode;
  /** Save button label. Default: 'Guardar' */
  saveLabel?: string;
  /** Cancel button label. Default: 'Cancelar' */
  cancelLabel?: string;
  /** True while saving (disables buttons, shows spinner) */
  loading?: boolean;
  /** Mode: 'create' shows + icon, 'edit' shows pencil icon. Default: 'create' */
  mode?: 'create' | 'edit' | 'view';
  /** Max width. Default: 'sm' */
  maxWidth?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  /** Full screen on mobile. Default: true */
  fullScreenMobile?: boolean;
  /** Extra actions to show alongside save/cancel */
  extraActions?: React.ReactNode;
  /** Hide the save button (view-only mode) */
  hideSave?: boolean;
  /** Disable save button (e.g., form not valid) */
  disableSave?: boolean;
}

export function FormDialog({
  open,
  onClose,
  onSave,
  title,
  subtitle,
  children,
  saveLabel = 'Guardar',
  cancelLabel = 'Cancelar',
  loading = false,
  mode = 'create',
  maxWidth = 'sm',
  fullScreenMobile = true,
  extraActions,
  hideSave = false,
  disableSave = false,
}: FormDialogProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const fullScreen = fullScreenMobile && isMobile;

  const handleSave = async () => {
    if (onSave) await onSave();
  };

  const ModeIcon = mode === 'edit' ? EditIcon : mode === 'create' ? AddIcon : null;

  return (
    <Dialog
      open={open}
      onClose={loading ? undefined : onClose}
      maxWidth={maxWidth}
      fullWidth
      fullScreen={fullScreen}
      PaperProps={{
        sx: {
          borderRadius: fullScreen ? 0 : 3,
          // On mobile fullscreen, add safe area padding
          ...(fullScreen ? { pt: 'env(safe-area-inset-top)' } : {}),
        },
      }}
    >
      {/* Header */}
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          pr: 6, // space for close button
          py: 2,
        }}
      >
        {ModeIcon && (
          <Box
            sx={{
              width: 36,
              height: 36,
              borderRadius: '50%',
              bgcolor: mode === 'edit' ? 'warning.light' : 'primary.light',
              color: mode === 'edit' ? 'warning.contrastText' : 'primary.contrastText',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <ModeIcon fontSize="small" />
          </Box>
        )}
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography variant="h6" fontWeight={700} sx={{ fontSize: '1.05rem', lineHeight: 1.3 }} noWrap>
            {title}
          </Typography>
          {subtitle && (
            <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.75rem' }}>
              {subtitle}
            </Typography>
          )}
        </Box>

        {/* Close button */}
        <IconButton
          onClick={onClose}
          disabled={loading}
          size="small"
          sx={{ position: 'absolute', right: 12, top: 12 }}
        >
          <CloseIcon fontSize="small" />
        </IconButton>
      </DialogTitle>

      <Divider />

      {/* Content */}
      <DialogContent
        sx={{
          pt: 2.5,
          pb: 2,
          // Ensure form fields have proper spacing
          '& .MuiTextField-root, & .MuiFormControl-root': {
            mb: 0,
          },
        }}
      >
        {children}
      </DialogContent>

      {/* Actions */}
      {(mode !== 'view' || extraActions) && (
        <>
          <Divider />
          <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
            {extraActions && <Box sx={{ mr: 'auto' }}>{extraActions}</Box>}
            <Button
              onClick={onClose}
              disabled={loading}
              variant="outlined"
              color="inherit"
              sx={{ borderRadius: 2, minWidth: 90 }}
            >
              {cancelLabel}
            </Button>
            {!hideSave && (
              <Button
                onClick={handleSave}
                disabled={loading || disableSave}
                variant="contained"
                color={mode === 'edit' ? 'warning' : 'primary'}
                sx={{ borderRadius: 2, minWidth: 100 }}
                startIcon={
                  loading ? (
                    <CircularProgress size={16} color="inherit" />
                  ) : (
                    <SaveIcon fontSize="small" />
                  )
                }
              >
                {loading ? 'Guardando...' : saveLabel}
              </Button>
            )}
          </DialogActions>
        </>
      )}
    </Dialog>
  );
}
