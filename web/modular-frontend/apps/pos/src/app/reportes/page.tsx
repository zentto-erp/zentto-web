'use client';

import React, { useState } from 'react';
import {
    Box,
    Typography,
    Paper,
    Grid,
    Card,
    CardContent,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Tabs,
    Tab,
    Chip,
} from '@mui/material';
import { DatePicker } from '@datqbox/shared-ui';
import dayjs, { Dayjs } from 'dayjs';
import dynamic from 'next/dynamic';
import {
    usePosReporteFormasPago,
    usePosReporteProductosTop,
    usePosReporteResumen,
    usePosReporteVentas,
} from '@/hooks';

const DownloadIcon = dynamic(() => import('@mui/icons-material/Download'), { ssr: false });
const PrintIcon = dynamic(() => import('@mui/icons-material/Print'), { ssr: false });
const TrendingUpIcon = dynamic(() => import('@mui/icons-material/TrendingUp'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });

/**
 * Página de Reportes POS
 * Visualización de ventas, productos más vendidos, y estadísticas
 */
export default function PosReportesPage() {
    const [activeTab, setActiveTab] = useState(0);
    const [fechaDesde, setFechaDesde] = useState<Dayjs | null>(dayjs().startOf('day'));
    const [fechaHasta, setFechaHasta] = useState<Dayjs | null>(dayjs().endOf('day'));
    const [appliedDesde, setAppliedDesde] = useState<string>(dayjs().format('YYYY-MM-DD'));
    const [appliedHasta, setAppliedHasta] = useState<string>(dayjs().format('YYYY-MM-DD'));

    const resumenQuery = usePosReporteResumen(appliedDesde, appliedHasta);
    const ventasQuery = usePosReporteVentas(appliedDesde, appliedHasta, 200);
    const productosTopQuery = usePosReporteProductosTop(appliedDesde, appliedHasta, 20);
    const formasPagoQuery = usePosReporteFormasPago(appliedDesde, appliedHasta);

    const resumen = resumenQuery.data ?? {
        totalVentas: 0,
        transacciones: 0,
        productosVendidos: 0,
        productosDiferentes: 0,
        ticketPromedio: 0,
    };
    const ventasRecientes = ventasQuery.data ?? [];
    const productosTop = productosTopQuery.data ?? [];
    const formasPago = formasPagoQuery.data ?? [];

    const isLoading =
        resumenQuery.isLoading ||
        ventasQuery.isLoading ||
        productosTopQuery.isLoading ||
        formasPagoQuery.isLoading;

    const hasError =
        resumenQuery.isError ||
        ventasQuery.isError ||
        productosTopQuery.isError ||
        formasPagoQuery.isError;

    const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
        setActiveTab(newValue);
    };

    const handleGenerar = () => {
        setAppliedDesde((fechaDesde ?? dayjs()).format('YYYY-MM-DD'));
        setAppliedHasta((fechaHasta ?? dayjs()).format('YYYY-MM-DD'));
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" gutterBottom fontWeight="bold">
                Reportes POS
            </Typography>

            {/* Filtros de fecha */}
            <Paper sx={{ p: 2, mb: 3 }}>
                <Grid container spacing={2} alignItems="center">
                    <Grid item xs={12} sm={3}>
                        <DatePicker
                            label="Desde"
                            value={fechaDesde}
                            onChange={setFechaDesde}
                            slotProps={{ textField: { fullWidth: true, size: 'small' } }}
                        />
                    </Grid>
                    <Grid item xs={12} sm={3}>
                        <DatePicker
                            label="Hasta"
                            value={fechaHasta}
                            onChange={setFechaHasta}
                            slotProps={{ textField: { fullWidth: true, size: 'small' } }}
                        />
                    </Grid>
                    <Grid item xs={12} sm={3}>
                        <Button variant="contained" fullWidth onClick={handleGenerar}>
                            Generar
                        </Button>
                    </Grid>
                    <Grid item xs={12} sm={3}>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Button variant="outlined" startIcon={<PrintIcon />} fullWidth>
                                Imprimir
                            </Button>
                            <Button variant="outlined" startIcon={<DownloadIcon />} fullWidth>
                                Exportar
                            </Button>
                        </Box>
                    </Grid>
                </Grid>
            </Paper>

            {/* Resumen Cards */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={12} sm={3}>
                    <Card>
                        <CardContent>
                            <Typography color="text.secondary" gutterBottom>
                                Total Ventas
                            </Typography>
                            <Typography variant="h4" fontWeight="bold">
                                ${resumen.totalVentas.toFixed(2)}
                            </Typography>
                            <Chip
                                icon={<TrendingUpIcon />}
                                label={`Rango: ${appliedDesde} a ${appliedHasta}`}
                                color="success"
                                size="small"
                                sx={{ mt: 1 }}
                            />
                        </CardContent>
                    </Card>
                </Grid>
                <Grid item xs={12} sm={3}>
                    <Card>
                        <CardContent>
                            <Typography color="text.secondary" gutterBottom>
                                Transacciones
                            </Typography>
                            <Typography variant="h4" fontWeight="bold">
                                {resumen.transacciones}
                            </Typography>
                            <Chip
                                icon={<ReceiptIcon />}
                                label={`Prom: $${resumen.ticketPromedio.toFixed(2)}`}
                                size="small"
                                sx={{ mt: 1 }}
                            />
                        </CardContent>
                    </Card>
                </Grid>
                <Grid item xs={12} sm={3}>
                    <Card>
                        <CardContent>
                            <Typography color="text.secondary" gutterBottom>
                                Productos Vendidos
                            </Typography>
                            <Typography variant="h4" fontWeight="bold">
                                {resumen.productosVendidos}
                            </Typography>
                            <Chip label={`${resumen.productosDiferentes} diferentes`} size="small" sx={{ mt: 1 }} />
                        </CardContent>
                    </Card>
                </Grid>
                <Grid item xs={12} sm={3}>
                    <Card>
                        <CardContent>
                            <Typography color="text.secondary" gutterBottom>
                                Ticket Promedio
                            </Typography>
                            <Typography variant="h4" fontWeight="bold">
                                ${resumen.ticketPromedio.toFixed(2)}
                            </Typography>
                            <Chip label={`${resumen.transacciones} operaciones`} color="warning" size="small" sx={{ mt: 1 }} />
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>

            {isLoading && (
                <Paper sx={{ p: 2, mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">
                        Cargando reportes...
                    </Typography>
                </Paper>
            )}

            {hasError && (
                <Paper sx={{ p: 2, mb: 2 }}>
                    <Typography variant="body2" color="error">
                        No se pudieron cargar los datos de reportes para el rango seleccionado.
                    </Typography>
                </Paper>
            )}

            {/* Tabs con tablas */}
            <Paper sx={{ width: '100%' }}>
                <Tabs value={activeTab} onChange={handleTabChange} sx={{ borderBottom: 1, borderColor: 'divider' }}>
                    <Tab label="Ventas del Período" />
                    <Tab label="Productos Más Vendidos" />
                    <Tab label="Por Forma de Pago" />
                </Tabs>

                {/* Tab 1: Ventas */}
                {activeTab === 0 && (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>N° Factura</TableCell>
                                    <TableCell>Fecha</TableCell>
                                    <TableCell>Cliente</TableCell>
                                    <TableCell align="right">Total</TableCell>
                                    <TableCell>Estado</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {ventasRecientes.map((venta) => (
                                    <TableRow key={`${venta.id}-${venta.numFactura}`}>
                                        <TableCell>{venta.numFactura}</TableCell>
                                        <TableCell>{dayjs(venta.fecha).format('YYYY-MM-DD HH:mm')}</TableCell>
                                        <TableCell>{venta.cliente}</TableCell>
                                        <TableCell align="right">${venta.total.toFixed(2)}</TableCell>
                                        <TableCell>
                                            <Chip
                                                label={venta.estado}
                                                color={venta.estado === 'Completada' ? 'success' : 'error'}
                                                size="small"
                                            />
                                        </TableCell>
                                    </TableRow>
                                ))}
                                {ventasRecientes.length === 0 && !isLoading && (
                                    <TableRow>
                                        <TableCell colSpan={5} align="center">
                                            Sin ventas registradas en este período.
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}

                {/* Tab 2: Productos */}
                {activeTab === 1 && (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>Producto</TableCell>
                                    <TableCell align="right">Cantidad Vendida</TableCell>
                                    <TableCell align="right">Total Generado</TableCell>
                                    <TableCell align="right">% del Total</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {productosTop.map((prod, idx) => (
                                    <TableRow key={`${prod.productoId}-${idx}`}>
                                        <TableCell>{prod.nombre}</TableCell>
                                        <TableCell align="right">{prod.cantidad}</TableCell>
                                        <TableCell align="right">${prod.total.toFixed(2)}</TableCell>
                                        <TableCell align="right">
                                            {resumen.totalVentas > 0 ? ((prod.total / resumen.totalVentas) * 100).toFixed(1) : '0.0'}%
                                        </TableCell>
                                    </TableRow>
                                ))}
                                {productosTop.length === 0 && !isLoading && (
                                    <TableRow>
                                        <TableCell colSpan={4} align="center">
                                            Sin productos vendidos en este período.
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}

                {/* Tab 3: Formas de Pago */}
                {activeTab === 2 && (
                    <TableContainer>
                        <Table>
                            <TableHead>
                                <TableRow>
                                    <TableCell>Forma de Pago</TableCell>
                                    <TableCell align="right">Transacciones</TableCell>
                                    <TableCell align="right">Total</TableCell>
                                    <TableCell align="right">% del Total</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {formasPago.map((row, idx) => (
                                    <TableRow key={`${row.metodoPago}-${idx}`}>
                                        <TableCell>{row.metodoPago}</TableCell>
                                        <TableCell align="right">{row.transacciones}</TableCell>
                                        <TableCell align="right">${row.total.toFixed(2)}</TableCell>
                                        <TableCell align="right">
                                            {resumen.totalVentas > 0 ? ((row.total / resumen.totalVentas) * 100).toFixed(1) : '0.0'}%
                                        </TableCell>
                                    </TableRow>
                                ))}
                                {formasPago.length === 0 && !isLoading && (
                                    <TableRow>
                                        <TableCell colSpan={4} align="center">
                                            Sin movimientos por forma de pago en este período.
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}
            </Paper>
        </Box>
    );
}
