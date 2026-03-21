'use client';

import React from 'react';
import Link from 'next/link';
import {
  Alert,
  Box,
  Button,
  Card,
  CircularProgress,
  FormControl,
  FormHelperText,
  IconButton,
  InputAdornment,
  OutlinedInput,
  Stack,
  Typography,
} from '@mui/material';
import { Visibility, VisibilityOff } from '@mui/icons-material';
import Grid from '@mui/material/Grid2';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Logo } from '@zentto/shared-ui';
import { TurnstileCaptcha } from '@zentto/shared-auth';

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
  const [registeredEmail, setRegisteredEmail] = React.useState<string | null>(null);
  const captchaEnabled = Boolean(process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY);

  const [showPassword, setShowPassword] = React.useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = React.useState(false);

  const {
    control,
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
      setRegisteredEmail(values.email);
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

            {registeredEmail ? (
              /* ── Pantalla de confirmación de email ── */
              <Stack spacing={3} alignItems="center" textAlign="center">
                <Box sx={{ fontSize: 56, lineHeight: 1 }}>&#9993;</Box>
                <Typography variant="h5" fontWeight={700}>
                  Revisa tu correo
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Enviamos un enlace de confirmacion a:
                </Typography>
                <Typography variant="body1" fontWeight={600}>
                  {registeredEmail}
                </Typography>
                <Typography variant="caption" color="text.secondary" sx={{ maxWidth: 360 }}>
                  Haz clic en el enlace del email para activar tu cuenta.
                  Si no lo ves, revisa la carpeta de spam o correo no deseado.
                </Typography>
                <Button
                  component={Link}
                  href="/authentication/login"
                  variant="contained"
                  sx={{ py: 1.5, px: 6 }}
                >
                  Ir al login
                </Button>
                <Typography variant="caption" color="text.secondary">
                  No recibiste el email?{' '}
                  <Typography
                    component="span"
                    variant="caption"
                    sx={{ color: 'primary.main', cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
                    onClick={() => { setRegisteredEmail(null); setSuccess(null); }}
                  >
                    Intentar de nuevo
                  </Typography>
                </Typography>
              </Stack>
            ) : (
              /* ── Formulario de registro ── */
              <>
                <Typography variant="subtitle1" textAlign="center" color="textSecondary" mb={1}>
                  Crea tu cuenta para comenzar
                </Typography>

                {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
                {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

                <form onSubmit={handleSubmit(onSubmit)}>
                  <Stack spacing={2}>
                    <Controller
                      name="usuario"
                      control={control}
                      render={({ field }) => (
                        <FormControl error={!!errors.usuario} fullWidth>
                          <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary' }}>
                            Usuario
                          </Typography>
                          <OutlinedInput
                            {...field}
                            placeholder="Nombre de usuario"
                            sx={{
                              '& .MuiOutlinedInput-input': { py: 1.75, px: 2 },
                              '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                            }}
                          />
                          {errors.usuario && <FormHelperText>{errors.usuario.message}</FormHelperText>}
                        </FormControl>
                      )}
                    />

                    <Controller
                      name="nombre"
                      control={control}
                      render={({ field }) => (
                        <FormControl error={!!errors.nombre} fullWidth>
                          <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary' }}>
                            Nombre completo
                          </Typography>
                          <OutlinedInput
                            {...field}
                            placeholder="Tu nombre completo"
                            sx={{
                              '& .MuiOutlinedInput-input': { py: 1.75, px: 2 },
                              '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                            }}
                          />
                          {errors.nombre && <FormHelperText>{errors.nombre.message}</FormHelperText>}
                        </FormControl>
                      )}
                    />

                    <Controller
                      name="email"
                      control={control}
                      render={({ field }) => (
                        <FormControl error={!!errors.email} fullWidth>
                          <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary' }}>
                            Correo electrónico
                          </Typography>
                          <OutlinedInput
                            {...field}
                            type="email"
                            placeholder="tu@correo.com"
                            sx={{
                              '& .MuiOutlinedInput-input': { py: 1.75, px: 2 },
                              '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                            }}
                          />
                          {errors.email && <FormHelperText>{errors.email.message}</FormHelperText>}
                        </FormControl>
                      )}
                    />

                    <Controller
                      name="password"
                      control={control}
                      render={({ field }) => (
                        <FormControl error={!!errors.password} fullWidth>
                          <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary' }}>
                            Contraseña
                          </Typography>
                          <OutlinedInput
                            {...field}
                            type={showPassword ? 'text' : 'password'}
                            placeholder="Contraseña"
                            sx={{
                              '& .MuiOutlinedInput-input': {
                                py: 1.75, px: 2,
                                '&::-ms-reveal, &::-ms-clear': { display: 'none' },
                                '&::-webkit-credentials-auto-fill-button, &::-webkit-clear-button, &::-webkit-textfield-decoration-container': { display: 'none' },
                              },
                              '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                            }}
                            endAdornment={
                              field.value ? (
                                <InputAdornment position="end">
                                  <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small" sx={{ p: 0.5 }}>
                                    {showPassword ? <VisibilityOff sx={{ fontSize: 18 }} /> : <Visibility sx={{ fontSize: 18 }} />}
                                  </IconButton>
                                </InputAdornment>
                              ) : null
                            }
                          />
                          {errors.password && <FormHelperText>{errors.password.message}</FormHelperText>}
                        </FormControl>
                      )}
                    />

                    <Controller
                      name="confirmPassword"
                      control={control}
                      render={({ field }) => (
                        <FormControl error={!!errors.confirmPassword} fullWidth>
                          <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary' }}>
                            Confirmar contraseña
                          </Typography>
                          <OutlinedInput
                            {...field}
                            type={showConfirmPassword ? 'text' : 'password'}
                            placeholder="Repite la contraseña"
                            sx={{
                              '& .MuiOutlinedInput-input': {
                                py: 1.75, px: 2,
                                '&::-ms-reveal, &::-ms-clear': { display: 'none' },
                                '&::-webkit-credentials-auto-fill-button, &::-webkit-clear-button, &::-webkit-textfield-decoration-container': { display: 'none' },
                              },
                              '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                            }}
                            endAdornment={
                              field.value ? (
                                <InputAdornment position="end">
                                  <IconButton onClick={() => setShowConfirmPassword(!showConfirmPassword)} edge="end" size="small" sx={{ p: 0.5 }}>
                                    {showConfirmPassword ? <VisibilityOff sx={{ fontSize: 18 }} /> : <Visibility sx={{ fontSize: 18 }} />}
                                  </IconButton>
                                </InputAdornment>
                              ) : null
                            }
                          />
                          {errors.confirmPassword && <FormHelperText>{errors.confirmPassword.message}</FormHelperText>}
                        </FormControl>
                      )}
                    />

                    <TurnstileCaptcha onTokenChange={setCaptchaToken} />
                    <Button type="submit" variant="contained" disabled={isSubmitting} sx={{ py: 1.5 }}>
                      {isSubmitting ? <CircularProgress size={22} color="inherit" /> : 'Registrar'}
                    </Button>
                  </Stack>
                </form>

                <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
                  <Typography variant="body2" color="textSecondary" fontWeight="500">
                    ¿Ya tienes cuenta?
                  </Typography>
                  <Typography
                    component={Link}
                    href="/authentication/login"
                    variant="body2"
                    fontWeight="500"
                    sx={{ textDecoration: 'none', color: 'primary.main', '&:hover': { textDecoration: 'underline' } }}
                  >
                    Iniciar sesión
                  </Typography>
                </Stack>
              </>
            )}
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}

