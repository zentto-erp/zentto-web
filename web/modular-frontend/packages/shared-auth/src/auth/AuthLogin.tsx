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
  Select,
  MenuItem,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Visibility, VisibilityOff } from '@mui/icons-material';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { signIn } from 'next-auth/react';
import { useToast } from '@zentto/shared-ui';

interface loginType {
  title?: string;
  subtitle?: React.ReactNode;
  subtext?: React.ReactNode;
}

type CompanyOption = {
  companyId: number;
  companyCode: string;
  companyName: string;
  branchId: number;
  branchCode: string;
  branchName: string;
  countryCode: string;
};

const loginSchema = z.object({
  email: z.string().min(1, 'El usuario es requerido'),
  password: z.string().min(1, 'La contrasena es requerida'),
});

type LoginFormData = z.infer<typeof loginSchema>;

const AuthLogin = ({ title, subtitle, subtext }: loginType) => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [showPassword, setShowPassword] = React.useState(false);
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);
  const [emailNotVerified, setEmailNotVerified] = React.useState(false);
  const [resendBusy, setResendBusy] = React.useState(false);
  const [loadingCompanies, setLoadingCompanies] = React.useState(false);
  const [companyOptions, setCompanyOptions] = React.useState<CompanyOption[]>([]);
  const [selectedScope, setSelectedScope] = React.useState<string>('');
  const { showToast } = useToast();

  const {
    control,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const usernameInput = watch('email');

  const backendUrl = React.useMemo(
    () =>
      process.env.NEXT_PUBLIC_API_BASE_URL ||
      process.env.NEXT_PUBLIC_API_URL ||
      process.env.NEXT_PUBLIC_BACKEND_URL ||
      'http://localhost:4000',
    []
  );

  React.useEffect(() => {
    const error = searchParams.get('error');
    if (error) {
      if (error === 'CredentialsSignin') {
        setErrorMsg('Usuario o contrasena incorrectos');
      } else {
        setErrorMsg('Error al iniciar sesion. Intente nuevamente.');
      }
        setEmailNotVerified(false);
    }
  }, [searchParams]);

  React.useEffect(() => {
    const normalized = String(usernameInput ?? '').trim();
    if (!normalized) {
      setCompanyOptions([]);
      setSelectedScope('');
      return;
    }

    const loginUser = normalized.includes('@') ? normalized.split('@')[0] : normalized;

    const timer = setTimeout(async () => {
      setLoadingCompanies(true);
      try {
        const response = await fetch(
          `${backendUrl}/v1/auth/login-options?usuario=${encodeURIComponent(loginUser)}`,
          { method: 'GET', headers: { Accept: 'application/json' } }
        );

        if (!response.ok) {
          setCompanyOptions([]);
          setSelectedScope('');
          return;
        }

        const data = await response.json();
        const rows: CompanyOption[] = Array.isArray(data?.rows) ? data.rows : [];
        setCompanyOptions(rows);

        if (rows.length > 0) {
          const active = data?.active as CompanyOption | null;
          const activeKey = active
            ? `${active.companyId}:${active.branchId}`
            : `${rows[0].companyId}:${rows[0].branchId}`;
          setSelectedScope(activeKey);
        } else {
          setSelectedScope('');
        }
      } catch {
        setCompanyOptions([]);
        setSelectedScope('');
      } finally {
        setLoadingCompanies(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [usernameInput, backendUrl]);

  const handleResendVerification = React.useCallback(async () => {
    const identifier = String(usernameInput ?? '').trim();
    if (!identifier) {
      setErrorMsg('Indica el usuario para reenviar la verificacion.');
      return;
    }

    setResendBusy(true);
    try {
      const response = await fetch(`${backendUrl}/v1/auth/resend-verification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier }),
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        setErrorMsg(String(data?.message || 'No se pudo reenviar la verificacion.'));
        return;
      }
      showToast('Si la cuenta esta pendiente, se envio un nuevo enlace de verificacion.', 'success');
    } catch {
      setErrorMsg('Error de red al reenviar verificacion.');
    } finally {
      setResendBusy(false);
    }
  }, [backendUrl, showToast, usernameInput]);

  const onSubmit = async (data: LoginFormData) => {
    setIsSubmitting(true);
    setErrorMsg(null);
    setEmailNotVerified(false);

    let companyId: number | undefined;
    let branchId: number | undefined;

    if (selectedScope) {
      const [c, b] = selectedScope.split(':').map((v) => Number(v));
      if (Number.isFinite(c) && c > 0) companyId = c;
      if (Number.isFinite(b) && b > 0) branchId = b;
    }

    try {
      const result = await signIn('credentials', {
        username: data.email,
        password: data.password,
        companyId: companyId ? String(companyId) : undefined,
        branchId: branchId ? String(branchId) : undefined,
        callbackUrl: '/',
        redirect: false,
      });

      if (result?.error) {
        const lowerError = String(result.error).toLowerCase();
        if (lowerError.includes('email_not_verified')) {
          setEmailNotVerified(true);
          setErrorMsg('Debes verificar tu correo antes de iniciar sesion.');
        } else {
          setErrorMsg('Usuario o contrasena incorrectos');
        }
        setIsSubmitting(false);
      } else if (result?.ok) {
        showToast('Inicio de sesion exitoso', 'success');
        router.push('/');
        router.refresh();
      }
    } catch {
      setErrorMsg('Error al iniciar sesion. Intente nuevamente.');
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

      {errorMsg && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {errorMsg}
        </Alert>
      )}

      {emailNotVerified && (
        <Alert
          severity="warning"
          sx={{ mb: 3 }}
          action={
            <Button color="inherit" size="small" onClick={handleResendVerification} disabled={resendBusy}>
              {resendBusy ? 'Enviando...' : 'Reenviar verificacion'}
            </Button>
          }
        >
          Tu cuenta existe pero el correo aun no esta verificado.
        </Alert>
      )}

      <form onSubmit={handleSubmit(onSubmit)} style={{ width: '100%' }}>
        <Stack spacing={3}>
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
                {errors.email && <FormHelperText>{errors.email.message}</FormHelperText>}
              </FormControl>
            )}
          />

          {(loadingCompanies || companyOptions.length > 0) && (
            <FormControl fullWidth>
              <Typography variant="body2" fontWeight={600} sx={{ mb: 1, color: 'text.primary' }}>
                Empresa / Sucursal
              </Typography>
              <Select
                value={selectedScope}
                onChange={(e) => setSelectedScope(String(e.target.value))}
                disabled={isSubmitting || loadingCompanies || companyOptions.length === 0}
              >
                {companyOptions.map((opt) => (
                  <MenuItem key={`${opt.companyId}:${opt.branchId}`} value={`${opt.companyId}:${opt.branchId}`}>
                    {`${opt.companyCode} - ${opt.companyName} / ${opt.branchCode} - ${opt.branchName}`}
                  </MenuItem>
                ))}
              </Select>
              {loadingCompanies && <FormHelperText>Cargando empresas...</FormHelperText>}
            </FormControl>
          )}

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
                  Contrasena
                </Typography>
                <OutlinedInput
                  {...field}
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Contrasena"
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
                {errors.password && <FormHelperText>{errors.password.message}</FormHelperText>}
              </FormControl>
            )}
          />

          <Stack justifyContent="flex-start" direction="row" alignItems="center">
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

          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Box />
            <Typography
              component={Link}
              href="/authentication/forgot-password"
              variant="body2"
              sx={{ textDecoration: 'none', color: 'primary.main', '&:hover': { textDecoration: 'underline' } }}
            >
              Olvide mi contrasena
            </Typography>
          </Stack>

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
            {isSubmitting ? <CircularProgress size={24} color="inherit" /> : 'Iniciar Sesion'}
          </Button>
        </Stack>
      </form>
      {subtitle}
    </Box>
  );
};

export default AuthLogin;
