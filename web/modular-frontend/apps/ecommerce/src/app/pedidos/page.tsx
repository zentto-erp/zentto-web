'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
    Box, Typography, Alert, Dialog, DialogContent, DialogTitle,
    IconButton, CircularProgress,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import {
    useCartStore, useMyOrders, OrderHistory,
    useMyOrderDetail, ReturnRequestForm,
} from '@zentto/module-ecommerce';

export default function PedidosPage() {
    const router = useRouter();
    const customerToken = useCartStore((s) => s.customerToken);
    const [page] = useState(1);
    const { data, isLoading } = useMyOrders(page, 20);

    const [returnOrderNumber, setReturnOrderNumber] = useState<string | null>(null);
    const [returnSuccess, setReturnSuccess] = useState(false);

    const { data: orderDetail, isFetching: loadingDetail } = useMyOrderDetail(
        returnOrderNumber ?? undefined
    );

    const handleReturnCreated = (_returnId: number) => {
        setReturnOrderNumber(null);
        setReturnSuccess(true);
    };

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
            <Typography variant="h5" gutterBottom>Mis Pedidos</Typography>

            {returnSuccess && (
                <Alert severity="success" sx={{ mb: 2 }} onClose={() => setReturnSuccess(false)}>
                    Solicitud de devolución enviada. Te contactaremos pronto.
                </Alert>
            )}

            <OrderHistory
                orders={data?.rows ?? []}
                loading={isLoading}
                onRequestReturn={(orderNumber) => {
                    setReturnSuccess(false);
                    setReturnOrderNumber(orderNumber);
                }}
            />

            <Dialog
                open={!!returnOrderNumber}
                onClose={() => setReturnOrderNumber(null)}
                maxWidth="md"
                fullWidth
            >
                <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    Solicitar devolución
                    <IconButton onClick={() => setReturnOrderNumber(null)} size="small">
                        <CloseIcon />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    {loadingDetail && (
                        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                            <CircularProgress />
                        </Box>
                    )}
                    {!loadingDetail && orderDetail && (
                        <ReturnRequestForm
                            orderNumber={orderDetail.orderNumber}
                            lines={orderDetail.lines}
                            onCreated={handleReturnCreated}
                            onCancel={() => setReturnOrderNumber(null)}
                        />
                    )}
                </DialogContent>
            </Dialog>
        </Box>
    );
}
