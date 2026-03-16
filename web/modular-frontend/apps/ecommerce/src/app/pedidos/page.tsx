'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Typography, Alert } from '@mui/material';
import { useCartStore, useMyOrders, OrderHistory } from '@zentto/module-ecommerce';

export default function PedidosPage() {
    const router = useRouter();
    const customerToken = useCartStore((s) => s.customerToken);
    const [page] = useState(1);
    const { data, isLoading } = useMyOrders(page, 20);

    if (!customerToken) {
        return (
            <Box sx={{ textAlign: 'center', py: 8 }}>
                <Alert severity="info" sx={{ maxWidth: 500, mx: 'auto', mb: 2 }}>
                    Inicia sesion para ver tu historial de pedidos.
                </Alert>
                <Typography
                    variant="body1"
                    color="primary"
                    sx={{ cursor: 'pointer', textDecoration: 'underline' }}
                    onClick={() => router.push('/login')}
                >
                    Iniciar sesion
                </Typography>
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h5" gutterBottom>
                Mis Pedidos
            </Typography>
            <OrderHistory
                orders={data?.rows ?? []}
                loading={isLoading}
            />
        </Box>
    );
}
