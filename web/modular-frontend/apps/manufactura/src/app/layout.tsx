'use client';

import * as React from 'react';
import Script from 'next/script';
import { Suspense, useEffect, useState } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider, useHydrateModuleSettings } from '@zentto/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    BrandedThemeProvider,
    ZenttoLayout
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildNav } from './nav';

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos, company } = useAuth();
    const [showContent, setShowContent] = useState(false);

    // Hidratar configuracion general + manufactura desde BD al arrancar
    useHydrateModuleSettings('manufactura', company?.companyId ?? 1);

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
                    <ZenttoLayout navigationFields={navigation} appCode="manufactura">
                        <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
                    </ZenttoLayout>
                </ToastProvider>
            )}
        </AppBarWrapper>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>Manufactura - Zentto App</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/manufactura/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            
                                <BrandedThemeProvider defaultMode="system">
                                    <CssBaseline />
                                    <LocalizationProviderWrapper>
                                        <AppContent>{children}</AppContent>
                                        <Script src="https://docs.zentto.net/widget.js" strategy="afterInteractive" />
                                    </LocalizationProviderWrapper>
                                </BrandedThemeProvider>
                            
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
