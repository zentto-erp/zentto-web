'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
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
    OdooLayout,
    type CommandSection
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

import { buildNav } from './nav';
import QuickCreateProvider, { useQuickCreate } from './QuickCreateProvider';

function AppShell({
    children,
    showContent,
    navigation,
}: {
    children: React.ReactNode;
    showContent: boolean;
    navigation: Array<Record<string, unknown>>;
}) {
    const qc = useQuickCreate();
    return (
        <AppBarWrapper
            paletteStaticSections={qc.sections as CommandSection[]}
            palettePlaceholder="Crear, navegar, buscar… (Ctrl+K)"
        >
            {!showContent ? (
                <LoadingFallback />
            ) : (
                <OdooLayout navigationFields={navigation}>
                    <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
                </OdooLayout>
            )}
        </AppBarWrapper>
    );
}

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos, company } = useAuth();
    const [showContent, setShowContent] = useState(false);

    // Hidratar configuración general + crm desde BD al arrancar
    useHydrateModuleSettings('general', company?.companyId ?? 1);

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
        <ToastProvider>
            <QuickCreateProvider>
                <AppShell showContent={showContent} navigation={navigation}>
                    {children}
                </AppShell>
            </QuickCreateProvider>
        </ToastProvider>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>CRM - Zentto App</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/crm/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            <AppRouterCacheProvider>
                                <BrandedThemeProvider defaultMode="system">
                                    <CssBaseline />
                                    <LocalizationProviderWrapper>
                                        <AppContent>{children}</AppContent>
                                    </LocalizationProviderWrapper>
                                </BrandedThemeProvider>
                            </AppRouterCacheProvider>
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
