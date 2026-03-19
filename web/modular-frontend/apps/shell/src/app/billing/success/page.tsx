'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Button, Paper, Container, CircularProgress, Alert, LinearProgress } from '@mui/material';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import MailOutlineIcon from '@mui/icons-material/MailOutline';
import AccessTimeIcon from '@mui/icons-material/AccessTime';

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

const MAX_ATTEMPTS = 40; // 2 minutos (cada 3s)

export default function BillingSuccessPage() {
  const [status, setStatus] = useState<'checking' | 'ready' | 'waiting' | 'email_sent'>('checking');
  const [tenant, setTenant] = useState<TenantInfo | null>(null);
  const [attempts, setAttempts] = useState(0);
  const [email, setEmail] = useState<string | null>(null);

  const checkTenant = useCallback(async () => {
    try {
      const params = new URLSearchParams(window.location.search);
      const customerEmail = params.get('customer_email') || params.get('email');

      if (!customerEmail) {
        // Sin email — mostrar pantalla de "revisa tu correo"
        setStatus('email_sent');
        return;
      }

      setEmail(customerEmail);

      const res = await fetch(`${API_BASE}/api/tenants/resolve-by-email/${encodeURIComponent(customerEmail)}`);
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

  useEffect(() => {
    if (status === 'ready' || status === 'email_sent') return;
    if (attempts >= MAX_ATTEMPTS) {
      // Timeout — pero el pago se proceso, mostrar pantalla de email
      setStatus('email_sent');
      return;
    }

    const timer = setTimeout(checkTenant, 3000);
    return () => clearTimeout(timer);
  }, [status, attempts, checkTenant]);

  useEffect(() => { checkTenant(); }, [checkTenant]);

  const subdomain = tenant?.TenantSubdomain;
  const tenantUrl = subdomain ? `https://${subdomain}.zentto.net` : 'https://app.zentto.net';
  const progress = Math.min((attempts / MAX_ATTEMPTS) * 100, 100);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', px: 2 }}>
      <Container maxWidth="sm">
        <Paper elevation={6} sx={{ p: { xs: 4, md: 6 }, borderRadius: 3, textAlign: 'center' }}>

          {/* ── ESTADO: Tenant listo ── */}
          {status === 'ready' && tenant ? (
            <>
              <CheckCircleOutlineIcon sx={{ fontSize: 72, color: '#4caf50', mb: 2 }} />
              <Typography variant="h4" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2, fontSize: { xs: '1.5rem', md: '2rem' } }}>
                Tu cuenta esta lista!
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
              </Paper>

              <Alert severity="info" sx={{ mb: 3, textAlign: 'left' }}>
                <strong>Tus credenciales fueron enviadas a {tenant.OwnerEmail}.</strong><br />
                Revisa tu bandeja de entrada (y la carpeta de spam) para obtener tu usuario y contrasena temporal.
              </Alert>

              <Button
                variant="contained"
                size="large"
                onClick={() => window.location.href = `${tenantUrl}/authentication/login`}
                sx={{ py: 1.5, px: 5, fontWeight: 700, fontSize: '1rem', borderRadius: 2, bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' } }}
              >
                Ir a iniciar sesion
              </Button>
            </>

          /* ── ESTADO: Timeout o sin email — mostrar que revise correo ── */
          ) : status === 'email_sent' ? (
            <>
              <MailOutlineIcon sx={{ fontSize: 72, color: COLORS.accent, mb: 2 }} />
              <Typography variant="h4" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2, fontSize: { xs: '1.4rem', md: '1.8rem' } }}>
                Pago confirmado!
              </Typography>

              <Typography variant="body1" sx={{ color: 'text.secondary', mb: 3 }}>
                Tu suscripcion fue procesada exitosamente por Paddle.
              </Typography>

              <Paper variant="outlined" sx={{ p: 3, mb: 3, bgcolor: '#fff8e1', textAlign: 'left', borderColor: COLORS.accent }}>
                <Typography variant="body1" fontWeight={600} sx={{ mb: 1, color: COLORS.darkPrimary }}>
                  Que sigue?
                </Typography>
                <Box component="ul" sx={{ m: 0, pl: 2.5 }}>
                  <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                    <strong>Paddle</strong> te enviara un recibo de tu compra.
                  </Typography>
                  <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                    <strong>Zentto</strong> te enviara un correo con tu <strong>usuario y contrasena temporal</strong> para acceder a tu cuenta.
                  </Typography>
                  <Typography component="li" variant="body2" sx={{ mb: 1 }}>
                    Tu ambiente estara listo en un maximo de <strong>5 minutos</strong>.
                  </Typography>
                  <Typography component="li" variant="body2">
                    Al iniciar sesion por primera vez, se te pedira cambiar tu contrasena.
                  </Typography>
                </Box>
              </Paper>

              {email && (
                <Alert severity="info" sx={{ mb: 3, textAlign: 'left' }}>
                  Busca el correo de <strong>Zentto</strong> en la bandeja de <strong>{email}</strong>. Si no lo ves en unos minutos, revisa la carpeta de spam.
                </Alert>
              )}

              <Alert severity="warning" sx={{ mb: 3, textAlign: 'left' }}>
                <strong>No cierres esta ventana todavia?</strong> Si tu cuenta ya esta lista, puedes ir directamente al login.
              </Alert>

              <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center', flexWrap: 'wrap' }}>
                <Button
                  variant="contained"
                  size="large"
                  onClick={() => {
                    setStatus('checking');
                    setAttempts(0);
                  }}
                  sx={{
                    py: 1.5, px: 4, fontWeight: 700, fontSize: '0.95rem', borderRadius: 2,
                    bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' },
                  }}
                >
                  Verificar si mi cuenta esta lista
                </Button>
                <Button
                  variant="outlined"
                  size="large"
                  onClick={() => window.location.href = 'https://app.zentto.net/authentication/login'}
                  sx={{
                    py: 1.5, px: 4, fontWeight: 700, fontSize: '0.95rem', borderRadius: 2,
                    borderColor: COLORS.accent, color: COLORS.darkPrimary,
                    '&:hover': { borderColor: '#e68a00', bgcolor: '#fff8e1' },
                  }}
                >
                  Ir al login
                </Button>
              </Box>
            </>

          /* ── ESTADO: Esperando provisioning ── */
          ) : (
            <>
              <AccessTimeIcon sx={{ fontSize: 60, color: COLORS.purple, mb: 2 }} />
              <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 2 }}>
                Configurando tu cuenta...
              </Typography>
              <Typography variant="body1" sx={{ color: 'text.secondary', mb: 1 }}>
                Tu pago fue confirmado. Estamos preparando tu ambiente.
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.disabled', mb: 3 }}>
                Esto normalmente toma entre 10 y 30 segundos.
              </Typography>

              <Box sx={{ width: '100%', mb: 3 }}>
                <LinearProgress
                  variant="determinate"
                  value={progress}
                  sx={{
                    height: 8, borderRadius: 4,
                    bgcolor: '#e0e0e0',
                    '& .MuiLinearProgress-bar': { bgcolor: COLORS.purple, borderRadius: 4 },
                  }}
                />
                <Typography variant="caption" sx={{ color: 'text.disabled', mt: 0.5, display: 'block' }}>
                  {attempts > 0 ? `Verificando... (intento ${attempts}/${MAX_ATTEMPTS})` : 'Iniciando verificacion...'}
                </Typography>
              </Box>

              <CircularProgress size={24} sx={{ color: COLORS.purple }} />
            </>
          )}
        </Paper>
      </Container>
    </Box>
  );
}
