'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider } from 'next-auth/react';
import { AuthProvider, useAuth } from '@zentto/shared-auth';
import { QueryProvider } from '@zentto/shared-api';
import {
    LoadingFallback,
    ToastProvider,
    BrandedThemeProvider,
} from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';

function AppContent({ children }: { children: React.ReactNode }) {
    const { isLoading } = useAuth();
    const [showContent, setShowContent] = useState(false);

    useEffect(() => {
        if (!isLoading) {
            const t = setTimeout(() => setShowContent(true), 100);
            return () => clearTimeout(t);
        }
    }, [isLoading]);

    if (isLoading || !showContent) {
        return <LoadingFallback />;
    }

    return (
        <ToastProvider>
            <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
        </ToastProvider>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>Report Studio - Zentto</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/report-studio/api/auth">
                    <QueryProvider>
                        <AuthProvider>
                            
                                <BrandedThemeProvider defaultMode="system">
                                    <CssBaseline />
                                    <AppContent>{children}</AppContent>
                                    <script src="https://docs.zentto.net/widget.js" defer />
                                </BrandedThemeProvider>
                            
                        </AuthProvider>
                    </QueryProvider>
                </SessionProvider>
            </body>
        </html>
    );
}
