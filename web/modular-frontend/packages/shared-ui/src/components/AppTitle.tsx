'use client';

import React from 'react';
import { Typography, Stack, useTheme } from '@mui/material';
import { getSharedAssetUrl } from '../lib/asset-url';
import { useBranding } from '../hooks/useBranding';
import { brandColors } from '../theme';

export default function AppTitle() {
  const theme = useTheme();
  const { branding } = useBranding();
  const isDark = theme.palette.mode === 'dark';
  const defaultLogoSrc = getSharedAssetUrl(isDark ? '/logo-blanco.svg' : '/logo-gris.svg');
  const logoSrc = branding.logoUrl || defaultLogoSrc;
  const appName = branding.appName || 'Zentto';

  return (
    <Stack direction="row" alignItems="center" spacing={1} sx={{ minHeight: { xs: '56px', sm: '64px' }, px: 0.5 }}>
      <img src={logoSrc} alt={appName} style={{ height: 28, width: 28, objectFit: 'contain' }} />
      <Typography component="span"
        sx={{ fontWeight: 700, letterSpacing: '-0.01em', color: isDark ? '#ffffff' : brandColors.textMuted, fontSize: '1.15rem', whiteSpace: 'nowrap' }}>
        {appName}
      </Typography>
    </Stack>
  );
}
