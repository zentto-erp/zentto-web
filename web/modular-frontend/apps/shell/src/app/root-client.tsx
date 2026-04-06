'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { SessionProvider } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider } from '@zentto/shared-api';
import CssBaseline from '@mui/material/CssBaseline';
import {
  LoadingFallback,
  ToastProvider,
  LocalizationProviderWrapper,
  BrandedThemeProvider,
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';
import { I18nProvider } from '@zentto/shared-i18n';

import { HardwareAgentBanner } from '../components/HardwareAgentBanner';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';
const ZENTTO_DOMAINS = new Set([
  'app.zentto.net', 'www.zentto.net', 'zentto.net',
  'appdev.zentto.net',
  'localhost',
]);

function TenantGuard({ children }: { children: React.ReactNode }) {
  const [ok, setOk] = useState<boolean | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const host = window.location.hostname;
    const isSubdomain = host.endsWith('.zentto.net') && !ZENTTO_DOMAINS.has(host);

    if (!isSubdomain) {
      // Dominio conocido: limpiar tenant data previo
      localStorage.removeItem('zentto-tenant');
      setOk(true);
      return;
    }

    const subdomain = host.replace('.zentto.net', '');
    fetch(`${API_BASE}/api/tenants/resolve/${subdomain}`)
      .then(r => {
        if (!r.ok) { window.location.href = 'https://zentto.net'; return; }
        return r.json();
      })
      .then(data => {
        if (!data) return;
        // Almacenar tenant resuelto para que authHeader() lo envíe
        localStorage.setItem('zentto-tenant', JSON.stringify({
          companyId: data.CompanyId,
          slug: subdomain,
          name: data.LegalName || data.CompanyCode || subdomain,
        }));
        setOk(true);
      })
      .catch(() => { window.location.href = 'https://zentto.net'; });
  }, []);

  if (ok === null) return null;
  return <>{children}</>;
}

function AppContent({ children }: { children: React.ReactNode }) {
  const { isLoading, modulos } = useAuth();
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    if (!isLoading) {
      const t = setTimeout(() => setShowContent(true), 100);
      return () => clearTimeout(t);
    }
  }, [isLoading]);

  if (isLoading) return <LoadingFallback />;

  return (
    <>
      <HardwareAgentBanner modulos={modulos} />
      {!showContent ? (
        <LoadingFallback />
      ) : (
        <ToastProvider>
          <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
        </ToastProvider>
      )}
    </>
  );
}

export default function RootClient({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider>
      <QueryProvider>
        <AuthProvider>
          <AppRouterCacheProvider>
            <BrandedThemeProvider defaultMode="system">
              <CssBaseline />
              <I18nProvider defaultLocale="es">
                <LocalizationProviderWrapper>
                  <TenantGuard>
                    <AppContent>{children}</AppContent>
                  </TenantGuard>
                </LocalizationProviderWrapper>
              </I18nProvider>
            </BrandedThemeProvider>
          </AppRouterCacheProvider>
        </AuthProvider>
      </QueryProvider>
    </SessionProvider>
  );
}
