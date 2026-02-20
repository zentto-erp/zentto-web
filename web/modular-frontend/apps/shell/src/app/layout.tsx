'use client';

import * as React from 'react';
import { Suspense, useEffect, useMemo, useState } from 'react';
import { AppProvider } from '@toolpad/core/nextjs';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import type { Navigation } from '@toolpad/core/AppProvider';
import { SessionProvider, signIn, signOut, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@datqbox/shared-auth';
import type { SystemModule } from '@datqbox/shared-auth';
import { QueryProvider } from '@datqbox/shared-api';
import {
  AppBarWrapper,
  AppTitle,
  LoadingFallback,
  ToastProvider,
  LocalizationProviderWrapper,
  Copyright,
  theme,
} from '@datqbox/shared-ui';
import '@datqbox/shared-ui/globals.css';

import DashboardIcon from '@mui/icons-material/Dashboard';
import InventoryIcon from '@mui/icons-material/Inventory';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import PaymentIcon from '@mui/icons-material/Payment';
import PeopleIcon from '@mui/icons-material/People';
import SettingsIcon from '@mui/icons-material/Settings';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import PaymentsIcon from '@mui/icons-material/Payments';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import BadgeIcon from '@mui/icons-material/Badge';
import ManageAccountsIcon from '@mui/icons-material/ManageAccounts';

// Navigation

/** Check if a user has access to a given module */
function has(modulos: string[], mod: SystemModule): boolean {
  return modulos.includes(mod);
}

export function buildNavigation(isAdmin: boolean, modulos: string[], pathname: string): any[] {
  const nav: any[] = [];

  // If we are on the App Selector, show no menus in the top bar
  if (pathname === '/' || pathname === '/aplicaciones') {
    return nav;
  }

  // Helper
  const isApp = (appPath: string) => pathname.startsWith(appPath);

  // App: Contabilidad
  if (has(modulos, 'contabilidad') && isApp('/contabilidad')) {
    nav.push({ kind: 'page', segment: 'contabilidad', title: 'Dashboard', icon: <AccountBalanceWalletIcon /> });
    nav.push({ kind: 'page', segment: 'contabilidad/asientos', title: 'Asientos', icon: <AccountBalanceWalletIcon /> });
    nav.push({ kind: 'page', segment: 'contabilidad/cuentas', title: 'Plan de Cuentas', icon: <AccountBalanceWalletIcon /> });
    nav.push({ kind: 'page', segment: 'contabilidad/reportes', title: 'Reportes', icon: <AccountBalanceWalletIcon /> });
    return nav;
  }

  // App: Nómina
  if (has(modulos, 'nomina') && isApp('/nomina')) {
    nav.push({ kind: 'page', segment: 'nomina', title: 'Dashboard', icon: <BadgeIcon /> });
    nav.push({ kind: 'page', segment: 'nomina/nominas', title: 'Nóminas', icon: <BadgeIcon /> });
    nav.push({ kind: 'page', segment: 'nomina/conceptos', title: 'Conceptos', icon: <BadgeIcon /> });
    nav.push({ kind: 'page', segment: 'nomina/vacaciones', title: 'Vacaciones', icon: <BadgeIcon /> });
    nav.push({ kind: 'page', segment: 'nomina/liquidaciones', title: 'Liquidaciones', icon: <BadgeIcon /> });
    nav.push({ kind: 'page', segment: 'nomina/constantes', title: 'Constantes', icon: <BadgeIcon /> });
    return nav;
  }

  // App: Bancos
  if (has(modulos, 'bancos') && isApp('/bancos')) {
    nav.push({ kind: 'page', segment: 'bancos', title: 'Dashboard', icon: <AccountBalanceIcon /> });
    nav.push({ kind: 'page', segment: 'bancos/cuentas', title: 'Cuentas y Movimientos', icon: <AccountBalanceIcon /> });
    nav.push({ kind: 'page', segment: 'bancos/conciliaciones', title: 'Conciliación Bancaria', icon: <AccountBalanceIcon /> });
    return nav;
  }

  // App: Inventario
  if ((has(modulos, 'inventario') || has(modulos, 'articulos')) && isApp('/inventario')) {
    nav.push({ kind: 'page', segment: 'inventario', title: 'Dashboard', icon: <InventoryIcon /> });
    nav.push({ kind: 'page', segment: 'articulos', title: 'Maestro de Artículos', icon: <InventoryIcon /> });
    nav.push({ kind: 'page', segment: 'inventario/marcas', title: 'Marcas', icon: <InventoryIcon /> });
    nav.push({ kind: 'page', segment: 'inventario/categorias', title: 'Categorías', icon: <InventoryIcon /> });
    nav.push({ kind: 'page', segment: 'inventario/clases', title: 'Clases', icon: <InventoryIcon /> });
    nav.push({ kind: 'page', segment: 'inventario/tipos', title: 'Tipos', icon: <InventoryIcon /> });
    return nav;
  }

  // App: Ventas y CxC
  const hasVentas = has(modulos, 'facturas') || has(modulos, 'abonos') || has(modulos, 'cxc') || has(modulos, 'clientes');
  if (hasVentas && isApp('/ventas')) {
    nav.push({ kind: 'page', segment: 'ventas', title: 'Dashboard', icon: <PaymentIcon /> });
    if (has(modulos, 'facturas')) nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <PaymentIcon /> });
    if (has(modulos, 'abonos')) nav.push({ kind: 'page', segment: 'abonos', title: 'Abonos', icon: <PaymentsIcon /> });
    if (has(modulos, 'cxc')) nav.push({ kind: 'page', segment: 'cxc', title: 'Cuentas por Cobrar (CxC)', icon: <PaymentsIcon /> });
    if (has(modulos, 'clientes')) nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
    return nav;
  }

  // App: Compras y CxP
  const hasCompras = has(modulos, 'compras') || has(modulos, 'cuentas-por-pagar') || has(modulos, 'pagos') || has(modulos, 'cxp') || has(modulos, 'proveedores');
  if (hasCompras && isApp('/compras')) {
    nav.push({ kind: 'page', segment: 'compras', title: 'Dashboard', icon: <LocalShippingIcon /> });
    if (has(modulos, 'compras')) nav.push({ kind: 'page', segment: 'compras', title: 'Compras', icon: <LocalShippingIcon /> });
    if (has(modulos, 'cuentas-por-pagar')) nav.push({ kind: 'page', segment: 'cuentas-por-pagar', title: 'Cuentas por Pagar', icon: <AccountBalanceIcon /> });
    if (has(modulos, 'pagos')) nav.push({ kind: 'page', segment: 'pagos', title: 'Pagos', icon: <PaymentIcon /> });
    if (has(modulos, 'cxp')) nav.push({ kind: 'page', segment: 'cxp', title: 'Pagos CxP', icon: <PaymentsIcon /> });
    if (has(modulos, 'proveedores')) nav.push({ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <PeopleIcon /> });
    return nav;
  }

  // App: Configuración Central (Ajustes) y Maestros
  if (isAdmin && isApp('/configuracion')) {
    nav.push({ kind: 'page', segment: 'configuracion', title: 'Ajustes Generales', icon: <SettingsIcon /> });
    if (has(modulos, 'usuarios')) {
      nav.push({ kind: 'page', segment: 'usuarios', title: 'Usuarios', icon: <ManageAccountsIcon /> });
    }
    nav.push({ kind: 'page', segment: 'maestros/correlativo', title: 'Correlativos', icon: <SettingsIcon /> });
    nav.push({ kind: 'page', segment: 'maestros/empresa', title: 'Empresa', icon: <SettingsIcon /> });
    nav.push({ kind: 'page', segment: 'maestros/feriados', title: 'Feriados', icon: <SettingsIcon /> });
    nav.push({ kind: 'page', segment: 'maestros/monedas', title: 'Monedas', icon: <SettingsIcon /> });
    nav.push({ kind: 'page', segment: 'maestros/tasa-moneda', title: 'Tasa Moneda', icon: <SettingsIcon /> });
    nav.push({ kind: 'page', segment: 'empleados', title: 'Empleados', icon: <PeopleIcon /> });
    return nav;
  }

  return nav;
}

