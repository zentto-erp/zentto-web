'use client';

import React from 'react';
import { Box, Typography, Button, Paper, Container } from '@mui/material';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import { useRouter } from 'next/navigation';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  bg: '#eaeded',
  white: '#ffffff',
} as const;

export default function BillingSuccessPage() {
  const router = useRouter();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        bgcolor: COLORS.bg,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        px: 2,
      }}
    >
      <Container maxWidth="sm">
        <Paper elevation={6} sx={{ p: { xs: 4, md: 6 }, borderRadius: 3, textAlign: 'center' }}>
          <CheckCircleOutlineIcon sx={{ fontSize: 72, color: '#4caf50', mb: 2 }} />

          <Typography
            variant="h4"
            fontWeight={700}
            sx={{ color: COLORS.darkPrimary, mb: 2, fontSize: { xs: '1.5rem', md: '2rem' } }}
          >
            Bienvenido a Zentto!
          </Typography>

          <Typography
            variant="body1"
            sx={{ color: 'text.secondary', mb: 1 }}
          >
            Tu suscripcion esta activa.
          </Typography>

          <Typography
            variant="body1"
            sx={{ color: 'text.secondary', mb: 4 }}
          >
            Tu empresa esta siendo configurada. En unos momentos tendras acceso completo a todas las funcionalidades de tu plan.
          </Typography>

          <Button
            variant="contained"
            size="large"
            onClick={() => router.push('/')}
            sx={{
              py: 1.5,
              px: 5,
              fontWeight: 700,
              fontSize: '1rem',
              borderRadius: 2,
              bgcolor: COLORS.accent,
              color: COLORS.darkPrimary,
              '&:hover': { bgcolor: '#e68a00' },
            }}
          >
            Ir al dashboard
          </Button>
        </Paper>
      </Container>
    </Box>
  );
}
