'use client';

import * as React from 'react';
import { Suspense } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { theme } from '@datqbox/shared-ui';
import '@datqbox/shared-ui/globals.css';
import { StoreLayout } from '@datqbox/module-ecommerce';
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
        <html lang="es" suppressHydrationWarning>
            <head>
                <title>DatqBox Store - Tienda en linea</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <QueryClientProvider client={queryClient}>
                    <AppRouterCacheProvider options={{ enableCssLayer: true }}>
                        <ThemeProvider theme={theme} defaultMode="system">
                            <AppContent>{children}</AppContent>
                        </ThemeProvider>
                    </AppRouterCacheProvider>
                </QueryClientProvider>
            </body>
        </html>
    );
}
