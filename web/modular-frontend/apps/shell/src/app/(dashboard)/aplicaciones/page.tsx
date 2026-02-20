'use client';

import React from 'react';
import { Box, Typography, Button, Paper, useTheme, Avatar, Chip, Stack } from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useAuth } from '@datqbox/shared-auth';

// Icons
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const StorefrontIcon = dynamic(() => import('@mui/icons-material/Storefront'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const ContentPasteSearchIcon = dynamic(() => import('@mui/icons-material/ContentPasteSearch'), { ssr: false });

interface StoreApp {
    id: string;
    name: string;
    description: string;
    icon: React.ReactNode;
    bgColor: string;
    category: string;
}

const CATALOG: StoreApp[] = [
    { id: 'contabilidad', name: 'Contabilidad', description: 'Gestione la contabilidad financiera y analítica, asientos, mayores y reportes.', icon: <AccountBalanceWalletIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#875A7B', category: 'Finanzas' },
    { id: 'nomina', name: 'Nómina', description: 'Administración de empleados, vacaciones, liquidaciones y roles de pago.', icon: <BadgeIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#00A09D', category: 'Recursos Humanos' },
    { id: 'bancos', name: 'Bancos e Inst.', description: 'Gestión de cuentas corrientes, movimientos y conciliación bancaria.', icon: <AccountBalanceIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#E67E22', category: 'Finanzas' },
    { id: 'inventario', name: 'Inventario', description: 'Controle su stock, existencias, bodegas, kardex y valoración.', icon: <StorefrontIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#27AE60', category: 'Operaciones' },
    { id: 'ventas', name: 'Ventas', description: 'Gestione facturas, abonos, cuentas por cobrar (CxC) y bases de clientes.', icon: <ShoppingCartIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#3498DB', category: 'Ventas' },
    { id: 'compras', name: 'Compras', description: 'Órdenes de compra, recepción de facturas proveedor y cuentas por pagar.', icon: <LocalShippingIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#F39C12', category: 'Operaciones' },
    { id: 'pos', name: 'Punto de Venta', description: 'Software TPV optimizado para tiendas. Fácil, rápido y robusto.', icon: <PointOfSaleIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#9B59B6', category: 'Ventas' },
    { id: 'restaurant', name: 'Restaurante', description: 'Extensión de Punto de Venta con mapas de mesas, salones y cocina.', icon: <StorefrontIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#E84393', category: 'Especializados' },
    { id: 'ecommerce', name: 'Comercio Electrónico', description: 'Tienda en línea B2B/B2C integrada en tiempo real con facturación.', icon: <ShoppingCartIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#0984E3', category: 'Ventas' },
    { id: 'auditoria', name: 'Auditoría Fiscal', description: 'Preparación de libros contables legales y declaración de impuestos.', icon: <ContentPasteSearchIcon sx={{ fontSize: 40, color: '#fff' }} />, bgColor: '#2D3436', category: 'Especializados' },
];

export default function AppsStorePage() {
    const { modulos, isAdmin } = useAuth();
    const theme = useTheme();

    const isInstalled = (id: string) => {
        if (isAdmin) return true;
        if (id === 'ventas') return modulos.includes('facturas') || modulos.includes('cxc');
        if (id === 'compras') return modulos.includes('compras') || modulos.includes('cxp');
        return modulos.includes(id);
    };

    return (
        <Box sx={{ flex: 1, p: { xs: 2, md: 4 }, bgcolor: '#F9FAFB' }}>

            {/* Odoo-like header for Apps section */}
            <Stack direction="row" alignItems="center" justifyContent="space-between" mb={4}>
                <Typography variant="h5" sx={{ fontWeight: 600, color: '#111827' }}>
                    Aplicaciones
                </Typography>
            </Stack>

            <Grid container spacing={3}>
                {CATALOG.map((app) => {
                    const installed = isInstalled(app.id);
                    return (
                        <Grid key={app.id} size={{ xs: 12, md: 6, lg: 4 }}>
                            <Paper
                                elevation={0}
                                sx={{
                                    p: 3,
                                    height: '100%',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    border: '1px solid #E5E7EB',
                                    borderRadius: 2,
                                    transition: 'border-color 0.2s, box-shadow 0.2s',
                                    '&:hover': {
                                        borderColor: '#D1D5DB',
                                        boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)'
                                    }
                                }}
                            >
                                <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                                    <Avatar
                                        variant="rounded"
                                        sx={{ width: 64, height: 64, bgcolor: app.bgColor }}
                                    >
                                        {app.icon}
                                    </Avatar>
                                    <Box sx={{ flex: 1 }}>
                                        <Typography variant="subtitle1" sx={{ fontWeight: 600, lineHeight: 1.2, mb: 0.5 }}>
                                            {app.name}
                                        </Typography>
                                        <Typography variant="body2" color="text.secondary" sx={{ display: 'flex', gap: 1 }}>
                                            {app.category}
                                        </Typography>
                                    </Box>
                                </Box>

                                <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1, mb: 3 }}>
                                    {app.description}
                                </Typography>

                                <Stack direction="row" gap={1}>
                                    {installed ? (
                                        <Button
                                            variant="contained"
                                            color="inherit"
                                            size="small"
                                            disabled
                                            sx={{
                                                bgcolor: '#E5E7EB !important',
                                                color: '#4B5563 !important',
                                                fontWeight: 600,
                                                textTransform: 'none'
                                            }}
                                        >
                                            Instalado
                                        </Button>
                                    ) : (
                                        <Button
                                            variant="contained"
                                            color="primary"
                                            size="small"
                                            sx={{
                                                bgcolor: theme.palette.primary.main,
                                                fontWeight: 600,
                                                textTransform: 'none',
                                                boxShadow: 'none'
                                            }}
                                        >
                                            Instalar
                                        </Button>
                                    )}
                                    <Button
                                        variant="text"
                                        color="inherit"
                                        size="small"
                                        sx={{ textTransform: 'none', color: '#6B7280' }}
                                    >
                                        Más información
                                    </Button>
                                </Stack>
                            </Paper>
                        </Grid>
                    );
                })}
            </Grid>
        </Box>
    );
}
