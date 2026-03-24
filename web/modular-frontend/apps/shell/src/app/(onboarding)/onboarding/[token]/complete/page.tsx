'use client';

import React, { Suspense, useEffect, useState, useRef } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  Stack,
  Divider,
  Chip,
  Alert,
  CircularProgress,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { useSearchParams } from 'next/navigation';
import { useByocDeploy } from '@/hooks/useByocDeploy';

const CheckCircleIcon = dynamic(() => import('@mui/icons-material/CheckCircle'), { ssr: false });
const OpenInNewIcon = dynamic(() => import('@mui/icons-material/OpenInNew'), { ssr: false });
const LanguageIcon = dynamic(() => import('@mui/icons-material/Language'), { ssr: false });
const PersonIcon = dynamic(() => import('@mui/icons-material/Person'), { ssr: false });
const VpnKeyIcon = dynamic(() => import('@mui/icons-material/VpnKey'), { ssr: false });
const EmailIcon = dynamic(() => import('@mui/icons-material/Email'), { ssr: false });
const ContentCopyIcon = dynamic(() => import('@mui/icons-material/ContentCopy'), { ssr: false });

// ─── Contenido interno (necesita Suspense por useSearchParams) ────────────────

function CompletePageContent({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const searchParams = useSearchParams();
  const { companyName, clearState } = useByocDeploy();

  const [token, setToken] = useState('');
  const [copied, setCopied] = useState(false);
  const hasCleared = useRef(false);

  // URL del tenant desde query param
  const tenantUrl = searchParams.get('url') || '';
  const decodedUrl = tenantUrl ? decodeURIComponent(tenantUrl) : '';

  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  // Limpiar el estado del wizard al llegar a la pagina de exito (una sola vez)
  useEffect(() => {
    if (!hasCleared.current) {
      hasCleared.current = true;
      // Pequeño delay para asegurar que la UI se monte antes de limpiar
      setTimeout(() => clearState(), 500);
    }
  }, [clearState]);

  const handleOpenZentto = () => {
    if (decodedUrl) {
      window.open(decodedUrl, '_blank', 'noopener,noreferrer');
    }
  };

  const handleCopyUrl = async () => {
    if (!decodedUrl) return;
    try {
      await navigator.clipboard.writeText(decodedUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // clipboard no disponible
    }
  };

  // ─── Info cards de acceso ─────────────────────────────────────────────────

  interface InfoCard {
    icon: React.ReactNode;
    label: string;
    value: string;
    copyable?: boolean;
  }

  const infoCards: InfoCard[] = [
    {
      icon: <LanguageIcon sx={{ color: '#ff9900' }} />,
      label: 'Tu URL',
      value: decodedUrl || 'Cargando...',
      copyable: true,
    },
    {
      icon: <PersonIcon sx={{ color: '#4caf50' }} />,
      label: 'Usuario administrador',
      value: 'ADMIN',
    },
    {
      icon: <VpnKeyIcon sx={{ color: '#2196f3' }} />,
      label: 'Contrasena',
      value: 'Revisa tu correo electronico',
    },
  ];

  return (
    <Box sx={{ flex: 1, py: 6, px: { xs: 2, sm: 4, md: 8 } }}>
      <Box sx={{ maxWidth: 600, mx: 'auto', textAlign: 'center' }}>
        {/* Animacion de check */}
        <Box
          sx={{
            width: 100,
            height: 100,
            borderRadius: '50%',
            bgcolor: '#e8f5e9',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            mx: 'auto',
            mb: 3,
            animation: 'popIn 0.5s cubic-bezier(0.34, 1.56, 0.64, 1)',
            '@keyframes popIn': {
              '0%': { transform: 'scale(0)', opacity: 0 },
              '100%': { transform: 'scale(1)', opacity: 1 },
            },
          }}
        >
          <CheckCircleIcon sx={{ fontSize: 60, color: '#4caf50' }} />
        </Box>

        {/* Titulo */}
        <Typography
          variant="h4"
          fontWeight={900}
          sx={{ color: '#1a1a2e', mb: 1 }}
        >
          Tu Zentto esta listo!
        </Typography>

        {companyName && (
          <Typography variant="h6" sx={{ color: '#ff9900', fontWeight: 700, mb: 1 }}>
            {companyName}
          </Typography>
        )}

        <Typography color="text.secondary" sx={{ mb: 4 }}>
          Tu instancia privada de Zentto ERP ha sido instalada y configurada exitosamente.
          Ya puedes acceder y comenzar a usar el sistema.
        </Typography>

        {/* Cards de informacion de acceso */}
        <Paper
          elevation={0}
          sx={{
            p: { xs: 3, sm: 4 },
            mb: 4,
            border: '1px solid #e0e0e0',
            borderRadius: 3,
            textAlign: 'left',
          }}
        >
          <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 3, color: '#1a1a2e' }}>
            Datos de acceso
          </Typography>

          <Stack spacing={2}>
            {infoCards.map((card, i) => (
              <Box key={i}>
                {i > 0 && <Divider sx={{ mb: 2 }} />}
                <Stack direction="row" alignItems="flex-start" spacing={2}>
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: 2,
                      bgcolor: '#f5f5f5',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    {card.icon}
                  </Box>
                  <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                      {card.label}
                    </Typography>
                    <Typography
                      variant="body2"
                      fontWeight={600}
                      sx={{
                        color: '#1a1a2e',
                        wordBreak: 'break-all',
                        fontFamily: card.label === 'Tu URL' ? 'monospace' : 'inherit',
                      }}
                    >
                      {card.value}
                    </Typography>
                  </Box>
                  {card.copyable && decodedUrl && (
                    <Button
                      size="small"
                      variant="text"
                      onClick={handleCopyUrl}
                      startIcon={<ContentCopyIcon sx={{ fontSize: 16 }} />}
                      sx={{
                        textTransform: 'none',
                        color: copied ? '#4caf50' : '#666',
                        fontSize: 12,
                        flexShrink: 0,
                      }}
                    >
                      {copied ? 'Copiado!' : 'Copiar'}
                    </Button>
                  )}
                </Stack>
              </Box>
            ))}
          </Stack>
        </Paper>

        {/* Nota de email */}
        <Alert
          severity="info"
          icon={<EmailIcon />}
          sx={{ mb: 4, textAlign: 'left', fontSize: 13 }}
        >
          Hemos enviado tus credenciales de acceso a tu correo electronico. Revisa tambien
          la carpeta de spam si no lo encuentras.
        </Alert>

        {/* Tags de lo que esta incluido */}
        <Stack direction="row" flexWrap="wrap" gap={1} justifyContent="center" sx={{ mb: 4 }}>
          {[
            'SSL activado',
            'Base de datos lista',
            'Docker configurado',
            'Backups automaticos',
            'Soporte incluido',
          ].map(tag => (
            <Chip
              key={tag}
              label={tag}
              size="small"
              icon={<CheckCircleIcon sx={{ fontSize: '14px !important', color: '#4caf50 !important' }} />}
              sx={{ bgcolor: '#e8f5e9', color: '#2e7d32', fontWeight: 600, fontSize: 12 }}
            />
          ))}
        </Stack>

        {/* Boton principal */}
        <Button
          variant="contained"
          size="large"
          onClick={handleOpenZentto}
          disabled={!decodedUrl}
          endIcon={<OpenInNewIcon />}
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
            '&:disabled': {
              bgcolor: '#e0e0e0',
              color: '#9e9e9e',
            },
          }}
        >
          Ir a mi Zentto
        </Button>

        <Typography variant="caption" sx={{ display: 'block', mt: 2, color: '#9e9e9e' }}>
          Se abrira en una nueva pestana
        </Typography>
      </Box>
    </Box>
  );
}

// ─── Export con Suspense (requerido por useSearchParams en Next.js 14) ────────

export default function CompletePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  return (
    <Suspense
      fallback={
        <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', py: 8 }}>
          <CircularProgress sx={{ color: '#ff9900' }} />
        </Box>
      }
    >
      <CompletePageContent params={params} />
    </Suspense>
  );
}
