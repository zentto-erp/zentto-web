'use client';

import * as React from 'react';
import { AppProvider } from '@toolpad/core/nextjs';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import type { Navigation } from '@toolpad/core/AppProvider';
import { SessionProvider, signIn, signOut, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@/app/authentication/AuthContext';
import AppBarWrapper from '@/app/(dashboard)/AppBarWrapper';
import AppTitle from '@/app/(dashboard)/AppTitle';
import QueryProvider from '@/app/providers/QueryProvider';
import ToastProvider from '@/providers/ToastProvider';
import LocalizationProviderWrapper from '@/providers/LocalizationProviderWrapper';
import { getMenuItems } from '@/lib/menuConfig';
import type { MenuItem } from '@/lib/menuConfig';
import { Suspense, useEffect, useState } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import theme from '../../theme';
import '@/app/globals.css';

function LoadingFallback() {
  const [showMessage, setShowMessage] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setShowMessage(true), 500);
    return () => clearTimeout(t);
  }, []);
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: 'calc(100vh - 64px)',
        width: '100%',
        backgroundColor: 'background.default',
      }}
    >
      <CircularProgress size={40} />
      {showMessage && (
        <Typography variant="body1" sx={{ mt: 2, color: 'text.secondary', textAlign: 'center' }}>
          Cargando...
        </Typography>
      )}
    </Box>
  );
}

const AUTHENTICATION = { signIn, signOut };

function menuItemToNav(item: MenuItem): Navigation[0] {
  const segment = item.href != null ? item.href.replace(/^\//, '') : '';
  const Icon = item.icon;
  const iconNode = Icon ? React.createElement(Icon) : undefined;
  if (item.children?.length) {
    return {
      kind: 'page',
      title: item.title,
      segment: segment || undefined,
      icon: iconNode,
      children: item.children.map((c) => menuItemToNav(c)) as any,
    } as const;
  }
  return {
    kind: 'page',
    segment: segment || '',
    title: item.title,
    icon: iconNode,
  } as const;
}

function buildNavigation(isAdmin: boolean): Navigation {
  const items = getMenuItems(isAdmin);
  const nav: Navigation = [
    { kind: 'header', title: 'Navegación' } as const,
    { kind: 'divider' } as const,
    ...items.map((item) => menuItemToNav(item)),
  ];
  return nav;
}

function AppContent({ children }: { children: React.ReactNode }) {
  const { data: session } = useSession();
  const { isLoading, isAdmin } = useAuth();
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    if (!isLoading) {
      const t = setTimeout(() => setShowContent(true), 100);
      return () => clearTimeout(t);
    }
  }, [isLoading]);

  const navigation = React.useMemo(() => buildNavigation(isAdmin), [isAdmin]);

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
        <LoadingFallback />
      </Box>
    );
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
