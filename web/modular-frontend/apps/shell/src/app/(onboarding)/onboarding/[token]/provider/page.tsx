'use client';

import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  Chip,
  Stack,
} from '@mui/material';
import Grid from '@mui/material/Grid2';
import { useRouter } from 'next/navigation';
import { useByocDeploy, ByocProvider } from '@/hooks/useByocDeploy';

// ─── Datos de proveedores ─────────────────────────────────────────────────────

interface ProviderCard {
  id: ByocProvider;
  label: string;
  icon: string;
  description: string;
  badge?: string;
  accentColor: string;
}

const PROVIDERS: ProviderCard[] = [
  {
    id: 'hetzner',
    label: 'Hetzner',
    icon: '🇩🇪',
    description: 'Servidores en Europa a precio bajo. Ideal para equipos pequenos y medianos.',
    accentColor: '#d50c2d',
  },
  {
    id: 'digitalocean',
    label: 'DigitalOcean',
    icon: '🌊',
    description: 'Simple, confiable y con excelente soporte para desarrolladores.',
    accentColor: '#0080ff',
  },
  {
    id: 'ssh',
    label: 'Mi propio VPS',
    icon: '🖥️',
    description: 'Tienes tu propio servidor. Solo necesitamos IP y acceso SSH.',
    accentColor: '#4caf50',
  },
  {
    id: 'aws',
    label: 'Amazon AWS',
    icon: '☁️',
    description: 'La mayor escala disponible en la nube. Proximamente.',
    badge: 'Proximamente',
    accentColor: '#ff9900',
  },
  {
    id: 'gcp',
    label: 'Google Cloud',
    icon: '🔵',
    description: 'Infraestructura de Google con alcance global. Proximamente.',
    badge: 'Proximamente',
    accentColor: '#4285f4',
  },
  {
    id: 'azure',
    label: 'Microsoft Azure',
    icon: '🟦',
    description: 'Ecosistema Microsoft integrado para empresas. Proximamente.',
    badge: 'Proximamente',
    accentColor: '#0078d4',
  },
];

// ─── Paso 2: Selector de proveedor ───────────────────────────────────────────

export default function ProviderPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const router = useRouter();
  const { provider, setProvider } = useByocDeploy();

  const [token, setToken] = useState('');
  const [hovered, setHovered] = useState<string | null>(null);

  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  const handleSelect = (id: ByocProvider) => {
    setProvider(id);
  };

  const handleNext = () => {
    if (!provider || !token) return;
    router.push(`/onboarding/${token}/credentials`);
  };

  const handleBack = () => {
    if (!token) return;
    router.push(`/onboarding/${token}`);
  };

  return (
    <Box sx={{ flex: 1, py: 6, px: { xs: 2, sm: 4, md: 8 } }}>
      {/* Titulo */}
      <Box sx={{ maxWidth: 800, mx: 'auto', mb: 5 }}>
        <Typography variant="h5" fontWeight={800} sx={{ color: '#1a1a2e', mb: 1 }}>
          Donde quieres alojar tu Zentto?
        </Typography>
        <Typography color="text.secondary">
          Elige el proveedor de nube donde instalaremos tu instancia privada.
          Los proveedores activos tienen configuracion automatica.
        </Typography>
      </Box>

      {/* Grid de cards */}
      <Box sx={{ maxWidth: 800, mx: 'auto', mb: 5 }}>
        <Grid container spacing={2}>
          {PROVIDERS.map(p => {
            const isDisabled = !!p.badge;
            const isSelected = provider === p.id;
            const isHovered = hovered === p.id && !isDisabled;

            return (
              <Grid key={p.id} size={{ xs: 12, sm: 6, md: 4 }}>
                <Paper
                  elevation={0}
                  onClick={() => !isDisabled && handleSelect(p.id)}
                  onMouseEnter={() => setHovered(p.id)}
                  onMouseLeave={() => setHovered(null)}
                  sx={{
                    p: 3,
                    height: '100%',
                    border: isSelected
                      ? `2px solid ${p.accentColor}`
                      : '2px solid #e0e0e0',
                    borderRadius: 2,
                    cursor: isDisabled ? 'not-allowed' : 'pointer',
                    opacity: isDisabled ? 0.5 : 1,
                    transition: 'all 0.2s ease',
                    background: isSelected
                      ? `${p.accentColor}08`
                      : isHovered
                      ? '#fafafa'
                      : '#fff',
                    transform: isSelected || isHovered ? 'translateY(-2px)' : 'none',
                    boxShadow: isSelected
                      ? `0 4px 16px ${p.accentColor}30`
                      : isHovered
                      ? '0 4px 12px rgba(0,0,0,0.08)'
                      : 'none',
                    position: 'relative',
                  }}
                >
                  {/* Badge "Proximamente" */}
                  {p.badge && (
                    <Chip
                      label={p.badge}
                      size="small"
                      sx={{
                        position: 'absolute',
                        top: 10,
                        right: 10,
                        fontSize: 10,
                        height: 20,
                        bgcolor: '#e0e0e0',
                        color: '#666',
                      }}
                    />
                  )}

                  {/* Icono */}
                  <Typography sx={{ fontSize: 36, mb: 1.5, lineHeight: 1 }}>
                    {p.icon}
                  </Typography>

                  {/* Nombre */}
                  <Typography
                    variant="subtitle1"
                    fontWeight={700}
                    sx={{ color: isSelected ? p.accentColor : '#1a1a2e', mb: 0.5 }}
                  >
                    {p.label}
                  </Typography>

                  {/* Descripcion */}
                  <Typography variant="body2" color="text.secondary" sx={{ fontSize: 13 }}>
                    {p.description}
                  </Typography>

                  {/* Indicator de seleccion */}
                  {isSelected && (
                    <Box
                      sx={{
                        position: 'absolute',
                        bottom: 10,
                        right: 10,
                        width: 20,
                        height: 20,
                        borderRadius: '50%',
                        bgcolor: p.accentColor,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <Typography sx={{ color: '#fff', fontSize: 12, fontWeight: 900 }}>
                        ✓
                      </Typography>
                    </Box>
                  )}
                </Paper>
              </Grid>
            );
          })}
        </Grid>
      </Box>

      {/* Navegacion */}
      <Box sx={{ maxWidth: 800, mx: 'auto' }}>
        <Stack direction="row" spacing={2} justifyContent="space-between">
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
            disabled={!provider}
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
            Continuar con {PROVIDERS.find(p => p.id === provider)?.label || '...'}
          </Button>
        </Stack>
      </Box>
    </Box>
  );
}
