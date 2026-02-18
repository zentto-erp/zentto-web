'use client';
import React, { useEffect, useState } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';

export function LoadingFallback() {
  const [showMessage, setShowMessage] = useState(false);
  useEffect(() => { const t = setTimeout(() => setShowMessage(true), 500); return () => clearTimeout(t); }, []);
  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: 'calc(100vh - 64px)', width: '100%', backgroundColor: 'background.default' }}>
      <CircularProgress size={40} />
      {showMessage && <Typography variant="body1" sx={{ mt: 2, color: 'text.secondary', textAlign: 'center' }}>Cargando...</Typography>}
    </Box>
  );
}
