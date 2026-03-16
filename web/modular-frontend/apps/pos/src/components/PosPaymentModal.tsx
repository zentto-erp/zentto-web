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
import QrCode2Icon from '@mui/icons-material/QrCode2';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import PrintIcon from '@mui/icons-material/Print';

import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import { usePosStore } from '@zentto/shared-api';

interface PaymentMethod {
    id: string;
    nombre: string;
    icon: React.ReactElement;
    color: string;
    isDivisa?: boolean;
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
    { id: 'divisas', nombre: 'Divisas (Efectivo)', icon: <AttachMoneyIcon />, color: '#2e7d32', isDivisa: true },
    { id: 'punto_venta', nombre: 'Punto de Venta', icon: <CreditCardIcon />, color: '#2196f3' },
    { id: 'pago_movil', nombre: 'Pago Móvil', icon: <SmartphoneIcon />, color: '#9c27b0' },
    { id: 'transferencia', nombre: 'Transferencia', icon: <AccountBalanceIcon />, color: '#ff9800' },
    { id: 'cashea', nombre: 'Cashea', icon: <QrCode2Icon />, color: '#e91e63' },
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

    const { localizacion, getSubtotal, getImpuestos } = usePosStore();
    const isBs = localizacion.monedaPrincipal === 'Bs';
    const symP = localizacion.monedaPrincipal;
    const symR = localizacion.monedaReferencia;
    const tc = localizacion.tasaCambio || 1;

    // Calcular montos desde el carrito para ser precisos
    const subtotalLocal = getSubtotal();
    const impuestosLocal = getImpuestos();
    const totalLocal = total; // = getTotal()

    const totalRef = totalLocal / tc;

    // Si pagan con divisa, calcular IGTF
    const pagosDivisa = payments.filter(p => PAYMENT_METHODS.find(m => m.nombre === p.metodo)?.isDivisa);
    const totalPagadoDivisaLocal = pagosDivisa.reduce((sum, p) => sum + p.monto, 0);
    const igtfAplicado = (localizacion.aplicarIgtf && localizacion.tasaIgtf > 0)
        ? Math.round(totalPagadoDivisaLocal * (localizacion.tasaIgtf / 100) * 100) / 100
        : 0;

    const totalConIgtf = totalLocal + igtfAplicado;
    const totalPagado = payments.reduce((sum, p) => sum + p.monto, 0);
    const restante = Math.max(0, totalConIgtf - totalPagado);
    const cambio = Math.max(0, totalPagado - totalConIgtf);

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

        // Si el método es en divisa, el amount tipeado está en divisa, lo guardamos en local en 'monto' para totalizar
        // Ejemplo: Tipeó "10" dólares, tc=45 => monto = 450 Bs.
        const montoLocal = method.isDivisa ? amount * tc : amount;

        setPayments(prev => [...prev, {
            metodo: method.nombre,
            monto: montoLocal,
            referencia: referencia || undefined,
        }]);

