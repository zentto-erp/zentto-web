'use client';
import React, { useState } from 'react';
import { Box, Typography, Button, Stack } from '@mui/material';

export interface SettingsCategory {
    id: string;
    label: string;
    icon?: React.ReactNode;
}

interface SettingsLayoutProps {
    categories: SettingsCategory[];
    onSave?: () => void;
    onDiscard?: () => void;
    isSaving?: boolean;
    hasChanges?: boolean;
    children: React.ReactNode;
}

export default function SettingsLayout({
    categories,
    onSave,
    onDiscard,
    isSaving,
    hasChanges,
    children
}: SettingsLayoutProps) {
    const [activeCategory, setActiveCategory] = useState<string>(categories[0]?.id || '');

    const handleScrollTo = (id: string) => {
        setActiveCategory(id);
        const element = document.getElementById(`settings-section-${id}`);
        if (element) {
            // Ajuste de offset por los headers fijos
            const y = element.getBoundingClientRect().top + window.scrollY - 140;
            window.scrollTo({ top: y, behavior: 'smooth' });
        }
    };

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: 'background.default' }}>
            {/* Barra superior de Acciones (Guardar/Descartar Fijada) */}
            <Box sx={{
                position: 'sticky', top: 0, zIndex: 1100, bgcolor: '#ffffff',
                borderBottom: '1px solid #E5E7EB', px: 3, py: 1.5,
                display: 'flex', alignItems: 'center', gap: 2,
                boxShadow: '0 1px 2px rgba(0,0,0,0.03)'
            }}>
                <Button
                    variant="contained"
                    color="primary"
                    onClick={onSave}
                    disabled={!hasChanges || isSaving}
                    disableElevation
                >
                    {isSaving ? 'Guardando...' : 'Guardar'}
                </Button>
                <Button
                    variant="outlined"
                    onClick={onDiscard}
                    disabled={!hasChanges || isSaving}
                    sx={{ borderColor: '#D1D5DB', color: '#374151', '&:hover': { bgcolor: '#F3F4F6', borderColor: '#9CA3AF' } }}
                >
                    Descartar
                </Button>
            </Box>

            {/* Contenido Dividido (Sidebar + Scroll Area) */}
            <Box sx={{ display: 'flex', flexGrow: 1, minHeight: 0, overflow: 'hidden' }}>
                {/* Sidebar Lateral Fijo tipo Ancla */}
                <Box sx={{
                    width: 250, flexShrink: 0, bgcolor: '#F8F9FA', borderRight: '1px solid #E5E7EB',
                    overflowY: 'auto', py: 2
                }}>
                    <Stack spacing={0.5} sx={{ px: 1 }}>
                        {categories.map((cat) => (
                            <Box
                                key={cat.id}
                                onClick={() => handleScrollTo(cat.id)}
                                sx={{
                                    display: 'flex', alignItems: 'center', gap: 1.5,
                                    px: 2, py: 1.25, borderRadius: 1.5, cursor: 'pointer',
                                    bgcolor: activeCategory === cat.id ? '#DEE2E6' : 'transparent',
                                    color: activeCategory === cat.id ? '#111827' : '#4B5563',
                                    fontWeight: activeCategory === cat.id ? 600 : 500,
                                    fontSize: '0.9rem',
                                    '&:hover': { bgcolor: activeCategory === cat.id ? '#DEE2E6' : '#F3F4F6' },
                                    transition: 'all 0.1s ease'
                                }}
                            >
                                {cat.icon && <Box sx={{ display: 'flex', color: activeCategory === cat.id ? 'primary.main' : 'inherit' }}>{cat.icon}</Box>}
                                {cat.label}
                            </Box>
                        ))}
                    </Stack>
                </Box>

                {/* Área Derecha de Contenido Desplazable */}
                <Box sx={{ flexGrow: 1, overflowY: 'auto', p: { xs: 2, md: 4 }, bgcolor: '#FFFFFF' }}>
                    <Box sx={{ maxWidth: 1000, mx: 'auto' }}>
                        {children}
                    </Box>
                </Box>
            </Box>
        </Box>
    );
}
