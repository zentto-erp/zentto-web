'use client';

import React, { useEffect, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Divider,
  Paper,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';
import PaletteIcon from '@mui/icons-material/Palette';
import PreviewIcon from '@mui/icons-material/Preview';
import { useAuth } from '@zentto/shared-auth';
import { useBrandConfig, useSaveBrandConfig } from '@zentto/shared-api';
import type { BrandConfigInput } from '@zentto/shared-api';

const DEFAULT_PRIMARY = '#FFB547';
const DEFAULT_SECONDARY = '#232f3e';
const DEFAULT_ACCENT = '#FFB547';

export default function MarcaPage() {
  const { company } = useAuth();
  const { data: config, isLoading } = useBrandConfig();
  const saveMutation = useSaveBrandConfig();

  // Form state
  const [form, setForm] = useState<BrandConfigInput>({
    logoUrl: '',
    faviconUrl: '',
    primaryColor: DEFAULT_PRIMARY,
    secondaryColor: DEFAULT_SECONDARY,
    accentColor: DEFAULT_ACCENT,
    appName: '',
    supportEmail: '',
    supportPhone: '',
    customDomain: '',
    footerText: '',
    loginBgUrl: '',
  });

  // Hydrate form when data loads
  useEffect(() => {
    if (!config) return;
    setForm({
      logoUrl: config.LogoUrl || '',
      faviconUrl: config.FaviconUrl || '',
      primaryColor: config.PrimaryColor || DEFAULT_PRIMARY,
      secondaryColor: config.SecondaryColor || DEFAULT_SECONDARY,
      accentColor: config.AccentColor || DEFAULT_ACCENT,
      appName: config.AppName || '',
      supportEmail: config.SupportEmail || '',
      supportPhone: config.SupportPhone || '',
      customDomain: config.CustomDomain || '',
      footerText: config.FooterText || '',
      loginBgUrl: config.LoginBgUrl || '',
    });
  }, [config]);

  const handleChange = (field: keyof BrandConfigInput) => (
    e: React.ChangeEvent<HTMLInputElement>,
  ) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }));
  };

  const handleSave = () => {
    saveMutation.mutate(form);
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ maxWidth: 900, mx: 'auto', py: 3, px: 2 }}>
      <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 3 }}>
        <PaletteIcon color="primary" />
        <Typography variant="h5" fontWeight={600}>
          Personalizar Marca
        </Typography>
      </Stack>

      {saveMutation.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Configuracion de marca guardada exitosamente.
        </Alert>
      )}
      {saveMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error al guardar: {(saveMutation.error as Error)?.message || 'Error desconocido'}
        </Alert>
      )}

      {/* ── Colores ── */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>Colores</Typography>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
            <Box sx={{ flex: 1 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                Color primario
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <input
                  type="color"
                  value={form.primaryColor || DEFAULT_PRIMARY}
                  onChange={(e) => setForm((p) => ({ ...p, primaryColor: e.target.value }))}
                  style={{ width: 48, height: 40, border: 'none', cursor: 'pointer', borderRadius: 8 }}
                />
                <TextField
                  size="small"
                  value={form.primaryColor || ''}
                  onChange={handleChange('primaryColor')}
                  sx={{ width: 130 }}
                />
              </Stack>
            </Box>
            <Box sx={{ flex: 1 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                Color secundario
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <input
                  type="color"
                  value={form.secondaryColor || DEFAULT_SECONDARY}
                  onChange={(e) => setForm((p) => ({ ...p, secondaryColor: e.target.value }))}
                  style={{ width: 48, height: 40, border: 'none', cursor: 'pointer', borderRadius: 8 }}
                />
                <TextField
                  size="small"
                  value={form.secondaryColor || ''}
                  onChange={handleChange('secondaryColor')}
                  sx={{ width: 130 }}
                />
              </Stack>
            </Box>
            <Box sx={{ flex: 1 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                Color de acento
              </Typography>
              <Stack direction="row" spacing={1} alignItems="center">
                <input
                  type="color"
                  value={form.accentColor || DEFAULT_ACCENT}
                  onChange={(e) => setForm((p) => ({ ...p, accentColor: e.target.value }))}
                  style={{ width: 48, height: 40, border: 'none', cursor: 'pointer', borderRadius: 8 }}
                />
                <TextField
                  size="small"
                  value={form.accentColor || ''}
                  onChange={handleChange('accentColor')}
                  sx={{ width: 130 }}
                />
              </Stack>
            </Box>
          </Stack>
        </CardContent>
      </Card>

      {/* ── Preview ── */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 2 }}>
            <PreviewIcon fontSize="small" />
            <Typography variant="h6">Vista previa</Typography>
          </Stack>
          <Paper
            elevation={0}
            sx={{
              p: 3,
              borderRadius: 2,
              border: '1px solid',
              borderColor: 'divider',
              background: form.secondaryColor || DEFAULT_SECONDARY,
            }}
          >
            <Stack direction="row" alignItems="center" spacing={2}>
              {form.logoUrl && (
                <Box
                  component="img"
                  src={form.logoUrl}
                  alt="Logo"
                  sx={{ height: 40, maxWidth: 120, objectFit: 'contain' }}
                />
              )}
              <Typography sx={{ color: '#fff', fontWeight: 600, fontSize: '1.1rem' }}>
                {form.appName || 'Zentto ERP'}
              </Typography>
            </Stack>
            <Box sx={{ mt: 2 }}>
              <Button
                variant="contained"
                size="small"
                sx={{
                  bgcolor: form.primaryColor || DEFAULT_PRIMARY,
                  color: form.secondaryColor || DEFAULT_SECONDARY,
                  '&:hover': { bgcolor: form.accentColor || DEFAULT_ACCENT },
                }}
              >
                Boton primario
              </Button>
              <Button
                variant="outlined"
                size="small"
                sx={{
                  ml: 1,
                  borderColor: form.primaryColor || DEFAULT_PRIMARY,
                  color: '#fff',
                }}
              >
                Boton secundario
              </Button>
            </Box>
            {form.footerText && (
              <Typography sx={{ color: '#9CA3AF', mt: 2, fontSize: '0.75rem' }}>
                {form.footerText}
              </Typography>
            )}
          </Paper>
        </CardContent>
      </Card>

      {/* ── Identidad ── */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>Identidad</Typography>
          <Stack spacing={2}>
            <TextField
              label="Nombre de la aplicacion"
              value={form.appName || ''}
              onChange={handleChange('appName')}
              placeholder="Zentto ERP"
              helperText="Se muestra en la barra lateral y el titulo del navegador"
            />
            <TextField
              label="URL del logo"
              value={form.logoUrl || ''}
              onChange={handleChange('logoUrl')}
              placeholder="https://..."
              helperText="Logo principal (recomendado 200x50 px)"
            />
            <TextField
              label="URL del favicon"
              value={form.faviconUrl || ''}
              onChange={handleChange('faviconUrl')}
              placeholder="https://..."
              helperText="Icono del navegador (32x32 px)"
            />
            <TextField
              label="URL fondo de login"
              value={form.loginBgUrl || ''}
              onChange={handleChange('loginBgUrl')}
              placeholder="https://..."
              helperText="Imagen de fondo para la pagina de inicio de sesion"
            />
          </Stack>
        </CardContent>
      </Card>

      {/* ── Contacto y dominio ── */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>Contacto y dominio</Typography>
          <Stack spacing={2}>
            <TextField
              label="Email de soporte"
              value={form.supportEmail || ''}
              onChange={handleChange('supportEmail')}
              placeholder="soporte@miempresa.com"
            />
            <TextField
              label="Telefono de soporte"
              value={form.supportPhone || ''}
              onChange={handleChange('supportPhone')}
              placeholder="+58 412 1234567"
            />
            <TextField
              label="Dominio personalizado"
              value={form.customDomain || ''}
              onChange={handleChange('customDomain')}
              placeholder="erp.miempresa.com"
              helperText="Requiere configuracion DNS adicional"
            />
            <TextField
              label="Texto del pie de pagina"
              value={form.footerText || ''}
              onChange={handleChange('footerText')}
              placeholder="© 2026 Mi Empresa. Todos los derechos reservados."
            />
          </Stack>
        </CardContent>
      </Card>

      {/* ── Save ── */}
      <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
        <Button
          variant="contained"
          startIcon={saveMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <SaveIcon />}
          onClick={handleSave}
          disabled={saveMutation.isPending}
          size="large"
        >
          Guardar cambios
        </Button>
      </Box>
    </Box>
  );
}
