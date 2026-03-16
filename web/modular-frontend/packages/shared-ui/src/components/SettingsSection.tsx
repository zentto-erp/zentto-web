'use client';
import React from 'react';
import { Box, Typography } from '@mui/material';

interface SettingsSectionProps {
    id: string;
    title: string;
    children: React.ReactNode;
}

export default function SettingsSection({ id, title, children }: SettingsSectionProps) {
    return (
        <Box id={`settings-section-${id}`} sx={{ mb: 6 }}>
            {/* Separador Gris con Título Pleno (Estilo Odoo Settings Section Header) */}
            <Box sx={{
                bgcolor: 'action.hover',
                px: 2, py: 1.5,
                mt: 2, mb: 3,
                borderBottom: '1px solid',
                borderTop: '1px solid',
                borderColor: 'divider'
            }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, color: 'text.primary' }}>
                    {title}
                </Typography>
            </Box>

            {/* Grid de 2 Columnas para alojar bloques de configuración múltiples y no perder el ancho */}
            <Box sx={{
                display: 'grid',
                gridTemplateColumns: { xs: '1fr', lg: '1fr 1fr' },
                columnGap: 6,
                rowGap: 4,
                px: 2
            }}>
                {children}
            </Box>
        </Box>
    );
}
