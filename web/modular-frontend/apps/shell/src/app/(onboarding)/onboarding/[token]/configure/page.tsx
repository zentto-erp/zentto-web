'use client';

import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  TextField,
  Stack,
  Alert,
  MenuItem,
  FormControlLabel,
  Checkbox,
  Divider,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useByocDeploy, ByocConfig } from '@/hooks/useByocDeploy';

const InfoOutlinedIcon = dynamic(() => import('@mui/icons-material/InfoOutlined'), { ssr: false });

// ─── Opciones de region y tamano por proveedor ────────────────────────────────

interface RegionOption {
  value: string;
  label: string;
}

interface SizeOption {
  value: string;
  label: string;
  description: string;
}

const REGIONS: Record<string, RegionOption[]> = {
  hetzner: [
    { value: 'nbg1', label: 'Nuremberg, Alemania (NBG1)' },
    { value: 'fsn1', label: 'Falkenstein, Alemania (FSN1)' },
    { value: 'hel1', label: 'Helsinki, Finlandia (HEL1)' },
    { value: 'ash',  label: 'Ashburn, EEUU (ASH)' },
    { value: 'hil',  label: 'Hillsboro, EEUU (HIL)' },
    { value: 'sin',  label: 'Singapur (SIN)' },
  ],
  digitalocean: [
    { value: 'nyc1', label: 'Nueva York 1' },
    { value: 'nyc3', label: 'Nueva York 3' },
    { value: 'sfo3', label: 'San Francisco 3' },
    { value: 'ams3', label: 'Amsterdam 3' },
    { value: 'fra1', label: 'Frankfurt 1' },
    { value: 'lon1', label: 'Londres 1' },
    { value: 'sgp1', label: 'Singapur 1' },
    { value: 'tor1', label: 'Toronto 1' },
    { value: 'syd1', label: 'Sydney 1' },
  ],
  ssh: [
    { value: 'custom', label: 'Tu servidor (auto-detectado)' },
  ],
};

const SIZES: Record<string, SizeOption[]> = {
  hetzner: [
    {
      value: 'cx22',
      label: 'CX22 — 2 CPU / 4GB RAM / 40GB SSD',
      description: 'Recomendado para hasta 20 usuarios',
    },
    {
      value: 'cx32',
      label: 'CX32 — 4 CPU / 8GB RAM / 80GB SSD',
      description: 'Para hasta 100 usuarios',
    },
    {
      value: 'cx42',
      label: 'CX42 — 8 CPU / 16GB RAM / 160GB SSD',
      description: 'Para empresas con alto volumen',
    },
  ],
  digitalocean: [
    {
      value: 's-2vcpu-4gb',
      label: 'Basic — 2 vCPU / 4GB RAM / 80GB SSD',
      description: 'Recomendado para hasta 20 usuarios',
    },
    {
      value: 's-4vcpu-8gb',
      label: 'Basic — 4 vCPU / 8GB RAM / 160GB SSD',
      description: 'Para hasta 100 usuarios',
    },
    {
      value: 'g-2vcpu-8gb',
      label: 'General Purpose — 2 vCPU / 8GB RAM',
      description: 'Balance de CPU y RAM para cargas mixtas',
    },
  ],
  ssh: [
    {
      value: 'custom',
      label: 'Usar el servidor tal como esta',
      description: 'Instalaremos en el hardware disponible',
    },
  ],
};

// ─── Paso 4: Configuracion ────────────────────────────────────────────────────

