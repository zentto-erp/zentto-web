'use client';

import React from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import {
  Alert,
  Box,
  Button,
  Card,
  CircularProgress,
  Stack,
  Typography,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import Logo from '@/app/(dashboard)/shared/logo/Logo';

function getBackendUrl() {
  return (
    process.env.NEXT_PUBLIC_API_BASE_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    process.env.NEXT_PUBLIC_BACKEND_URL ||
    'http://localhost:4000'
  );
}

export default function VerifyEmailPage() {
  const searchParams = useSearchParams();
  const token = String(searchParams.get('token') || '');
  const [loading, setLoading] = React.useState(true);
  const [success, setSuccess] = React.useState<string | null>(null);
  const [error, setError] = React.useState<string | null>(null);

  const verify = React.useCallback(async () => {
    if (!token) {
      setError('Token de verificacion invalido');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      const response = await fetch(
        `${getBackendUrl()}/v1/auth/verify-email?token=${encodeURIComponent(token)}`,
        { method: 'GET' }
      );
      const data = await response.json();
      if (!response.ok) {
        setError(data?.message || 'No fue posible verificar la cuenta');
      } else {
        setSuccess(data?.message || 'Cuenta verificada correctamente');
      }
    } catch {
      setError('Error de red al verificar cuenta');
    } finally {
      setLoading(false);
    }
  }, [token]);

  React.useEffect(() => {
    verify();
  }, [verify]);

  return (
    <Box
      sx={{
        position: 'relative',
        width: '100%',
        height: '100vh',
        '&:before': {
          content: '""',
          background: 'radial-gradient(#d2f1df, #d3d7fa, #bad8f4)',
          backgroundSize: '400% 400%',
          animation: 'gradient 15s ease infinite',
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          opacity: 0.3,
        },
      }}
    >
      <Grid container spacing={0} sx={{ width: '100%', height: '100%', justifyContent: 'center', alignItems: 'center' }}>
        <Grid size={{ xs: 12, sm: 12, lg: 5, xl: 4 }} sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <Card elevation={9} sx={{ p: 4, zIndex: 1, width: '100%', maxWidth: '520px', mx: 2 }}>
            <Box display="flex" alignItems="center" justifyContent="center" mb={2}>
              <Logo />
            </Box>

            <Typography variant="h5" fontWeight={700} textAlign="center" mb={1}>
              Verificacion de correo
            </Typography>
            <Typography variant="body2" textAlign="center" color="text.secondary" mb={3}>
              Validando enlace de activacion
            </Typography>

            {loading && (
              <Stack direction="row" spacing={1} justifyContent="center" alignItems="center" sx={{ mb: 2 }}>
                <CircularProgress size={22} />
                <Typography variant="body2">Procesando...</Typography>
              </Stack>
            )}
            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

            <Stack spacing={1}>
              {!loading && error && (
                <Button variant="outlined" onClick={verify}>
                  Reintentar verificacion
                </Button>
              )}
              <Button component={Link} href="/authentication/login" variant="contained">
                Ir a iniciar sesion
              </Button>
            </Stack>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
