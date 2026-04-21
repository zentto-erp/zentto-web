'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider, useHydrateLocalizacion } from '@zentto/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    BrandedThemeProvider,
    ZenttoLayout,
    ZenttoChatWidget,
    useIsDesktop
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildPosNav } from './nav';

/**
 * Componente interno que maneja la lógica de autenticación y renderiza
 * el layout con navegación POS
 */
function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos, company } = useAuth();
    const [showContent, setShowContent] = useState(false);
    const isDesktop = useIsDesktop();

    // Hidratar localización desde BD al arrancar
    useHydrateLocalizacion('pos', company?.companyId ?? 1);

    useEffect(() => {
        if (!isLoading) {
            const t = setTimeout(() => setShowContent(true), 100);
            return () => clearTimeout(t);
        }
    }, [isLoading]);

    const navigation = React.useMemo(() => buildPosNav(isAdmin, modulos), [isAdmin, modulos]);

    if (isLoading) {
        return <LoadingFallback />;
    }

    if (isDesktop) {
        return (
            <ToastProvider>
                <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
            </ToastProvider>
        );
    }

    return (
        <AppBarWrapper>
            {!showContent ? (
                <LoadingFallback />
            ) : (
                <ToastProvider>
                    <ZenttoLayout navigationFields={navigation}>
                        <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
                    </ZenttoLayout>
                </ToastProvider>
            )}
        </AppBarWrapper>
    );
}

/**
 * Root Layout del módulo POS
 * Configura providers de autenticación, query, theming y layout Odoo
 */
export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>POS - Punto de Venta - Zentto App</title>
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
                <meta name="description" content="Sistema de Punto de Venta Zentto - Facturación rápida y gestión de caja" />
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/pos/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            
                                <BrandedThemeProvider defaultMode="system">
                                    <CssBaseline />
                                    <LocalizationProviderWrapper>
                                        <AppContent>{children}</AppContent>
                                        <ZenttoChatWidget />
                                    </LocalizationProviderWrapper>
                                </BrandedThemeProvider>
                            
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
