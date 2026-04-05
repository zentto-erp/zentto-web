'use client';

import React, { useState } from 'react';
import {
    Box,
    Typography,
    Button,
    Paper,
    useTheme,
    Chip,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    IconButton,
    List,
    ListItem,
    ListItemIcon,
    ListItemText,
    Tooltip,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useAuth } from '@zentto/shared-auth';
import { useRouter } from 'next/navigation';
import { resolveAppHref } from '@/lib/app-links';

// Icons — outlined variants (match landing style)
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWalletOutlined'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/BadgeOutlined'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalanceOutlined'), { ssr: false });
const StorefrontIcon = dynamic(() => import('@mui/icons-material/WarehouseOutlined'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCartOutlined'), { ssr: false });
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSaleOutlined'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShippingOutlined'), { ssr: false });
const ContentPasteSearchIcon = dynamic(() => import('@mui/icons-material/ContentPasteSearchOutlined'), { ssr: false });
const RestaurantIcon = dynamic(() => import('@mui/icons-material/RestaurantOutlined'), { ssr: false });
const LanguageIcon = dynamic(() => import('@mui/icons-material/PublicOutlined'), { ssr: false });
const CloseIcon = dynamic(() => import('@mui/icons-material/Close'), { ssr: false });
const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });
const StarIcon = dynamic(() => import('@mui/icons-material/Star'), { ssr: false });
const UpdateIcon = dynamic(() => import('@mui/icons-material/Update'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });
const RocketLaunchIcon = dynamic(() => import('@mui/icons-material/RocketLaunch'), { ssr: false });
const LockIcon = dynamic(() => import('@mui/icons-material/Lock'), { ssr: false });
const PrecisionManufacturingIcon = dynamic(() => import('@mui/icons-material/PrecisionManufacturingOutlined'), { ssr: false });
const DirectionsCarIcon = dynamic(() => import('@mui/icons-material/DirectionsCarOutlined'), { ssr: false });
const GroupsIcon = dynamic(() => import('@mui/icons-material/GroupsOutlined'), { ssr: false });

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

const DescriptionIcon = dynamic(() => import('@mui/icons-material/DescriptionOutlined'), { ssr: false });
const ExtensionIcon = dynamic(() => import('@mui/icons-material/ExtensionOutlined'), { ssr: false });
const RouteIcon = dynamic(() => import('@mui/icons-material/RouteOutlined'), { ssr: false });
const ShoppingBagIcon = dynamic(() => import('@mui/icons-material/ShoppingBagOutlined'), { ssr: false });
const VerifiedUserIcon = dynamic(() => import('@mui/icons-material/VerifiedUserOutlined'), { ssr: false });
const ConfirmationNumberIcon = dynamic(() => import('@mui/icons-material/ConfirmationNumberOutlined'), { ssr: false });
const LocalHospitalIcon = dynamic(() => import('@mui/icons-material/LocalHospitalOutlined'), { ssr: false });

