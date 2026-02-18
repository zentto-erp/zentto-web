'use client';

import { Box, Typography, CircularProgress } from '@mui/material';
import { Suspense } from 'react';
import dynamic from 'next/dynamic';

// Importar el componente dinámicamente para asegurar que se cargue solo en el cliente
const DebugContentDynamic = dynamic(() => import('./components/DebugContent'), {
  ssr: false,
  loading: () => (
    <Box sx={{ p: 3, display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
      <CircularProgress />
    </Box>
  ),
});

export default function DebugPage() {
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🐛 Panel de Debug
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
        Monitorea todos los requests POST y PATCH en tiempo real. Los logs se guardan automáticamente en SQLite.
      </Typography>
      <Suspense fallback={<CircularProgress />}>
        <DebugContentDynamic />
      </Suspense>
    </Box>
  );
}
