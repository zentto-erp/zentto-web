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
  IconButton,
  InputAdornment,
  OutlinedInput,
  Stack,
  Typography,
  Tooltip,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Logo, ThemeToggle, EyeIcon, EyeOffIcon } from '@zentto/shared-ui';
import { TurnstileCaptcha } from '@zentto/shared-auth';
import BrandPanel from '../BrandPanel';

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
    <Box sx={{ display: 'flex', minHeight: '100vh', width: '100%' }}>
      {/* Left panel — register form */}
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

        <Box sx={{ width: '100%', maxWidth: 440 }}>
          {/* Logo for mobile */}
          <Box sx={{ display: { xs: 'flex', md: 'none' }, justifyContent: 'center', mb: 3 }}>
            <Logo />
          </Box>

          {registeredEmail ? (
            <Stack spacing={3} alignItems="center" textAlign="center">
              <Box sx={{ fontSize: 56, lineHeight: 1 }}>&#9993;</Box>
              <Typography
                sx={{ fontFamily: "'Inter', system-ui, sans-serif", fontWeight: 700, fontSize: '1.25rem' }}
              >
                Revisa tu correo
              </Typography>
              <Typography sx={{ fontFamily: "'Inter', system-ui, sans-serif", color: 'text.secondary', fontSize: '0.875rem' }}>
                Enviamos un enlace de confirmacion a:
              </Typography>
              <Typography sx={{ fontFamily: "'Inter', system-ui, sans-serif", fontWeight: 600, fontSize: '1rem' }}>
                {registeredEmail}
              </Typography>
              <Typography sx={{ fontFamily: "'Inter', system-ui, sans-serif", color: 'text.secondary', fontSize: '0.75rem', maxWidth: 360 }}>
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
              <Typography sx={{ fontFamily: "'Inter', system-ui, sans-serif", color: 'text.secondary', fontSize: '0.75rem' }}>
                No recibiste el email?{' '}
                <Typography
                  component="span"
                  sx={{
                    fontFamily: "'Inter', system-ui, sans-serif",
                    fontSize: '0.75rem',
                    color: 'primary.main',
                    cursor: 'pointer',
                    '&:hover': { textDecoration: 'underline' },
                  }}
                  onClick={() => { setRegisteredEmail(null); setSuccess(null); }}
                >
                  Intentar de nuevo
                </Typography>
              </Typography>
            </Stack>
          ) : (
            <>
              <Typography
                sx={{
                  fontFamily: "'Inter', system-ui, sans-serif",
                  fontWeight: 700,
                  fontSize: '1.25rem',
                  letterSpacing: '-0.025em',
                  mb: 0.5,
                }}
              >
                Crear cuenta
              </Typography>
              <Typography
                sx={{
                  fontFamily: "'Inter', system-ui, sans-serif",
                  color: 'text.secondary',
                  fontSize: '0.875rem',
                  mb: 3,
                }}
              >
                Completa tus datos para comenzar
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
                        <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
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
                        <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
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
                        <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
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
                        <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
                          Contraseña
                        </Typography>
                        <OutlinedInput
                          {...field}
                          type="text"
                          placeholder="Contraseña"
                          autoComplete="new-password"
                          sx={{
                            '& .MuiOutlinedInput-input': {
                              py: 1.75, px: 2,
                              ...(!showPassword && { WebkitTextSecurity: 'disc', textSecurity: 'disc' }),
                            },
                            '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                          }}
                          endAdornment={field.value ? (
                            <InputAdornment position="end">
                              <Tooltip title={showPassword ? "Ocultar contrasena" : "Mostrar contrasena"}>
                                <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small" sx={{ p: 0.5 }}>
                                  {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                                </IconButton>
                              </Tooltip>
                            </InputAdornment>
                          ) : null}
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
                        <Typography variant="body2" fontWeight={600} component="label" sx={{ mb: 1, color: 'text.primary', fontFamily: "'Inter', system-ui, sans-serif" }}>
                          Confirmar contraseña
                        </Typography>
                        <OutlinedInput
                          {...field}
                          type="text"
                          placeholder="Repite la contraseña"
                          autoComplete="new-password"
                          sx={{
                            '& .MuiOutlinedInput-input': {
                              py: 1.75, px: 2,
                              ...(!showConfirmPassword && { WebkitTextSecurity: 'disc', textSecurity: 'disc' }),
                            },
                            '& .MuiOutlinedInput-notchedOutline': { borderRadius: 2 },
                          }}
                          endAdornment={
                            field.value ? (
                              <InputAdornment position="end">
                                <Tooltip title={showConfirmPassword ? "Ocultar contrasena" : "Mostrar contrasena"}>
                                  <IconButton onClick={() => setShowConfirmPassword(!showConfirmPassword)} edge="end" size="small" sx={{ p: 0.5 }}>
                                    {showConfirmPassword ? <EyeOffIcon /> : <EyeIcon />}
                                  </IconButton>
                                </Tooltip>
                              </InputAdornment>
                            ) : null
                          }
                        />
                        {errors.confirmPassword && <FormHelperText>{errors.confirmPassword.message}</FormHelperText>}
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
                    {isSubmitting ? <CircularProgress size={24} color="inherit" /> : 'Registrar'}
                  </Button>
                </Stack>
              </form>

              <Stack direction="row" spacing={1} justifyContent="center" mt={3}>
                <Typography variant="body2" color="textSecondary" fontWeight="500" sx={{ fontFamily: "'Inter', system-ui, sans-serif" }}>
                  ¿Ya tienes cuenta?
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
            </>
          )}
        </Box>
      </Box>

      <BrandPanel
        side="right"
        title={<>Únete a{' '}<Box component="span" sx={{ color: '#FFB547' }}>Zentto</Box></>}
        description="Gestiona tu empresa con una plataforma moderna, simple y poderosa."
      />
    </Box>
  );
}
