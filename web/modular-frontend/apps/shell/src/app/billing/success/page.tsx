'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Button, Paper, Container, CircularProgress, Alert } from '@mui/material';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  purple: '#6C63FF',
  bg: '#eaeded',
  white: '#ffffff',
} as const;

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

interface TenantInfo {
  CompanyId: number;
  CompanyCode: string;
  LegalName: string;
  OwnerEmail: string;
  Plan: string;
  TenantStatus: string;
  TenantSubdomain: string;
}

export default function BillingSuccessPage() {
  const [status, setStatus] = useState<'checking' | 'ready' | 'waiting' | 'error'>('checking');
  const [tenant, setTenant] = useState<TenantInfo | null>(null);
  const [attempts, setAttempts] = useState(0);

  const checkTenant = useCallback(async () => {
    try {
      // Buscar en query params si Paddle paso el email
      const params = new URLSearchParams(window.location.search);
      const email = params.get('customer_email') || params.get('email');

      if (!email) {
        setStatus('waiting');
        return;
      }

      // Intentar resolver tenant por email via la API
      const res = await fetch(`${API_BASE}/api/tenants/resolve-by-email/${encodeURIComponent(email)}`);
      if (res.ok) {
        const data = await res.json();
        setTenant(data);
        setStatus('ready');
      } else {
        setAttempts((a) => a + 1);
        setStatus('waiting');
      }
    } catch {
      setAttempts((a) => a + 1);
      setStatus('waiting');
    }
  }, []);

  // Polling cada 3 segundos, max 20 intentos (1 minuto)
  useEffect(() => {
    if (status === 'ready' || status === 'error') return;
    if (attempts >= 20) {
      setStatus('error');
      return;
    }

    const timer = setTimeout(checkTenant, 3000);
    return () => clearTimeout(timer);
  }, [status, attempts, checkTenant]);

  useEffect(() => { checkTenant(); }, [checkTenant]);

  const subdomain = tenant?.TenantSubdomain;
  const tenantUrl = subdomain ? `https://${subdomain}.zentto.net` : 'https://app.zentto.net';

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', px: 2 }}>
      <Container maxWidth="sm">
        <Paper elevation={6} sx={{ p: { xs: 4, md: 6 }, borderRadius: 3, textAlign: 'center' }}>
          {status === 'ready' && tenant ? (
            <>
              <CheckCircleOutlineIcon sx={{ fontSize: 72, color: '#4caf50', mb: 2 }} />
              <Typography variant="h4" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2, fontSize: { xs: '1.5rem', md: '2rem' } }}>
                Bienvenido a Zentto!
              </Typography>
              <Typography variant="body1" sx={{ color: 'text.secondary', mb: 2 }}>
                Tu empresa <strong>{tenant.LegalName}</strong> ha sido creada exitosamente.
              </Typography>

              <Paper variant="outlined" sx={{ p: 2, mb: 3, bgcolor: '#f5f5f5', textAlign: 'left' }}>
                <Typography variant="body2" sx={{ mb: 0.5 }}><strong>Plan:</strong> {tenant.Plan}</Typography>
                <Typography variant="body2" sx={{ mb: 0.5 }}><strong>Email:</strong> {tenant.OwnerEmail}</Typography>
                {subdomain && (
                  <Typography variant="body2" sx={{ mb: 0.5 }}>
                    <strong>Tu URL:</strong>{' '}
                    <a href={tenantUrl} style={{ color: COLORS.purple }}>{subdomain}.zentto.net</a>
                  </Typography>
                )}
                <Typography variant="body2" color="error" sx={{ mt: 1 }}>
                  Revisa tu email para obtener tu contrasena temporal.
                </Typography>
              </Paper>

              <Button
                variant="contained"
                size="large"
                onClick={() => window.location.href = `${tenantUrl}/authentication/login`}
                sx={{ py: 1.5, px: 5, fontWeight: 700, fontSize: '1rem', borderRadius: 2, bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' } }}
              >
                Ir a iniciar sesion
              </Button>
            </>
          ) : status === 'error' ? (
            <>
              <ErrorOutlineIcon sx={{ fontSize: 72, color: '#ff9800', mb: 2 }} />
              <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2 }}>
                Suscripcion confirmada
              </Typography>
              <Alert severity="info" sx={{ mb: 3, textAlign: 'left' }}>
                Tu pago fue procesado exitosamente. Tu empresa esta siendo configurada.
                Recibiras un email con tus credenciales en los proximos minutos.
              </Alert>
              <Button
                variant="contained"
                size="large"
                onClick={() => window.location.href = 'https://app.zentto.net/authentication/login'}
                sx={{ py: 1.5, px: 5, fontWeight: 700, fontSize: '1rem', borderRadius: 2, bgcolor: COLORS.accent, color: COLORS.darkPrimary, '&:hover': { bgcolor: '#e68a00' } }}
              >
                Ir al login
              </Button>
            </>
          ) : (
            <>
              <CircularProgress size={60} sx={{ color: COLORS.purple, mb: 3 }} />
              <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2 }}>
                Configurando tu empresa...
              </Typography>
              <Typography variant="body1" sx={{ color: 'text.secondary', mb: 1 }}>
                Tu pago fue confirmado. Estamos creando tu cuenta.
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.disabled' }}>
                Esto puede tomar unos segundos...
              </Typography>
            </>
          )}
        </Paper>
      </Container>
    </Box>
  );
}
