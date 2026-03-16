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
            const scrollContainer = document.getElementById('settings-scroll-container');
            if (scrollContainer) {
                const y = element.offsetTop - 100; // offset for the sticky header inside the layout
                scrollContainer.scrollTo({ top: y, behavior: 'smooth' });
            } else {
                element.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }
    };

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: 'background.default' }}>
            {/* Barra superior de Acciones (Guardar/Descartar Fijada) */}
            <Box sx={{
                position: 'sticky', top: 0, zIndex: 1100, bgcolor: 'background.paper',
                borderBottom: '1px solid', borderColor: 'divider', px: 3, py: 1.5,
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
                    sx={{ borderColor: 'divider', color: 'text.primary', '&:hover': { bgcolor: 'action.hover', borderColor: 'text.secondary' } }}
                >
                    Descartar
                </Button>
            </Box>

            {/* Contenido Dividido (Sidebar + Scroll Area) */}
            <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, flexGrow: 1, minHeight: 0 }}>
                {/* Sidebar Lateral Fijo tipo Ancla */}
                <Box sx={{
                    width: { xs: '100%', md: 250 },
                    flexShrink: 0,
                    bgcolor: 'background.default',
                    borderRight: { xs: 'none', md: '1px solid' },
                    borderBottom: { xs: '1px solid', md: 'none' },
                    borderColor: 'divider',
                    overflowY: { xs: 'hidden', md: 'auto' },
                    overflowX: { xs: 'auto', md: 'hidden' },
                    py: { xs: 1, md: 2 }
                }}>
                    <Stack direction={{ xs: 'row', md: 'column' }} spacing={0.5} sx={{ px: 1 }}>
                        {categories.map((cat) => (
                            <Box
                                key={cat.id}
                                onClick={() => handleScrollTo(cat.id)}
                                sx={{
                                    display: 'flex', alignItems: 'center', gap: 1.5,
                                    px: 2, py: 1.25, borderRadius: 1.5, cursor: 'pointer',
                                    whiteSpace: 'nowrap',
                                    bgcolor: activeCategory === cat.id ? 'action.selected' : 'transparent',
                                    color: activeCategory === cat.id ? 'text.primary' : 'text.secondary',
                                    fontWeight: activeCategory === cat.id ? 600 : 500,
                                    fontSize: '0.9rem',
                                    '&:hover': { bgcolor: activeCategory === cat.id ? 'action.selected' : 'action.hover' },
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
                <Box id="settings-scroll-container" sx={{ flexGrow: 1, overflowY: 'auto', p: { xs: 2, md: 4 }, bgcolor: 'background.paper' }}>
                    <Box sx={{ maxWidth: 1000, mx: 'auto' }}>
                        {children}
                    </Box>
                </Box>
            </Box>
        </Box>
    );
}
