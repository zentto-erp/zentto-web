'use client';

import { useRouter } from 'next/navigation';
import { Box, Typography } from '@mui/material';
import { CheckoutForm, useCartStore } from '@zentto/module-ecommerce';

export default function CheckoutPage() {
    const router = useRouter();
    const items = useCartStore((s) => s.items);

    if (items.length === 0) {
        router.push('/carrito');
        return null;
    }

    return (
        <Box>
            <Typography variant="h5" gutterBottom>
                Finalizar compra
            </Typography>
            <CheckoutForm
                onSuccess={(orderToken) => router.push(`/confirmacion/${orderToken}`)}
                onBack={() => router.push('/carrito')}
            />
        </Box>
    );
}
