'use client';

import React, { useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Button,
    Grid,
    Paper,
    TextField,
    Typography,
} from '@mui/material';
import { usePosStore } from '@datqbox/shared-api';
import { apiGet, apiPost } from '@datqbox/shared-api';

export default function PosFiscalPage() {
    const fiscalPrinter = usePosStore((s) => s.fiscalPrinter);

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [result, setResult] = useState<any>(null);
    const [mes, setMes] = useState<number>(new Date().getMonth() + 1);
    const [anio, setAnio] = useState<number>(new Date().getFullYear());
    const [docTitulo, setDocTitulo] = useState('DOCUMENTO NO FISCAL');
    const [docTexto, setDocTexto] = useState('Línea 1\nLínea 2');

    const basePayload = useMemo(() => ({
        marca: fiscalPrinter.marca,
        puerto: fiscalPrinter.puerto,
        conexion: fiscalPrinter.conexion,
    }), [fiscalPrinter.marca, fiscalPrinter.puerto, fiscalPrinter.conexion]);

    const run = async (executor: () => Promise<any>) => {
        setLoading(true);
        setError(null);
        try {
            const data = await executor();
            if (data?.Success === false || data?.success === false) {
                throw new Error(data?.Message || data?.message || data?.error || 'Operación no completada');
            }
            setResult(data);
        } catch (e: any) {
            setError(e?.message || 'Error en operación fiscal');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
                Módulo Fiscal
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Estado de impresora fiscal, reportes X/Z, reporte mensual, memoria fiscal y documentos no fiscales.
            </Typography>

            <Paper sx={{ p: 2, mb: 2 }}>
                <Grid container spacing={2} alignItems="center">
                    <Grid item xs={12} md={3}>
                        <TextField label="Marca" value={fiscalPrinter.marca} fullWidth size="small" disabled />
                    </Grid>
                    <Grid item xs={12} md={2}>
                        <TextField label="Puerto" value={fiscalPrinter.puerto} fullWidth size="small" disabled />
                    </Grid>
                    <Grid item xs={12} md={2}>
                        <TextField label="Conexión" value={fiscalPrinter.conexion} fullWidth size="small" disabled />
                    </Grid>
                    <Grid item xs={12} md={5}>
                        <TextField label="Agent URL" value={fiscalPrinter.agentUrl} fullWidth size="small" disabled />
                    </Grid>
                </Grid>
            </Paper>

            <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                    <Paper sx={{ p: 2, height: '100%' }}>
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Operaciones Fiscales</Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                            <Button
                                variant="outlined"
                                disabled={loading}
                                onClick={() => run(() => apiGet('/v1/pos/fiscal/status', {
                                    ...basePayload,
                                    agentUrl: fiscalPrinter.agentUrl,
                                }))}
                            >
                                Ver Estado
                            </Button>
                            <Button
                                variant="contained"
                                disabled={loading}
                                onClick={() => run(() => apiPost('/v1/pos/fiscal/reporte/x', {
                                    ...basePayload,
                                    agentUrl: fiscalPrinter.agentUrl,
                                }))}
                            >
                                Emitir X
                            </Button>
                            <Button
                                variant="contained"
                                color="warning"
                                disabled={loading}
                                onClick={() => run(() => apiPost('/v1/pos/fiscal/reporte/z', {
                                    ...basePayload,
                                    agentUrl: fiscalPrinter.agentUrl,
                                }))}
                            >
                                Emitir Z
                            </Button>
                            <Button
                                variant="outlined"
                                disabled={loading}
                                onClick={() => run(() => apiGet('/v1/pos/fiscal/memoria', {
                                    ...basePayload,
                                    agentUrl: fiscalPrinter.agentUrl,
                                }))}
                            >
                                Memoria Fiscal
                            </Button>
                        </Box>
                    </Paper>
                </Grid>

                <Grid item xs={12} md={6}>
                    <Paper sx={{ p: 2, height: '100%' }}>
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Reporte Mensual</Typography>
                        <Grid container spacing={1}>
                            <Grid item xs={6}>
                                <TextField type="number" size="small" fullWidth label="Mes" value={mes} onChange={(e) => setMes(Number(e.target.value || 1))} inputProps={{ min: 1, max: 12 }} />
                            </Grid>
                            <Grid item xs={6}>
                                <TextField type="number" size="small" fullWidth label="Año" value={anio} onChange={(e) => setAnio(Number(e.target.value || new Date().getFullYear()))} inputProps={{ min: 2000, max: 2100 }} />
                            </Grid>
                            <Grid item xs={12}>
                                <Button
                                    variant="outlined"
                                    disabled={loading}
                                    onClick={() => run(() => apiGet('/v1/pos/fiscal/reporte/mensual', {
                                        anio,
                                        mes,
                                        ...basePayload,
                                        agentUrl: fiscalPrinter.agentUrl,
                                    }))}
                                >
                                    Generar Reporte Mensual
                                </Button>
                            </Grid>
                        </Grid>
                    </Paper>
                </Grid>

                <Grid item xs={12}>
                    <Paper sx={{ p: 2 }}>
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Documento No Fiscal</Typography>
                        <Grid container spacing={1}>
                            <Grid item xs={12} md={4}>
                                <TextField label="Título" size="small" fullWidth value={docTitulo} onChange={(e) => setDocTitulo(e.target.value)} />
                            </Grid>
                            <Grid item xs={12} md={8}>
                                <TextField label="Líneas (una por renglón)" size="small" fullWidth multiline minRows={2} value={docTexto} onChange={(e) => setDocTexto(e.target.value)} />
                            </Grid>
                            <Grid item xs={12}>
                                <Button
                                    variant="outlined"
                                    disabled={loading}
                                    onClick={() => run(() => apiPost('/v1/pos/fiscal/documento-no-fiscal', {
                                        ...basePayload,
                                        agentUrl: fiscalPrinter.agentUrl,
                                        titulo: docTitulo,
                                        lineas: docTexto.split('\n').map((l) => l.trim()).filter(Boolean),
                                    }))}
                                >
                                    Emitir Documento No Fiscal
                                </Button>
                            </Grid>
                        </Grid>
                    </Paper>
                </Grid>
            </Grid>

            {error && <Alert severity="error" sx={{ mt: 2 }}>{error}</Alert>}

            <Paper sx={{ mt: 2, p: 2 }}>
                <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
                    Resultado
                </Typography>
                <Box
                    component="pre"
                    sx={{ m: 0, whiteSpace: 'pre-wrap', wordBreak: 'break-word', fontSize: 12 }}
                >
                    {JSON.stringify(result, null, 2)}
                </Box>
            </Paper>
        </Box>
    );
}
