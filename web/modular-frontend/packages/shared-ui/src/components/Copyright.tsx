'use client';

import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import { useColorScheme } from '@mui/material/styles';
import type { SxProps, Theme } from '@mui/material/styles';
import { getSharedAssetUrl } from '../lib/asset-url';

export default function Copyright(props: { sx?: SxProps<Theme> }) {
  const { mode } = useColorScheme();
  const logoSrc = getSharedAssetUrl(mode === 'dark' ? '/logo-blanco.svg' : '/logo-gris.svg');

  return (
    <Box
      sx={[
        { display: 'flex', flexDirection: 'row', alignItems: 'center', gap: 1 },
        ...(Array.isArray(props.sx) ? props.sx : [props.sx].filter(Boolean)),
      ]}
    >
      <img src={logoSrc} alt="Zentto" style={{ width: 24, height: 24, objectFit: 'contain' }} />
      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
        {'© Zentto '}
        {new Date().getFullYear()}
        {'.'}
      </Typography>
    </Box>
  );
}
