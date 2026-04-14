'use client';

import { useSearchParams } from 'next/navigation';
import { Box, Container, Card, CardContent, Typography, Button, Alert } from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

export default function RegistroExitoPage() {
  const params = useSearchParams();
  const subdomain = params.get('subdomain') || '';
  const trial = params.get('trial') === '1';
  const magicLinkSent = params.get('magic') === '1';
  const expiresAt = params.get('expires');

  const tenantUrl = subdomain ? `https://${subdomain}.zentto.net` : 'https://app.zentto.net';

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5', display: 'flex', alignItems: 'center', py: 4 }}>
      <Container maxWidth="sm">
        <Card elevation={4} sx={{ borderRadius: 3, textAlign: 'center' }}>
          <CardContent sx={{ p: { xs: 4, md: 6 } }}>
            <CheckCircleIcon sx={{ fontSize: 64, color: '#4caf50', mb: 2 }} />
            <Typography variant="h4" fontWeight={800} sx={{ mb: 2, color: '#131921' }}>
              ¡Tu cuenta está lista!
            </Typography>

            {trial && (
              <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                Comenzó tu prueba gratuita{expiresAt ? ` hasta el ${new Date(expiresAt).toLocaleDateString()}` : ''}.
              </Typography>
            )}

            {magicLinkSent ? (
              <Alert severity="info" sx={{ mb: 3, textAlign: 'left' }}>
                <Typography variant="body2">
                  Te enviamos un email con un <strong>link seguro para fijar tu contraseña</strong>.
                  Revisa tu bandeja (también en spam). El link expira en 24 horas.
                </Typography>
              </Alert>
            ) : (
              <Alert severity="warning" sx={{ mb: 3, textAlign: 'left' }}>
                <Typography variant="body2">
                  Te enviamos un email de bienvenida con tus credenciales iniciales.
                  Te recomendamos cambiar la contraseña al primer login.
                </Typography>
              </Alert>
            )}

            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              Tu URL exclusiva:<br />
              <Typography component="span" fontWeight={700} sx={{ color: '#6C63FF' }}>{tenantUrl}</Typography>
            </Typography>

            <Button
              variant="contained"
              size="large"
              href={tenantUrl}
              sx={{
                bgcolor: '#6C63FF',
                '&:hover': { bgcolor: '#5b54e6' },
                textTransform: 'none',
                fontWeight: 700,
                px: 4,
                py: 1.5,
                borderRadius: 2,
              }}
            >
              Ir a mi Zentto
            </Button>
          </CardContent>
        </Card>
      </Container>
    </Box>
  );
}
