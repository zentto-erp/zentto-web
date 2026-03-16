'use client';

import { useRouter } from 'next/navigation';
import { Box, Typography, Button, Divider, Grid, Paper } from '@mui/material';
import ShoppingCartCheckoutIcon from '@mui/icons-material/ShoppingCartCheckout';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import DeleteSweepIcon from '@mui/icons-material/DeleteSweep';
import { useCartStore, CartItem, OrderSummary } from '@zentto/module-ecommerce';

export default function CarritoPage() {
    const router = useRouter();
    const items = useCartStore((s) => s.items);
    const clearCart = useCartStore((s) => s.clearCart);
    const updateQuantity = useCartStore((s) => s.updateQuantity);
    const removeItem = useCartStore((s) => s.removeItem);
    const getSubtotal = useCartStore((s) => s.getSubtotal);
    const getTaxTotal = useCartStore((s) => s.getTaxTotal);
    const getTotal = useCartStore((s) => s.getTotal);

    if (items.length === 0) {
        return (
            <Box sx={{ textAlign: 'center', py: 8 }}>
                <Typography variant="h5" gutterBottom>
                    Tu carrito esta vacio
                </Typography>
                <Button variant="contained" onClick={() => router.push('/productos')}>
                    Ver productos
                </Button>
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h5" gutterBottom>
                Carrito de compras
            </Typography>

            <Grid container spacing={3}>
                <Grid xs={12} md={8}>
                    <Paper sx={{ p: 2 }}>
                        {items.map((item) => (
                            <Box key={item.productCode} sx={{ display: 'flex', alignItems: 'center', gap: 2, py: 1, borderBottom: '1px solid', borderColor: 'divider' }}>
                                <Box sx={{ width: 60, height: 60, bgcolor: 'grey.100', borderRadius: 1, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    {item.imageUrl ? (
                                        <Box component="img" src={item.imageUrl} alt={item.productName} sx={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
                                    ) : (
                                        <Typography variant="caption" color="text.secondary">Sin img</Typography>
                                    )}
                                </Box>
                                <Box sx={{ flexGrow: 1 }}>
                                    <Typography variant="body2" fontWeight="medium">{item.productName}</Typography>
                                    <Typography variant="caption" color="text.secondary">${item.unitPrice.toFixed(2)} c/u</Typography>
                                </Box>
                                <Box component="input" type="number" value={item.quantity} min={1} max={999}
                                    onChange={(e: any) => updateQuantity(item.productCode, Number(e.target.value))}
                                    style={{ width: 60, textAlign: 'center', padding: '4px' }}
                                />
                                <Typography variant="body2" fontWeight="bold" sx={{ minWidth: 80, textAlign: 'right' }}>
                                    ${item.total.toFixed(2)}
                                </Typography>
                                <Button size="small" color="error" onClick={() => removeItem(item.productCode)}>
                                    Quitar
                                </Button>
                            </Box>
                        ))}
                    </Paper>
                    <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
                        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push('/productos')}>
                            Seguir comprando
                        </Button>
                        <Button startIcon={<DeleteSweepIcon />} color="error" onClick={clearCart}>
                            Vaciar carrito
                        </Button>
                    </Box>
                </Grid>
                <Grid xs={12} md={4}>
                    <Paper sx={{ p: 3, position: 'sticky', top: 80 }}>
                        <OrderSummary items={items} subtotal={getSubtotal()} tax={getTaxTotal()} total={getTotal()} />
                        <Button
                            variant="contained"
                            fullWidth
                            size="large"
                            startIcon={<ShoppingCartCheckoutIcon />}
                            onClick={() => router.push('/checkout')}
                            sx={{ mt: 2 }}
                        >
                            Proceder al pago
                        </Button>
                    </Paper>
                </Grid>
            </Grid>
        </Box>
    );
}
