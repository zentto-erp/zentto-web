'use client';
import * as React from 'react';
import Box from '@mui/material/Box';

export default function AppBarWrapper({ children }: { children: React.ReactNode }) {
  return (
    <Box sx={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      {children}
    </Box>
  );
}
