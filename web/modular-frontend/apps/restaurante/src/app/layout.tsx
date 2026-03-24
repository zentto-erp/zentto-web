'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { SessionProvider } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider, useHydrateLocalizacion } from '@zentto/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    OdooLayout,
    theme
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildRestauranteNav } from './nav';

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos, company } = useAuth();
    const [showContent, setShowContent] = useState(false);

    // Hidratar localización desde BD al arrancar
    useHydrateLocalizacion('restaurante', company?.companyId ?? 1);

    useEffect(() => {
        if (!isLoading) {
            const t = setTimeout(() => setShowContent(true), 100);
            return () => clearTimeout(t);
        }
    }, [isLoading]);

    const navigation = React.useMemo(() => buildRestauranteNav(isAdmin, modulos), [isAdmin, modulos]);

    if (isLoading) {
        return <LoadingFallback />;
    }

    return (
        <AppBarWrapper>
            {!showContent ? (
                <LoadingFallback />
            ) : (
                <ToastProvider>
                    <OdooLayout navigationFields={navigation}>
                        <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
                    </OdooLayout>
                </ToastProvider>
            )}
        </AppBarWrapper>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" data-toolpad-color-scheme="light" suppressHydrationWarning>
            <head>
                <title>Restaurante - Zentto App</title>
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
            </head>
            <body>
                <SessionProvider basePath="/restaurante/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            <AppRouterCacheProvider>
                                <ThemeProvider theme={theme} defaultMode="system">
                                    <CssBaseline />
                                    <LocalizationProviderWrapper>
                                        <AppContent>{children}</AppContent>
                                    </LocalizationProviderWrapper>
                                </ThemeProvider>
                            </AppRouterCacheProvider>
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
