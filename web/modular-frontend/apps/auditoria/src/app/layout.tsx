'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider } from '@zentto/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    BrandedThemeProvider,
    OdooLayout
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildNav } from './nav';

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos } = useAuth();
    const [showContent, setShowContent] = useState(false);

    useEffect(() => {
        if (!isLoading) {
            const t = setTimeout(() => setShowContent(true), 100);
            return () => clearTimeout(t);
        }
    }, [isLoading]);

    const navigation = React.useMemo(() => buildNav(isAdmin, modulos), [isAdmin, modulos]);

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
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>Auditoría Fiscal - Zentto App</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/auditoria/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            
                                <BrandedThemeProvider defaultMode="system">
                                    <CssBaseline />
                                    <LocalizationProviderWrapper>
                                        <AppContent>{children}</AppContent>
                                    </LocalizationProviderWrapper>
                                </BrandedThemeProvider>
                            
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
