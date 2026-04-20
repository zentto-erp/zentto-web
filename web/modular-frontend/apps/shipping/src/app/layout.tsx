'use client';

import * as React from 'react';
import { Suspense } from 'react';
import CssBaseline from '@mui/material/CssBaseline';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrandedThemeProvider } from '@zentto/shared-ui';
import '@zentto/shared-ui/globals.css';
import { ShippingLayout } from '@zentto/module-shipping';
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
        <ShippingLayout onNavigate={handleNavigate}>
            <Suspense fallback={<LoadingFallback />}>{children}</Suspense>
        </ShippingLayout>
    );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="es" suppressHydrationWarning>
            <head>
                <title>Zentto Shipping - Portal de Envíos</title>
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
