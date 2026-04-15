'use client';

import React from 'react';
import { Box, Typography, ButtonBase, useMediaQuery } from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useAuth } from '@zentto/shared-auth';
import { isShellLocalPath, resolveAppHref } from '@/lib/app-links';

// Icons — outlined variants (match landing style)
const AccountBalanceWalletOutlinedIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWalletOutlined'), { ssr: false });
const BadgeOutlinedIcon = dynamic(() => import('@mui/icons-material/BadgeOutlined'), { ssr: false });
const AccountBalanceOutlinedIcon = dynamic(() => import('@mui/icons-material/AccountBalanceOutlined'), { ssr: false });
const WarehouseOutlinedIcon = dynamic(() => import('@mui/icons-material/WarehouseOutlined'), { ssr: false });
const ShoppingCartOutlinedIcon = dynamic(() => import('@mui/icons-material/ShoppingCartOutlined'), { ssr: false });
const AppsOutlinedIcon = dynamic(() => import('@mui/icons-material/AppsOutlined'), { ssr: false });
const SettingsOutlinedIcon = dynamic(() => import('@mui/icons-material/SettingsOutlined'), { ssr: false });
const PointOfSaleOutlinedIcon = dynamic(() => import('@mui/icons-material/PointOfSaleOutlined'), { ssr: false });
const ShoppingBagOutlinedIcon = dynamic(() => import('@mui/icons-material/ShoppingBagOutlined'), { ssr: false });
const LocalShippingOutlinedIcon = dynamic(() => import('@mui/icons-material/LocalShippingOutlined'), { ssr: false });
const RestaurantOutlinedIcon = dynamic(() => import('@mui/icons-material/RestaurantOutlined'), { ssr: false });
const PublicOutlinedIcon = dynamic(() => import('@mui/icons-material/PublicOutlined'), { ssr: false });
const VerifiedUserOutlinedIcon = dynamic(() => import('@mui/icons-material/VerifiedUserOutlined'), { ssr: false });
const PrecisionManufacturingOutlinedIcon = dynamic(() => import('@mui/icons-material/PrecisionManufacturingOutlined'), { ssr: false });
const DirectionsCarOutlinedIcon = dynamic(() => import('@mui/icons-material/DirectionsCarOutlined'), { ssr: false });
const GroupsOutlinedIcon = dynamic(() => import('@mui/icons-material/GroupsOutlined'), { ssr: false });
const DescriptionOutlinedIcon = dynamic(() => import('@mui/icons-material/DescriptionOutlined'), { ssr: false });
const ExtensionOutlinedIcon = dynamic(() => import('@mui/icons-material/ExtensionOutlined'), { ssr: false });
const RouteOutlinedIcon = dynamic(() => import('@mui/icons-material/RouteOutlined'), { ssr: false });
const ConfirmationNumberOutlinedIcon = dynamic(() => import('@mui/icons-material/ConfirmationNumberOutlined'), { ssr: false });
const LocalHospitalOutlinedIcon = dynamic(() => import('@mui/icons-material/LocalHospitalOutlined'), { ssr: false });
const ApartmentOutlinedIcon = dynamic(() => import('@mui/icons-material/ApartmentOutlined'), { ssr: false });

interface AppShortcut {
  id: string;
  name: string;
  icon: React.ReactNode;
  path: string;
  bgColor: string;
}

