'use client';

import React from 'react';
import {
    Box,
    Button,
    Paper,
} from '@mui/material';
import dynamic from 'next/dynamic';

const BackspaceIcon = dynamic(() => import('@mui/icons-material/Backspace'), { ssr: false });

interface PosNumpadProps {
    onNumberPress: (num: string) => void;
    onBackspace: () => void;
    onClear: () => void;
    onQuantity: () => void;
    onDiscount: () => void;
    onPrice: () => void;
    activeMode?: 'qty' | 'discount' | 'price';
}

export function PosNumpad({
    onNumberPress,
    onBackspace,
    onClear,
    onQuantity,
    onDiscount,
    onPrice,
    activeMode = 'qty',
}: PosNumpadProps) {
    const numbers = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '+/-', '0', '.'];

    const getModeButtonStyle = (mode: 'qty' | 'discount' | 'price') => {
        const isActive = activeMode === mode;
        return {
            bgcolor: isActive ? '#e3f2fd' : '#fff',
            color: isActive ? '#1976d2' : 'text.primary',
            borderLeft: '1px solid #e0e0e0',
            borderBottom: '1px solid #e0e0e0',
            fontWeight: isActive ? 'bold' : 'normal',
            fontSize: { xs: '0.8rem', md: '1rem' },
            minHeight: { xs: 40, md: 'auto' },
            '&:hover': {
                bgcolor: isActive ? '#bbdefb' : '#f5f5f5',
            },
        };
    };

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            {/* Grid de Números y Modos */}
            <Box sx={{ display: 'flex', flexGrow: 1 }}>
                {/* Números */}
                <Box sx={{ flex: 3, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)' }}>
                    {numbers.map((num) => (
                        <Button
                            key={num}
                            onClick={() => onNumberPress(num)}
                            sx={{
                                borderRadius: 0,
                                borderRight: '1px solid #e0e0e0',
                                borderBottom: '1px solid #e0e0e0',
                                fontSize: { xs: '1rem', md: '1.25rem' },
                                fontWeight: 'medium',
                                bgcolor: '#fff',
                                color: 'text.primary',
                                minHeight: { xs: 40, md: 56 },
                                '&:hover': {
                                    bgcolor: '#f5f5f5',
                                },
                            }}
                        >
                            {num}
                        </Button>
                    ))}
                </Box>

                {/* Columna de Modos */}
                <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                    <Button
                        onClick={onQuantity}
                        sx={getModeButtonStyle('qty')}
                    >
                        Cant
                    </Button>
                    <Button
                        onClick={onDiscount}
                        sx={getModeButtonStyle('discount')}
                    >
                        % Desc
                    </Button>
                    <Button
                        onClick={onPrice}
                        sx={getModeButtonStyle('price')}
                    >
                        Precio
                    </Button>
                    <Button
                        onClick={onBackspace}
                        sx={{
                            flexGrow: 1,
                            borderLeft: '1px solid #e0e0e0',
                            borderBottom: '1px solid #e0e0e0',
                            borderRadius: 0,
                            bgcolor: '#fff',
                            color: 'error.main',
                            '&:hover': {
                                bgcolor: '#ffebee',
                            },
                        }}
                    >
                        <BackspaceIcon />
                    </Button>
                </Box>
            </Box>
        </Box>
    );
}
