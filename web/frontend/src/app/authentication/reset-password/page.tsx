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
  TextField,
  Typography,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import Logo from '@/app/(dashboard)/shared/logo/Logo';
import TurnstileCaptcha from '../auth/TurnstileCaptcha';

const resetSchema = z
  .object({
    password: z
      .string()
      .min(8)
      .regex(/[A-Z]/, 'Debe incluir una mayuscula')
      .regex(/[a-z]/, 'Debe incluir una minuscula')
      .regex(/[0-9]/, 'Debe incluir un numero'),
    confirmPassword: z.string().min(8),
  })
  .refine((v) => v.password === v.confirmPassword, {
    path: ['confirmPassword'],
    message: 'Las contrasenas no coinciden',
  });

type ResetForm = z.infer<typeof resetSchema>;

function getBackendUrl() {
  return (
    process.env.NEXT_PUBLIC_API_BASE_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    process.env.NEXT_PUBLIC_BACKEND_URL ||
    'http://localhost:4000'
  );
}

export default function ResetPasswordPage() {
  const searchParams = useSearchParams();
  const token = String(searchParams.get('token') || '');
  const [captchaToken, setCaptchaToken] = React.useState('');
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState<string | null>(null);
  const captchaEnabled = Boolean(process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ResetForm>({
    resolver: zodResolver(resetSchema),
    defaultValues: {
      password: '',
      confirmPassword: '',
    },
  });

  const onSubmit = async (values: ResetForm) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    if (!token) {
      setError('Token de recuperacion invalido');
      setIsSubmitting(false);
      return;
    }

    if (captchaEnabled && !captchaToken) {
      setError('Completa la verificacion CAPTCHA');
      setIsSubmitting(false);
      return;
    }

    try {
      const response = await fetch(`${getBackendUrl()}/v1/auth/reset-password/confirm`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token,
          newPassword: values.password,
          captchaToken: captchaEnabled ? captchaToken : undefined,
        }),
      });
      const data = await response.json();
      if (!response.ok) {
        setError(data?.message || 'No fue posible restablecer la contrasena');
        return;
      }

      setSuccess(data?.message || 'Contrasena actualizada correctamente');
    } catch {
      setError('Error de red al restablecer contrasena');
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
              Restablecer contrasena
            </Typography>
            <Typography variant="body2" textAlign="center" color="text.secondary" mb={3}>
              Define una nueva contrasena segura
            </Typography>

            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

            <form onSubmit={handleSubmit(onSubmit)}>
              <Stack spacing={2}>
                <TextField
                  label="Nueva contrasena"
                  type="password"
                  {...register('password')}
                  error={!!errors.password}
                  helperText={errors.password?.message}
                />
                <TextField
                  label="Confirmar contrasena"
                  type="password"
                  {...register('confirmPassword')}
                  error={!!errors.confirmPassword}
                  helperText={errors.confirmPassword?.message}
                />
                <TurnstileCaptcha onTokenChange={setCaptchaToken} />
                <Button type="submit" variant="contained" disabled={isSubmitting} sx={{ py: 1.5 }}>
                  {isSubmitting ? <CircularProgress size={22} color="inherit" /> : 'Actualizar contrasena'}
                </Button>
              </Stack>
            </form>

            <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
              <Typography variant="body2" color="text.secondary">
                Ir a
              </Typography>
              <Typography
                component={Link}
                href="/authentication/login"
                variant="body2"
                sx={{ textDecoration: 'none', color: 'primary.main', '&:hover': { textDecoration: 'underline' } }}
              >
                Iniciar sesion
              </Typography>
            </Stack>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
