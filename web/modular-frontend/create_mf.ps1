param (
    [string]$appName,
    [string]$appTitle,
    [int]$port,
    [string]$iconName
)

$baseDir = "D:\DatqBoxWorkspace\DatqBoxWeb\web\modular-frontend\apps\$appName"
$srcDir = "$baseDir\src\app"

if (-Not (Test-Path -Path $baseDir)) {
    New-Item -ItemType Directory -Path $baseDir | Out-Null
    New-Item -ItemType Directory -Path $srcDir | Out-Null
}

$packageJson = @"
{
    "name": "@datqbox/$appName",
    "version": "0.1.0",
    "private": true,
    "scripts": {
        "dev": "next dev -p $port",
        "build": "next build",
        "start": "next start -p $port",
        "lint": "next lint"
    },
    "dependencies": {
        "@datqbox/shared-api": "workspace:*",
        "@datqbox/shared-auth": "workspace:*",
        "@datqbox/shared-ui": "workspace:*",
        "@emotion/cache": "^11.14.0",
        "@emotion/react": "^11.14.0",
        "@emotion/styled": "^11.14.0",
        "@mui/icons-material": "^6.4.1",
        "@mui/material": "^6.4.1",
        "@mui/material-nextjs": "^6.4.1",
        "@mui/system": "^6.4.6",
        "@mui/x-data-grid": "^7.24.0",
        "@mui/x-date-pickers": "^7.26.0",
        "@tanstack/react-query": "^5.64.1",
        "dayjs": "^1.11.13",
        "next": "15.5.12",
        "next-auth": "5.0.0-beta.25",
        "react": "^18.3.1",
        "react-dom": "^18.3.1"
    },
    "devDependencies": {
        "@types/node": "^20",
        "@types/react": "^18",
        "@types/react-dom": "^18",
        "eslint": "^9",
        "eslint-config-next": "15.5.12",
        "typescript": "^5"
    }
}
"@
Set-Content -Path "$baseDir\package.json" -Value $packageJson -Encoding UTF8

$nextConfig = @"
/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    basePath: '/$appName',
    transpilePackages: ['@datqbox/shared-ui', '@datqbox/shared-auth', '@datqbox/shared-api'],
};

export default nextConfig;
"@
Set-Content -Path "$baseDir\next.config.mjs" -Value $nextConfig -Encoding UTF8

$tsconfig = @"
{
    "compilerOptions": {
        "target": "es5",
        "lib": ["dom", "dom.iterable", "esnext"],
        "allowJs": true,
        "skipLibCheck": true,
        "strict": true,
        "forceConsistentCasingInFileNames": true,
        "noEmit": true,
        "esModuleInterop": true,
        "module": "esnext",
        "moduleResolution": "node",
        "resolveJsonModule": true,
        "isolatedModules": true,
        "jsx": "preserve",
        "incremental": true,
        "plugins": [{"name": "next"}],
        "paths": {"@/*": ["./src/*"]}
    },
    "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
    "exclude": ["node_modules"]
}
"@
Set-Content -Path "$baseDir\tsconfig.json" -Value $tsconfig -Encoding UTF8

$envLocal = @"
NEXT_PUBLIC_BACKEND_URL=http://localhost:4000
AUTH_SECRET=your-secret-key-here-change-in-production-pos
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_API_BASE_URL=http://localhost:4000
API_URL=http://localhost:4000
"@
Set-Content -Path "$baseDir\.env.local" -Value $envLocal -Encoding UTF8

$navTsx = @"
import React from 'react';
import dynamic from 'next/dynamic';

const NavIcon = dynamic(() => import('@mui/icons-material/$iconName'), { ssr: false });

export function buildNav(isAdmin: boolean, modulos: string[]): any[] {
    const nav: any[] = [];
    const has = (mod: string) => isAdmin || modulos.includes(mod);

    if (has('$appName')) {
        nav.push({ kind: 'header', title: '$appTitle' });
        nav.push({ kind: 'page', segment: '', title: 'Dashboard', icon: <NavIcon /> });
    }

    return nav;
}
"@
Set-Content -Path "$srcDir\nav.tsx" -Value $navTsx -Encoding UTF8

$layoutTsx = @"
'use client';

import * as React from 'react';
import { Suspense, useEffect, useState } from 'react';
import { AppRouterCacheProvider } from '@mui/material-nextjs/v15-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import InitColorSchemeScript from '@mui/material/InitColorSchemeScript';
import { SessionProvider, useSession } from 'next-auth/react';
import { AuthProvider, useAuth } from '@datqbox/shared-auth';
import { QueryProvider } from '@datqbox/shared-api';
import {
    AppBarWrapper,
    LoadingFallback,
    ToastProvider,
    LocalizationProviderWrapper,
    theme,
    OdooLayout
} from '@datqbox/shared-ui';
import '@datqbox/shared-ui/globals.css';

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
        <html lang="es" suppressHydrationWarning>
            <head>
                <title>$appTitle - DatqBox App</title>
                <InitColorSchemeScript attribute="data-toolpad-color-scheme" />
            </head>
            <body>
                <SessionProvider basePath="/api/auth">
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
"@
Set-Content -Path "$srcDir\layout.tsx" -Value $layoutTsx -Encoding UTF8

$pageTsx = @"
'use client';
import { Box, Typography } from '@mui/material';

export default function Page() {
    return (
        <Box sx={{ p: 4 }}>
            <Typography variant="h4" gutterBottom>
                $appTitle Dashboard
            </Typography>
            <Typography variant="body1">
                Bienvenido al módulo de $appTitle. Contenido en construcción.
            </Typography>
        </Box>
    );
}
"@
Set-Content -Path "$srcDir\page.tsx" -Value $pageTsx -Encoding UTF8

Write-Host "Created app $appName at port $port"
