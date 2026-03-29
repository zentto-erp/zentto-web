'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardActions from '@mui/material/CardActions';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid2';
import dynamic from 'next/dynamic';

const ExtensionIcon = dynamic(() => import('@mui/icons-material/Extension'), { ssr: false });
const OpenInNewIcon = dynamic(() => import('@mui/icons-material/OpenInNew'), { ssr: false });

import { listAddons } from '@zentto/shared-api';
import type { StudioAddon } from '@zentto/shared-api';

export default function AddonsPage() {
    const router = useRouter();
    const [addons, setAddons] = useState<StudioAddon[]>([]);

    useEffect(() => {
        listAddons('compras').then(setAddons).catch(() => setAddons([]));
    }, []);

    const handleOpen = (appId: string) => {
        router.push(`/compras/addons/${appId}`);
    };

    const handleGoToStudio = () => {
        window.location.href = '/addons';
    };

    if (addons.length === 0) {
        return (
            <Box sx={{ p: 4, textAlign: 'center' }}>
                <ExtensionIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                <Typography variant="h5" gutterBottom>
                    No hay addons para Compras
                </Typography>
                <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                    Crea aplicaciones personalizadas desde el Studio y asígnalas al módulo Compras.
                </Typography>
                <Button variant="contained" onClick={handleGoToStudio} startIcon={<OpenInNewIcon />}>
                    Ir al Studio
                </Button>
            </Box>
        );
    }

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h5">Addons de Compras</Typography>
                <Button variant="outlined" onClick={handleGoToStudio} size="small" startIcon={<OpenInNewIcon />}>
                    Gestionar en Studio
                </Button>
            </Box>

            <Grid container spacing={3}>
                {addons.map((addon) => (
                    <Grid key={addon.id} size={{ xs: 12, sm: 6, md: 4 }}>
                        <Card
                            sx={{
                                height: '100%',
                                display: 'flex',
                                flexDirection: 'column',
                                cursor: 'pointer',
                                transition: 'box-shadow 0.2s',
                                '&:hover': { boxShadow: 6 },
                            }}
                            onClick={() => handleOpen(addon.id)}
                        >
                            <CardContent sx={{ flexGrow: 1 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                                    <Typography fontSize={28}>{addon.icon || '📦'}</Typography>
                                    <Typography variant="h6">{addon.title}</Typography>
                                </Box>
                                {addon.description && (
                                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                                        {addon.description}
                                    </Typography>
                                )}
                                <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                                    {addon.modules.map((m) => (
                                        <Chip key={m} label={m} size="small" variant="outlined" />
                                    ))}
                                </Box>
                            </CardContent>
                            <CardActions>
                                <Button size="small" onClick={() => handleOpen(addon.id)}>
                                    Abrir
                                </Button>
                            </CardActions>
                        </Card>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );
}
