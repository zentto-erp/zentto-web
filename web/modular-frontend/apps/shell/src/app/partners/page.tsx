'use client';

import React, { useState } from 'react';
import {
  Box, Container, Typography, TextField, Button, Paper,
  Alert, Grid, Card, CardContent, CircularProgress,
} from '@mui/material';
import HandshakeIcon from '@mui/icons-material/Handshake';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import GroupAddIcon from '@mui/icons-material/GroupAdd';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  purple: '#6C63FF',
  bg: '#f5f5f5',
  white: '#ffffff',
} as const;

const BENEFITS = [
  { icon: <MonetizationOnIcon sx={{ fontSize: 40, color: COLORS.purple }} />, title: 'Comisiones recurrentes', desc: 'Gana hasta 20% de comision por cada cliente referido mientras mantenga su suscripcion.' },
  { icon: <GroupAddIcon sx={{ fontSize: 40, color: COLORS.purple }} />, title: 'Link de referido unico', desc: 'Comparte tu link personalizado y rastrea cada referido en tiempo real desde tu dashboard.' },
  { icon: <TrendingUpIcon sx={{ fontSize: 40, color: COLORS.purple }} />, title: 'Dashboard exclusivo', desc: 'Accede a metricas de conversiones, comisiones pendientes y pagadas en un solo lugar.' },
];

export default function PartnersPage() {
  const [form, setForm] = useState({ companyName: '', contactName: '', email: '', phone: '' });
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.companyName || !form.contactName || !form.email) return;

    setLoading(true);
    setResult(null);
    try {
      const res = await fetch(`${API_BASE}/v1/partners/apply`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const data = await res.json();
      setResult({ success: data.success, message: data.message || data.error });
      if (data.success) {
        setForm({ companyName: '', contactName: '', email: '', phone: '' });
      }
    } catch {
      setResult({ success: false, message: 'Error de conexion. Intenta de nuevo.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg }}>
      {/* Hero */}
      <Box sx={{
        bgcolor: COLORS.darkPrimary, color: '#fff', py: { xs: 6, md: 10 },
        textAlign: 'center', position: 'relative', overflow: 'hidden',
      }}>
        <Container maxWidth="md">
          <HandshakeIcon sx={{ fontSize: 64, color: COLORS.accent, mb: 2 }} />
          <Typography variant="h3" fontWeight={800} sx={{ mb: 2, fontSize: { xs: '1.8rem', md: '2.8rem' } }}>
            Programa de Partners
          </Typography>
          <Typography variant="h6" sx={{ opacity: 0.85, fontWeight: 400, mb: 3, maxWidth: 600, mx: 'auto' }}>
            Unete a nuestro ecosistema y genera ingresos recurrentes refiriendo clientes a Zentto.
          </Typography>
          <Button
            variant="contained"
            size="large"
            href="#apply"
            sx={{
              py: 1.5, px: 5, fontWeight: 700, fontSize: '1rem', borderRadius: 2,
              bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' },
              textTransform: 'none',
            }}
          >
            Aplicar ahora
          </Button>
        </Container>
      </Box>

      {/* Benefits */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography variant="h4" fontWeight={700} textAlign="center" sx={{ color: COLORS.darkPrimary, mb: 5 }}>
          Por que ser Partner de Zentto?
        </Typography>
        <Grid container spacing={4}>
          {BENEFITS.map((b, i) => (
            <Grid item xs={12} md={4} key={i}>
              <Card elevation={2} sx={{ borderRadius: 3, height: '100%', textAlign: 'center', p: 2 }}>
                <CardContent>
                  {b.icon}
                  <Typography variant="h6" fontWeight={700} sx={{ mt: 2, mb: 1, color: COLORS.darkPrimary }}>
                    {b.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {b.desc}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Application Form */}
      <Box id="apply" sx={{ bgcolor: COLORS.white, py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm">
          <Paper elevation={4} sx={{ p: { xs: 3, md: 5 }, borderRadius: 3 }}>
            <Typography variant="h5" fontWeight={700} sx={{ color: COLORS.darkPrimary, mb: 1, textAlign: 'center' }}>
              Solicitud de Partner
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3, textAlign: 'center' }}>
              Completa el formulario y nuestro equipo revisara tu solicitud en 24-48 horas.
            </Typography>

            {result && (
              <Alert severity={result.success ? 'success' : 'error'} sx={{ mb: 3 }}>
                {result.message}
              </Alert>
            )}

            <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
              <TextField
                label="Nombre de la empresa"
                value={form.companyName}
                onChange={(e) => setForm((f) => ({ ...f, companyName: e.target.value }))}
                required
                fullWidth
              />
              <TextField
                label="Nombre de contacto"
                value={form.contactName}
                onChange={(e) => setForm((f) => ({ ...f, contactName: e.target.value }))}
                required
                fullWidth
              />
              <TextField
                label="Email"
                type="email"
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                required
                fullWidth
              />
              <TextField
                label="Telefono (opcional)"
                value={form.phone}
                onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
                fullWidth
              />
              <Button
                type="submit"
                variant="contained"
                size="large"
                disabled={loading}
                sx={{
                  py: 1.5, fontWeight: 700, borderRadius: 2, textTransform: 'none',
                  bgcolor: COLORS.purple, '&:hover': { bgcolor: '#5b54e6' },
                  fontSize: '1rem',
                }}
              >
                {loading ? <CircularProgress size={24} sx={{ color: '#fff' }} /> : 'Enviar solicitud'}
              </Button>
            </Box>
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