const CATALOG: StoreApp[] = [
    // Mismo orden y colores que el home (escala cromática: rojo → naranja → verde → teal → azul → púrpura → rosa)
    { id: 'contabilidad', name: 'Contabilidad', description: 'Gestione la contabilidad financiera y analítica, asientos, mayores y reportes.', fullDescription: 'El módulo de Contabilidad le permite gestionar toda la contabilidad de su empresa de manera eficiente. Incluye gestión de asientos contables, plan de cuentas, mayores, balances y reportes financieros completos.', icon: <AccountBalanceWalletIcon sx={{ fontSize: 28 }} />, bgColor: '#E74C3C', category: 'Finanzas', path: '/contabilidad', features: ['Asientos contables', 'Plan de cuentas', 'Mayores automáticos', 'Balances', 'Reportes financieros'], version: '2.1.0', author: 'Zentto' },
    { id: 'nomina', name: 'Nómina', description: 'Administración de empleados, vacaciones, liquidaciones y roles de pago.', fullDescription: 'Gestione su talento humano con el módulo de Nómina. Incluye administración de empleados, cálculo de nómina, gestión de vacaciones, liquidaciones y roles de pago automatizados.', icon: <BadgeIcon sx={{ fontSize: 28 }} />, bgColor: '#E67E22', category: 'Recursos Humanos', path: '/nomina', features: ['Gestión de empleados', 'Cálculo de nómina', 'Vacaciones', 'Liquidaciones', 'Roles de pago'], version: '1.8.5', author: 'Zentto' },
    { id: 'bancos', name: 'Bancos e Inst.', description: 'Gestión de cuentas corrientes, movimientos y conciliación bancaria.', fullDescription: 'Controle sus finanzas bancarias con este módulo integrado. Gestione múltiples cuentas corrientes, registre movimientos y realice conciliaciones bancarias automáticas.', icon: <AccountBalanceIcon sx={{ fontSize: 28 }} />, bgColor: '#F39C12', category: 'Finanzas', path: '/bancos', features: ['Múltiples cuentas', 'Conciliación bancaria', 'Movimientos', 'Reportes', 'Integración contable'], version: '1.5.2', author: 'Zentto' },
    { id: 'inventario', name: 'Inventario', description: 'Controle su stock, existencias, bodegas, kardex y valoración.', fullDescription: 'Mantenga el control total de su inventario. Gestione bodegas múltiples, movimientos de stock, kardex valorizado, y obtenga reportes detallados de existencias.', icon: <StorefrontIcon sx={{ fontSize: 28 }} />, bgColor: '#27AE60', category: 'Operaciones', path: '/inventario', features: ['Múltiples bodegas', 'Kardex valorizado', 'Movimientos', 'Alertas de stock', 'Reportes'], version: '3.0.1', author: 'Zentto' },
    { id: 'ventas', name: 'Ventas', description: 'Gestione facturas, abonos, cuentas por cobrar (CxC) y bases de clientes.', fullDescription: 'Maximice sus ventas con este completo módulo. Gestione facturación, cuentas por cobrar, abonos, notas de crédito/débito y mantenga su cartera de clientes organizada.', icon: <ShoppingCartIcon sx={{ fontSize: 28 }} />, bgColor: '#1ABC9C', category: 'Ventas', path: '/ventas', features: ['Facturación', 'Cuentas por cobrar', 'Abonos', 'Notas crédito/débito', 'Clientes'], version: '2.5.0', author: 'Zentto' },
    { id: 'compras', name: 'Compras', description: 'Órdenes de compra, recepción de facturas proveedor y cuentas por pagar.', fullDescription: 'Optimice su proceso de compras. Desde órdenes de compra hasta recepción de mercancía y gestión de cuentas por pagar. Mantenga a sus proveedores organizados.', icon: <ShoppingBagIcon sx={{ fontSize: 28 }} />, bgColor: '#00A09D', category: 'Operaciones', path: '/compras', features: ['Órdenes de compra', 'Recepciones', 'Cuentas por pagar', 'Proveedores', 'Reportes'], version: '2.0.3', author: 'Zentto' },
    { id: 'pos', name: 'Punto de Venta', description: 'Software TPV optimizado para tiendas. Fácil, rápido y robusto.', fullDescription: 'El Punto de Venta perfecto para su tienda. Interfaz táctil optimizada, gestión de caja, facturación rápida y reportes de ventas en tiempo real.', icon: <PointOfSaleIcon sx={{ fontSize: 28 }} />, bgColor: '#3498DB', category: 'Ventas', path: '/pos', features: ['Interfaz táctil', 'Múltiples formas de pago', 'Cierre de caja', 'Reportes Z', 'Facturación'], version: '1.9.0', author: 'Zentto' },
    { id: 'restaurante', name: 'Restaurante', description: 'Extensión de Punto de Venta con mapas de mesas, salones y cocina.', fullDescription: 'Especializado para restaurantes. Gestione mapas de mesas, múltiples salones, comandas para cocina y propinas. Integrado con el módulo POS.', icon: <RestaurantIcon sx={{ fontSize: 28 }} />, bgColor: '#0984E3', category: 'Especializados', path: '/restaurante', features: ['Mapa de mesas', 'Salones múltiples', 'Comandas cocina', 'Propinas', 'Integración POS'], version: '1.2.0', author: 'Zentto' },
    { id: 'ecommerce', name: 'Comercio Electrónico', description: 'Tienda en línea B2B/B2C integrada en tiempo real con facturación.', fullDescription: 'Lleve su negocio al siguiente nivel con una tienda en línea integrada. Ventas B2B y B2C, sincronización automática de inventario y facturación electrónica.', icon: <LanguageIcon sx={{ fontSize: 28 }} />, bgColor: '#1565C0', category: 'Ventas', path: '/ecommerce', features: ['Tienda online', 'B2B/B2C', 'Sincronización inventario', 'Pagos en línea', 'Envíos'], version: '1.0.5', author: 'Zentto' },
    { id: 'auditoria', name: 'Auditoría Fiscal', description: 'Preparación de libros contables legales y declaración de impuestos.', fullDescription: 'Mantenga su empresa al día con las obligaciones fiscales. Generación de libros legales, declaraciones de impuestos y reportes para auditorías.', icon: <VerifiedUserIcon sx={{ fontSize: 28 }} />, bgColor: '#5C6BC0', category: 'Especializados', path: '/auditoria', features: ['Libros legales', 'Declaraciones', 'Reportes fiscales', 'Auditorías', 'Compliance'], version: '1.3.2', author: 'Zentto' },
    { id: 'logistica', name: 'Logística', description: 'Recepción de mercancía, devoluciones, albaranes y transportistas.', fullDescription: 'Gestione toda la cadena logística de su empresa. Reciba mercancía con inspección de calidad, procese devoluciones a proveedores, genere albaranes de entrega con firma digital y administre su flota de transportistas.', icon: <RouteIcon sx={{ fontSize: 28 }} />, bgColor: '#7E57C2', category: 'Operaciones', path: '/logistica', features: ['Recepción mercancía', 'Inspección de calidad', 'Devoluciones', 'Albaranes / Guías despacho', 'Transportistas', 'Firma digital de entrega'], version: '1.0.0', author: 'Zentto' },
    { id: 'crm', name: 'CRM', description: 'Pipeline de ventas, leads, actividades y seguimiento comercial.', fullDescription: 'Impulse su fuerza de ventas con un CRM completo. Visualice su pipeline en tablero Kanban, gestione leads con probabilidad de cierre, registre actividades (llamadas, emails, reuniones) y analice su tasa de conversión.', icon: <GroupsIcon sx={{ fontSize: 28 }} />, bgColor: '#9B59B6', category: 'Ventas', path: '/crm', features: ['Pipeline Kanban', 'Leads con probabilidad', 'Actividades y tareas', 'Historial de cambios', 'Funnel de conversión', 'Multi-pipeline'], version: '1.0.0', author: 'Zentto' },
    { id: 'manufactura', name: 'Manufactura', description: 'Listas de materiales (BOM), centros de trabajo y órdenes de producción.', fullDescription: 'Controle su proceso productivo de principio a fin. Defina listas de materiales con componentes y costos, configure centros de trabajo con capacidad, y gestione órdenes de producción con seguimiento de estado en tiempo real.', icon: <PrecisionManufacturingIcon sx={{ fontSize: 28 }} />, bgColor: '#8E44AD', category: 'Operaciones', path: '/manufactura', features: ['Listas de materiales (BOM)', 'Centros de trabajo', 'Órdenes de producción', 'Control de costos', 'Seguimiento en tiempo real', 'Integración contable'], version: '1.0.0', author: 'Zentto' },
    { id: 'flota', name: 'Control de Flota', description: 'Vehículos, combustible, mantenimiento preventivo y registro de viajes.', fullDescription: 'Administre todos los vehículos de su empresa. Registre cargas de combustible con costos, programe mantenimiento preventivo y correctivo, lleve control de viajes con origen/destino y analice costos operativos por vehículo.', icon: <DirectionsCarIcon sx={{ fontSize: 28 }} />, bgColor: '#875A7B', category: 'Operaciones', path: '/flota', features: ['Registro de vehículos', 'Control de combustible', 'Mantenimiento preventivo', 'Registro de viajes', 'Costos por vehículo', 'Alertas de servicio'], version: '1.0.0', author: 'Zentto' },
    { id: 'shipping', name: 'Zentto Shipping', description: 'Portal de paquetería: envía, rastrea y gestiona paquetes con múltiples carriers.', fullDescription: 'Plataforma completa de envíos para clientes finales. Registro de clientes, cotización multi-carrier (Zoom, MRW, Liberty Express), generación de guías, rastreo en tiempo real con timeline, gestión de aduanas para envíos internacionales, y notificaciones automáticas en cada cambio de estado.', icon: <LocalShippingIcon sx={{ fontSize: 28 }} />, bgColor: '#E84393', category: 'Operaciones', path: '/shipping', features: ['Envíos nacionales e internacionales', 'Cotización multi-carrier', 'Rastreo en tiempo real', 'Gestión de aduanas', 'Notificaciones automáticas', 'Portal público de rastreo', 'Zoom / MRW / Liberty Express'], version: '1.0.0', author: 'Zentto' },
    { id: 'report-studio', name: 'Report Studio', description: 'Diseñador de reportes profesional con motor propio y plantillas listas para usar.', fullDescription: 'Crea reportes personalizados para tu empresa sin programar. El Designer visual permite arrastrar y soltar campos, tablas, graficos y codigos QR. Incluye 30+ plantillas del sistema (facturas, nominas, inventario) y 25 layouts predefinidos por modulo.', icon: <DescriptionIcon sx={{ fontSize: 28 }} />, bgColor: '#FF6584', category: 'Herramientas', path: '/report-studio', features: ['Designer visual WYSIWYG', '30+ plantillas del sistema', '25 layouts por modulo', 'Motor de expresiones (80+ funciones)', 'Graficos SVG, QR y codigos de barra', 'Exportar a PDF y HTML', 'Guardar en la nube sin deploy'], version: '1.9.2', author: 'Zentto' },
    { id: 'tickets', name: 'Zentto Tickets', description: 'Eventos, boletos y experiencias con mapas interactivos de asientos.', fullDescription: 'Gestiona venues, eventos, venta de boletos con mapas interactivos de asientos, carreras de calle, inscripciones, dorsales y escaneo QR en puerta. Comisión por boleto vendido.', icon: <ConfirmationNumberIcon sx={{ fontSize: 28 }} />, bgColor: '#6366F1', category: 'Especializados', path: '/tickets', features: ['Mapas de asientos interactivos', 'Editor visual de venues', 'Carreras 5K/10K/maratón', 'QR tickets anti-fraude', 'Hold temporal 10 min', 'Clasificación en tiempo real'], version: '0.1.0', author: 'Zentto' },
    { id: 'medical', name: 'Zentto Medical', description: 'Gestión médica: citas, pacientes, médicos, recetas y chat.', fullDescription: 'Plataforma completa de gestión médica para doctores y clínicas. Agende citas con lifecycle completo, gestione pacientes con historial médico, emita recetas electrónicas, chat médico-paciente y facturación con comisiones.', icon: <LocalHospitalIcon sx={{ fontSize: 28 }} />, bgColor: '#059669', category: 'Especializados', path: '/medical', features: ['Citas con lifecycle completo', 'Historial médico', 'Recetas electrónicas', 'Chat médico-paciente', 'Dashboard por rol', '15 especialidades médicas'], version: '0.1.0', author: 'Zentto' },
    { id: 'addons', name: 'Addons', description: 'Crea aplicaciones personalizadas con el Wizard o el Designer visual.', fullDescription: 'Extiende tu ERP con aplicaciones a medida. El Wizard guiado permite crear apps en minutos sin codigo, mientras que el Designer ofrece control total sobre el layout.', icon: <ExtensionIcon sx={{ fontSize: 28 }} />, bgColor: '#B0879E', category: 'Herramientas', path: '/addons', features: ['Wizard guiado paso a paso', 'Designer visual avanzado', 'Asignar a multiples modulos', 'Preview en tiempo real', 'Publicar y compartir', 'Sin necesidad de programar'], version: '1.0.0', author: 'Zentto' },
];

