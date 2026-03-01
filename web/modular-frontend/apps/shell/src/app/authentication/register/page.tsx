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
import { Logo } from '@datqbox/shared-ui';
import { TurnstileCaptcha } from '@datqbox/shared-auth';

const registerSchema = z
  .object({
    usuario: z.string().min(3).max(10).regex(/^[A-Za-z0-9._-]+$/),
    nombre: z.string().min(3).max(100),
    email: z.string().email(),
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

type RegisterForm = z.infer<typeof registerSchema>;

function getBackendUrl() {
  return (
    process.env.NEXT_PUBLIC_API_BASE_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    process.env.NEXT_PUBLIC_BACKEND_URL ||
    'http://localhost:4000'
  );
}

export default function RegisterPage() {
  const [captchaToken, setCaptchaToken] = React.useState('');
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState<string | null>(null);
  const captchaEnabled = Boolean(process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterForm>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      usuario: '',
      nombre: '',
      email: '',
      password: '',
      confirmPassword: '',
    },
  });

  const onSubmit = async (values: RegisterForm) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    if (captchaEnabled && !captchaToken) {
      setError('Completa la verificacion CAPTCHA');
      setIsSubmitting(false);
      return;
    }

    try {
      const response = await fetch(`${getBackendUrl()}/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuario: values.usuario,
          nombre: values.nombre,
          email: values.email,
          password: values.password,
          captchaToken: captchaEnabled ? captchaToken : undefined,
        }),
      });
      const data = await response.json();
      if (!response.ok) {
        setError(data?.message || 'No fue posible completar el registro');
        return;
      }
      setSuccess(data?.message || 'Registro completado');
    } catch {
      setError('Error de red al registrar usuario');
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
          <Card elevation={9} sx={{ p: 4, zIndex: 1, width: '100%', maxWidth: '560px', mx: 2 }}>
            <Box display="flex" alignItems="center" justifyContent="center" mb={2}>
              <Logo />
            </Box>
            <Typography variant="h5" fontWeight={700} textAlign="center" mb={1}>
              Crear cuenta
            </Typography>
            <Typography variant="body2" textAlign="center" color="text.secondary" mb={3}>
              Registro con verificacion por correo y proteccion anti-bot
            </Typography>

            {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

            <form onSubmit={handleSubmit(onSubmit)}>
              <Stack spacing={2}>
                <TextField label="Usuario" {...register('usuario')} error={!!errors.usuario} helperText={errors.usuario?.message} />
                <TextField label="Nombre completo" {...register('nombre')} error={!!errors.nombre} helperText={errors.nombre?.message} />
                <TextField label="Correo" type="email" {...register('email')} error={!!errors.email} helperText={errors.email?.message} />
                <TextField label="Contrasena" type="password" {...register('password')} error={!!errors.password} helperText={errors.password?.message} />
                <TextField
                  label="Confirmar contrasena"
                  type="password"
                  {...register('confirmPassword')}
                  error={!!errors.confirmPassword}
                  helperText={errors.confirmPassword?.message}
                />
                <TurnstileCaptcha onTokenChange={setCaptchaToken} />
                <Button type="submit" variant="contained" disabled={isSubmitting} sx={{ py: 1.5 }}>
                  {isSubmitting ? <CircularProgress size={22} color="inherit" /> : 'Registrar'}
                </Button>
              </Stack>
            </form>

            <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
              <Typography variant="body2" color="text.secondary">
                Ya tienes cuenta?
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

