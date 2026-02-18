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
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import PaymentsIcon from '@mui/icons-material/Payments';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import BadgeIcon from '@mui/icons-material/Badge';
import ManageAccountsIcon from '@mui/icons-material/ManageAccounts';

// ─── Navigation ───────────────────────────────────────────────

/** Check if a user has access to a given module */
function has(modulos: string[], mod: SystemModule): boolean {
  return modulos.includes(mod);
}

function buildNavigation(isAdmin: boolean, modulos: string[]): Navigation {
  const nav: Navigation = [
    { kind: 'header', title: 'Principal' },
    { kind: 'page', segment: '', title: 'Dashboard', icon: <DashboardIcon /> },
  ];

  // ── Business modules (flat — different top-level routes) ──
  const hasAnyBusiness =
    has(modulos, 'facturas') || has(modulos, 'compras') ||
    has(modulos, 'cuentas-por-pagar') || has(modulos, 'pagos') ||
    has(modulos, 'cxc') || has(modulos, 'cxp') || has(modulos, 'abonos');

  if (hasAnyBusiness) {
    nav.push({ kind: 'header', title: 'Módulos de Negocio' });
    if (has(modulos, 'facturas'))
      nav.push({ kind: 'page', segment: 'facturas', title: 'Facturas', icon: <PaymentIcon /> });
    if (has(modulos, 'compras'))
      nav.push({ kind: 'page', segment: 'compras', title: 'Compras', icon: <LocalShippingIcon /> });
    if (has(modulos, 'cuentas-por-pagar'))
      nav.push({ kind: 'page', segment: 'cuentas-por-pagar', title: 'Cuentas por Pagar', icon: <AccountBalanceIcon /> });
    if (has(modulos, 'pagos'))
      nav.push({ kind: 'page', segment: 'pagos', title: 'Pagos', icon: <PaymentIcon /> });
    if (has(modulos, 'abonos'))
      nav.push({ kind: 'page', segment: 'abonos', title: 'Abonos', icon: <PaymentsIcon /> });
    if (has(modulos, 'cxc'))
      nav.push({ kind: 'page', segment: 'cxc', title: 'Cobros CxC', icon: <PaymentsIcon />,
        children: [{ kind: 'page', segment: 'new', title: 'Nuevo Cobro CxC', icon: <PaymentsIcon /> }] as any,
      } as any);
    if (has(modulos, 'cxp'))
      nav.push({ kind: 'page', segment: 'cxp', title: 'Pagos CxP', icon: <PaymentsIcon />,
        children: [{ kind: 'page', segment: 'new', title: 'Nuevo Pago CxP', icon: <PaymentsIcon /> }] as any,
      } as any);
  }

  // ── Standalone pages (flat) ──
  const hasAnyStandalone =
    has(modulos, 'inventario') || has(modulos, 'proveedores') ||
    has(modulos, 'articulos') || has(modulos, 'clientes');

  if (hasAnyStandalone) {
    nav.push({ kind: 'header', title: 'Catálogos' });
    if (has(modulos, 'clientes'))
      nav.push({ kind: 'page', segment: 'clientes', title: 'Clientes', icon: <PeopleIcon /> });
    if (has(modulos, 'proveedores'))
      nav.push({ kind: 'page', segment: 'proveedores', title: 'Proveedores', icon: <PeopleIcon /> });
    if (has(modulos, 'articulos'))
      nav.push({ kind: 'page', segment: 'articulos', title: 'Artículos', icon: <InventoryIcon /> });
    if (has(modulos, 'inventario'))
      nav.push({ kind: 'page', segment: 'inventario', title: 'Inventario', icon: <InventoryIcon /> });
  }

  // ── Bancos group (nested under /bancos/) ──
  if (has(modulos, 'bancos')) {
    nav.push({
      kind: 'page', segment: 'bancos', title: 'Bancos', icon: <AccountBalanceIcon />,
      children: [
        { kind: 'page', segment: 'cuentas', title: 'Cuentas y Mov. Bancarios', icon: <AccountBalanceIcon /> },
        { kind: 'page', segment: 'conciliaciones', title: 'Conciliación Bancaria', icon: <AccountBalanceIcon /> },
      ] as any,
    } as any);
  }

  // ── Contabilidad group (nested under /contabilidad/) ──
  if (has(modulos, 'contabilidad')) {
    nav.push({
      kind: 'page', segment: 'contabilidad', title: 'Contabilidad', icon: <AccountBalanceWalletIcon />,
      children: [
        { kind: 'page', segment: 'asientos', title: 'Asientos', icon: <AccountBalanceWalletIcon /> },
        { kind: 'page', segment: 'cuentas', title: 'Plan de Cuentas', icon: <AccountBalanceWalletIcon /> },
        { kind: 'page', segment: 'reportes', title: 'Reportes', icon: <AccountBalanceWalletIcon /> },
      ] as any,
    } as any);
  }

  // ── Nómina group (nested under /nomina/) ──
  if (has(modulos, 'nomina')) {
    nav.push({
      kind: 'page', segment: 'nomina', title: 'Nómina', icon: <BadgeIcon />,
      children: [
        { kind: 'page', segment: 'nominas', title: 'Nóminas', icon: <BadgeIcon /> },
        { kind: 'page', segment: 'conceptos', title: 'Conceptos', icon: <BadgeIcon /> },
        { kind: 'page', segment: 'vacaciones', title: 'Vacaciones', icon: <BadgeIcon /> },
        { kind: 'page', segment: 'liquidaciones', title: 'Liquidaciones', icon: <BadgeIcon /> },
        { kind: 'page', segment: 'constantes', title: 'Constantes', icon: <BadgeIcon /> },
      ] as any,
    } as any);
  }

  // ── Administration (admin only, nested under /configuracion/) ──
  if (isAdmin) {
    nav.push({ kind: 'header', title: 'Administración' });
    const adminChildren: any[] = [];
    if (has(modulos, 'usuarios')) {
      adminChildren.push({ kind: 'page', segment: 'usuarios', title: 'Usuarios', icon: <ManageAccountsIcon /> });
    }
    nav.push({
      kind: 'page', segment: 'configuracion', title: 'Configuración', icon: <SettingsIcon />,
      children: adminChildren,
    } as any);
  }

  return nav;
}

const AUTHENTICATION = { signIn, signOut };

// ─── Inner App (has access to session + auth) ─────────────────
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

// ─── Root Layout ──────────────────────────────────────────────
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
