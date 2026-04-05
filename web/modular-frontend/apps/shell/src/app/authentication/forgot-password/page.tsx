'use client';

import React from 'react';
import Link from 'next/link';
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  FormControl,
  FormHelperText,
  OutlinedInput,
  Stack,
  Typography,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Logo, ThemeToggle } from '@zentto/shared-ui';
import { TurnstileCaptcha } from '@zentto/shared-auth';
import BrandPanel from '../BrandPanel';

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
    control,
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
      setError('Completa la verificación CAPTCHA');
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
      setError('Error de red al solicitar recuperación');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', width: '100%' }}>
      <BrandPanel
        title={<>Recupera tu acceso a{' '}<Box component="span" sx={{ color: '#FFB547' }}>Zentto</Box></>}
        description="Te enviaremos un enlace para restablecer tu contraseña de forma segura."
      />

      {/* Right panel — forgot password form */}
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          p: { xs: 3, sm: 5 },
          bgcolor: 'background.default',
          position: 'relative',
        }}
      >
        <ThemeToggle sx={{ position: 'absolute', top: 16, right: 16 }} />

        <Box sx={{ width: '100%', maxWidth: 400 }}>
          {/* Logo for mobile */}
          <Box sx={{ display: { xs: 'flex', md: 'none' }, justifyContent: 'center', mb: 3 }}>
            <Logo />
          </Box>

          <Typography
            sx={{
              fontFamily: "'Inter', system-ui, sans-serif",
              fontWeight: 700,
              fontSize: '1.25rem',
              letterSpacing: '-0.025em',
              mb: 0.5,
            }}
          >
            Recuperar contraseña
          </Typography>
          <Typography
            sx={{
              fontFamily: "'Inter', system-ui, sans-serif",
              color: 'text.secondary',
              fontSize: '0.875rem',
              mb: 3,
            }}
          >
            Ingresa tu usuario o correo para recuperar acceso
          </Typography>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

          <form onSubmit={handleSubmit(onSubmit)}>
            <Stack spacing={2}>
              <Controller
                name="identifier"
                control={control}
                render={({ field }) => (
                  <FormControl error={!!errors.identifier} fullWidth>
                    <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
                      Usuario o correo
                    </Typography>
                    <OutlinedInput
                      {...field}
                      placeholder="Tu usuario o correo electrónico"
                      disabled={isSubmitting}
                      sx={{
                        '& .MuiOutlinedInput-input': { py: 1.75, px: 2 },
                        '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                      }}
                    />
                    {errors.identifier && <FormHelperText>{errors.identifier.message}</FormHelperText>}
                  </FormControl>
                )}
              />
              <TurnstileCaptcha onTokenChange={setCaptchaToken} />
              <Button
                type="submit"
                variant="contained"
                size="large"
                disabled={isSubmitting}
                fullWidth
                sx={{
                  py: 1.75,
                  fontWeight: 600,
                  textTransform: 'none',
                  fontSize: '1rem',
                  borderRadius: 2,
                  mt: 1,
                }}
              >
                {isSubmitting ? <CircularProgress size={24} color="inherit" /> : 'Enviar enlace'}
              </Button>
            </Stack>
          </form>

          <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
            <Typography variant="body2" color="textSecondary" fontWeight="500" sx={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
              ¿Recordaste tu contraseña?
            </Typography>
            <Typography
              component={Link}
              href="/authentication/login"
              variant="body2"
              fontWeight="500"
              sx={{ fontFamily: "'Inter', system-ui, sans-serif", textDecoration: 'none', color: 'primary.main', '&:hover': { textDecoration: 'underline' } }}
            >
              Iniciar sesión
            </Typography>
          </Stack>
        </Box>
      </Box>
    </Box>
  );
}
