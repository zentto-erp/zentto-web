'use client';

import { Box, Typography } from '@mui/material';

const FONT = "'Inter', system-ui, sans-serif";

interface BrandPanelProps {
  title: React.ReactNode;
  description: string;
  side?: 'left' | 'right';
}

export default function BrandPanel({ title, description, side = 'left' }: BrandPanelProps) {
  return (
    <Box
      sx={{
        display: { xs: 'none', md: 'flex' },
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'center',
        width: '45%',
        background: '#3b3699',
        color: '#fff',
        p: 6,
        textAlign: 'center',
        order: side === 'right' ? 1 : 0,
      }}
    >
      <Box sx={{ mb: 3 }}>
        <img src="/logo-blanco.svg" alt="Zentto" style={{ height: 48 }} />
      </Box>
      <Typography
        sx={{
          fontFamily: FONT,
          fontWeight: 700,
          fontSize: '1.5rem',
          letterSpacing: '-0.025em',
          mb: 1.5,
          color: '#fff',
        }}
      >
        {title}
      </Typography>
      <Typography
        sx={{
          fontFamily: FONT,
          fontSize: '0.9375rem',
          color: 'rgba(255,255,255,0.7)',
          maxWidth: 280,
          lineHeight: 1.7,
        }}
      >
        {description}
      </Typography>
      <Box sx={{ mt: 4, display: 'flex', gap: 2, flexWrap: 'wrap', justifyContent: 'center' }}>
        {['Facturación', 'Inventario', 'Contabilidad', 'POS'].map((mod) => (
          <Typography
            key={mod}
            sx={{
              fontSize: '0.6875rem',
              fontWeight: 600,
              color: 'rgba(255,255,255,0.4)',
              fontFamily: FONT,
              letterSpacing: '0.05em',
              textTransform: 'uppercase',
            }}
          >
            {mod}
          </Typography>
        ))}
      </Box>
    </Box>
  );
}