export default function ConfigurePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const router = useRouter();
  const { provider, config, setConfig, companyName } = useByocDeploy();

  const [token, setToken] = useState('');
  const [form, setForm] = useState<ByocConfig>({
    region: '',
    size: '',
    domain: '',
    useZenttoDomain: true,
    ...config,
  });

  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  // Preseleccionar defaults cuando cambia el proveedor
  useEffect(() => {
    if (!provider) return;
    const regions = REGIONS[provider] ?? [];
    const sizes = SIZES[provider] ?? [];
    setForm(prev => ({
      ...prev,
      region: prev.region || (regions[0]?.value ?? ''),
      size: prev.size || (sizes[0]?.value ?? ''),
    }));
  }, [provider]);

  const handleChange = (field: keyof ByocConfig) => (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    setForm(prev => ({ ...prev, [field]: e.target.value }));
  };

  const handleToggleZenttoDomain = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm(prev => ({ ...prev, useZenttoDomain: e.target.checked, domain: e.target.checked ? '' : prev.domain }));
  };

  const canContinue = !!form.region && !!form.size;

  const handleNext = () => {
    setConfig(form);
    router.push(`/onboarding/${token}/deploy`);
  };

  const handleBack = () => {
    router.push(`/onboarding/${token}/credentials`);
  };

  const regions = REGIONS[provider || ''] ?? [];
  const sizes = SIZES[provider || ''] ?? [];
  const isSsh = provider === 'ssh';

  // Dominio Zentto sugerido
  const suggestedSubdomain = companyName
    ? companyName.toLowerCase().replace(/[^a-z0-9]/g, '')
    : 'tuempresa';

  return (
    <Box sx={{ flex: 1, py: 6, px: { xs: 2, sm: 4, md: 8 } }}>
      <Box sx={{ maxWidth: 600, mx: 'auto' }}>
        {/* Titulo */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h5" fontWeight={800} sx={{ color: '#1a1a2e', mb: 1 }}>
            Configuracion del servidor
          </Typography>
          <Typography color="text.secondary">
            Elige la region, el tamano y (opcionalmente) tu dominio personalizado.
          </Typography>
        </Box>

        <Paper
          elevation={0}
          sx={{ p: { xs: 3, sm: 4 }, border: '1px solid #e0e0e0', borderRadius: 3 }}
        >
          <Stack spacing={3}>
            {/* Region / Datacenter */}
            {!isSsh && (
              <Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  Region / Datacenter *
                </Typography>
                <TextField
                  select
                  fullWidth
                  size="small"
                  value={form.region || ''}
                  onChange={handleChange('region')}
                  variant="outlined"
                >
                  {regions.map(r => (
                    <MenuItem key={r.value} value={r.value}>
                      {r.label}
                    </MenuItem>
                  ))}
                </TextField>
                <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>
                  Elige la region mas cercana a tus usuarios para menor latencia.
                </Typography>
              </Box>
            )}

            {/* Tamano del servidor */}
            {!isSsh && (
              <Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  Tamano del servidor *
                </Typography>
                <TextField
                  select
                  fullWidth
                  size="small"
                  value={form.size || ''}
                  onChange={handleChange('size')}
                  variant="outlined"
                >
                  {sizes.map(s => (
                    <MenuItem key={s.value} value={s.value}>
                      <Box>
                        <Typography variant="body2" fontWeight={600}>
                          {s.label}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {s.description}
                        </Typography>
                      </Box>
                    </MenuItem>
                  ))}
                </TextField>
              </Box>
            )}

            {isSsh && (
              <Alert severity="info" icon={<InfoOutlinedIcon />} sx={{ fontSize: 13 }}>
                Para servidores SSH propios, usaremos el hardware disponible tal como esta.
                Asegurate de tener al menos 2GB de RAM y 20GB de espacio libre.
              </Alert>
            )}

            <Divider />

            {/* Dominio personalizado */}
            <Box>
              <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                Dominio
              </Typography>

              <FormControlLabel
                control={
                  <Checkbox
                    checked={form.useZenttoDomain ?? true}
                    onChange={handleToggleZenttoDomain}
                    sx={{ color: '#1a1a2e', '&.Mui-checked': { color: '#ff9900' } }}
                  />
                }
                label={
                  <Typography variant="body2">
                    Usar subdominio Zentto:{' '}
                    <strong>{suggestedSubdomain}.zentto.net</strong>
                  </Typography>
                }
              />

              {!form.useZenttoDomain && (
                <Box sx={{ mt: 2 }}>
                  <TextField
                    fullWidth
                    size="small"
                    placeholder="erp.miempresa.com"
                    value={form.domain || ''}
                    onChange={handleChange('domain')}
                    variant="outlined"
                    helperText="Ingresa solo el dominio o subdominio (sin https://)"
                  />
                  <Alert severity="warning" sx={{ mt: 2, fontSize: 12 }}>
                    <strong>Importante:</strong> Tras el deploy, deberas crear un registro DNS
                    de tipo A apuntando a la IP que te asignaremos. Te lo indicaremos al finalizar.
                  </Alert>
                </Box>
              )}
            </Box>

            {/* Resumen de configuracion */}
            {form.region && form.size && (
              <Box
                sx={{
                  p: 2,
                  bgcolor: '#f8f9fa',
                  borderRadius: 2,
                  border: '1px solid #e0e0e0',
                }}
              >
                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#1a1a2e' }}>
                  Resumen de tu configuracion
                </Typography>
                <Stack spacing={0.5}>
                  {!isSsh && (
                    <>
                      <Typography variant="body2" color="text.secondary">
                        Region: <strong>{regions.find(r => r.value === form.region)?.label}</strong>
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Servidor: <strong>{sizes.find(s => s.value === form.size)?.label}</strong>
                      </Typography>
                    </>
                  )}
                  <Typography variant="body2" color="text.secondary">
                    Dominio:{' '}
                    <strong>
                      {form.useZenttoDomain
                        ? `${suggestedSubdomain}.zentto.net`
                        : form.domain || '(pendiente)'}
                    </strong>
                  </Typography>
                </Stack>
              </Box>
            )}
          </Stack>
        </Paper>

        {/* Navegacion */}
        <Stack direction="row" spacing={2} justifyContent="space-between" sx={{ mt: 4 }}>
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
            disabled={!canContinue}
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
            Iniciar instalacion
          </Button>
        </Stack>
      </Box>
    </Box>
  );
}
