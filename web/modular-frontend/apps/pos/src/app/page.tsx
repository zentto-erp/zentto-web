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
export default function PosDashboardPage() {
    const router = useRouter();

    const quickActions = [
        {
            title: 'Nueva Factura',
            description: 'Iniciar venta rápida',
            icon: <PointOfSaleIcon sx={{ fontSize: 48 }} />,
            path: '/pos/facturacion',
            color: '#1976d2',
        },
        {
            title: 'Cierre de Caja',
            description: 'Arqueo y cuadre',
            icon: <AccountBalanceWalletIcon sx={{ fontSize: 48 }} />,
            path: '/pos/cierre-caja',
            color: '#388e3c',
        },
        {
            title: 'Reportes',
            description: 'Ventas y estadísticas',
            icon: <BarChartIcon sx={{ fontSize: 48 }} />,
            path: '/pos/reportes',
            color: '#f57c00',
        },
        {
            title: 'Últimas Facturas',
            description: 'Historial de ventas',
            icon: <ReceiptIcon sx={{ fontSize: 48 }} />,
            path: '/pos/facturacion',
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

            {/* Resumen del día - Placeholder para datos futuros */}
            <Box sx={{ mt: 6 }}>
                <Typography variant="h5" gutterBottom>
                    Resumen del Día
                </Typography>
                <Grid container spacing={2}>
                    <Grid item xs={12} sm={4}>
                        <Card sx={{ bgcolor: 'primary.light', color: 'primary.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6">Ventas Hoy</Typography>
                                <Typography variant="h4" fontWeight="bold">
                                    $0.00
                                </Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                    <Grid item xs={12} sm={4}>
                        <Card sx={{ bgcolor: 'success.light', color: 'success.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6">Transacciones</Typography>
                                <Typography variant="h4" fontWeight="bold">
                                    0
                                </Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                    <Grid item xs={12} sm={4}>
                        <Card sx={{ bgcolor: 'warning.light', color: 'warning.contrastText' }}>
                            <CardContent>
                                <Typography variant="h6">Productos Vendidos</Typography>
                                <Typography variant="h4" fontWeight="bold">
                                    0
                                </Typography>
                            </CardContent>
                        </Card>
                    </Grid>
                </Grid>
            </Box>

            {/* Botón de acción flotante para nueva factura */}
            <Box sx={{ mt: 4, display: 'flex', justifyContent: 'center' }}>
                <Button
                    variant="contained"
                    size="large"
                    startIcon={<PointOfSaleIcon />}
                    onClick={() => router.push('/pos/facturacion')}
                    sx={{
                        px: 6,
                        py: 2,
                        fontSize: '1.2rem',
                        borderRadius: 3,
                    }}
                >
                    Iniciar Nueva Venta
                </Button>
            </Box>
        </Box>
    );
}