        setCurrentAmount('');
        setReferencia('');
    };

    const handleRemovePayment = (index: number) => {
        setPayments(prev => prev.filter((_, i) => i !== index));
    };

    const handleCompletePayment = () => {
        if (totalPagado >= totalConIgtf) {
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

    const suggestedAmounts = [10, 20, 50, 100, 200, 500].filter(a => a >= (totalConIgtf / tc) || a >= (restante / tc));

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
        <Dialog
            open={open}
            onClose={onClose}
            maxWidth={false}
            fullWidth
            PaperProps={{
                sx: {
                    width: 'min(1320px, 98vw)',
                },
            }}
        >
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
                        <Paper sx={{ p: 2, height: '100%', bgcolor: 'action.hover' }}>
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
                                            {symP} {item.total.toFixed(2)}
                                        </Typography>
                                    </Box>
                                ))}
                            </Box>

                            <Divider sx={{ my: 1 }} />

                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Subtotal Base:</Typography>
                                <Typography>{symP} {subtotalLocal.toFixed(2)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>IVA Totales:</Typography>
                                <Typography>{symP} {impuestosLocal.toFixed(2)}</Typography>
                            </Box>

                            {igtfAplicado > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                    <Typography color="secondary.main">IGTF ({localizacion.tasaIgtf}%):</Typography>
                                    <Typography color="secondary.main">{symP} {igtfAplicado.toFixed(2)}</Typography>
                                </Box>
                            )}

                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2, alignItems: 'center' }}>
                                <Typography variant="h6" fontWeight="bold">Total Pagar:</Typography>
                                <Box sx={{ textAlign: 'right' }}>
                                    <Typography variant="h6" fontWeight="bold" color="primary">
                                        {symP} {totalConIgtf.toFixed(2)}
                                    </Typography>
                                    <Typography variant="caption" color="text.secondary">
                                        Ref {symR} {(totalConIgtf / tc).toFixed(2)} (Tasa: {tc.toFixed(2)})
                                    </Typography>
                                </Box>
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
                                    {PAYMENT_METHODS[activeTab].isDivisa && (
                                        <Typography component="span" variant="caption" color="secondary" sx={{ ml: 1 }}>
                                            (+{localizacion.tasaIgtf}% IGTF)
                                        </Typography>
                                    )}
                                </Typography>
                                <TextField
                                    fullWidth
                                    type="number"
                                    value={currentAmount}
                                    onChange={(e) => setCurrentAmount(e.target.value)}
                                    placeholder="0.00"
                                    InputProps={{
                                        startAdornment: <Typography sx={{ mr: 1, whiteSpace: 'nowrap' }}>
                                            {PAYMENT_METHODS[activeTab].isDivisa ? symR : symP}
                                        </Typography>,
                                    }}
                                    sx={{ mb: 1 }}
                                    helperText={`Nota: Ingresa el monto en ${PAYMENT_METHODS[activeTab].isDivisa ? 'Divisa (' + symR + ')' : 'Moneda Local (' + symP + ')'} `}
                                />
                                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                                    {PAYMENT_METHODS[activeTab].isDivisa ? (
                                        <Button size="small" variant="outlined" onClick={() => setCurrentAmount((restante / tc).toFixed(2))}>
                                            Exacto Ref ({symR} {(restante / tc).toFixed(2)})
                                        </Button>
                                    ) : (
                                        <Button size="small" variant="outlined" onClick={() => setCurrentAmount(restante.toFixed(2))}>
                                            Exacto ({symP} {restante.toFixed(2)})
                                        </Button>
                                    )}
                                </Box>
                            </Box>

                            {/* Referencia (para tarjeta/transferencia/etc) */}
                            {!['efectivo', 'divisas'].includes(PAYMENT_METHODS[activeTab].id) && (
                                <TextField
                                    fullWidth
                                    label={
                                        PAYMENT_METHODS[activeTab].id === 'cashea' ? 'Token / Nro de Orden Cashea' :
                                            PAYMENT_METHODS[activeTab].id === 'punto_venta' ? 'Nro de Aprobación (Lote/Ref)' :
                                                PAYMENT_METHODS[activeTab].id === 'pago_movil' ? 'Referencia Pago Móvil (Ultimos dígitos)' :
                                                    'Número de Referencia Bancaria'
                                    }
                                    value={referencia}
                                    onChange={(e) => setReferencia(e.target.value)}
                                    placeholder="Simula ingreso de Ref / API externa futura"
                                    sx={{ mb: 2 }}
                                    helperText={
                                        ['cashea', 'pago_movil', 'punto_venta'].includes(PAYMENT_METHODS[activeTab].id)
                                            ? "Nota: A futuro esto se llenará automáticamente vía integración API." : ""
                                    }
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
                                                {symP} {payment.monto.toFixed(2)}
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
                        <Paper sx={{ p: 2, mt: 2, bgcolor: totalPagado >= totalConIgtf ? 'success.light' : 'warning.light' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography>Pagado:</Typography>
                                <Typography fontWeight="bold">{symP} {totalPagado.toFixed(2)}</Typography>
                            </Box>
                            {restante > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                    <Typography color="warning.main">Restante:</Typography>
                                    <Typography fontWeight="bold" color="warning.main">
                                        {symP} {restante.toFixed(2)}
                                    </Typography>
                                </Box>
                            )}
                            {cambio > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                    <Typography color="success.main">Cambio:</Typography>
                                    <Typography fontWeight="bold" color="success.main">
                                        {symP} {cambio.toFixed(2)}
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
                    disabled={totalPagado < totalConIgtf}
                    sx={{
                        bgcolor: totalPagado >= totalConIgtf ? 'success.main' : 'grey.400',
                        '&:hover': { bgcolor: totalPagado >= totalConIgtf ? 'success.dark' : 'grey.400' },
                    }}
                >
                    {totalPagado >= totalConIgtf ? 'Facturar e Imprimir' : `Faltan ${symP} ${restante.toFixed(2)}`}
                </Button>
            </DialogActions>
        </Dialog>
    );
}
