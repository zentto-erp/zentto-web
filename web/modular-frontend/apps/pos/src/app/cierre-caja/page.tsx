'use client';

import React, { useState } from 'react';
import {
    Box,
    Typography,
    Paper,
    Grid,
    TextField,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Divider,
    Alert,
} from '@mui/material';
import dynamic from 'next/dynamic';

const LockIcon = dynamic(() => import('@mui/icons-material/Lock'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const SaveIcon = dynamic(() => import('@mui/icons-material/Save'), { ssr: false });

/**
 * Página de Cierre de Caja (Arqueo)
 * Permite cuadrar los montos físicos con los registrados en el sistema
 */
export default function PosCierreCajaPage() {
    const [denominaciones, setDenominaciones] = useState([
        { tipo: 'billete', valor: 100, cantidad: 0, total: 0 },
        { tipo: 'billete', valor: 50, cantidad: 0, total: 0 },
        { tipo: 'billete', valor: 20, cantidad: 0, total: 0 },
        { tipo: 'billete', valor: 10, cantidad: 0, total: 0 },
        { tipo: 'billete', valor: 5, cantidad: 0, total: 0 },
        { tipo: 'billete', valor: 2, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 1, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 0.5, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 0.25, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 0.1, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 0.05, cantidad: 0, total: 0 },
        { tipo: 'moneda', valor: 0.01, cantidad: 0, total: 0 },
    ]);

    const [efectivoSistema] = useState(1500.00); // Placeholder
    const [tarjetaSistema] = useState(850.00); // Placeholder
    const [transferenciaSistema] = useState(0.00); // Placeholder

    // Actualizar cantidad de una denominación
    const updateCantidad = (index: number, cantidad: string) => {
        const qty = parseInt(cantidad) || 0;
        setDenominaciones(prev => prev.map((den, i) => 
            i === index 
                ? { ...den, cantidad: qty, total: qty * den.valor }
                : den
        ));
    };

    // Calcular totales
    const totalEfectivoFisico = denominaciones.reduce((sum, d) => sum + d.total, 0);
    const totalSistema = efectivoSistema + tarjetaSistema + transferenciaSistema;
    const diferencia = totalEfectivoFisico - efectivoSistema;

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" gutterBottom fontWeight="bold">
                Cierre de Caja
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
                Realice el arqueo de efectivo y cuadre con los montos del sistema.
            </Typography>

            <Grid container spacing={3}>
                {/* Panel de Arqueo */}
                <Grid item xs={12} md={7}>
                    <Paper sx={{ p: 3 }}>
                        <Typography variant="h6" gutterBottom>
                            Arqueo de Efectivo
                        </Typography>

                        <TableContainer>
                            <Table size="small">
                                <TableHead>
                                    <TableRow>
                                        <TableCell>Denominación</TableCell>
                                        <TableCell align="center">Cantidad</TableCell>
                                        <TableCell align="right">Total</TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {denominaciones.map((den, index) => (
                                        <TableRow key={index}>
                                            <TableCell>
                                                <Typography 
                                                    variant="body2" 
                                                    sx={{ 
                                                        fontWeight: 'medium',
                                                        color: den.tipo === 'billete' ? 'primary.main' : 'text.secondary'
                                                    }}
                                                >
                                                    {den.tipo === 'billete' ? 'Billete' : 'Moneda'} de ${den.valor.toFixed(den.valor < 1 ? 2 : 0)}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="center">
                                                <TextField
                                                    type="number"
                                                    size="small"
                                                    value={den.cantidad || ''}
                                                    onChange={(e) => updateCantidad(index, e.target.value)}
                                                    inputProps={{ min: 0, style: { textAlign: 'center' } }}
                                                    sx={{ width: 80 }}
                                                />
                                            </TableCell>
                                            <TableCell align="right">
                                                <Typography fontWeight="medium">
                                                    ${den.total.toFixed(2)}
                                                </Typography>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </TableContainer>

                        <Divider sx={{ my: 2 }} />

                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Typography variant="h6">Total Efectivo en Caja:</Typography>
                            <Typography variant="h5" fontWeight="bold" color="primary">
                                ${totalEfectivoFisico.toFixed(2)}
                            </Typography>
                        </Box>
                    </Paper>
                </Grid>

                {/* Panel de Resumen del Sistema */}
                <Grid item xs={12} md={5}>
                    <Paper sx={{ p: 3, mb: 3 }}>
                        <Typography variant="h6" gutterBottom>
                            Montos en Sistema
                        </Typography>

                        <Box sx={{ mb: 2 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Efectivo:</Typography>
                                <Typography fontWeight="medium">${efectivoSistema.toFixed(2)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Tarjeta:</Typography>
                                <Typography fontWeight="medium">${tarjetaSistema.toFixed(2)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Transferencia:</Typography>
                                <Typography fontWeight="medium">${transferenciaSistema.toFixed(2)}</Typography>
                            </Box>
                        </Box>

                        <Divider sx={{ my: 2 }} />

                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                            <Typography variant="h6">Total Sistema:</Typography>
                            <Typography variant="h6" fontWeight="bold">
                                ${totalSistema.toFixed(2)}
                            </Typography>
                        </Box>
                    </Paper>

                    {/* Panel de Diferencia */}
                    <Paper sx={{ p: 3, mb: 3, bgcolor: diferencia === 0 ? 'success.light' : diferencia > 0 ? 'warning.light' : 'error.light' }}>
                        <Typography variant="h6" gutterBottom>
                            Diferencia
                        </Typography>
                        <Typography 
                            variant="h4" 
                            fontWeight="bold"
                            color={diferencia === 0 ? 'success.dark' : diferencia > 0 ? 'warning.dark' : 'error.dark'}
                        >
                            {diferencia >= 0 ? '+' : ''}${diferencia.toFixed(2)}
                        </Typography>
                        <Typography variant="body2" sx={{ mt: 1 }}>
                            {diferencia === 0 
                                ? '✓ Cuadre perfecto' 
                                : diferencia > 0 
                                    ? 'Sobrante en caja' 
                                    : 'Faltante en caja'}
                        </Typography>
                    </Paper>

                    {/* Alertas */}
                    {diferencia !== 0 && (
                        <Alert severity={diferencia > 0 ? 'warning' : 'error'} sx={{ mb: 2 }}>
                            {diferencia > 0 
                                ? 'Hay un sobrante. Verifique que todas las transacciones estén registradas.' 
                                : 'Hay un faltante. Verifique el conteo de efectivo.'}
                        </Alert>
                    )}

                    {/* Botones de acción */}
                    <Box sx={{ display: 'flex', gap: 2 }}>
                        <Button
                            variant="outlined"
                            startIcon={<PrintIcon />}
                            fullWidth
                        >
                            Imprimir Z
                        </Button>
                        <Button
                            variant="contained"
                            startIcon={<LockIcon />}
                            fullWidth
                            disabled={diferencia !== 0}
                            color="primary"
                        >
                            Cerrar Caja
                        </Button>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    );
}