export default function AppSelectorPage() {
  const router = useRouter();
  const { modulos, isAdmin } = useAuth();
  const isSmall = useMediaQuery('(max-width:700px)');

  const has = (mod: string) => isAdmin || modulos.includes(mod);

  const DEV_PORTS: Record<string, number> = {
    contabilidad: 3001,
    pos: 3002,
    nomina: 3003,
    bancos: 3004,
    inventario: 3005,
    ventas: 3006,
    compras: 3007,
    restaurante: 3008,
    ecommerce: 3009,
    auditoria: 3010,
    logistica: 3011,
    crm: 3012,
    manufactura: 3013,
    flota: 3014,
    shipping: 3015,
    lab: 3016,
    'report-studio': 3017,
    panel: 3018,
  };

  const navigateToApp = (appId: string, path: string) => {
    if (path.startsWith('http')) {
      window.open(path, '_blank');
      return;
    }
    if (isShellLocalPath(path)) {
      router.push(path);
      return;
    }
    const port = DEV_PORTS[appId];
    if (port) {
      window.location.href = `http://localhost:${port}${path}`;
      return;
    }
    window.location.href = resolveAppHref(appId, path);
  };

  // Todas las apps disponibles
  const allApps: AppShortcut[] = [];

  // Colores en escala cromática continua: rojo → naranja → ámbar → verde → teal → azul → índigo → púrpura → rosa
  if (has('contabilidad')) {
    allApps.push({ id: 'contabilidad', name: isSmall ? 'Cont.' : 'Contabilidad', icon: <AccountBalanceWalletOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/contabilidad', bgColor: '#E74C3C' });
  }
  if (has('nomina')) {
    allApps.push({ id: 'nomina', name: 'Nómina', icon: <BadgeOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/nomina', bgColor: '#E67E22' });
  }
  if (has('bancos')) {
    allApps.push({ id: 'bancos', name: 'Bancos', icon: <AccountBalanceOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/bancos', bgColor: '#F39C12' });
  }
  if (has('inventario') || has('articulos')) {
    allApps.push({ id: 'inventario', name: isSmall ? 'Inv.' : 'Inventario', icon: <WarehouseOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/inventario', bgColor: '#27AE60' });
  }
  if (has('ventas') || has('facturas')) {
    allApps.push({ id: 'ventas', name: 'Ventas', icon: <ShoppingCartOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/ventas', bgColor: '#1ABC9C' });
  }
  if (has('compras') || has('cxp')) {
    allApps.push({ id: 'compras', name: 'Compras', icon: <ShoppingBagOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/compras', bgColor: '#00A09D' });
  }
  if (has('pos')) {
    allApps.push({ id: 'pos', name: 'Punto de Venta', icon: <PointOfSaleOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/pos/facturacion', bgColor: '#3498DB' });
  }
  if (has('restaurante')) {
    allApps.push({ id: 'restaurante', name: isSmall ? 'Rest.' : 'Restaurante', icon: <RestaurantOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/restaurante', bgColor: '#0984E3' });
  }
  if (has('ecommerce')) {
    allApps.push({ id: 'ecommerce', name: 'E-Commerce', icon: <PublicOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/ecommerce', bgColor: '#1565C0' });
  }
  if (has('auditoria')) {
    allApps.push({ id: 'auditoria', name: isSmall ? 'Audit.' : 'Auditoría', icon: <VerifiedUserOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/auditoria', bgColor: '#5C6BC0' });
  }

  // Módulos avanzados — continúa la escala: índigo → púrpura → rosa
  if (has('logistica')) {
    allApps.push({ id: 'logistica', name: isSmall ? 'Logíst.' : 'Logística', icon: <RouteOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/logistica', bgColor: '#7E57C2' });
  }
  if (has('crm')) {
    allApps.push({ id: 'crm', name: 'CRM', icon: <GroupsOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/crm', bgColor: '#9B59B6' });
  }
  if (has('manufactura')) {
    allApps.push({ id: 'manufactura', name: isSmall ? 'Manuf.' : 'Manufactura', icon: <PrecisionManufacturingOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/manufactura', bgColor: '#8E44AD' });
  }
  if (has('flota')) {
    allApps.push({ id: 'flota', name: 'Flota', icon: <DirectionsCarOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/flota', bgColor: '#875A7B' });
  }
  if (has('shipping')) {
    allApps.push({ id: 'shipping', name: 'Shipping', icon: <LocalShippingOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/shipping', bgColor: '#E84393' });
  }

  // Apps standalone (dominios externos)
  allApps.push({ id: 'tickets', name: 'Tickets', icon: <ConfirmationNumberOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: process.env.NEXT_PUBLIC_TICKETS_URL || 'https://tickets.zentto.net', bgColor: '#6366F1' });
  allApps.push({ id: 'medical', name: 'Medical', icon: <LocalHospitalOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: process.env.NEXT_PUBLIC_MEDICAL_URL || 'https://medical.zentto.net', bgColor: '#059669' });
  allApps.push({ id: 'inmobiliario', name: isSmall ? 'Inmob.' : 'Inmobiliario', icon: <ApartmentOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: process.env.NEXT_PUBLIC_INMOBILIARIO_URL || 'https://inmobiliario.zentto.net', bgColor: '#D4A574' });

  // Utilidades (cierra la escala: rosa → coral → warm)
  if (has('report-studio')) {
    allApps.push({ id: 'report-studio', name: isSmall ? 'Reportes' : 'Report Studio', icon: <DescriptionOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/report-studio', bgColor: '#FF6584' });
  }
  if (isAdmin || has('addons')) {
    allApps.push({ id: 'addons', name: 'Addons', icon: <ExtensionOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/addons', bgColor: '#B0879E' });
  }
  allApps.push({ id: 'aplicaciones', name: isSmall ? 'Apps' : 'Aplicaciones', icon: <AppsOutlinedIcon sx={{ fontSize: 'inherit' }} />, path: '/aplicaciones', bgColor: '#78909C' });

  return (
    <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'center', p: { xs: 2, md: 4 }, bgcolor: 'background.default' }}>
      <Box sx={{ width: '100%', maxWidth: 1200, mt: 2 }}>
        {isAdmin && <Box sx={(t) => ({ width: '100%', p: 2, mb: 4, borderRadius: 2, textAlign: 'center', ...(t.palette.mode === 'dark' ? { bgcolor: '#1e293b', color: '#93c5fd', border: '1px solid #1e40af' } : { bgcolor: '#eff6ff', color: '#1e40af', border: '1px solid #bfdbfe' }) })}>
          <Typography variant="body2" sx={{ fontWeight: 600 }}>Modo administrador activo</Typography>
        </Box>}

        <Grid container spacing={4} justifyContent="center">
          {allApps.map((app) => (
            <Grid key={app.id} size={{ xs: 6, sm: 4, md: 3, lg: 2 }} sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <ButtonBase
                onClick={() => navigateToApp(app.id, app.path)}
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  borderRadius: 3,
                  p: 2,
                  '&:hover .app-icon-box': {
                    transform: 'translateY(-3px)',
                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)',
                  },
                }}
              >
                <Box
                  className="app-icon-box"
                  sx={{
                    width: 64,
                    height: 64,
                    fontSize: 30,
                    '@media (max-width: 700px)': { width: 44, height: 44, fontSize: 22 },
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    borderRadius: 3,
                    bgcolor: (t) => t.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : '#ffffff',
                    border: (t) => `1px solid ${t.palette.mode === 'dark' ? '#374151' : '#e5e7eb'}`,
                    boxShadow: '0 1px 2px 0 rgba(0,0,0,0.05)',
                    color: app.bgColor,
                    mb: 1.5,
                    transition: 'all 0.2s',
                  }}
                >
                  {app.icon}
                </Box>
                <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary', textAlign: 'center' }}>
                  {app.name}
                </Typography>
              </ButtonBase>
            </Grid>
          ))}
        </Grid>
      </Box>
    </Box>
  );
}
