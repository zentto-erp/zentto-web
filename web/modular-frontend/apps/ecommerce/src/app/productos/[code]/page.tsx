'use client';

import { useParams, useRouter } from 'next/navigation';
import { Box, CircularProgress, Typography } from '@mui/material';
import { useProductDetail, ProductDetail, ProductReviews } from '@zentto/module-ecommerce';

export default function ProductDetailPage() {
    const { code } = useParams<{ code: string }>();
    const router = useRouter();
    const { data: product, isLoading, error } = useProductDetail(code);

    if (isLoading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
                <CircularProgress sx={{ color: '#ff9900' }} />
            </Box>
        );
    }

    if (error || !product) {
        return (
            <Box sx={{ textAlign: 'center', py: 8 }}>
                <Typography variant="h6" color="error">
                    Producto no encontrado
                </Typography>
            </Box>
        );
    }

    return (
        <ProductDetail
            product={product}
            onBack={() => router.back()}
            reviews={<ProductReviews productCode={product.code} />}
        />
    );
}
