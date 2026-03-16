'use client';

import React, { useState } from 'react';
import {
    Box,
    Typography,
    Button,
    Paper,
    useTheme,
    Avatar,
    Chip,
    Stack,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    IconButton,
    List,
    ListItem,
    ListItemIcon,
    ListItemText,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useAuth } from '@zentto/shared-auth';
import { useRouter } from 'next/navigation';

// Icons
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const StorefrontIcon = dynamic(() => import('@mui/icons-material/Storefront'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const ContentPasteSearchIcon = dynamic(() => import('@mui/icons-material/ContentPasteSearch'), { ssr: false });
const RestaurantIcon = dynamic(() => import('@mui/icons-material/Restaurant'), { ssr: false });
const LanguageIcon = dynamic(() => import('@mui/icons-material/Language'), { ssr: false });
const CloseIcon = dynamic(() => import('@mui/icons-material/Close'), { ssr: false });
const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });
const StarIcon = dynamic(() => import('@mui/icons-material/Star'), { ssr: false });
const UpdateIcon = dynamic(() => import('@mui/icons-material/Update'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });

interface StoreApp {
    id: string;
    name: string;
    description: string;
    fullDescription: string;
    icon: React.ReactNode;
    bgColor: string;
    category: string;
    path: string;
    features: string[];
    version: string;
    author: string;
}

