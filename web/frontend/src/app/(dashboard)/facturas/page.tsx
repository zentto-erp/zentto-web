'use client';

import { Box, Typography, Card, CardContent, CardHeader } from '@mui/material';

export default function FacturasPage() {
  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Facturación
        </Typography>
        <Typography variant="body1" color="textSecondary">
          Gestiona tus facturas y transacciones comerciales
        </Typography>
      </Box>

      <Card>
        <CardHeader title="Listado de Facturas" />
        <CardContent>
          <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
            Módulo de facturación en desarrollo
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}

