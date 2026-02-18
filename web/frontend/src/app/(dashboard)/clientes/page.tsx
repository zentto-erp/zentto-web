'use client';

import { Box, Typography, Card, CardContent, CardHeader, Button } from '@mui/material';
import dynamic from 'next/dynamic';

const AddIcon = dynamic(() => import('@mui/icons-material/Add'), { ssr: false });

export default function ClientesPage() {
  return (
    <Box>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
            Clientes
          </Typography>
          <Typography variant="body1" color="textSecondary">
            Gestiona tu base de datos de clientes
          </Typography>
        </Box>
        <Button variant="contained" color="primary" startIcon={<AddIcon />}>
          Nuevo Cliente
        </Button>
      </Box>

      <Card>
        <CardHeader title="Listado de Clientes" />
        <CardContent>
          <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
            Módulo de clientes en desarrollo
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}