const CATALOG: StoreApp[] = [
    {
        id: 'contabilidad',
        name: 'Contabilidad',
        description: 'Gestione la contabilidad financiera y analítica, asientos, mayores y reportes.',
        fullDescription: 'El módulo de Contabilidad le permite gestionar toda la contabilidad de su empresa de manera eficiente. Incluye gestión de asientos contables, plan de cuentas, mayores, balances y reportes financieros completos.',
        icon: <AccountBalanceWalletIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#875A7B',
        category: 'Finanzas',
        path: '/contabilidad',
        features: ['Asientos contables', 'Plan de cuentas', 'Mayores automáticos', 'Balances', 'Reportes financieros'],
        version: '2.1.0',
        author: 'Zentto'
    },
    {
        id: 'nomina',
        name: 'Nómina',
        description: 'Administración de empleados, vacaciones, liquidaciones y roles de pago.',
        fullDescription: 'Gestione su talento humano con el módulo de Nómina. Incluye administración de empleados, cálculo de nómina, gestión de vacaciones, liquidaciones y roles de pago automatizados.',
        icon: <BadgeIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#00A09D',
        category: 'Recursos Humanos',
        path: '/nomina',
        features: ['Gestión de empleados', 'Cálculo de nómina', 'Vacaciones', 'Liquidaciones', 'Roles de pago'],
        version: '1.8.5',
        author: 'Zentto'
    },
    {
        id: 'bancos',
        name: 'Bancos e Inst.',
        description: 'Gestión de cuentas corrientes, movimientos y conciliación bancaria.',
        fullDescription: 'Controle sus finanzas bancarias con este módulo integrado. Gestione múltiples cuentas corrientes, registre movimientos y realice conciliaciones bancarias automáticas.',
        icon: <AccountBalanceIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#E67E22',
        category: 'Finanzas',
        path: '/bancos',
        features: ['Múltiples cuentas', 'Conciliación bancaria', 'Movimientos', 'Reportes', 'Integración contable'],
        version: '1.5.2',
        author: 'Zentto'
    },
    {
        id: 'inventario',
        name: 'Inventario',
        description: 'Controle su stock, existencias, bodegas, kardex y valoración.',
        fullDescription: 'Mantenga el control total de su inventario. Gestione bodegas múltiples, movimientos de stock, kardex valorizado, y obtenga reportes detallados de existencias.',
        icon: <StorefrontIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#27AE60',
        category: 'Operaciones',
        path: '/inventario',
        features: ['Múltiples bodegas', 'Kardex valorizado', 'Movimientos', 'Alertas de stock', 'Reportes'],
        version: '3.0.1',
        author: 'Zentto'
    },
    {
        id: 'ventas',
        name: 'Ventas',
        description: 'Gestione facturas, abonos, cuentas por cobrar (CxC) y bases de clientes.',
        fullDescription: 'Maximice sus ventas con este completo módulo. Gestione facturación, cuentas por cobrar, abonos, notas de crédito/débito y mantenga su cartera de clientes organizada.',
        icon: <ShoppingCartIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#3498DB',
        category: 'Ventas',
        path: '/ventas',
        features: ['Facturación', 'Cuentas por cobrar', 'Abonos', 'Notas crédito/débito', 'Clientes'],
        version: '2.5.0',
        author: 'Zentto'
    },
    {
        id: 'compras',
        name: 'Compras',
        description: 'Órdenes de compra, recepción de facturas proveedor y cuentas por pagar.',
        fullDescription: 'Optimice su proceso de compras. Desde órdenes de compra hasta recepción de mercancía y gestión de cuentas por pagar. Mantenga a sus proveedores organizados.',
        icon: <LocalShippingIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#F39C12',
        category: 'Operaciones',
        path: '/compras',
        features: ['Órdenes de compra', 'Recepciones', 'Cuentas por pagar', 'Proveedores', 'Reportes'],
        version: '2.0.3',
        author: 'Zentto'
    },
    {
        id: 'pos',
        name: 'Punto de Venta',
        description: 'Software TPV optimizado para tiendas. Fácil, rápido y robusto.',
        fullDescription: 'El Punto de Venta perfecto para su tienda. Interfaz táctil optimizada, gestión de caja, facturación rápida y reportes de ventas en tiempo real.',
        icon: <PointOfSaleIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#9B59B6',
        category: 'Ventas',
        path: '/pos',
        features: ['Interfaz táctil', 'Múltiples formas de pago', 'Cierre de caja', 'Reportes Z', 'Facturación'],
        version: '1.9.0',
        author: 'Zentto'
    },
    {
        id: 'restaurante',
        name: 'Restaurante',
        description: 'Extensión de Punto de Venta con mapas de mesas, salones y cocina.',
        fullDescription: 'Especializado para restaurantes. Gestione mapas de mesas, múltiples salones, comandas para cocina y propinas. Integrado con el módulo POS.',
        icon: <RestaurantIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#E84393',
        category: 'Especializados',
        path: '/restaurante',
        features: ['Mapa de mesas', 'Salones múltiples', 'Comandas cocina', 'Propinas', 'Integración POS'],
        version: '1.2.0',
        author: 'Zentto'
    },
    {
        id: 'ecommerce',
        name: 'Comercio Electrónico',
        description: 'Tienda en línea B2B/B2C integrada en tiempo real con facturación.',
        fullDescription: 'Lleve su negocio al siguiente nivel con una tienda en línea integrada. Ventas B2B y B2C, sincronización automática de inventario y facturación electrónica.',
        icon: <LanguageIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#0984E3',
        category: 'Ventas',
        path: '/ecommerce',
        features: ['Tienda online', 'B2B/B2C', 'Sincronización inventario', 'Pagos en línea', 'Envíos'],
        version: '1.0.5',
        author: 'Zentto'
    },
    {
        id: 'auditoria',
        name: 'Auditoría Fiscal',
        description: 'Preparación de libros contables legales y declaración de impuestos.',
        fullDescription: 'Mantenga su empresa al día con las obligaciones fiscales. Generación de libros legales, declaraciones de impuestos y reportes para auditorías.',
        icon: <ContentPasteSearchIcon sx={{ fontSize: 40, color: '#fff' }} />,
        bgColor: '#2D3436',
        category: 'Especializados',
        path: '/auditoria',
        features: ['Libros legales', 'Declaraciones', 'Reportes fiscales', 'Auditorías', 'Compliance'],
        version: '1.3.2',
        author: 'Zentto'
    },
];

