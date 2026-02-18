'use client';

import React from 'react';
import { Box, Typography, useTheme, Stack } from '@mui/material';

export default function AppTitle() {
  const theme = useTheme();
  return (
    <Stack direction="row" alignItems="center" spacing={1.5} sx={{ minHeight: { xs: '56px', sm: '64px' }, px: 0.5 }}>
      <Box sx={{
        width: 36, height: 36, minWidth: 36, borderRadius: 1.5,
        background: `linear-gradient(135deg, ${theme.palette.primary.main}, ${theme.palette.primary.dark})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 2px 8px ${theme.palette.primary.main}30`,
      }}>
        <Typography sx={{ color: '#fff', fontWeight: 800, fontSize: '0.9rem', letterSpacing: 1, lineHeight: 1 }}>DB</Typography>
      </Box>
      <Box sx={{ overflow: 'hidden' }}>
        <Typography variant="subtitle1" component="span"
          sx={{ fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'text.primary', lineHeight: 1.2, whiteSpace: 'nowrap', fontSize: '0.85rem' }}>
          DATQBOX
        </Typography>
        <Typography variant="caption" component="span" display="block"
          sx={{ color: 'text.secondary', letterSpacing: '0.05em', fontWeight: 400, fontSize: '0.65rem', whiteSpace: 'nowrap' }}>
          Sistema de Administración
        </Typography>
      </Box>
    </Stack>
  );
}
