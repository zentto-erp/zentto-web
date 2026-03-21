'use client';

import * as React from 'react';
import { Suspense, useEffect, useMemo, useState } from 'react';
import { usePathname } from 'next/navigation';
import { AppProvider } from '@toolpad/core/nextjs';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { createTheme } from '@mui/material/styles';
import { SessionProvider, signIn, signOut, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider } from '@zentto/shared-api';
import {
  AppBarWrapper,
  AppTitle,
  LoadingFallback,
  ToastProvider,
  LocalizationProviderWrapper,
  brandColors,
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildNavigation } from '../lib/navigation';
import { HardwareAgentBanner } from '../components/HardwareAgentBanner';

const AUTHENTICATION = { signIn, signOut };
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';
const ZENTTO_DOMAINS = new Set(['app.zentto.net', 'www.zentto.net', 'zentto.net']);
const shellTheme = createTheme({
  palette: {
    primary: { main: brandColors.accent, light: '#ffad33', dark: '#e68a00', contrastText: brandColors.dark },
    secondary: { main: brandColors.darkSecondary, light: '#37475a', dark: brandColors.dark, contrastText: '#fff' },
    background: { default: brandColors.bgPage, paper: brandColors.bgCard },
    text: { primary: brandColors.textDark, secondary: brandColors.textMuted },
  },
  breakpoints: {
    values: { xs: 0, sm: 600, md: 600, lg: 1200, xl: 1536 },
  },
  typography: {
    fontFamily: [
      'Inter',
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    button: {
      textTransform: 'none',
      fontWeight: 500,
    },
    h6: {
      fontWeight: 600,
      fontSize: '1.125rem',
    },
  },
});

// Valida que el subdominio actual exista en BD. Si no, redirige a zentto.net.
function TenantGuard({ children }: { children: React.ReactNode }) {
  const [ok, setOk] = useState<boolean | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const host = window.location.hostname;
    const isSubdomain = host.endsWith('.zentto.net') && !ZENTTO_DOMAINS.has(host);
    if (!isSubdomain) { setOk(true); return; }
    const subdomain = host.replace('.zentto.net', '');
    fetch(`${API_BASE}/api/tenants/resolve/${subdomain}`)
      .then(r => {
        if (!r.ok) { window.location.href = 'https://zentto.net'; return; }
        setOk(true);
      })
      .catch(() => { window.location.href = 'https://zentto.net'; });
  }, []);

  if (ok === null) return null;
  return <>{children}</>;
}

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
      theme={shellTheme}
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
    <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
      <head>
        <title>Zentto</title>
      </head>
      <body>
        <SessionProvider>
          <QueryProvider>
            <AuthProvider>
              <AppRouterCacheProvider options={{ enableCssLayer: true }}>
                <LocalizationProviderWrapper>
                  <TenantGuard>
                    <AppContent>{children}</AppContent>
                  </TenantGuard>
                </LocalizationProviderWrapper>
              </AppRouterCacheProvider>
            </AuthProvider>
          </QueryProvider>
        </SessionProvider>
      </body>
    </html>
  );
}
