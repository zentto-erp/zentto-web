'use client';

import * as React from 'react';
import { Suspense, useEffect, useMemo, useState } from 'react';
import { usePathname } from 'next/navigation';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { AppProvider } from '@toolpad/core/nextjs';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { SessionProvider, signIn, signOut, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider } from '@zentto/shared-api';
import {
  AppBarWrapper,
  AppTitle,
  LoadingFallback,
  ToastProvider,
  LocalizationProviderWrapper,
  theme,
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildNavigation } from '../lib/navigation';
import { HardwareAgentBanner } from '../components/HardwareAgentBanner';

const AUTHENTICATION = { signIn, signOut };

// Inner App (has access to session + auth)
function AppContent({ children }: { children: React.ReactNode }) {
  const { data: session } = useSession();
  const { isLoading, isAdmin, modulos } = useAuth();
  const [showContent, setShowContent] = useState(false);
  const pathname = usePathname() || '/';

  useEffect(() => {
    if (!isLoading) {
      const t = setTimeout(() => setShowContent(true), 100);
      return () => clearTimeout(t);
    }
  }, [isLoading]);

  const navigation = useMemo(() => buildNavigation(isAdmin, modulos, pathname), [isAdmin, modulos, pathname]);

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
      <HardwareAgentBanner modulos={modulos} />
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
    <html lang="es" suppressHydrationWarning>
      <head>
        <title>Zentto</title>
        <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
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
