'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@datqbox/shared-auth';
import { QueryProvider, useHydrateModuleSettings } from '@datqbox/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    theme,
    OdooLayout
} from '@datqbox/shared-ui';
import '@datqbox/shared-ui/globals.css';

import { buildContabilidadNav } from './nav';

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading, isAdmin, modulos, company } = useAuth();
    const [showContent, setShowContent] = useState(false);

    // Hidratar configuración general + contabilidad desde BD al arrancar
    useHydrateModuleSettings('contabilidad', company?.companyId ?? 1);

    useEffect(() => {
        if (!isLoading) {
            const t = setTimeout(() => setShowContent(true), 100);
            return () => clearTimeout(t);
        }
    }, [isLoading]);

    const navigation = React.useMemo(() => buildContabilidadNav(isAdmin, modulos), [isAdmin, modulos]);

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
    // Configured basePath allows session fetch relative to /contabilidad/api/auth
    return (
        <html lang="es" suppressHydrationWarning>
            <head>
                <title>Contabilidad - DatqBox App</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/api/auth">
                    {/* Note: setting basePath forces NextAuth to search on root port 3000 mapping, so token is shared. Or simply /api/auth ignores /contabilidad basepath if we do custom domain */}
                    <QueryProvider>
                        <AuthProvider>
                            <AppRouterCacheProvider options={{ enableCssLayer: true }}>
                                <ThemeProvider theme={theme} defaultMode="system">
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
