'use client';

import { Box, Stack, Typography, Button } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useRouter, useParams } from 'next/navigation';
import { AdminProductForm } from '@zentto/module-ecommerce';

export default function EditAdminProductPage() {
    const router = useRouter();
    const params = useParams();
    const code = decodeURIComponent(String(params?.code ?? ''));

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
                    Editar producto · {code}
                </Typography>
            </Stack>
            <AdminProductForm code={code} />
        </Box>
    );
}
