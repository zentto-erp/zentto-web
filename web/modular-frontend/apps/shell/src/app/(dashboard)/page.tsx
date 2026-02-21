'use client';

import React from 'react';
import { Box, Typography, ButtonBase, useTheme, Avatar } from '@mui/material';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useAuth } from '@datqbox/shared-auth';

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

  const has = (mod: string) => isAdmin || modulos.includes(mod);

  const navigateToApp = (path: string) => {
    const localPaths = ['/aplicaciones', '/configuracion', '/docs', '/soporte', '/info'];
    if (localPaths.includes(path)) {
      router.push(path);
      return;
    }
    window.location.assign(path);
  };

  // Todas las apps disponibles
  const allApps: AppShortcut[] = [];

  if (has('contabilidad')) {
    allApps.push({ id: 'contabilidad', name: 'Contabilidad', icon: <AccountBalanceWalletIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/contabilidad', bgColor: '#875A7B' });
  }
  if (has('nomina')) {
    allApps.push({ id: 'nomina', name: 'Nómina', icon: <BadgeIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/nomina', bgColor: '#00A09D' });
  }
  if (has('bancos')) {
    allApps.push({ id: 'bancos', name: 'Bancos e Inst.', icon: <AccountBalanceIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/bancos', bgColor: '#E67E22' });
  }
  if (has('inventario') || has('articulos')) {
    allApps.push({ id: 'inventario', name: 'Inventario', icon: <StorefrontIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/inventario', bgColor: '#27AE60' });
  }
  if (has('ventas') || has('facturas')) {
    allApps.push({ id: 'ventas', name: 'Ventas', icon: <ShoppingCartIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/ventas', bgColor: '#3498DB' });
  }
  if (has('compras') || has('cxp')) {
    allApps.push({ id: 'compras', name: 'Compras', icon: <LocalShippingIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/compras', bgColor: '#F39C12' });
  }
  if (has('pos')) {
    allApps.push({ id: 'pos', name: 'Punto de Venta', icon: <PointOfSaleIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/pos', bgColor: '#9B59B6' });
  }
  if (has('restaurante')) {
    allApps.push({ id: 'restaurant', name: 'Restaurante', icon: <RestaurantIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/restaurante', bgColor: '#E84393' });
  }
  if (has('ecommerce')) {
    allApps.push({ id: 'ecommerce', name: 'E-Commerce', icon: <LanguageIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/ecommerce', bgColor: '#0984E3' });
  }
  if (has('auditoria')) {
    allApps.push({ id: 'auditoria', name: 'Auditoría', icon: <ContentPasteSearchIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/auditoria', bgColor: '#2D3436' });
  }

  // Siempre agregar App Store y Settings al final
  allApps.push({ id: 'apps', name: 'Aplicaciones', icon: <AppsIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/aplicaciones', bgColor: '#E74C3C' });
  if (isAdmin) {
    allApps.push({ id: 'settings', name: 'Ajustes', icon: <SettingsIcon sx={{ fontSize: 40, color: '#fff' }} />, path: '/configuracion', bgColor: '#7F8C8D' });
  }

  return (
    <Box sx={{ minHeight: '100%', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', p: { xs: 2, md: 8 }, background: 'linear-gradient(to right bottom, #f3f4f6, #e5e7eb)' }}>
      <Box sx={{ width: '100%', maxWidth: 1200, mt: 5 }}>
        {isAdmin && <Box sx={{ width: '100%', p: 2, mb: 4, bgcolor: '#fdf2f8', color: '#831843', borderRadius: 2, border: '1px solid #fbcfe8', textAlign: 'center' }}>
          <Typography variant="body2" sx={{ fontWeight: 600 }}>⚙️ Modo Administrador de Sistema activado. Tienes acceso a todas las aplicaciones.</Typography>
        </Box>}

        <Grid container spacing={4} justifyContent="center">
          {allApps.map((app) => (
            <Grid key={app.id} size={{ xs: 4, sm: 3, md: 2 }} sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <ButtonBase
                onClick={() => navigateToApp(app.path)}
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  borderRadius: 4,
                  p: 2,
                  transition: 'all 0.2s',
                  '&:hover': {
                    transform: 'translateY(-5px)',
                    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
                  }
                }}
              >
                <Avatar
                  variant="rounded"
                  sx={{
                    width: 80,
                    height: 80,
                    bgcolor: app.bgColor,
                    mb: 1.5,
                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)'
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
