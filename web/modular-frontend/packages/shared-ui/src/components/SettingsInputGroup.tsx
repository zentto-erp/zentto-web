'use client';
import React from 'react';
import { Box } from '@mui/material';

export default function SettingsInputGroup({ children }: { children: React.ReactNode }) {
    return (
        <Box sx={{
            display: 'flex',
            flexDirection: 'column',
            gap: 2,
            mt: 1,
            // Indentación ligera y línea guía para agrupar visualmente los hijos (Inputs)
            pl: 2,
            borderLeft: '2px solid #E5E7EB',
            '& .MuiInputBase-root': {
                bgcolor: 'transparent' // Inputs en Settings típicamente no tienen fondo blanco fuerte sobre fondo blanco de la pagina Odoo
            }
        }}>
            {children}
        </Box>
    );
}
