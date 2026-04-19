'use client';

import { useParams, useRouter } from 'next/navigation';
import {
  Box, Typography, Paper, Button, CircularProgress, Divider, List, ListItem, ListItemText, Alert, Grid,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { useOrderByToken, OrderTimeline, RecentlyViewedRail } from '@zentto/module-ecommerce';

export default function ConfirmacionPage() {
    const { token } = useParams<{ token: string }>();
    const router = useRouter();
    const { data: order, isLoading, error } = useOrderByToken(token);

    if (isLoading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                <CircularProgress />
            </Box>
        );
    }

    if (error || !order) {
        return (
            <Box sx={{ textAlign: 'center', py: 8 }}>
                <Alert severity="error" sx={{ maxWidth: 500, mx: 'auto' }}>
                    No se pudo encontrar el pedido. Verifica el enlace.
                </Alert>
            </Box>
        );
    }

    const fmt = (n: number | undefined) =>
        n != null ? Number(n).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00';

    return (
        <Box sx={{ maxWidth: 1080, mx: 'auto', py: 4, px: 2 }}>
            <Paper sx={{ p: 4, mb: 3, textAlign: 'center', bgcolor: '#f0faf0', border: '1px solid #c3eccd' }}>
                <CheckCircleIcon color="success" sx={{ fontSize: 64, mb: 1 }} />
                <Typography variant="h4" gutterBottom fontWeight={700}>
                    Pedido confirmado
                </Typography>
                <Typography variant="h6" color="text.secondary" gutterBottom>
                    {order.orderNumber}
                </Typography>
                <Typography variant="body1">
                    Gracias por tu compra, {order.customerName}. Te avisaremos por email cada vez que haya
                    una novedad sobre tu pedido.
                </Typography>
            </Paper>

            <Grid container spacing={3}>
                {/* Detalle */}
                <Grid item xs={12} md={7}>
                    <Paper sx={{ p: 3 }}>
                        <Typography variant="h6" gutterBottom fontWeight={700}>
                            Detalle del pedido
                        </Typography>
                        <List dense>
                            {(order.lines ?? []).map((line: any) => (
                                <ListItem key={line.lineNumber} disableGutters>
                                    <ListItemText
                                        primary={line.productName}
                                        secondary={`${line.quantity} x ${fmt(line.unitPrice)}`}
                                    />
                                    <Typography variant="body2" fontWeight="bold">
                                        {fmt(line.totalAmount)}
                                    </Typography>
                                </ListItem>
                            ))}
                        </List>

                        <Divider sx={{ my: 2 }} />

                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                            <Typography>Subtotal:</Typography>
                            <Typography>{fmt(order.subtotal)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                            <Typography>Impuestos:</Typography>
                            <Typography>{fmt(order.taxAmount)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 1 }}>
                            <Typography variant="h6" fontWeight={700}>Total:</Typography>
                            <Typography variant="h6" color="primary" fontWeight={700}>
                                {fmt(order.totalAmount)}
                            </Typography>
                        </Box>
                    </Paper>
                </Grid>

                {/* Timeline */}
                <Grid item xs={12} md={5}>
                    <Paper sx={{ p: 3 }}>
                        <Typography variant="h6" gutterBottom fontWeight={700}>
                            Seguimiento
                        </Typography>
                        <OrderTimeline orderToken={token} />
                    </Paper>
                </Grid>
            </Grid>

            <Box sx={{ textAlign: 'center', mt: 3 }}>
                <Button variant="contained" onClick={() => router.push('/')} size="large">
                    Seguir comprando
                </Button>
            </Box>

            <RecentlyViewedRail
                title="Mientras tanto, mira esto"
                onProductClick={(code) => router.push(`/productos/${code}`)}
            />
        </Box>
    );
}
