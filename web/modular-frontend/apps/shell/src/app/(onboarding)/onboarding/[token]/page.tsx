'use client';

import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  CircularProgress,
  Alert,
  Chip,
  Stack,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useByocDeploy } from '@/hooks/useByocDeploy';

const RocketLaunchIcon = dynamic(() => import('@mui/icons-material/RocketLaunch'), { ssr: false });
const ErrorOutlineIcon = dynamic(() => import('@mui/icons-material/ErrorOutline'), { ssr: false });
const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });

const API_URL = process.env.NEXT_PUBLIC_API_URL || '';

// ─── Tipos ────────────────────────────────────────────────────────────────────

interface OnboardingTokenData {
  valid: boolean;
  companyId?: number;
  companyName?: string;
  planLabel?: string;
  expiresAt?: string;
  message?: string;
}

// ─── Paso 1: Bienvenida ───────────────────────────────────────────────────────

export default function OnboardingWelcomePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const router = useRouter();
  const { setCompanyInfo } = useByocDeploy();

  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<OnboardingTokenData | null>(null);

  // Resolver params (Next.js 14 App Router — params es promesa)
  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  // Validar token cuando este disponible
  useEffect(() => {
    if (!token) return;

    const validate = async () => {
      setLoading(true);
      try {
        const res = await fetch(
          `${API_URL}/v1/byoc/onboarding/validate?token=${encodeURIComponent(token)}`
        );
        const json = await res.json() as OnboardingTokenData;
        setData(json);

        if (json.valid && json.companyId && json.companyName) {
          setCompanyInfo(json.companyId, json.companyName, json.planLabel ?? '');
        }
      } catch {
        setData({ valid: false, message: 'No se pudo conectar al servidor. Intenta de nuevo.' });
      } finally {
        setLoading(false);
      }
    };

    validate();
  }, [token, setCompanyInfo]);

  const handleStart = () => {
    router.push(`/onboarding/${token}/provider`);
  };

  // ─── Estados de carga / error ─────────────────────────────────────────────

  if (loading) {
    return (
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          py: 8,
        }}
      >
        <Stack alignItems="center" spacing={2}>
          <CircularProgress sx={{ color: '#ff9900' }} size={48} />
          <Typography color="text.secondary">Verificando tu invitacion...</Typography>
        </Stack>
      </Box>
    );
  }

  if (!data?.valid) {
    return (
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          py: 8,
          px: 2,
        }}
      >
        <Paper
          elevation={0}
          sx={{
            p: { xs: 3, sm: 5 },
            maxWidth: 480,
            width: '100%',
            border: '1px solid #ffcdd2',
            borderRadius: 3,
            textAlign: 'center',
          }}
        >
          <ErrorOutlineIcon sx={{ fontSize: 64, color: '#f44336', mb: 2 }} />
          <Typography variant="h5" fontWeight={700} sx={{ color: '#1a1a2e', mb: 1 }}>
            Enlace invalido o expirado
          </Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>
            {data?.message || 'Este enlace de configuracion no es valido o ha caducado.'}
          </Typography>
          <Alert severity="info" sx={{ mb: 3, textAlign: 'left' }}>
            Los enlaces de configuracion son validos por 72 horas. Si necesitas uno nuevo,
            contacta al equipo de Zentto.
          </Alert>
          <Button
            variant="contained"
            href="mailto:soporte@zentto.net"
            sx={{
              bgcolor: '#1a1a2e',
              color: '#ff9900',
              fontWeight: 700,
              textTransform: 'none',
              px: 4,
              '&:hover': { bgcolor: '#2d2d4a' },
            }}
          >
            Contactar soporte
          </Button>
        </Paper>
      </Box>
    );
  }

  // ─── Token valido: pantalla de bienvenida ─────────────────────────────────

  return (
    <Box
      sx={{
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        py: 6,
        px: 2,
      }}
    >
      <Paper
        elevation={0}
        sx={{
          p: { xs: 3, sm: 6 },
          maxWidth: 600,
          width: '100%',
          border: '1px solid #e0e0e0',
          borderRadius: 3,
          textAlign: 'center',
        }}
      >
        {/* Icono de bienvenida */}
        <Box
          sx={{
            width: 80,
            height: 80,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #1a1a2e 0%, #2d2d4a 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            mx: 'auto',
            mb: 3,
          }}
        >
          <RocketLaunchIcon sx={{ fontSize: 40, color: '#ff9900' }} />
        </Box>

        {/* Titulo */}
        <Typography variant="h4" fontWeight={900} sx={{ color: '#1a1a2e', mb: 1 }}>
          Bienvenido a Zentto
        </Typography>
        <Typography variant="h6" sx={{ color: '#ff9900', fontWeight: 700, mb: 3 }}>
          {data.companyName}
        </Typography>

        {/* Info del plan */}
        {data.planLabel && (
          <Chip
            icon={<CheckCircleIcon />}
            label={`Plan: ${data.planLabel}`}
            color="success"
            variant="outlined"
            sx={{ mb: 3, fontWeight: 600 }}
          />
        )}

        {/* Descripcion del proceso */}
        <Typography color="text.secondary" sx={{ mb: 4, lineHeight: 1.7 }}>
          En los proximos minutos configuraremos tu instancia privada de Zentto ERP.
          Elegiras donde alojar tu servidor, ingresaras tus credenciales de nube y
          nosotros nos encargamos de instalar y configurar todo automaticamente.
        </Typography>

        {/* Pasos del proceso (visual rapido) */}
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={2}
          justifyContent="center"
          sx={{ mb: 4 }}
        >
          {['Elige proveedor', 'Credenciales', 'Configurar', 'Deploy automatico'].map(
            (step, i) => (
              <Box key={step} sx={{ textAlign: 'center' }}>
                <Box
                  sx={{
                    width: 32,
                    height: 32,
                    borderRadius: '50%',
                    bgcolor: '#1a1a2e',
                    color: '#ff9900',
                    fontWeight: 700,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mx: 'auto',
                    mb: 0.5,
                    fontSize: 14,
                  }}
                >
                  {i + 1}
                </Box>
                <Typography variant="caption" sx={{ color: '#666', fontSize: 11 }}>
                  {step}
                </Typography>
              </Box>
            )
          )}
        </Stack>

        {/* CTA principal */}
        <Button
          variant="contained"
          size="large"
          onClick={handleStart}
          endIcon={<RocketLaunchIcon />}
          sx={{
            bgcolor: '#ff9900',
            color: '#1a1a2e',
            fontWeight: 800,
            textTransform: 'none',
            px: 5,
            py: 1.5,
            fontSize: 16,
            borderRadius: 2,
            boxShadow: '0 4px 14px rgba(255,153,0,0.4)',
            '&:hover': {
              bgcolor: '#e68a00',
              boxShadow: '0 6px 20px rgba(255,153,0,0.5)',
            },
          }}
        >
          Comenzar configuracion
        </Button>

        <Typography variant="caption" sx={{ display: 'block', mt: 2, color: '#9e9e9e' }}>
          El proceso tarda aproximadamente 5-10 minutos
        </Typography>
      </Paper>
    </Box>
  );
}
