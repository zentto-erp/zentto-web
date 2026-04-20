'use client';

import { Box, Stack, Typography, Button } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useRouter } from 'next/navigation';
import { AdminProductForm } from '@zentto/module-ecommerce';

export default function NewAdminProductPage() {
    const router = useRouter();
    return (
        <Box>
            <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
                <Button
                    startIcon={<ArrowBackIcon />}
                    onClick={() => router.push('/admin/productos')}
                    size="small"
                >
                    Volver
                </Button>
                <Typography variant="h5" fontWeight={700}>
                    Nuevo producto
                </Typography>
            </Stack>
            <AdminProductForm onSaved={(code) => router.push(`/admin/productos/${encodeURIComponent(code)}/editar`)} />
        </Box>
    );
}