export default function AppsStorePage() {
    const { modulos, isAdmin } = useAuth();
    const theme = useTheme();
    const router = useRouter();
    const [selectedApp, setSelectedApp] = useState<StoreApp | null>(null);

    const isInstalled = (id: string) => {
        // Admin con todos los modulos = tiene suscripcion activa
        if (isAdmin && modulos.length > 0) return true;
        if (id === 'ventas') return modulos.includes('facturas') || modulos.includes('cxc');
        if (id === 'compras') return modulos.includes('compras') || modulos.includes('cxp');
        return modulos.includes(id);
    };

    const handleOpenApp = (app: StoreApp) => {
        const href = resolveAppHref(app.id, app.path);
        if (href === app.path) {
            router.push(href);
            return;
        }

        window.location.assign(href);
    };

    return (
        <Box sx={{ flex: 1, p: { xs: 2, md: 4 }, bgcolor: 'background.default' }}>
            <Typography variant="h5" sx={{ fontWeight: 600, color: 'text.primary', mb: 4 }}>
                Aplicaciones
            </Typography>

            <Grid container spacing={3}>
                {CATALOG.map((app) => {
                    const installed = isInstalled(app.id);
                    return (
                        <Grid key={app.id} size={{ xs: 12, md: 6, lg: 4 }}>
                            <Paper
                                elevation={0}
                                onClick={() => installed ? handleOpenApp(app) : setSelectedApp(app)}
                                sx={{
                                    p: 3,
                                    height: '100%',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    border: (t) => `1px solid ${t.palette.divider}`,
                                    borderRadius: 4,
                                    cursor: 'pointer',
                                    transition: 'box-shadow 0.2s',
                                    bgcolor: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.04)' : 'background.paper',
                                    boxShadow: (t) => t.palette.mode === 'dark' ? 'none' : '0 1px 4px rgba(0,0,0,0.06)',
                                    '&:hover': {
                                        boxShadow: (t) => t.palette.mode === 'dark' ? '0 4px 12px rgba(0,0,0,0.3)' : '0 4px 12px rgba(0,0,0,0.1)',
                                    }
                                }}
                            >
                                {/* Icon box — landing style */}
                                <Box sx={{
                                    width: 48, height: 48, borderRadius: 3,
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    bgcolor: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#fff',
                                    border: (t) => `1px solid ${t.palette.divider}`,
                                    boxShadow: (t) => t.palette.mode === 'dark' ? 'none' : '0 2px 8px rgba(0,0,0,0.12)',
                                    color: app.bgColor,
                                    mb: 2.5,
                                }}>
                                    {app.icon}
                                </Box>

                                <Typography variant="subtitle1" sx={{ fontWeight: 600, color: 'text.secondary', mb: 1 }}>
                                    {app.name}
                                </Typography>

                                <Typography variant="body2" color="text.secondary" sx={{ flexGrow: 1, mb: 3, lineHeight: 1.6 }}>
                                    {app.description}
                                </Typography>

                                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                                    {installed ? (
                                        <Button
                                            variant="contained"
                                            size="small"
                                            onClick={(e) => { e.stopPropagation(); handleOpenApp(app); }}
                                            startIcon={<CheckCircleIcon />}
                                            sx={{
                                                bgcolor: app.bgColor,
                                                color: '#fff',
                                                fontWeight: 600,
                                                textTransform: 'none',
                                                '&:hover': { bgcolor: app.bgColor, opacity: 0.9 }
                                            }}
                                        >
                                            Abrir
                                        </Button>
                                    ) : (
                                        <Button
                                            variant="contained"
                                            size="small"
                                            startIcon={<LockIcon />}
                                            onClick={(e) => { e.stopPropagation(); router.push('/pricing'); }}
                                            sx={{
                                                bgcolor: '#6C63FF',
                                                fontWeight: 600,
                                                textTransform: 'none',
                                                boxShadow: 'none',
                                                '&:hover': { bgcolor: '#5b54e6' },
                                            }}
                                        >
                                            Suscribirse
                                        </Button>
                                    )}
                                    <Button
                                        variant="text"
                                        color="inherit"
                                        size="small"
                                        onClick={(e) => { e.stopPropagation(); setSelectedApp(app); }}
                                        sx={{ textTransform: 'none', color: 'text.secondary' }}
                                    >
                                        Más información
                                    </Button>
                                </Box>
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
                                <Box sx={{ width: 56, height: 56, borderRadius: 3, display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)', color: selectedApp.bgColor }}>
                                    {selectedApp.icon}
                                </Box>
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
                            <Tooltip title="Cerrar">
                              <IconButton onClick={() => setSelectedApp(null)} size="small">
                                <CloseIcon />
                              </IconButton>
                            </Tooltip>
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

                            {isInstalled(selectedApp.id) ? (
                                <Box sx={(t) => ({ p: 2, borderRadius: 1, display: 'flex', alignItems: 'center', gap: 1, ...(t.palette.mode === 'dark' ? { bgcolor: 'rgba(46,125,50,0.15)' } : { bgcolor: '#e8f5e9' }) })}>
                                    <CheckCircleIcon color="success" />
                                    <Typography variant="body2" color="success.main">
                                        Esta aplicación está instalada y lista para usar.
                                    </Typography>
                                </Box>
                            ) : (
                                <Box sx={(t) => ({ p: 2, borderRadius: 1, display: 'flex', alignItems: 'center', gap: 1, ...(t.palette.mode === 'dark' ? { bgcolor: 'rgba(108,99,255,0.15)' } : { bgcolor: '#f3f0ff' }) })}>
                                    <RocketLaunchIcon sx={{ color: '#6C63FF' }} />
                                    <Typography variant="body2" sx={{ color: '#6C63FF' }}>
                                        Suscríbete a un plan para acceder a este módulo.
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
                                <Button
                                    variant="contained"
                                    startIcon={<RocketLaunchIcon />}
                                    onClick={() => {
                                        setSelectedApp(null);
                                        router.push('/pricing');
                                    }}
                                    sx={{ bgcolor: '#6C63FF', '&:hover': { bgcolor: '#5b54e6' } }}
                                >
                                    Ver planes y suscribirse
                                </Button>
                            )}
                        </DialogActions>
                    </>
                )}
            </Dialog>
        </Box>
    );
}
