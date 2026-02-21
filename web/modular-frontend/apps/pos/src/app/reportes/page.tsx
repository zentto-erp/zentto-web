'use client';

import React, { useState } from 'react';
import {
    Box,
    Typography,
    Paper,
    Grid,
    Card,
    CardContent,
    TextField,
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
    const [fechaDesde, setFechaDesde] = useState<Dayjs | null>(dayjs());
    const [fechaHasta, setFechaHasta] = useState<Dayjs | null>(dayjs());

    // Datos de ejemplo (placeholder)
    const ventasRecientes = [
        { id: 'F-001', fecha: '2026-02-20', cliente: 'Consumidor Final', total: 125.50, estado: 'Completada' },
        { id: 'F-002', fecha: '2026-02-20', cliente: 'Juan Pérez', total: 450.00, estado: 'Completada' },
        { id: 'F-003', fecha: '2026-02-20', cliente: 'María García', total: 78.25, estado: 'Completada' },
        { id: 'F-004', fecha: '2026-02-19', cliente: 'Consumidor Final', total: 230.00, estado: 'Completada' },
        { id: 'F-005', fecha: '2026-02-19', cliente: 'Pedro López', total: 89.90, estado: 'Cancelada' },
    ];

    const productosTop = [
        { nombre: 'Producto A', cantidad: 45, total: 1125.00 },
        { nombre: 'Producto B', cantidad: 32, total: 800.00 },
        { nombre: 'Producto C', cantidad: 28, total: 560.00 },
        { nombre: 'Producto D', cantidad: 20, total: 600.00 },
        { nombre: 'Producto E', cantidad: 15, total: 375.00 },
    ];

    const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
        setActiveTab(newValue);
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
                        <Button variant="contained" fullWidth>
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
                                $2,450.00
                            </Typography>
                            <Chip 
                                icon={<TrendingUpIcon />} 
                                label="+12% vs ayer" 
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
                                47
                            </Typography>
                            <Chip 
                                icon={<ReceiptIcon />} 
                                label="Prom: $52.13" 
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
                                128
                            </Typography>
                            <Chip label="15 diferentes" size="small" sx={{ mt: 1 }} />
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
                                $52.13
                            </Typography>
                            <Chip label="Meta: $60" color="warning" size="small" sx={{ mt: 1 }} />
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>

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
                                    <TableRow key={venta.id}>
                                        <TableCell>{venta.id}</TableCell>
                                        <TableCell>{venta.fecha}</TableCell>
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
                                    <TableRow key={idx}>
                                        <TableCell>{prod.nombre}</TableCell>
                                        <TableCell align="right">{prod.cantidad}</TableCell>
                                        <TableCell align="right">${prod.total.toFixed(2)}</TableCell>
                                        <TableCell align="right">
                                            {((prod.total / 3460) * 100).toFixed(1)}%
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </TableContainer>
                )}

                {/* Tab 3: Formas de Pago */}
                {activeTab === 2 && (
                    <Box sx={{ p: 3 }}>
                        <Typography variant="body1" color="text.secondary">
                            Reporte de formas de pago en desarrollo...
                        </Typography>
                    </Box>
                )}
            </Paper>
        </Box>
    );
}