const AUTHENTICATION = { signIn, signOut };

// Inner App (has access to session + auth)
function AppContent({ children }: { children: React.ReactNode }) {
  const { data: session } = useSession();
  const { isLoading, isAdmin, modulos } = useAuth();
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    if (!isLoading) {
      const t = setTimeout(() => setShowContent(true), 100);
      return () => clearTimeout(t);
    }
  }, [isLoading]);

  const navigation = useMemo(() => buildNavigation(isAdmin, modulos), [isAdmin, modulos]);

  if (isLoading) {
    return <LoadingFallback />;
  }

  return (
    <AppProvider
      theme={theme}
      navigation={navigation}
      session={session ?? undefined}
      authentication={AUTHENTICATION}
      branding={{
        logo: <AppTitle />,
        title: '',
      }}
    >
      <AppBarWrapper>
        {!showContent ? (
          <LoadingFallback />
        ) : (
          <ToastProvider>
            <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
          </ToastProvider>
        )}
      </AppBarWrapper>
    </AppProvider>
  );
}

// Root Layout
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es" data-toolpad-color-scheme="light" suppressHydrationWarning>
      <head>
        <title>DatqBox Web</title>
      </head>
      <body>
        <SessionProvider>
          <QueryProvider>
            <AuthProvider>
              <AppRouterCacheProvider options={{ enableCssLayer: true }}>
                <LocalizationProviderWrapper>
                  <AppContent>{children}</AppContent>
                </LocalizationProviderWrapper>
              </AppRouterCacheProvider>
            </AuthProvider>
          </QueryProvider>
        </SessionProvider>
      </body>
    </html>
  );
}
