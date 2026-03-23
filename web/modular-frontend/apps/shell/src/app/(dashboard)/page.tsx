'use client';

import React from 'react';
import { Box, Typography, ButtonBase, useTheme, Avatar, useMediaQuery } from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useAuth } from '@zentto/shared-auth';
import { isShellLocalPath, resolveAppHref } from '@/lib/app-links';

// Icons - Importar todos los necesarios
const AccountBalanceWalletIcon = dynamic(() => import('@mui/icons-material/AccountBalanceWallet'), { ssr: false });
const BadgeIcon = dynamic(() => import('@mui/icons-material/Badge'), { ssr: false });
const AccountBalanceIcon = dynamic(() => import('@mui/icons-material/AccountBalance'), { ssr: false });
const StorefrontIcon = dynamic(() => import('@mui/icons-material/Storefront'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const AppsIcon = dynamic(() => import('@mui/icons-material/Apps'), { ssr: false });
const SettingsIcon = dynamic(() => import('@mui/icons-material/Settings'), { ssr: false });
const PointOfSaleIcon = dynamic(() => import('@mui/icons-material/PointOfSale'), { ssr: false });
const LocalShippingIcon = dynamic(() => import('@mui/icons-material/LocalShipping'), { ssr: false });
const RestaurantIcon = dynamic(() => import('@mui/icons-material/Restaurant'), { ssr: false });
const LanguageIcon = dynamic(() => import('@mui/icons-material/Language'), { ssr: false });
const ContentPasteSearchIcon = dynamic(() => import('@mui/icons-material/ContentPasteSearch'), { ssr: false });
const PrecisionManufacturingIcon = dynamic(() => import('@mui/icons-material/PrecisionManufacturing'), { ssr: false });
const DirectionsCarIcon = dynamic(() => import('@mui/icons-material/DirectionsCar'), { ssr: false });
const GroupsIcon = dynamic(() => import('@mui/icons-material/Groups'), { ssr: false });

interface AppShortcut {
  id: string;
  name: string;
  icon: React.ReactNode;
  path: string;
  bgColor: string;
  requiredModule?: string;
}

export default function AppSelectorPage() {
  const router = useRouter();
  const theme = useTheme();
  const { userName, modulos, isAdmin } = useAuth();
  const isSmall = useMediaQuery('(max-width:700px)');

  const has = (mod: string) => isAdmin || modulos.includes(mod);

  const navigateToApp = (appId: string, path: string) => {
    const href = resolveAppHref(appId, path);
    if (isShellLocalPath(path)) {
      router.push(href);
      return;
    }
    window.location.assign(href);
  };

  // Todas las apps disponibles
  const allApps: AppShortcut[] = [];

  if (has('contabilidad')) {
    allApps.push({ id: 'contabilidad', name: isSmall ? 'Cont.' : 'Contabilidad', icon: <AccountBalanceWalletIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/contabilidad', bgColor: '#875A7B' });
  }
  if (has('nomina')) {
    allApps.push({ id: 'nomina', name: 'Nómina', icon: <BadgeIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/nomina', bgColor: '#00A09D' });
  }
  if (has('bancos')) {
    allApps.push({ id: 'bancos', name: 'Bancos', icon: <AccountBalanceIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/bancos', bgColor: '#E67E22' });
  }
  if (has('inventario') || has('articulos')) {
    allApps.push({ id: 'inventario', name: isSmall ? 'Inv.' : 'Inventario', icon: <StorefrontIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/inventario', bgColor: '#27AE60' });
  }
  if (has('ventas') || has('facturas')) {
    allApps.push({ id: 'ventas', name: 'Ventas', icon: <ShoppingCartIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/ventas', bgColor: '#3498DB' });
  }
  if (has('compras') || has('cxp')) {
    allApps.push({ id: 'compras', name: 'Compras', icon: <LocalShippingIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/compras', bgColor: '#F39C12' });
  }
  if (has('pos')) {
    allApps.push({ id: 'pos', name: 'Punto de Venta', icon: <PointOfSaleIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/pos/facturacion', bgColor: '#9B59B6' });
  }
  if (has('restaurante')) {
    allApps.push({ id: 'restaurante', name: isSmall ? 'Rest.' : 'Restaurante', icon: <RestaurantIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/restaurante', bgColor: '#E84393' });
  }
  if (has('ecommerce')) {
    allApps.push({ id: 'ecommerce', name: 'E-Commerce', icon: <LanguageIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/ecommerce', bgColor: '#0984E3' });
  }
  if (has('auditoria')) {
    allApps.push({ id: 'auditoria', name: isSmall ? 'Audit.' : 'Auditoría', icon: <ContentPasteSearchIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/auditoria', bgColor: '#2D3436' });
  }

  // Nuevos módulos
  allApps.push({ id: 'logistica', name: isSmall ? 'Logíst.' : 'Logística', icon: <LocalShippingIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/logistica', bgColor: '#1ABC9C' });
  allApps.push({ id: 'crm', name: 'CRM', icon: <GroupsIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/crm', bgColor: '#E74C3C' });
  allApps.push({ id: 'manufactura', name: isSmall ? 'Manuf.' : 'Manufactura', icon: <PrecisionManufacturingIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/manufactura', bgColor: '#8E44AD' });
  allApps.push({ id: 'flota', name: 'Flota', icon: <DirectionsCarIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/flota', bgColor: '#2C3E50' });

  // Siempre agregar App Store y Settings al final
  allApps.push({ id: 'apps', name: isSmall ? 'Apps' : 'Aplicaciones', icon: <AppsIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/aplicaciones', bgColor: '#E74C3C' });
  if (isAdmin) {
    allApps.push({ id: 'settings', name: 'Ajustes', icon: <SettingsIcon sx={{ fontSize: 'inherit', color: '#fff' }} />, path: '/configuracion', bgColor: '#7F8C8D' });
  }

  return (
    <Box sx={{ minHeight: '100%', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', p: { xs: 2, md: 8 }, background: 'linear-gradient(to right bottom, #f3f4f6, #e5e7eb)' }}>
      <Box sx={{ width: '100%', maxWidth: 1200, mt: 5 }}>
        {isAdmin && <Box sx={{ width: '100%', p: 2, mb: 4, bgcolor: '#eff6ff', color: '#1e40af', borderRadius: 2, border: '1px solid #bfdbfe', textAlign: 'center' }}>
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
                  borderRadius: 4,
                  p: 2,
                  '&:hover .app-avatar': {
                    transform: 'translateY(-5px)',
                    boxShadow: '0 10px 20px -3px rgba(0, 0, 0, 0.2)',
                  },
                }}
              >
                <Avatar
                  variant="circular"
                  className="app-avatar"
                  sx={{
                    width: 80,
                    height: 80,
                    fontSize: 40,
                    '@media (max-width: 1200px)': { width: 68, height: 68, fontSize: 34 },
                    '@media (max-width: 900px)': { width: 56, height: 56, fontSize: 28 },
                    '@media (max-width: 700px)': { width: 32, height: 32, fontSize: 16 },
                    bgcolor: app.bgColor,
                    mb: 1.5,
                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)',
                    transition: 'all 0.2s',
                  }}
                >
                  {app.icon}
                </Avatar>
                <Typography variant="body2" sx={{ fontWeight: 600, color: '#374151', textAlign: 'center' }}>
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
