'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  Box, Container, Card, CardContent, Typography, TextField, Button,
  Alert, CircularProgress, InputAdornment, IconButton,
} from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';

const COLORS = { darkPrimary: '#131921', purple: '#6C63FF', accent: '#ff9900' };

const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'https://api.zentto.net';

const AUTH_BASE =
  process.env.NEXT_PUBLIC_AUTH_URL || 'https://auth.zentto.net';

function SetPasswordContent() {
  const params = useSearchParams();
  const router = useRouter();
  const token = params.get('token') ?? '';

  const [pwd, setPwd] = useState('');
  const [pwd2, setPwd2] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (!token || token.length < 20) setError('token_invalid');
  }, [token]);

  const valid =
    pwd.length >= 8 &&
    pwd === pwd2 &&
    /[A-Z]/.test(pwd) &&
    /[a-z]/.test(pwd) &&
    /\d/.test(pwd);

  async function handleSubmit() {
    if (!valid || !token) return;
    setSubmitting(true);
    setError(null);

    // Estrategia: zentto-auth primero, fallback a la API local
    const targets = [
      { name: 'zentto-auth', url: `${AUTH_BASE}/auth/set-password` },
      { name: 'erp-local', url: `${API_BASE}/v1/auth/set-password` },
    ];

    let success = false;
    let lastError = '';
    for (const target of targets) {
      try {
        const res = await fetch(target.url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token, newPassword: pwd }),
        });
        const json = await res.json().catch(() => ({}));
        if (res.ok && (json.ok !== false)) {
          success = true;
          break;
        }
        lastError = String(json.error || res.statusText);
        // Si el token es inválido/usado/expirado en el primer endpoint, no
        // tiene sentido reintentar en el segundo (el token vive en uno solo).
        if (['token_invalid', 'token_used', 'token_expired'].includes(lastError)) break;
      } catch (e: any) {
        lastError = e?.message || 'network_error';
      }
    }

    setSubmitting(false);
    if (success) {
      setSuccess(true);
      setTimeout(() => router.push('/authentication/login'), 3000);
    } else {
      setError(lastError || 'unknown_error');
    }
  }

  if (success) {
    return (
      <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', bgcolor: '#f5f5f5' }}>
        <Container maxWidth="sm">
          <Card elevation={4} sx={{ borderRadius: 3, textAlign: 'center' }}>
            <CardContent sx={{ p: { xs: 4, md: 6 } }}>
              <CheckCircleIcon sx={{ fontSize: 64, color: '#4caf50', mb: 2 }} />
              <Typography variant="h5" fontWeight={800} sx={{ mb: 1 }}>
                Contraseña actualizada
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Te estamos redirigiendo al login...
              </Typography>
            </CardContent>
          </Card>
        </Container>
      </Box>
    );
  }

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', bgcolor: '#f5f5f5', py: 4 }}>
      <Container maxWidth="sm">
        <Card elevation={4} sx={{ borderRadius: 3 }}>
          <CardContent sx={{ p: { xs: 3, md: 5 } }}>
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <Box sx={{ display: 'inline-flex', p: 2, borderRadius: '50%', bgcolor: `${COLORS.purple}15` }}>
                <LockIcon sx={{ fontSize: 40, color: COLORS.purple }} />
              </Box>
              <Typography variant="h5" fontWeight={800} sx={{ mt: 2, mb: 1, color: COLORS.darkPrimary }}>
                Establece tu contraseña
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Crea una contraseña segura para acceder a tu cuenta de Zentto.
              </Typography>
            </Box>

            {error === 'token_invalid' || error === 'token_used' || error === 'token_expired' ? (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error === 'token_invalid' && 'El link no es válido. Verifica que copiaste la URL completa.'}
                {error === 'token_used' && 'Este link ya fue usado. Si necesitas restablecer tu contraseña, contacta a soporte.'}
                {error === 'token_expired' && 'El link expiró (válido 24h). Solicita uno nuevo a soporte@zentto.net.'}
              </Alert>
            ) : error ? (
              <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>
            ) : null}

            <TextField
              label="Nueva contraseña"
              type={showPwd ? 'text' : 'password'}
              fullWidth
              required
              value={pwd}
              onChange={(e) => setPwd(e.target.value)}
              sx={{ mb: 2 }}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={() => setShowPwd(!showPwd)} edge="end">
                      {showPwd ? <VisibilityOffIcon /> : <VisibilityIcon />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
              helperText="Mínimo 8 caracteres, una mayúscula, una minúscula y un número"
            />

            <TextField
              label="Confirmar contraseña"
              type={showPwd ? 'text' : 'password'}
              fullWidth
              required
              value={pwd2}
              onChange={(e) => setPwd2(e.target.value)}
              error={pwd2.length > 0 && pwd !== pwd2}
              helperText={pwd2.length > 0 && pwd !== pwd2 ? 'No coinciden' : ' '}
              sx={{ mb: 3 }}
            />

            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={handleSubmit}
              disabled={!valid || submitting || !token}
              sx={{
                bgcolor: COLORS.purple,
                '&:hover': { bgcolor: '#5b54e6' },
                py: 1.5,
                textTransform: 'none',
                fontWeight: 700,
                fontSize: '1rem',
              }}
              startIcon={submitting ? <CircularProgress size={18} color="inherit" /> : null}
            >
              {submitting ? 'Procesando...' : 'Establecer contraseña'}
            </Button>

            <Typography variant="caption" display="block" sx={{ mt: 3, textAlign: 'center', color: 'text.secondary' }}>
              ¿Tu link expiró? Escribe a{' '}
              <a href="mailto:soporte@zentto.net" style={{ color: COLORS.purple }}>soporte@zentto.net</a>
            </Typography>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
}

export default function SetPasswordPage() {
  return (
    <Suspense fallback={<Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}><CircularProgress /></Box>}>
      <SetPasswordContent />
    </Suspense>
  );
}
