'use client';

import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  TextField,
  Stack,
  Alert,
  CircularProgress,
  InputAdornment,
  IconButton,
  Link,
} from '@mui/material';
import { FormGrid, FormField } from '@zentto/shared-ui';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useByocDeploy, ByocCredentials } from '@/hooks/useByocDeploy';

const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });
const ErrorIcon = dynamic(() => import('@mui/icons-material/Error'), { ssr: false });
const VisibilityIcon = dynamic(() => import('@mui/icons-material/Visibility'), { ssr: false });
const VisibilityOffIcon = dynamic(() => import('@mui/icons-material/VisibilityOff'), { ssr: false });
const OpenInNewIcon = dynamic(() => import('@mui/icons-material/OpenInNew'), { ssr: false });

const API_URL = process.env.NEXT_PUBLIC_API_URL || '';

// ─── Tipo de resultado de validacion ─────────────────────────────────────────

type ValidateResult = 'idle' | 'loading' | 'ok' | 'error';

// ─── Paso 3: Credenciales ─────────────────────────────────────────────────────

export default function CredentialsPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const router = useRouter();
  const { provider, credentials, setCredentials } = useByocDeploy();

  const [token, setToken] = useState('');
  const [showToken, setShowToken] = useState(false);
  const [showKey, setShowKey] = useState(false);
  const [validateResult, setValidateResult] = useState<ValidateResult>('idle');
  const [validateMessage, setValidateMessage] = useState('');

  // Estado local del formulario
  const [form, setForm] = useState<ByocCredentials>({
    apiToken: '',
    ip: '',
    sshPort: 22,
    sshUser: 'root',
    sshKey: '',
    ...credentials,
  });

  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  const handleChange = (field: keyof ByocCredentials) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const value = field === 'sshPort' ? Number(e.target.value) : e.target.value;
    setForm(prev => ({ ...prev, [field]: value }));
    setValidateResult('idle');
  };

  // Verificar conexion con el backend
  const handleValidate = async () => {
    setValidateResult('loading');
    setValidateMessage('');

    try {
      const res = await fetch(`${API_URL}/v1/byoc/validate-creds`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ provider, credentials: form }),
      });

      const data = await res.json() as { ok: boolean; message?: string };

      if (data.ok) {
        setValidateResult('ok');
        setValidateMessage('Conexion verificada correctamente.');
        setCredentials(form);
      } else {
        setValidateResult('error');
        setValidateMessage(data.message || 'No se pudo verificar la conexion.');
      }
    } catch {
      setValidateResult('error');
      setValidateMessage('Error de red. Verifica tu conexion a internet.');
    }
  };

  const handleNext = () => {
    setCredentials(form);
    router.push(`/onboarding/${token}/configure`);
  };

  const handleBack = () => {
    router.push(`/onboarding/${token}/provider`);
  };

  const isApiProvider = provider === 'hetzner' || provider === 'digitalocean';
  const isSsh = provider === 'ssh';
  const canContinue =
    (isApiProvider && form.apiToken && form.apiToken.length > 0) ||
    (isSsh && form.ip && form.sshKey && form.sshKey.length > 0);

  // Docs de obtencion de API token por proveedor
  const apiTokenDocs: Record<string, string> = {
    hetzner: 'https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/',
    digitalocean: 'https://docs.digitalocean.com/reference/api/create-personal-access-token/',
  };

  return (
    <Box sx={{ flex: 1, py: 6, px: { xs: 2, sm: 4, md: 8 } }}>
      <Box sx={{ maxWidth: 600, mx: 'auto' }}>
        {/* Titulo */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h5" fontWeight={800} sx={{ color: '#1a1a2e', mb: 1 }}>
            Credenciales de acceso
          </Typography>
          <Typography color="text.secondary">
            {isApiProvider
              ? `Necesitamos tu API Token de ${provider === 'hetzner' ? 'Hetzner' : 'DigitalOcean'} para crear y configurar el servidor automaticamente.`
              : 'Necesitamos acceso SSH a tu servidor para instalar Zentto.'}
          </Typography>
        </Box>

        <Paper
          elevation={0}
          sx={{ p: { xs: 3, sm: 4 }, border: '1px solid #e0e0e0', borderRadius: 3 }}
        >
          {/* ─── Formulario para Hetzner / DigitalOcean ─────────────── */}
          {isApiProvider && (
            <Stack spacing={3}>
              <Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  API Token *
                </Typography>
                <TextField
                  fullWidth
                  type={showToken ? 'text' : 'password'}
                  placeholder="Pega tu API Token aqui..."
                  value={form.apiToken || ''}
                  onChange={handleChange('apiToken')}
                  variant="outlined"
                  size="small"
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowToken(v => !v)}
                          edge="end"
                          size="small"
                        >
                          {showToken ? <VisibilityOffIcon /> : <VisibilityIcon />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                />
                {apiTokenDocs[provider] && (
                  <Link
                    href={apiTokenDocs[provider]}
                    target="_blank"
                    rel="noopener noreferrer"
                    sx={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 0.5,
                      mt: 1,
                      fontSize: 13,
                      color: '#ff9900',
                    }}
                  >
                    Como obtener tu API Token
                    <OpenInNewIcon sx={{ fontSize: 14 }} />
                  </Link>
                )}
              </Box>

              <Alert severity="info" sx={{ fontSize: 13 }}>
                Tus credenciales se cifran con AES-256-GCM y se eliminan automaticamente al completar el deploy.
                El token necesita permisos de <strong>lectura y escritura</strong> (Read & Write).
              </Alert>
            </Stack>
          )}

          {/* ─── Formulario para SSH propio ──────────────────────────── */}
          {isSsh && (
            <Stack spacing={3}>
              <Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  IP del servidor *
                </Typography>
                <TextField
                  fullWidth
                  placeholder="Ej: 192.168.1.100 o 95.217.x.x"
                  value={form.ip || ''}
                  onChange={handleChange('ip')}
                  variant="outlined"
                  size="small"
                />
              </Box>

              <FormGrid spacing={2}>
                <FormField xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                    Puerto SSH
                  </Typography>
                  <TextField
                    fullWidth
                    type="number"
                    value={form.sshPort ?? 22}
                    onChange={handleChange('sshPort')}
                    variant="outlined"
                    size="small"
                  />
                </FormField>
                <FormField xs={12} sm={6}>
                  <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                    Usuario SSH
                  </Typography>
                  <TextField
                    fullWidth
                    value={form.sshUser || 'root'}
                    onChange={handleChange('sshUser')}
                    variant="outlined"
                    size="small"
                  />
                </FormField>
              </FormGrid>

              <Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  Clave privada SSH *
                </Typography>
                <TextField
                  fullWidth
                  multiline
                  rows={6}
                  placeholder={'-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----'}
                  value={form.sshKey || ''}
                  onChange={handleChange('sshKey')}
                  variant="outlined"
                  InputProps={{
                    sx: {
                      fontFamily: 'monospace',
                      fontSize: 12,
                    },
                  }}
                />
                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                  Pega tu clave privada RSA o Ed25519. Se transmite de forma cifrada.
                </Typography>
              </Box>

              <Alert severity="info" sx={{ fontSize: 13 }}>
                Tus credenciales se cifran con AES-256-GCM y se eliminan automaticamente al completar el deploy.
                El usuario SSH debe tener permisos de <strong>sudo</strong> o ser <strong>root</strong>.
              </Alert>
            </Stack>
          )}

          {/* ─── Boton de verificacion ───────────────────────────────── */}
          <Box sx={{ mt: 4 }}>
            <Button
              variant="outlined"
              onClick={handleValidate}
              disabled={!canContinue || validateResult === 'loading'}
              startIcon={
                validateResult === 'loading' ? (
                  <CircularProgress size={16} />
                ) : validateResult === 'ok' ? (
                  <CheckCircleIcon sx={{ color: '#4caf50' }} />
                ) : validateResult === 'error' ? (
                  <ErrorIcon sx={{ color: '#f44336' }} />
                ) : null
              }
              sx={{
                textTransform: 'none',
                borderColor:
                  validateResult === 'ok'
                    ? '#4caf50'
                    : validateResult === 'error'
                    ? '#f44336'
                    : '#1a1a2e',
                color:
                  validateResult === 'ok'
                    ? '#4caf50'
                    : validateResult === 'error'
                    ? '#f44336'
                    : '#1a1a2e',
              }}
            >
              {validateResult === 'loading'
                ? 'Verificando...'
                : validateResult === 'ok'
                ? 'Conexion verificada'
                : validateResult === 'error'
                ? 'Fallo — intentar de nuevo'
                : 'Verificar conexion'}
            </Button>

            {validateMessage && (
              <Alert
                severity={validateResult === 'ok' ? 'success' : 'error'}
                sx={{ mt: 2, fontSize: 13 }}
              >
                {validateMessage}
              </Alert>
            )}
          </Box>
        </Paper>

        {/* Navegacion */}
        <Stack direction="row" spacing={2} justifyContent="space-between" sx={{ mt: 4 }}>
          <Button
            variant="outlined"
            onClick={handleBack}
            sx={{ textTransform: 'none', borderColor: '#1a1a2e', color: '#1a1a2e' }}
          >
            Atras
          </Button>
          <Button
            variant="contained"
            onClick={handleNext}
            disabled={!canContinue}
            sx={{
              bgcolor: '#ff9900',
              color: '#1a1a2e',
              fontWeight: 700,
              textTransform: 'none',
              px: 4,
              '&:hover': { bgcolor: '#e68a00' },
              '&:disabled': { bgcolor: '#e0e0e0', color: '#9e9e9e' },
            }}
          >
            Continuar
          </Button>
        </Stack>

        {validateResult !== 'ok' && canContinue && (
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1, textAlign: 'right' }}>
            Puedes continuar sin verificar, pero recomendamos verificar antes.
          </Typography>
        )}
      </Box>
    </Box>
  );
}
