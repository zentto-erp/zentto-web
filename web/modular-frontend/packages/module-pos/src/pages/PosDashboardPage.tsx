'use client';

import React from 'react';
import {
    Box,
    Typography,
    Grid,
    Card,
    CardContent,
    CardActionArea,
    Button,
    Stack
} from '@mui/material';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';

// Iconos dinámicos para evitar SSR issues
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BarChartIcon = dynamic(() => import('@mui/icons-material/BarChart'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });

/**
 * Dashboard principal del módulo POS
 * Muestra accesos rápidos a las funcionalidades principales
 */
export function PosDashboardPage() {
    const router = useRouter();

    const quickActions = [
        {
            title: 'Nueva Factura',
            description: 'Iniciar venta rápida',
            icon: <PointOfSaleIcon sx={{ fontSize: 48 }} />,
            path: '/facturacion',
            color: '#1976d2',
        },
        {
            title: 'Cierre de Caja',
            description: 'Arqueo y cuadre',
            icon: <AccountBalanceWalletIcon sx={{ fontSize: 48 }} />,
            path: '/cierre-caja',
            color: '#388e3c',
        },
        {
            title: 'Reportes',
            description: 'Ventas y estadísticas',
            icon: <BarChartIcon sx={{ fontSize: 48 }} />,
            path: '/reportes',
            color: '#f57c00',
        },
        {
            title: 'Últimas Facturas',
            description: 'Historial de ventas',
            icon: <ReceiptIcon sx={{ fontSize: 48 }} />,
            path: '/facturacion',
            color: '#7b1fa2',
        },
    ];

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" gutterBottom fontWeight="bold">
                Punto de Venta
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
                Bienvenido al sistema de facturación. Seleccione una acción para comenzar.
            </Typography>

            <Grid container spacing={3}>
                {quickActions.map((action, index) => (
                    <Grid item xs={12} sm={6} md={3} key={index}>
                        <Card
                            elevation={2}
                            sx={{
                                height: '100%',
                                transition: 'transform 0.2s, box-shadow 0.2s',
                                '&:hover': {
                                    transform: 'translateY(-4px)',
                                    boxShadow: 6,
                                },
                            }}
                        >
                            <CardActionArea
                                onClick={() => router.push(action.path)}
                                sx={{ height: '100%', p: 2 }}
                            >
                                <CardContent sx={{ textAlign: 'center' }}>
                                    <Box sx={{ color: action.color, mb: 2 }}>
                                        {action.icon}
                                    </Box>
                                    <Typography variant="h6" gutterBottom>
                                        {action.title}
                                    </Typography>
                                    <Typography variant="body2" color="text.secondary">
                                        {action.description}
                                    </Typography>
                                </CardContent>
                            </CardActionArea>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            <Box sx={{ mt: 6 }}>
                <Typography variant="h5" gutterBottom fontWeight="bold">
                    Resumen del Día
                </Typography>
                <Grid container spacing={3}>
                    <Grid item xs={12} md={4}>
                        <Card sx={{ bgcolor: 'primary.light', color: 'primary.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>Ventas Totales</Typography>
                                <Typography variant="h3">$1,250.00</Typography>
                                <Typography variant="body2" sx={{ mt: 1 }}>24 facturas emitidas</Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                    <Grid item xs={12} md={4}>
                        <Card sx={{ bgcolor: 'success.light', color: 'success.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>Efectivo en Caja</Typography>
                                <Typography variant="h3">$450.00</Typography>
                                <Typography variant="body2" sx={{ mt: 1 }}>Base: $100.00</Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                    <Grid item xs={12} md={4}>
                        <Card sx={{ bgcolor: 'warning.light', color: 'warning.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6" gutterBottom>En Espera</Typography>
                                <Typography variant="h3">3</Typography>
                                <Typography variant="body2" sx={{ mt: 1 }}>Facturas guardadas</Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                </Grid>
            </Box>
        </Box>
    );
}