export default function AppsStorePage() {
    const { modulos, isAdmin } = useAuth();
    const theme = useTheme();
    const router = useRouter();
    const [selectedApp, setSelectedApp] = useState<StoreApp | null>(null);

    const isInstalled = (id: string) => {
        if (isAdmin) return true;
        if (id === 'ventas') return modulos.includes('facturas') || modulos.includes('cxc');
        if (id === 'compras') return modulos.includes('compras') || modulos.includes('cxp');
        return modulos.includes(id);
    };

    const handleOpenApp = (app: StoreApp) => {
        router.push(app.path);
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

                                <Stack direction={{ xs: 'column', sm: 'row' }} gap={1}>
                                    {installed ? (
                                        <Button
                                            variant="contained"
                                            size="small"
                                            onClick={() => handleOpenApp(app)}
                                            startIcon={<CheckCircleIcon />}
                                            sx={{
                                                bgcolor: app.bgColor,
                                                color: '#fff',
                                                fontWeight: 600,
                                                textTransform: 'none',
                                                '&:hover': {
                                                    bgcolor: app.bgColor,
                                                    opacity: 0.9,
                                                }
                                            }}
                                        >
                                            Abrir
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
                                        onClick={() => setSelectedApp(app)}
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

            {/* Modal de Información de la App */}
            <Dialog
                open={!!selectedApp}
                onClose={() => setSelectedApp(null)}
                maxWidth="sm"
                fullWidth
            >
                {selectedApp && (
                    <>
                        <DialogTitle sx={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'flex-start',
                            pb: 1
                        }}>
                            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                                <Avatar
                                    variant="rounded"
                                    sx={{ width: 56, height: 56, bgcolor: selectedApp.bgColor }}
                                >
                                    {selectedApp.icon}
                                </Avatar>
                                <Box>
                                    <Typography variant="h6" fontWeight="bold">
                                        {selectedApp.name}
                                    </Typography>
                                    <Chip
                                        label={selectedApp.category}
                                        size="small"
                                        sx={{ mt: 0.5 }}
                                    />
                                </Box>
                            </Box>
                            <IconButton onClick={() => setSelectedApp(null)} size="small">
                                <CloseIcon />
                            </IconButton>
                        </DialogTitle>

                        <DialogContent>
                            <Typography variant="body1" sx={{ mb: 3 }}>
                                {selectedApp.fullDescription}
                            </Typography>

                            <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>
                                Características principales:
                            </Typography>
                            <List dense sx={{ mb: 3 }}>
                                {selectedApp.features.map((feature, idx) => (
                                    <ListItem key={idx} sx={{ py: 0.5 }}>
                                        <ListItemIcon sx={{ minWidth: 32 }}>
                                            <StarIcon fontSize="small" color="primary" />
                                        </ListItemIcon>
                                        <ListItemText primary={feature} />
                                    </ListItem>
                                ))}
                            </List>

                            <Box sx={{ display: 'flex', gap: 3, color: 'text.secondary', mb: 2 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                    <UpdateIcon fontSize="small" />
                                    <Typography variant="body2">
                                        Versión {selectedApp.version}
                                    </Typography>
                                </Box>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                    <PeopleIcon fontSize="small" />
                                    <Typography variant="body2">
                                        {selectedApp.author}
                                    </Typography>
                                </Box>
                            </Box>

                            {isInstalled(selectedApp.id) && (
                                <Box sx={{
                                    p: 2,
                                    bgcolor: '#e8f5e9',
                                    borderRadius: 1,
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 1
                                }}>
                                    <CheckCircleIcon color="success" />
                                    <Typography variant="body2" color="success.dark">
                                        Esta aplicación está instalada y lista para usar.
                                    </Typography>
                                </Box>
                            )}
                        </DialogContent>

                        <DialogActions sx={{ p: 2, gap: 1 }}>
                            <Button onClick={() => setSelectedApp(null)} variant="outlined">
                                Cerrar
                            </Button>
                            {isInstalled(selectedApp.id) ? (
                                <Button
                                    variant="contained"
                                    onClick={() => {
                                        handleOpenApp(selectedApp);
                                        setSelectedApp(null);
                                    }}
                                    sx={{
                                        bgcolor: selectedApp.bgColor,
                                        '&:hover': { bgcolor: selectedApp.bgColor, opacity: 0.9 }
                                    }}
                                >
                                    Abrir Aplicación
                                </Button>
                            ) : (
                                <Button variant="contained" color="primary">
                                    Instalar Ahora
                                </Button>
                            )}
                        </DialogActions>
                    </>
                )}
            </Dialog>
        </Box>
    );
}
