'use client';

import React from 'react';
import Link from 'next/link';
import {
  Alert,
  Box,
  Button,
  Card,
  CircularProgress,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Logo } from '@zentto/shared-ui';
import { TurnstileCaptcha } from '@zentto/shared-auth';

const forgotSchema = z.object({
  identifier: z.string().min(1, 'Usuario o correo requerido'),
});

type ForgotForm = z.infer<typeof forgotSchema>;

function getBackendUrl() {
  return (
    process.env.NEXT_PUBLIC_API_BASE_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    process.env.NEXT_PUBLIC_BACKEND_URL ||
    'http://localhost:4000'
  );
}

export default function ForgotPasswordPage() {
  const [captchaToken, setCaptchaToken] = React.useState('');
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState<string | null>(null);
  const captchaEnabled = Boolean(process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotForm>({
    resolver: zodResolver(forgotSchema),
    defaultValues: { identifier: '' },
  });

  const onSubmit = async (values: ForgotForm) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    if (captchaEnabled && !captchaToken) {
      setError('Completa la verificacion CAPTCHA');
      setIsSubmitting(false);
      return;
    }

    try {
      const response = await fetch(`${getBackendUrl()}/v1/auth/forgot-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          identifier: values.identifier,
          captchaToken: captchaEnabled ? captchaToken : undefined,
        }),
      });
      const data = await response.json();
      if (!response.ok) {
        setError(data?.message || 'No fue posible procesar la solicitud');
        return;
      }

      setSuccess(data?.message || 'Solicitud procesada');
    } catch {
      setError('Error de red al solicitar recuperacion');
    } finally {
      setIsSubmitting(false);
    }
  };

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
              Recuperar contrasena
            </Typography>
            <Typography variant="body2" textAlign="center" color="text.secondary" mb={3}>
              Te enviaremos un enlace para restablecer tu contrasena
            </Typography>

            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

            <form onSubmit={handleSubmit(onSubmit)}>
              <Stack spacing={2}>
                <TextField label="Usuario o correo" {...register('identifier')} error={!!errors.identifier} helperText={errors.identifier?.message} />
                <TurnstileCaptcha onTokenChange={setCaptchaToken} />
                <Button type="submit" variant="contained" disabled={isSubmitting} sx={{ py: 1.5 }}>
                  {isSubmitting ? <CircularProgress size={22} color="inherit" /> : 'Enviar enlace'}
                </Button>
              </Stack>
            </form>

            <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
              <Typography variant="body2" color="text.secondary">
                Volver a
              </Typography>
              <Typography component={Link} href="/authentication/login" variant="body2" sx={{ textDecoration: 'none', color: 'primary.main', '&:hover': { textDecoration: 'underline' } }}>
                Iniciar sesion
              </Typography>
            </Stack>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
