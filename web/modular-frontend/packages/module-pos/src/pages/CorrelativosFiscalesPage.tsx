'use client';

import React, { useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Button,
    Grid,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TextField,
    Typography,
    Tooltip
} from '@mui/material';
import { useGuardarPosCorrelativoFiscal, usePosCorrelativosFiscales } from '../hooks';

/**
 * Configuración mínima de correlativos fiscales por caja/serial.
 * Permite gestionar serial fiscal y correlativo actual para cuadrar caja.
 */
export function CorrelativosFiscalesPage() {
    const [cajaId, setCajaId] = useState('');
    const [serialFiscal, setSerialFiscal] = useState('');
    const [correlativoActual, setCorrelativoActual] = useState('0');
    const [descripcion, setDescripcion] = useState('');
    const [message, setMessage] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    const filtroCaja = cajaId.trim();
    const correlativosQuery = usePosCorrelativosFiscales(filtroCaja || undefined);
    const guardarMutation = useGuardarPosCorrelativoFiscal();

    const rows = correlativosQuery.data ?? [];
    const loading = correlativosQuery.isLoading || guardarMutation.isPending;

    const canSave = useMemo(() => serialFiscal.trim().length > 0, [serialFiscal]);

    const onGuardar = async () => {
        setMessage(null);
        setError(null);
        try {
            await guardarMutation.mutateAsync({
                cajaId: filtroCaja || undefined,
                serialFiscal: serialFiscal.trim(),
                correlativoActual: Number(correlativoActual || '0'),
                descripcion: descripcion.trim() || undefined,
            });
            setMessage('Correlativo fiscal guardado correctamente.');
            if (!filtroCaja) {
                setSerialFiscal('');
                setCorrelativoActual('0');
                setDescripcion('');
            }
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'No se pudo guardar el correlativo fiscal.');
        }
    };

    const onSeleccionarFila = (row: {
        cajaId?: string | null;
        serialFiscal?: string | null;
        correlativoActual?: number | null;
        descripcion?: string | null;
    }) => {
        setCajaId(row.cajaId ?? '');
        setSerialFiscal(row.serialFiscal ?? '');
        setCorrelativoActual(String(row.correlativoActual ?? 0));
        setDescripcion(row.descripcion ?? '');
        setMessage(null);
        setError(null);
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Configure serial fiscal y correlativo por caja para cuadrar reportes de ventas.
            </Typography>

            <Paper sx={{ p: 2, mb: 2 }}>
                <Grid container spacing={2}>
                    <Grid item xs={12} sm={3}>
                        <Tooltip title="Identificador de la caja para la que aplica este correlativo. Dejar vacío para configuración global." arrow placement="top">
                            <TextField
                                label="Caja"
                                value={cajaId}
                                onChange={(e) => setCajaId(e.target.value.toUpperCase())}
                                fullWidth
                                helperText="Vacío = configuración global FACTURA"
                            />
                        </Tooltip>
                    </Grid>
                    <Grid item xs={12} sm={3}>
                        <Tooltip title="Número de serie físico de la impresora fiscal asociada a esta caja." arrow placement="top">
                            <TextField
                                label="Serial Fiscal"
                                value={serialFiscal}
                                onChange={(e) => setSerialFiscal(e.target.value.toUpperCase())}
                                fullWidth
                                required
                            />
                        </Tooltip>
                    </Grid>
                    <Grid item xs={12} sm={2}>
                        <Tooltip title="Último número de factura o documento impreso. Se incrementará en 1 en la próxima venta." arrow placement="top">
                            <TextField
                                label="Correlativo"
                                value={correlativoActual}
                                onChange={(e) => setCorrelativoActual(e.target.value)}
                                fullWidth
                                type="number"
                                inputProps={{ min: 0 }}
                            />
                        </Tooltip>
                    </Grid>
                    <Grid item xs={12} sm={4}>
                        <Tooltip title="Nota descriptiva sobre esta configuración de correlativo." arrow placement="top">
                            <TextField
                                label="Descripción"
                                value={descripcion}
                                onChange={(e) => setDescripcion(e.target.value)}
                                fullWidth
                            />
                        </Tooltip>
                    </Grid>
                    <Grid item xs={12}>
                        <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                            <Button
                                variant="outlined"
                                onClick={() => correlativosQuery.refetch()}
                                disabled={loading}
                            >
                                Recargar
                            </Button>
                            <Button
                                variant="contained"
                                onClick={onGuardar}
                                disabled={!canSave || loading}
                            >
                                Guardar
                            </Button>
                        </Box>
                    </Grid>
                </Grid>
            </Paper>

            {message && <Alert severity="success" sx={{ mb: 2 }}>{message}</Alert>}
            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

            <Paper sx={{ width: '100%' }}>
                <TableContainer>
                    <Table size="small">
                        <TableHead>
                            <TableRow>
                                <TableCell>Tipo</TableCell>
                                <TableCell>Caja</TableCell>
                                <TableCell>Serial Fiscal</TableCell>
                                <TableCell align="right">Correlativo</TableCell>
                                <TableCell>Descripción</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {rows.map((row, idx) => (
                                <TableRow
                                    key={`${row.tipo}-${row.cajaId ?? 'global'}-${idx}`}
                                    hover
                                    onClick={() => onSeleccionarFila(row)}
                                    sx={{ cursor: 'pointer' }}
                                >
                                    <TableCell>{row.tipo}</TableCell>
                                    <TableCell>{row.cajaId || 'GLOBAL'}</TableCell>
                                    <TableCell>{row.serialFiscal || '-'}</TableCell>
                                    <TableCell align="right">{row.correlativoActual ?? 0}</TableCell>
                                    <TableCell>{row.descripcion || '-'}</TableCell>
                                </TableRow>
                            ))}
                            {rows.length === 0 && !correlativosQuery.isLoading && (
                                <TableRow>
                                    <TableCell colSpan={5} align="center">
                                        No hay correlativos fiscales configurados.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Paper>
        </Box>
    );
}
