'use client';

import { Box, Typography, Card, CardContent, CardHeader, Button } from '@mui/material';
import dynamic from 'next/dynamic';

const AddIcon = dynamic(() => import('@mui/icons-material/Add'), { ssr: false });

export default function InventarioPage() {
  return (
    <Box>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
            Inventario
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Gestiona tu inventario de productos
          </Typography>
        </Box>
        <Button variant="contained" color="primary" startIcon={<AddIcon />}>
          Nuevo Producto
        </Button>
      </Box>

      <Card>
        <CardHeader title="Listado de Inventario" />
        <CardContent>
          <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
            Módulo de inventario en desarrollo
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}
