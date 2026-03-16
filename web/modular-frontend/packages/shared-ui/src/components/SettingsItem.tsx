'use client';
import React from 'react';
import { Box, Typography, Checkbox, IconButton, Tooltip } from '@mui/material';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import ArrowRightAltIcon from '@mui/icons-material/ArrowRightAlt';

interface SettingsItemProps {
    title: string;
    description?: string;
    checked?: boolean;
    onCheckChange?: (checked: boolean) => void;
    hasCheckbox?: boolean;
    helpText?: string;
    actionLabel?: string;
    onActionClick?: () => void;
    children?: React.ReactNode;
}

export default function SettingsItem({
    title,
    description,
    checked = false,
    onCheckChange,
    hasCheckbox = true,
    helpText,
    actionLabel,
    onActionClick,
    children
}: SettingsItemProps) {
    return (
        <Box sx={{ display: 'flex', alignItems: 'flex-start', isolation: 'isolate' }}>
            {hasCheckbox && (
                <Box sx={{ mr: 1, mt: -1 }}>
                    <Checkbox
                        checked={checked}
                        onChange={(e) => onCheckChange && onCheckChange(e.target.checked)}
                        color="primary"
                    />
                </Box>
            )}

            <Box sx={{ flexGrow: 1, pl: hasCheckbox ? 0 : 4 }}>
                {/* Fila del Titulo y Botón de Ayuda */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <Typography variant="body1" sx={{ fontWeight: 600, color: '#111827' }}>
                        {title}
                    </Typography>
                    {helpText && (
                        <Tooltip title={helpText} arrow placement="top">
                            <IconButton size="small" sx={{ p: 0.5 }}>
                                <HelpOutlineIcon sx={{ fontSize: 16, color: '#3B82F6' }} />
                            </IconButton>
                        </Tooltip>
                    )}
                </Box>

                {/* Fila de Explicación Muteada */}
                {description && (
                    <Typography variant="body2" sx={{ color: '#6B7280', mt: 0.5, lineHeight: 1.4, pr: 2 }}>
                        {description}
                    </Typography>
                )}

                {/* Fila de Enlace a Acción Rapida (ej. --> Monedas) */}
                {actionLabel && (
                    <Box
                        component="span"
                        onClick={onActionClick}
                        sx={{
                            display: 'inline-flex', alignItems: 'center', gap: 0.5,
                            color: '#3B82F6', fontWeight: 500, mt: 1,
                            cursor: 'pointer', '&:hover': { textDecoration: 'underline' }
                        }}
                    >
                        <ArrowRightAltIcon fontSize="small" />
                        <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {actionLabel}
                        </Typography>
                    </Box>
                )}

                {/* Elementos Anidados: Se muestran dentro del ajuste si tiene inputs complejos */}
                {/* Solo se muestran si no hay checkbox, o si el checkbox está activado */}
                {(!hasCheckbox || checked) && children && (
                    <Box sx={{ mt: 2 }}>
                        {children}
                    </Box>
                )}
            </Box>
        </Box>
    );
}
