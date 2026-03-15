'use client';

import { useParams, useRouter } from 'next/navigation';
import { Box, Typography, Paper, Button, CircularProgress, Divider, List, ListItem, ListItemText, Alert } from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { useOrderByToken } from '@datqbox/module-ecommerce';

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

    return (
        <Box sx={{ maxWidth: 700, mx: 'auto', py: 4 }}>
            <Paper sx={{ p: 4, textAlign: 'center' }}>
                <CheckCircleIcon color="success" sx={{ fontSize: 64, mb: 2 }} />
                <Typography variant="h4" gutterBottom>
                    Pedido confirmado
                </Typography>
                <Typography variant="h6" color="text.secondary" gutterBottom>
                    {order.orderNumber}
                </Typography>
                <Typography variant="body1" sx={{ mb: 3 }}>
                    Gracias por tu compra, {order.customerName}. Te contactaremos para coordinar el pago y la entrega.
                </Typography>

                <Divider sx={{ my: 2 }} />

                <Typography variant="h6" align="left" gutterBottom>
                    Detalle del pedido
                </Typography>
                <List dense>
                    {(order.lines ?? []).map((line: any) => (
                        <ListItem key={line.lineNumber} disableGutters>
                            <ListItemText
                                primary={line.productName}
                                secondary={`${line.quantity} x $${line.unitPrice?.toFixed(2)}`}
                            />
                            <Typography variant="body2" fontWeight="bold">
                                ${line.totalAmount?.toFixed(2)}
                            </Typography>
                        </ListItem>
                    ))}
                </List>

                <Divider sx={{ my: 2 }} />

                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography>Subtotal:</Typography>
                    <Typography>${order.subtotal?.toFixed(2)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography>IVA:</Typography>
                    <Typography>${order.taxAmount?.toFixed(2)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                    <Typography variant="h6">Total:</Typography>
                    <Typography variant="h6" color="primary" fontWeight="bold">
                        ${order.totalAmount?.toFixed(2)}
                    </Typography>
                </Box>

                <Button variant="contained" onClick={() => router.push('/')} sx={{ mt: 2 }}>
                    Seguir comprando
                </Button>
            </Paper>
        </Box>
    );
}
