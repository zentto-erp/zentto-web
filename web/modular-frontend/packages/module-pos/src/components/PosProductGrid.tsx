'use client';

import React from 'react';
import {
    Box,
    Paper,
    Typography,
    Grid,
} from '@mui/material';

export interface Product {
    id: string;
    nombre: string;
    precio: number;
    imagen?: string;
    categoria?: string;
}

interface PosProductGridProps {
    products: Product[];
    onProductClick: (product: Product) => void;
    selectedCategory?: string;
}

export function PosProductGrid({ products, onProductClick, selectedCategory }: PosProductGridProps) {
    const [imageErrors, setImageErrors] = React.useState<Record<string, boolean>>({});
    const filteredProducts = selectedCategory 
        ? products.filter(p => p.categoria === selectedCategory)
        : products;

    return (
        <Box sx={{ height: '100%', overflow: 'auto', p: 2 }}>
            <Grid container spacing={1}>
                {filteredProducts.map((product) => (
                    <Grid item xs={6} sm={4} md={2.4} lg={2} key={product.id}>
                        {/*
                          Use native img to avoid Next/Image remote host restrictions
                          in modular MFEs while keeping graceful fallback.
                        */}
                        <Paper
                            onClick={() => onProductClick(product)}
                            elevation={1}
                            sx={{
                                cursor: 'pointer',
                                borderRadius: 2,
                                overflow: 'hidden',
                                transition: 'all 0.2s',
                                height: '100%',
                                display: 'flex',
                                flexDirection: 'column',
                                '&:hover': {
                                    transform: 'translateY(-2px)',
                                    boxShadow: 4,
                                },
                                '&:active': {
                                    transform: 'scale(0.98)',
                                },
                            }}
                        >
                            {/* Imagen del Producto */}
                            <Box
                                sx={{
                                    width: '100%',
                                    aspectRatio: '1.18',
                                    bgcolor: 'action.hover',
                                    position: 'relative',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    overflow: 'hidden',
                                }}
                            >
                                {product.imagen && !imageErrors[product.id] ? (
                                    <Box
                                        component="img"
                                        src={product.imagen}
                                        alt={product.nombre}
                                        onError={() =>
                                            setImageErrors((prev) => ({ ...prev, [product.id]: true }))
                                        }
                                        sx={{
                                            width: '100%',
                                            height: '100%',
                                            objectFit: 'contain',
                                            objectPosition: 'center',
                                            padding: 0.5,
                                        }}
                                    />
                                ) : (
                                    <Box
                                        sx={{
                                            width: '60%',
                                            height: '60%',
                                            bgcolor: 'action.selected',
                                            borderRadius: 1,
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                        }}
                                    >
                                        <Typography variant="caption" color="text.secondary">
                                            {product.id}
                                        </Typography>
                                    </Box>
                                )}
                            </Box>

                            {/* Info del Producto */}
                            <Box sx={{ p: 1, flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
                                <Typography
                                    variant="body2"
                                    fontWeight="medium"
                                    sx={{
                                        lineHeight: 1.25,
                                        mb: 0.25,
                                        display: '-webkit-box',
                                        WebkitLineClamp: 2,
                                        WebkitBoxOrient: 'vertical',
                                        overflow: 'hidden',
                                        minHeight: '2.45em',
                                        fontSize: '0.75rem',
                                    }}
                                >
                                    {product.nombre}
                                </Typography>
                                <Typography
                                    variant="caption"
                                    fontWeight="bold"
                                    color="primary"
                                    sx={{ mt: 'auto' }}
                                >
                                    ${product.precio.toFixed(2)}
                                </Typography>
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );
}
