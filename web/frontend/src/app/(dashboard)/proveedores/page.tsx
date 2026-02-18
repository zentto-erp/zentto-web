'use client';

import { Box, Typography, Card, CardContent, CardHeader, Button } from '@mui/material';
import dynamic from 'next/dynamic';

const AddIcon = dynamic(() => import('@mui/icons-material/Add'), { ssr: false });

export default function ProveedoresPage() {
  return (
    <Box>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
            Proveedores
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Gestiona tus relaciones con proveedores
          </Typography>
        </Box>
        <Button variant="contained" color="primary" startIcon={<AddIcon />}>
          Nuevo Proveedor
        </Button>
      </Box>

      <Card>
        <CardHeader title="Listado de Proveedores" />
        <CardContent>
          <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
            Módulo de proveedores en desarrollo
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}
