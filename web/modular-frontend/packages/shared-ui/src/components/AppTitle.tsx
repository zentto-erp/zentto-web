'use client';

import React from 'react';
import { Box, Typography, useTheme, Stack } from '@mui/material';
import { getSharedAssetUrl } from '../lib/asset-url';
import { useBranding } from '../hooks/useBranding';

export default function AppTitle({ lightText = false }: { lightText?: boolean }) {
  const theme = useTheme();
  const { branding } = useBranding();
  const defaultLogoSrc = getSharedAssetUrl('/logo-blanco.svg');
  const logoSrc = branding.logoUrl || defaultLogoSrc;
  const appName = branding.appName || 'ZENTTO';
  const appSubtitle = branding.appSubtitle || 'Sistema Administrador';

  return (
    <Stack direction="row" alignItems="center" spacing={1.5} sx={{ minHeight: { xs: '56px', sm: '64px' }, px: 0.5 }}>
      <Box sx={{
        width: 36, height: 36, minWidth: 36, borderRadius: '50%',
        background: `linear-gradient(135deg, ${theme.palette.primary.main}, ${theme.palette.primary.dark})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 2px 8px ${theme.palette.primary.main}30`,
      }}>
        <img src={logoSrc} alt={appName} style={{ width: 28, height: 28, objectFit: 'contain' }} />
      </Box>
      <Box sx={{ overflow: 'hidden' }}>
        <Typography variant="subtitle1" component="span" display="block"
          sx={{ fontWeight: 800, letterSpacing: '0.1em', color: lightText ? '#ffffff' : 'text.primary', lineHeight: 1, fontSize: '0.9rem', whiteSpace: 'nowrap' }}>
          {appName}
        </Typography>
        <Typography variant="caption" component="span" display="block"
          sx={{ color: lightText ? 'rgba(255,255,255,0.7)' : 'text.secondary', fontWeight: 600, fontSize: '0.65rem', whiteSpace: 'nowrap', mt: 0.2 }}>
          {appSubtitle}
        </Typography>
      </Box>
    </Stack>
  );
}
