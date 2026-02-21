'use client';

import React, { useState, useEffect } from 'react';
import {
    Box,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Button,
    TextField,
    Grid,
    Paper,
    Typography,
    Tabs,
    Tab,
    IconButton,
    Divider,
    Chip,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import MoneyIcon from '@mui/icons-material/Money';
import CreditCardIcon from '@mui/icons-material/CreditCard';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import SmartphoneIcon from '@mui/icons-material/Smartphone';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PrintIcon from '@mui/icons-material/Print';

interface PaymentMethod {
    id: string;
    nombre: string;
    icon: React.ReactElement;
    color: string;
}

interface Payment {
    metodo: string;
    monto: number;
    referencia?: string;
}

interface PosPaymentModalProps {
    open: boolean;
    onClose: () => void;
    total: number;
    items: Array<{
        nombre: string;
        cantidad: number;
        precio: number;
        total: number;
    }>;
    cliente: string;
    onPaymentComplete: (payments: Payment[]) => void;
}

const PAYMENT_METHODS: PaymentMethod[] = [
    { id: 'efectivo', nombre: 'Efectivo', icon: <MoneyIcon />, color: '#4caf50' },
    { id: 'tarjeta', nombre: 'Tarjeta', icon: <CreditCardIcon />, color: '#2196f3' },
    { id: 'transferencia', nombre: 'Transferencia', icon: <AccountBalanceIcon />, color: '#ff9800' },
    { id: 'pago_movil', nombre: 'Pago Móvil', icon: <SmartphoneIcon />, color: '#9c27b0' },
];

export function PosPaymentModal({
    open,
    onClose,
    total,
    items,
    cliente,
    onPaymentComplete,
}: PosPaymentModalProps) {
    const [activeTab, setActiveTab] = useState(0);
    const [payments, setPayments] = useState<Payment[]>([]);
    const [currentAmount, setCurrentAmount] = useState('');
    const [referencia, setReferencia] = useState('');
    const [change, setChange] = useState(0);
    const [showSuccess, setShowSuccess] = useState(false);

    const totalPagado = payments.reduce((sum, p) => sum + p.monto, 0);
    const restante = Math.max(0, total - totalPagado);
    const cambio = Math.max(0, totalPagado - total);

    useEffect(() => {
        if (open) {
            setPayments([]);
            setCurrentAmount('');
            setReferencia('');
            setChange(0);
            setShowSuccess(false);
            setActiveTab(0);
        }
    }, [open]);

    const handleAddPayment = () => {
        const amount = parseFloat(currentAmount);
        if (isNaN(amount) || amount <= 0) return;

        const method = PAYMENT_METHODS[activeTab];
        
        setPayments(prev => [...prev, {
            metodo: method.nombre,
            monto: amount,
            referencia: referencia || undefined,
        }]);

        setCurrentAmount('');
        setReferencia('');
    };

    const handleRemovePayment = (index: number) => {
        setPayments(prev => prev.filter((_, i) => i !== index));
    };

    const handleCompletePayment = () => {
        if (totalPagado >= total) {
            setShowSuccess(true);
            setTimeout(() => {
                onPaymentComplete(payments);
                onClose();
            }, 2000);
        }
    };

    const handleExactAmount = () => {
        setCurrentAmount(restante.toFixed(2));
    };

    const suggestedAmounts = [10, 20, 50, 100, 200, 500].filter(a => a >= total || a >= restante);

    if (showSuccess) {
        return (
            <Dialog open={open} maxWidth="sm" fullWidth>
                <DialogContent sx={{ textAlign: 'center', py: 6 }}>
                    <CheckCircleIcon sx={{ fontSize: 80, color: 'success.main', mb: 2 }} />
                    <Typography variant="h4" gutterBottom fontWeight="bold">
                        ¡Pago Completado!
                    </Typography>
                    <Typography variant="body1" color="text.secondary">
                        La factura ha sido procesada exitosamente.
                    </Typography>
                    {cambio > 0 && (
                        <Typography variant="h5" color="success.main" sx={{ mt: 2 }}>
                            Cambio: ${cambio.toFixed(2)}
                        </Typography>
                    )}
                </DialogContent>
            </Dialog>
        );
    }

    return (
        <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
            <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h6">Procesar Pago</Typography>
                <IconButton onClick={onClose}>
                    <CloseIcon />
                </IconButton>
            </DialogTitle>
            
            <DialogContent>
                <Grid container spacing={3}>
                    {/* Panel Izquierdo - Resumen */}
                    <Grid item xs={12} md={5}>
                        <Paper sx={{ p: 2, height: '100%', bgcolor: '#f5f5f5' }}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                Resumen de Compra
                            </Typography>
                            
                            <Box sx={{ maxHeight: 200, overflow: 'auto', mb: 2 }}>
                                {items.map((item, idx) => (
                                    <Box key={idx} sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                                        <Typography variant="body2">
                                            {item.cantidad}x {item.nombre}
                                        </Typography>
                                        <Typography variant="body2" fontWeight="medium">
                                            ${item.total.toFixed(2)}
                                        </Typography>
                                    </Box>
                                ))}
                            </Box>

                            <Divider sx={{ my: 1 }} />

                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Subtotal:</Typography>
                                <Typography>${(total / 1.16).toFixed(2)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>IVA (16%):</Typography>
                                <Typography>${(total - (total / 1.16)).toFixed(2)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                                <Typography variant="h6" fontWeight="bold">Total:</Typography>
                                <Typography variant="h6" fontWeight="bold" color="primary">
                                    ${total.toFixed(2)}
                                </Typography>
                            </Box>

                            <Divider sx={{ my: 1 }} />

                            <Typography variant="body2" color="text.secondary">
                                Cliente: {cliente}
                            </Typography>
                        </Paper>
                    </Grid>

                    {/* Panel Derecho - Formas de Pago */}
                    <Grid item xs={12} md={7}>
                        <Paper sx={{ p: 2 }}>
                            <Tabs
                                value={activeTab}
                                onChange={(_, newValue) => setActiveTab(newValue)}
                                variant="scrollable"
                                scrollButtons="auto"
                                sx={{ mb: 2 }}
                            >
                                {PAYMENT_METHODS.map((method) => (
                                    <Tab
                                        key={method.id}
                                        icon={method.icon}
                                        label={method.nombre}
                                        sx={{
                                            color: method.color,
                                            '&.Mui-selected': { color: method.color },
                                        }}
                                    />
                                ))}
                            </Tabs>

                            {/* Monto actual */}
                            <Box sx={{ mb: 3 }}>
                                <Typography variant="subtitle2" gutterBottom>
                                    Monto a Pagar ({PAYMENT_METHODS[activeTab].nombre})
                                </Typography>
                                <TextField
                                    fullWidth
                                    type="number"
                                    value={currentAmount}
                                    onChange={(e) => setCurrentAmount(e.target.value)}
                                    placeholder="0.00"
                                    InputProps={{
                                        startAdornment: <Typography sx={{ mr: 1 }}>$</Typography>,
                                    }}
                                    sx={{ mb: 1 }}
                                />
                                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                                    <Button size="small" variant="outlined" onClick={handleExactAmount}>
                                        Exacto (${restante.toFixed(2)})
                                    </Button>
                                    {suggestedAmounts.map(amount => (
                                        <Button
                                            key={amount}
                                            size="small"
                                            variant="outlined"
                                            onClick={() => setCurrentAmount(amount.toString())}
                                        >
                                            ${amount}
                                        </Button>
                                    ))}
                                </Box>
                            </Box>

                            {/* Referencia (para tarjeta/transferencia) */}
                            {activeTab !== 0 && (
                                <TextField
                                    fullWidth
                                    label="Número de Referencia"
                                    value={referencia}
                                    onChange={(e) => setReferencia(e.target.value)}
                                    placeholder={activeTab === 1 ? 'Últimos 4 dígitos' : 'Número de referencia'}
                                    sx={{ mb: 2 }}
                                />
                            )}

                            <Button
                                variant="contained"
                                fullWidth
                                onClick={handleAddPayment}
                                disabled={!currentAmount || parseFloat(currentAmount) <= 0}
                            >
                                Agregar Pago
                            </Button>
                        </Paper>

                        {/* Pagos realizados */}
                        {payments.length > 0 && (
                            <Paper sx={{ p: 2, mt: 2 }}>
                                <Typography variant="subtitle2" gutterBottom>
                                    Pagos Realizados
                                </Typography>
                                {payments.map((payment, idx) => (
                                    <Box
                                        key={idx}
                                        sx={{
                                            display: 'flex',
                                            justifyContent: 'space-between',
                                            alignItems: 'center',
                                            py: 1,
                                            borderBottom: idx < payments.length - 1 ? '1px solid #eee' : 'none',
                                        }}
                                    >
                                        <Box>
                                            <Typography variant="body2" fontWeight="medium">
                                                {payment.metodo}
                                            </Typography>
                                            {payment.referencia && (
                                                <Typography variant="caption" color="text.secondary">
                                                    Ref: {payment.referencia}
                                                </Typography>
                                            )}
                                        </Box>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Typography fontWeight="medium">
                                                ${payment.monto.toFixed(2)}
                                            </Typography>
                                            <IconButton
                                                size="small"
                                                color="error"
                                                onClick={() => handleRemovePayment(idx)}
                                            >
                                                <CloseIcon fontSize="small" />
                                            </IconButton>
                                        </Box>
                                    </Box>
                                ))}
                            </Paper>
                        )}

                        {/* Totales de pago */}
                        <Paper sx={{ p: 2, mt: 2, bgcolor: totalPagado >= total ? '#e8f5e9' : '#fff3e0' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Pagado:</Typography>
                                <Typography fontWeight="bold">${totalPagado.toFixed(2)}</Typography>
                            </Box>
                            {restante > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                    <Typography color="warning.main">Restante:</Typography>
                                    <Typography fontWeight="bold" color="warning.main">
                                        ${restante.toFixed(2)}
                                    </Typography>
                                </Box>
                            )}
                            {cambio > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                    <Typography color="success.main">Cambio:</Typography>
                                    <Typography fontWeight="bold" color="success.main">
                                        ${cambio.toFixed(2)}
                                    </Typography>
                                </Box>
                            )}
                        </Paper>
                    </Grid>
                </Grid>
            </DialogContent>

            <DialogActions sx={{ p: 2, gap: 1 }}>
                <Button onClick={onClose} variant="outlined">
                    Cancelar
                </Button>
                <Button
                    variant="contained"
                    startIcon={<PrintIcon />}
                    onClick={handleCompletePayment}
                    disabled={totalPagado < total}
                    sx={{
                        bgcolor: totalPagado >= total ? 'success.main' : 'grey.400',
                        '&:hover': { bgcolor: totalPagado >= total ? 'success.dark' : 'grey.400' },
                    }}
                >
                    {totalPagado >= total ? 'Facturar e Imprimir' : `Faltan $${restante.toFixed(2)}`}
                </Button>
            </DialogActions>
        </Dialog>
    );
}
