'use client';

import React, { useEffect, useState, useCallback } from 'react';
import {
  Box, Container, Typography, Paper, CircularProgress, Alert, Button,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import { useSearchParams } from 'next/navigation';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  bg: '#f0f2f5',
  green: '#4caf50',
  red: '#f44336',
} as const;

type VerifyStatus = 'loading' | 'success' | 'already_active' | 'error';

interface VerifyResult {
  ok: boolean;
  status?: string;
  companyId?: number;
  tenantSlug?: string;
  mensaje?: string;
  error?: string;
}

export default function VerifyPage() {
  const searchParams = useSearchParams();
  const token = searchParams.get('token');

  const [status, setStatus] = useState<VerifyStatus>('loading');
  const [result, setResult] = useState<VerifyResult | null>(null);
  const [errorMsg, setErrorMsg] = useState('');

  const verify = useCallback(async () => {
    if (!token) {
      setErrorMsg('Token no proporcionado');
      setStatus('error');
      return;
    }

    try {
      const res = await fetch(`${API_BASE}/v1/onboarding/verify/${encodeURIComponent(token)}`, {
        method: 'POST',
      });

      const data = await res.json();

      if (res.ok && data.ok) {
        setResult(data);
        if (data.status === 'active') {
          setStatus('success');
        } else {
          setStatus('already_active');
        }
      } else {
        setErrorMsg(data.error || 'Token invalido o expirado');
        setStatus('error');
      }
    } catch {
      setErrorMsg('Error de conexion. Intenta de nuevo.');
      setStatus('error');
    }
  }, [token]);

  useEffect(() => {
    verify();
  }, [verify]);

  const tenantUrl = result?.tenantSlug
    ? `https://${result.tenantSlug}.zentto.net`
    : 'https://zentto.net';

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <Box sx={{ bgcolor: COLORS.darkPrimary, py: 2, textAlign: 'center' }}>
        <Typography sx={{ color: COLORS.accent, fontWeight: 900, fontSize: 24, letterSpacing: 3 }}>
          ZENTTO
        </Typography>
      </Box>

      <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', py: 4 }}>
        <Container maxWidth="sm">
          <Paper elevation={3} sx={{ p: 5, textAlign: 'center', borderRadius: 3 }}>
            {status === 'loading' && (
              <>
                <CircularProgress size={48} sx={{ color: COLORS.accent, mb: 3 }} />
                <Typography variant="h6" fontWeight={600}>
                  Verificando tu cuenta...
                </Typography>
                <Typography color="text.secondary" variant="body2" sx={{ mt: 1 }}>
                  Estamos configurando tu instancia de Zentto
                </Typography>
              </>
            )}

            {status === 'success' && (
              <>
                <CheckCircleIcon sx={{ fontSize: 64, color: COLORS.green, mb: 2 }} />
                <Typography variant="h5" fontWeight={700} gutterBottom>
                  Cuenta verificada
                </Typography>
                <Typography color="text.secondary" sx={{ mb: 3 }}>
                  Tu instancia de Zentto ERP esta lista.
                </Typography>
                <Button
                  variant="contained"
                  size="large"
                  href={tenantUrl}
                  sx={{
                    bgcolor: COLORS.accent,
                    color: COLORS.darkPrimary,
                    fontWeight: 700,
                    px: 4,
                    '&:hover': { bgcolor: '#e68a00' },
                  }}
                >
                  Ir a mi Zentto
                </Button>
              </>
            )}

            {status === 'already_active' && (
              <>
                <CheckCircleIcon sx={{ fontSize: 64, color: COLORS.green, mb: 2 }} />
                <Typography variant="h5" fontWeight={700} gutterBottom>
                  Cuenta ya activa
                </Typography>
                <Typography color="text.secondary" sx={{ mb: 3 }}>
                  Tu cuenta ya fue verificada anteriormente. Puedes acceder a tu instancia.
                </Typography>
                <Button
                  variant="contained"
                  size="large"
                  href="https://zentto.net"
                  sx={{
                    bgcolor: COLORS.accent,
                    color: COLORS.darkPrimary,
                    fontWeight: 700,
                    px: 4,
                    '&:hover': { bgcolor: '#e68a00' },
                  }}
                >
                  Ir a Zentto
                </Button>
              </>
            )}

            {status === 'error' && (
              <>
                <ErrorIcon sx={{ fontSize: 64, color: COLORS.red, mb: 2 }} />
                <Typography variant="h5" fontWeight={700} gutterBottom>
                  Error de verificacion
                </Typography>
                <Alert severity="error" sx={{ mb: 3, textAlign: 'left' }}>
                  {errorMsg}
                </Alert>
                <Button
                  variant="outlined"
                  href="/signup"
                  sx={{ mr: 2 }}
                >
                  Registrarse de nuevo
                </Button>
                <Button
                  variant="contained"
                  onClick={() => { setStatus('loading'); verify(); }}
                  sx={{
                    bgcolor: COLORS.accent,
                    color: COLORS.darkPrimary,
                    fontWeight: 700,
                    '&:hover': { bgcolor: '#e68a00' },
                  }}
                >
                  Reintentar
                </Button>
              </>
            )}
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
