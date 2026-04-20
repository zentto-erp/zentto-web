'use client';

import * as React from 'react';
import { Suspense } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrandedThemeProvider } from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';
import { StoreLayout } from '@zentto/module-ecommerce';
import { useRouter } from 'next/navigation';
import { CircularProgress, Box } from '@mui/material';

const queryClient = new QueryClient({
    defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

function LoadingFallback() {
    return (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
            <CircularProgress />
        </Box>
    );
}

function AppContent({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const handleNavigate = (path: string) => router.push(path);

    return (
        <StoreLayout onNavigate={handleNavigate}>
            <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
        </StoreLayout>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" data-scroll-behavior="smooth" suppressHydrationWarning>
            <head>
                <title>Zentto Store - Tienda en linea</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <QueryClientProvider client={queryClient}>
                    
                        <BrandedThemeProvider defaultMode="system">
                            <CssBaseline />
                            <AppContent>{children}</AppContent>
                        </BrandedThemeProvider>
                    
                </QueryClientProvider>
            </body>
        </html>
    );
}
