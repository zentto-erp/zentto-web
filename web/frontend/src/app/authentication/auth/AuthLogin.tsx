'use client';
import React from 'react';
import {
  Box,
  Typography,
  Stack,
  Button,
  FormControl,
  OutlinedInput,
  FormHelperText,
  InputAdornment,
  IconButton,
  FormGroup,
  FormControlLabel,
  Checkbox,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Visibility, VisibilityOff } from '@mui/icons-material';
import { useRouter, useSearchParams } from 'next/navigation';
import { signIn } from 'next-auth/react';
import { useToast } from '@/providers/ToastProvider';

interface loginType {
  title?: string;
  subtitle?: React.ReactNode;
  subtext?: React.ReactNode;
}

const loginSchema = z.object({
  email: z.string().min(1, 'El usuario es requerido'),
  password: z.string().min(1, 'La contraseña es requerida'),
});

type LoginFormData = z.infer<typeof loginSchema>;

const AuthLogin = ({ title, subtitle, subtext }: loginType) => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [showPassword, setShowPassword] = React.useState(false);
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);
  const { showToast } = useToast();

  // Mostrar error si viene en la URL (de NextAuth)
  React.useEffect(() => {
    const error = searchParams.get('error');
    if (error) {
      if (error === 'CredentialsSignin') {
        setErrorMsg('Usuario o contraseña incorrectos');
      } else {
        setErrorMsg('Error al iniciar sesión. Intente nuevamente.');
      }
    }
  }, [searchParams]);

  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const onSubmit = async (data: LoginFormData) => {
    setIsSubmitting(true);
    setErrorMsg(null);
    
    try {
      const result = await signIn('credentials', {
        username: data.email,
        password: data.password,
        callbackUrl: '/',
        redirect: false,
      });

      if (result?.error) {
        setErrorMsg('Usuario o contraseña incorrectos');
        setIsSubmitting(false);
      } else if (result?.ok) {
        showToast('Inicio de sesión exitoso', 'success');
        router.push('/');
        router.refresh();
      }
    } catch (error) {
      setErrorMsg('Error al iniciar sesión. Intente nuevamente.');
      console.error('Error:', error);
      setIsSubmitting(false);
    }
  };

  return (
    <Box width="100%">
      {title && (
        <Typography fontWeight="700" variant="h2" mb={1}>
          {title}
        </Typography>
      )}

      {subtext}

      {/* Mensaje de error */}
      {errorMsg && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {errorMsg}
        </Alert>
      )}

      <form onSubmit={handleSubmit(onSubmit)} style={{ width: '100%' }}>
        <Stack spacing={3}>
          {/* Campo Usuario */}
          <Controller
            name="email"
            control={control}
            render={({ field }) => (
              <FormControl error={!!errors.email} fullWidth>
                <Typography
                  variant="body2"
                  fontWeight={600}
                  component="label"
                  htmlFor="email"
                  sx={{ mb: 1, color: 'text.primary' }}
                >
                  Usuario
                </Typography>
                <OutlinedInput
                  {...field}
                  id="email"
                  placeholder="Ingresa tu usuario"
                  autoComplete="username"
                  disabled={isSubmitting}
                  sx={{
                    '& .MuiOutlinedInput-input': {
                      py: 1.75,
                      px: 2,
                    },
                    '& .MuiOutlinedInput-notchedOutline': {
                      borderRadius: 2,
                    },
                  }}
                />
                {errors.email && (
                  <FormHelperText>{errors.email.message}</FormHelperText>
                )}
              </FormControl>
            )}
          />

          {/* Campo Contraseña */}
          <Controller
            name="password"
            control={control}
            render={({ field }) => (
              <FormControl error={!!errors.password} fullWidth>
                <Typography
                  variant="body2"
                  fontWeight={600}
                  component="label"
                  htmlFor="password"
                  sx={{ mb: 1, color: 'text.primary' }}
                >
                  Contraseña
                </Typography>
                <OutlinedInput
                  {...field}
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Contraseña"
                  autoComplete="current-password"
                  disabled={isSubmitting}
                  sx={{
                    '& .MuiOutlinedInput-input': {
                      py: 1.75,
                      px: 2,
                    },
                    '& .MuiOutlinedInput-notchedOutline': {
                      borderRadius: 2,
                    },
                  }}
                  endAdornment={
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                        disabled={isSubmitting}
                        size="small"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  }
                />
                {errors.password && (
                  <FormHelperText>{errors.password.message}</FormHelperText>
                )}
              </FormControl>
            )}
          />

          {/* Checkbox Recordar */}
          <Stack
            justifyContent="flex-start"
            direction="row"
            alignItems="center"
          >
            <FormGroup>
              <FormControlLabel
                control={
                  <Checkbox 
                    size="small" 
                    defaultChecked 
                    disabled={isSubmitting}
                    sx={{ '& .MuiSvgIcon-root': { fontSize: 20 } }}
                  />
                }
                label={
                  <Typography variant="body2" color="text.secondary">
                    Recordar este dispositivo
                  </Typography>
                }
              />
            </FormGroup>
          </Stack>

          {/* Botón Submit */}
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
            {isSubmitting ? (
              <CircularProgress size={24} color="inherit" />
            ) : (
              'Iniciar Sesión'
            )}
          </Button>
        </Stack>
      </form>
      
      {subtitle}
    </Box>
  );
};

export default AuthLogin;
