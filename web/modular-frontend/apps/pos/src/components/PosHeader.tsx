'use client';

import React, { useState } from 'react';
import {
    Box,
    TextField,
    InputAdornment,
    Breadcrumbs,
    Typography,
    Chip,
    IconButton,
    Button,
    useTheme,
    useMediaQuery,
    Tooltip,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { usePrinterStatus } from '../hooks';
import { usePosStore } from '@datqbox/shared-api';
import { LocalizacionModal } from '@datqbox/shared-ui';

const SearchIcon = dynamic(() => import('@mui/icons-material/Search'), { ssr: false });
const HomeIcon = dynamic(() => import('@mui/icons-material/Home'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const ChevronLeftIcon = dynamic(() => import('@mui/icons-material/ChevronLeft'), { ssr: false });
const ChevronRightIcon = dynamic(() => import('@mui/icons-material/ChevronRight'), { ssr: false });

interface Category {
    id: string;
    nombre: string;
    icono?: string;
}

interface PosHeaderProps {
    searchTerm: string;
    onSearchChange: (value: string) => void;
    categories: Category[];
    selectedCategory: string | null;
    onCategorySelect: (categoryId: string | null) => void;
    cajaName?: string;
    userName?: string;
    userAvatar?: string;
}

export function PosHeader({
    searchTerm,
    onSearchChange,
    categories,
    selectedCategory,
    onCategorySelect,
    cajaName = 'Caja Principal',
    userName = 'Usuario',
    userAvatar,
}: PosHeaderProps) {
    const [categoriaPage, setCategoriaPage] = useState(0);
    const allCategories = [{ id: null, nombre: 'Todo' }, ...categories];
    const theme = useTheme();
    const isDesktop = useMediaQuery(theme.breakpoints.up('md'));
    const itemsPerPage = isDesktop ? 6 : 3;
    const isDark = theme.palette.mode === 'dark';

    // Hook para monitorear el Estatus de Impresora Local en Background
    const { data: printerStatus, isError, isFetching } = usePrinterStatus("PNP", "EMULADOR", "emulador");

    // UI Global States
    const [settingsOpen, setSettingsOpen] = useState(false);
    const { localizacion, setLocalizacion } = usePosStore();

    return (
        <Box sx={{
            display: 'flex',
            flexDirection: 'column',
            borderBottom: '1px solid',
            borderColor: 'divider',
            bgcolor: 'background.paper',
        }}>
            {/* Barra Superior */}
            <Box sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                p: 1.5,
                gap: 2,
            }}>
                {/* Breadcrumb */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <HomeIcon color="action" />
                    <Breadcrumbs separator="›" aria-label="breadcrumb">
                        <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                            <Typography component="div" color="text.primary" fontWeight="medium" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                {cajaName}
                                {printerStatus && (
                                    <Tooltip title={printerStatus.message || "Estado de la impresora"}>
                                        <Chip
                                            icon={<PrintIcon style={{ fontSize: 14 }} />}
                                            label={printerStatus.success ? "Fiscal OK" : "Error Fiscal"}
                                            size="small"
                                            color={printerStatus.success ? "success" : "error"}
                                            variant={printerStatus.success ? "outlined" : "filled"}
                                            sx={{ height: 20, fontSize: '0.65rem' }}
                                        />
                                    </Tooltip>
                                )}
                                <IconButton size="small" onClick={() => setSettingsOpen(true)}>
                                    <SettingsIcon fontSize="small" />
                                </IconButton>
                            </Typography>
                        </Box>
                        {selectedCategory && (
                            <Typography color="text.primary">
                                {categories.find(c => c.id === selectedCategory)?.nombre}
                            </Typography>
                        )}
                    </Breadcrumbs>
                </Box>

                {/* Barra de Búsqueda */}
                <TextField
                    placeholder="Buscar producto..."
                    value={searchTerm}
                    onChange={(e) => onSearchChange(e.target.value)}
                    size="small"
                    sx={{
                        maxWidth: 300,
                        '& .MuiOutlinedInput-root': {
                            borderRadius: 2,
                            bgcolor: 'action.hover',
                        }
                    }}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <SearchIcon fontSize="small" />
                            </InputAdornment>
                        ),
                    }}
                />

            </Box>

            {/* Paginación de Categorías estilo Tablero Clásico (Odoo) */}
            <Box sx={{ display: 'flex', alignItems: 'stretch', height: 55, px: 1.5, pb: 1.5 }}>
                {/* Botón Izquierda */}
                <Button
                    variant="outlined"
                    disabled={categoriaPage === 0}
                    onClick={() => setCategoriaPage(Math.max(0, categoriaPage - 1))}
                    sx={{ minWidth: 40, width: 40, p: 0, borderRadius: 0, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}
                >
                    <ChevronLeftIcon />
                </Button>

                {/* Botones de Categorías Visibles (Dinámico: 6 o 3) */}
                <Box sx={{ flexGrow: 1, display: 'flex', overflow: 'hidden' }}>
                    {allCategories.slice(categoriaPage * itemsPerPage, (categoriaPage + 1) * itemsPerPage).map((cat) => {
                        const isActive = selectedCategory === cat.id;
                        const pastelColors = isDark
                            ? ['#2b3345', '#2f3b34', '#3a2f38', '#3a372a', '#2a3a44', '#372d40']
                            : ['#F5F5F5', '#CEEAD6', '#FCE8E6', '#FEF7E0', '#E4F7FB', '#F3E5F5'];
                        const colorIndex = allCategories.indexOf(cat) % pastelColors.length;
                        const bgColor = pastelColors[colorIndex];

                        return (
                            <Button
                                key={cat.id || 'todo'}
                                disableElevation
                                variant="contained"
                                onClick={() => onCategorySelect(cat.id)}
                                sx={{
                                    flex: 1,
                                    height: '100%',
                                    borderRadius: 0,
                                    fontWeight: isActive ? 'bold' : 'normal',
                                    color: 'text.primary',
                                    bgcolor: isActive ? 'background.paper' : bgColor,
                                    borderTop: '1px solid',
                                    borderBottom: '1px solid',
                                    borderRight: '1px solid',
                                    borderColor: 'divider',
                                    borderLeft: 0,
                                    textTransform: 'capitalize',
                                    boxShadow: 'none',
                                    px: 1,
                                    '&:hover': { bgcolor: isActive ? 'background.paper' : 'action.hover' },
                                    whiteSpace: 'nowrap',
                                    overflow: 'hidden',
                                    textOverflow: 'ellipsis',
                                    display: 'block'
                                }}
                            >
                                {cat.nombre}
                            </Button>
                        );
                    })}
                </Box>

                {/* Botón Derecha */}
                <Button
                    variant="outlined"
                    disabled={(categoriaPage + 1) * itemsPerPage >= allCategories.length}
                    onClick={() => setCategoriaPage(categoriaPage + 1)}
                    sx={{ minWidth: 40, width: 40, p: 0, borderRadius: 0, border: '1px solid', borderColor: 'divider', bgcolor: 'background.paper' }}
                >
                    <ChevronRightIcon />
                </Button>
            </Box>

            {/* Modal de Configuración Fiscal & Multimoneda */}
            <LocalizacionModal
                open={settingsOpen}
                onClose={() => setSettingsOpen(false)}
                currentConfig={localizacion}
                onSave={(newLoc) => setLocalizacion(newLoc)}
            />
        </Box>
    );
}
