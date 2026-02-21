'use client';

import React from 'react';
import {
    Box,
    TextField,
    InputAdornment,
    Breadcrumbs,
    Typography,
    Chip,
    Avatar,
    IconButton,
} from '@mui/material';
import dynamic from 'next/dynamic';

const SearchIcon = dynamic(() => import('@mui/icons-material/Search'), { ssr: false });
const HomeIcon = dynamic(() => import('@mui/icons-material/Home'), { ssr: false });
const WifiIcon = dynamic(() => import('@mui/icons-material/Wifi'), { ssr: false });
const MenuIcon = dynamic(() => import('@mui/icons-material/Menu'), { ssr: false });

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
    return (
        <Box sx={{ 
            display: 'flex', 
            flexDirection: 'column',
            borderBottom: '1px solid #e0e0e0',
            bgcolor: '#fff',
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
                        <Typography color="text.primary" fontWeight="medium">
                            {cajaName}
                        </Typography>
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
                            bgcolor: '#f5f5f5',
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

                {/* Info de Usuario y Estado */}
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <WifiIcon color="success" fontSize="small" />
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Avatar 
                            sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}
                            src={userAvatar}
                        >
                            {userName.charAt(0).toUpperCase()}
                        </Avatar>
                        <Typography variant="body2" fontWeight="medium">
                            {userName}
                        </Typography>
                    </Box>
                    <IconButton size="small">
                        <MenuIcon />
                    </IconButton>
                </Box>
            </Box>

            {/* Chips de Categorías */}
            <Box sx={{ 
                display: 'flex', 
                gap: 1, 
                p: 1.5,
                pt: 0,
                overflowX: 'auto',
                '&::-webkit-scrollbar': {
                    height: 4,
                },
                '&::-webkit-scrollbar-thumb': {
                    backgroundColor: '#ccc',
                    borderRadius: 2,
                },
            }}>
                <Chip
                    label="Todo"
                    onClick={() => onCategorySelect(null)}
                    color={selectedCategory === null ? 'primary' : 'default'}
                    variant={selectedCategory === null ? 'filled' : 'outlined'}
                    sx={{ 
                        minWidth: 80,
                        '&.MuiChip-colorPrimary': {
                            bgcolor: '#e3f2fd',
                            color: '#1976d2',
                        }
                    }}
                />
                {categories.map((category) => (
                    <Chip
                        key={category.id}
                        label={category.nombre}
                        onClick={() => onCategorySelect(category.id)}
                        color={selectedCategory === category.id ? 'primary' : 'default'}
                        variant={selectedCategory === category.id ? 'filled' : 'outlined'}
                        sx={{ 
                            minWidth: 80,
                            '&.MuiChip-colorPrimary': {
                                bgcolor: '#e3f2fd',
                                color: '#1976d2',
                            }
                        }}
                    />
                ))}
            </Box>
        </Box>
    );
}
