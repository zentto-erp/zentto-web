'use client';
import React from 'react';
import { Typography, Stack, useTheme } from '@mui/material';
import { getSharedAssetUrl } from '../lib/asset-url';
import { useBranding } from '../hooks/useBranding';

interface LogoProps { size?: 'small' | 'medium' | 'large' }

export default function Logo({ size = 'medium' }: LogoProps) {
  const theme = useTheme();
  const { branding } = useBranding();
  const isDark = theme.palette.mode === 'dark';
  const defaultLogoSrc = getSharedAssetUrl(isDark ? '/logo-blanco.svg' : '/logo-gris.svg');
  const logoSrc = branding.logoUrl || defaultLogoSrc;
  const appName = branding.appName || 'Zentto';
  const appSubtitle = branding.appSubtitle || 'Sistema de Administración';

  const imgSize = { small: 24, medium: 36, large: 48 }[size];
  const fontSize = { small: '1rem', medium: '1.5rem', large: '2rem' }[size];

  return (
    <Stack alignItems="center" spacing={1.5}>
      <Stack direction="row" alignItems="center" spacing={1}>
        <img src={logoSrc} alt={appName} style={{ height: imgSize, width: imgSize, objectFit: 'contain' }} />
        <Typography component="h1"
          sx={{ fontWeight: 700, letterSpacing: '-0.01em', color: 'text.primary', fontSize, lineHeight: 1.2 }}>
          {appName}
        </Typography>
      </Stack>
      <Typography variant="body2"
        sx={{ color: 'text.secondary', fontWeight: 500 }}>
        {appSubtitle}
      </Typography>
    </Stack>
  );
}
