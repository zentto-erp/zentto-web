'use client';
import React from 'react';
import { Typography, useTheme, Box, Stack } from '@mui/material';
import type { TypographyProps } from '@mui/material/Typography';

interface LogoProps { size?: 'small' | 'medium' | 'large' }

export default function Logo({ size = 'medium' }: LogoProps) {
  const theme = useTheme();
  const sizes: Record<'small' | 'medium' | 'large', { box: number; font: string; title: TypographyProps['variant']; subtitle: TypographyProps['variant'] }> = {
    small: { box: 32, font: '1rem', title: 'h6', subtitle: 'caption' },
    medium: { box: 56, font: '1.5rem', title: 'h5', subtitle: 'body2' },
    large: { box: 72, font: '2rem', title: 'h4', subtitle: 'body1' },
  };
  const s = sizes[size];

  return (
    <Stack alignItems="center" spacing={1.5}>
      <Box sx={{
        width: s.box, height: s.box, borderRadius: 2,
        background: `linear-gradient(135deg, ${theme.palette.primary.main}, ${theme.palette.primary.dark})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 4px 12px ${theme.palette.primary.main}40`,
      }}>
        <img src="/logo-blanco.svg" alt="Zentto" style={{ width: s.box * 0.75, height: s.box * 0.75, objectFit: 'contain' }} />
      </Box>
      <Box textAlign="center">
        <Typography variant={s.title} component="h1"
          sx={{ fontWeight: 700, letterSpacing: '0.15em', textTransform: 'uppercase', color: 'text.primary', lineHeight: 1.2 }}>
          Zentto
        </Typography>
        <Typography variant={s.subtitle}
          sx={{ color: 'text.secondary', letterSpacing: '0.1em', fontWeight: 500 }}>
          Sistema de Administración
        </Typography>
      </Box>
    </Stack>
  );
}
