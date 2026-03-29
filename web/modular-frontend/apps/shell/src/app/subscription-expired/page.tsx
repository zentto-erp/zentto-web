'use client';

import React from 'react';
import { Box, Typography, Button, Paper, Container, Alert } from '@mui/material';
import BlockIcon from '@mui/icons-material/Block';
import CreditCardIcon from '@mui/icons-material/CreditCard';
import { useRouter } from 'next/navigation';

export default function SubscriptionExpiredPage() {
  const router = useRouter();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        bgcolor: '#f5f5f5',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        px: 2,
      }}
    >
      <Container maxWidth="sm">
        <Paper elevation={6} sx={{ p: { xs: 4, md: 6 }, borderRadius: 3, textAlign: 'center' }}>
          <BlockIcon sx={{ fontSize: 72, color: '#e74c3c', mb: 2 }} />

          <Typography variant="h4" fontWeight={700} sx={{ mb: 2, fontSize: { xs: '1.5rem', md: '2rem' } }}>
            Suscripcion vencida
          </Typography>

          <Alert severity="warning" sx={{ mb: 3, textAlign: 'left' }}>
            Tu suscripcion ha expirado o fue cancelada. Para seguir usando Zentto,
            renueva tu plan o contacta a soporte.
          </Alert>

          <Typography variant="body2" sx={{ color: 'text.secondary', mb: 4 }}>
            Tus datos estan seguros y se mantendran intactos. Una vez que renueves tu suscripcion,
            podras acceder a todo como antes.
          </Typography>

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Button
              variant="contained"
              size="large"
              startIcon={<CreditCardIcon />}
              onClick={() => router.push('/pricing')}
              sx={{
                py: 1.5, fontWeight: 700, fontSize: '1rem', borderRadius: 2,
                bgcolor: '#6C63FF', '&:hover': { bgcolor: '#5b54e6' },
              }}
            >
              Renovar suscripcion
            </Button>

            <Button
              variant="outlined"
              size="large"
              onClick={() => window.location.href = 'mailto:soporte@zentto.net'}
              sx={{ py: 1.5, borderRadius: 2 }}
            >
              Contactar soporte
            </Button>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}
