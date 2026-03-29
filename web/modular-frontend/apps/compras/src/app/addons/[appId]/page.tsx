'use client';

import React, { useEffect, useState, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import dynamic from 'next/dynamic';

const ArrowBackIcon = dynamic(() => import('@mui/icons-material/ArrowBack'), { ssr: false });
const ErrorOutlineIcon = dynamic(() => import('@mui/icons-material/ErrorOutline'), { ssr: false });

import { getAddon } from '@zentto/shared-api';
import type { StudioAddon } from '@zentto/shared-api';

/* ── JSX declarations for web components ─────────────────────── */
declare global {
    namespace JSX {
        interface IntrinsicElements {
            'zentto-studio-app': React.DetailedHTMLProps<
                React.HTMLAttributes<HTMLElement> & Record<string, any>,
                HTMLElement
            >;
        }
    }
}

export default function AddonRunnerPage() {
    const params = useParams<{ appId: string }>();
    const router = useRouter();
    const appRef = useRef<any>(null);

    const [addon, setAddon] = useState<StudioAddon | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);
    const [studioReady, setStudioReady] = useState(false);

    /* ── Load addon config ────────────────────────────────────── */
    useEffect(() => {
        getAddon(params.appId)
            .then((found) => {
                if (found) setAddon(found);
                else setError(true);
            })
            .catch(() => setError(true))
            .finally(() => setLoading(false));
    }, [params.appId]);

    /* ── Load web component ───────────────────────────────────── */
    useEffect(() => {
        if (!addon) return;
        import('@zentto/studio').then(() => setStudioReady(true)).catch(() => setError(true));
    }, [addon]);

    /* ── Pass config to web component ─────────────────────────── */
    useEffect(() => {
        if (!studioReady || !appRef.current || !addon) return;
        appRef.current.config = addon.config;
    }, [studioReady, addon]);

    const handleBack = () => {
        router.push('/compras/addons');
    };

    /* ── Loading ──────────────────────────────────────────────── */
    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 300 }}>
                <CircularProgress />
            </Box>
        );
    }

    /* ── Error ────────────────────────────────────────────────── */
    if (error || !addon) {
        return (
            <Box sx={{ p: 4, textAlign: 'center' }}>
                <ErrorOutlineIcon sx={{ fontSize: 64, color: 'error.main', mb: 2 }} />
                <Typography variant="h5" gutterBottom>
                    Addon no encontrado
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                    No se encontró el addon &quot;{params.appId}&quot;. Puede que haya sido eliminado.
                </Typography>
                <Button variant="contained" onClick={handleBack} startIcon={<ArrowBackIcon />}>
                    Volver a Addons
                </Button>
            </Box>
        );
    }

    /* ── Render ────────────────────────────────────────────────── */
    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 64px)' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, px: 2, py: 1, borderBottom: 1, borderColor: 'divider' }}>
                <Button variant="text" onClick={handleBack} startIcon={<ArrowBackIcon />} size="small">
                    Volver
                </Button>
                <Typography fontSize={20}>{addon.title}</Typography>
            </Box>

            <Box sx={{ flex: 1, overflow: 'hidden' }}>
                {!studioReady ? (
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
                        <CircularProgress sx={{ mr: 2 }} />
                        <Typography>Cargando aplicación...</Typography>
                    </Box>
                ) : (
                    <zentto-studio-app ref={appRef} style={{ display: 'block', width: '100%', height: '100%' }} />
                )}
            </Box>
        </Box>
    );
}
