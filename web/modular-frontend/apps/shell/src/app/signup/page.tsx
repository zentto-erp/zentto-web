'use client';

import React, { useState } from 'react';
import {
  Box, Container, Typography, TextField, Button, Paper, Alert,
  CircularProgress, MenuItem, Select, InputLabel, FormControl,
} from '@mui/material';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import MailOutlineIcon from '@mui/icons-material/MailOutline';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  bg: '#f0f2f5',
  white: '#ffffff',
} as const;

const PLANS = [
  { value: 'free_trial', label: 'Prueba gratuita (14 dias)' },
  { value: 'basic', label: 'Basico' },
  { value: 'professional', label: 'Profesional' },
] as const;

type Status = 'idle' | 'loading' | 'success' | 'error';

export default function SignupPage() {
  const [email, setEmail] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [plan, setPlan] = useState<string>('free_trial');
  const [status, setStatus] = useState<Status>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('loading');
    setErrorMsg('');

    try {
      const res = await fetch(`${API_BASE}/v1/onboarding/signup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase(), companyName: companyName.trim(), plan }),
      });

      const data = await res.json();

      if (res.ok && data.ok) {
        setStatus('success');
      } else {
        setErrorMsg(data.error || 'Error al registrarse');
        setStatus('error');
      }
    } catch {
      setErrorMsg('Error de conexion. Intenta de nuevo.');
      setStatus('error');
    }
  };

  if (status === 'success') {
    return (
      <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', alignItems: 'center' }}>
        <Container maxWidth="sm">
          <Paper elevation={3} sx={{ p: 5, textAlign: 'center', borderRadius: 3 }}>
            <MailOutlineIcon sx={{ fontSize: 64, color: COLORS.accent, mb: 2 }} />
            <Typography variant="h5" fontWeight={700} gutterBottom>
              Revisa tu correo
            </Typography>
            <Typography color="text.secondary" sx={{ mb: 3 }}>
              Hemos enviado un enlace de verificacion a <strong>{email}</strong>.
              Haz clic en el enlace para activar tu cuenta.
            </Typography>
            <Alert severity="info" sx={{ textAlign: 'left' }}>
              Si no ves el correo, revisa la carpeta de spam. El enlace expira en 24 horas.
            </Alert>
          </Paper>
        </Container>
      </Box>
    );
  }

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
          <Paper elevation={3} sx={{ p: { xs: 3, sm: 5 }, borderRadius: 3 }}>
            <Box sx={{ textAlign: 'center', mb: 4 }}>
              <PersonAddIcon sx={{ fontSize: 48, color: COLORS.accent, mb: 1 }} />
              <Typography variant="h5" fontWeight={700}>
                Crea tu cuenta
              </Typography>
              <Typography color="text.secondary" variant="body2">
                Comienza a usar Zentto ERP en minutos
              </Typography>
            </Box>

            <form onSubmit={handleSubmit}>
              <TextField
                label="Correo electronico"
                type="email"
                fullWidth
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                sx={{ mb: 2.5 }}
                autoComplete="email"
              />

              <TextField
                label="Nombre de tu empresa"
                fullWidth
                required
                value={companyName}
                onChange={(e) => setCompanyName(e.target.value)}
                sx={{ mb: 2.5 }}
                inputProps={{ minLength: 2, maxLength: 200 }}
              />

              <FormControl fullWidth sx={{ mb: 3 }}>
                <InputLabel>Plan</InputLabel>
                <Select
                  value={plan}
                  label="Plan"
                  onChange={(e) => setPlan(e.target.value)}
                >
                  {PLANS.map((p) => (
                    <MenuItem key={p.value} value={p.value}>{p.label}</MenuItem>
                  ))}
                </Select>
              </FormControl>

              {status === 'error' && (
                <Alert severity="error" sx={{ mb: 2 }}>{errorMsg}</Alert>
              )}

              <Button
                type="submit"
                variant="contained"
                fullWidth
                size="large"
                disabled={status === 'loading'}
                sx={{
                  bgcolor: COLORS.accent,
                  color: COLORS.darkPrimary,
                  fontWeight: 700,
                  py: 1.5,
                  '&:hover': { bgcolor: '#e68a00' },
                }}
              >
                {status === 'loading' ? <CircularProgress size={24} /> : 'Registrarse'}
              </Button>
            </form>

            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 3, textAlign: 'center' }}>
              Al registrarte, aceptas nuestros terminos de servicio y politica de privacidad.
            </Typography>
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
