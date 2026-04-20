'use client';

import React from 'react';
import {
    Box,
    Paper,
    Typography,
    Grid,
    Chip,
    Button,
    Card,
    CardContent,
    Divider,
} from '@mui/material';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { ComandaCocina } from '../hooks/useRestaurante';

interface VistaCocinaProps {
    comandas: ComandaCocina[];
    onMarcarListo: (comandaId: string) => void;
}

export function VistaCocina({ comandas, onMarcarListo }: VistaCocinaProps) {
    const getTiempoTranscurrido = (hora: Date) => {
        const diff = Math.floor((new Date().getTime() - new Date(hora).getTime()) / 1000 / 60);
        return diff;
    };

    const getColorPrioridad = (prioridad: string, minutos: number) => {
        if (minutos > 20) return '#D32F2F'; // Rojo - muy demorado
        if (minutos > 10) return '#F57C00'; // Naranja - demorado
        if (prioridad === 'urgente') return '#D32F2F';
        if (prioridad === 'alta') return '#F57C00';
        return '#388E3C'; // Verde - normal
    };

    const comandasPorAmbiente = comandas.reduce((acc, comanda) => {
        if (!acc[comanda.ambiente]) acc[comanda.ambiente] = [];
        acc[comanda.ambiente].push(comanda);
        return acc;
    }, {} as Record<string, ComandaCocina[]>);

    return (
        <Box sx={{ height: '100%', p: 2 }}>
            <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                <Chip 
                    label={`${comandas.length} Pedidos pendientes`}
                    color="primary"
                    size="medium"
                />
                <Chip 
                    label={`${comandas.filter(c => c.prioridad === 'urgente' || getTiempoTranscurrido(c.horaRecibido) > 15).length} Urgentes`}
                    color="error"
                    size="medium"
                />
            </Box>

            {comandas.length === 0 ? (
                <Paper sx={{ p: 4, textAlign: 'center' }}>
                    <Typography variant="h6" color="text.secondary">
                        ✅ No hay pedidos pendientes
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                        La cocina está al día
                    </Typography>
                </Paper>
            ) : (
                <Grid container spacing={3}>
                    {Object.entries(comandasPorAmbiente).map(([ambiente, items]) => (
                        <Grid item xs={12} md={6} lg={4} key={ambiente}>
                            <Paper sx={{ p: 2, height: '100%' }}>
                                <Typography variant="h6" gutterBottom sx={{ 
                                    bgcolor: 'primary.main', 
                                    color: 'white',
                                    p: 1,
                                    borderRadius: 1,
                                    mb: 2
                                }}>
                                    {ambiente}
                                </Typography>

                                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                    {items.map((comanda) => {
                                        const minutos = getTiempoTranscurrido(comanda.horaRecibido);
                                        const color = getColorPrioridad(comanda.prioridad, minutos);

                                        return (
                                            <Card 
                                                key={comanda.id}
                                                sx={{
                                                    borderLeft: `6px solid ${color}`,
                                                    bgcolor: minutos > 15 ? '#FFEBEE' : 'white'
                                                }}
                                            >
                                                <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                                        <Typography variant="h5" fontWeight="bold">
                                                            {comanda.mesaNombre}
                                                        </Typography>
                                                        <Chip 
                                                            icon={<AccessTimeIcon />}
                                                            label={`${minutos}min`}
                                                            size="small"
                                                            sx={{ 
                                                                bgcolor: color,
                                                                color: 'white',
                                                                fontWeight: 'bold'
                                                            }}
                                                        />
                                                    </Box>

                                                    <Divider sx={{ my: 1 }} />

                                                    <Box sx={{ mb: 2 }}>
                                                        <Typography variant="body1" fontWeight="medium">
                                                            {comanda.item.cantidad}x {comanda.item.nombre}
                                                        </Typography>
                                                        
                                                        {comanda.item.componentes && comanda.item.componentes.length > 0 && (
                                                            <Box sx={{ mt: 1, pl: 2 }}>
                                                                {comanda.item.componentes.map((comp, idx) => (
                                                                    <Typography 
                                                                        key={idx} 
                                                                        variant="body2" 
                                                                        color="text.secondary"
                                                                    >
                                                                        • {comp.nombre}: {comp.opcionSeleccionada}
                                                                    </Typography>
                                                                ))}
                                                            </Box>
                                                        )}

                                                        {comanda.item.comentarios && (
                                                            <Typography 
                                                                variant="body2" 
                                                                color="warning.main"
                                                                sx={{ mt: 1, fontStyle: 'italic' }}
                                                            >
                                                                📝 {comanda.item.comentarios}
                                                            </Typography>
                                                        )}
                                                    </Box>

                                                    <Button
                                                        fullWidth
                                                        variant="contained"
                                                        color="success"
                                                        startIcon={<CheckCircleIcon />}
                                                        onClick={() => onMarcarListo(comanda.id)}
                                                        size="large"
                                                    >
                                                        Listo para servir
                                                    </Button>
                                                </CardContent>
                                            </Card>
                                        );
                                    })}
                                </Box>
                            </Paper>
                        </Grid>
                    ))}
                </Grid>
            )}
        </Box>
    );
}
