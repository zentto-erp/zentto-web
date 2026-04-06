'use client';

import React from 'react';
import {
  Box, Container, Typography, Paper, Button, List, ListItem, ListItemIcon, ListItemText,
} from '@mui/material';
import CelebrationIcon from '@mui/icons-material/Celebration';
import CheckIcon from '@mui/icons-material/Check';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  bg: '#f0f2f5',
  green: '#4caf50',
} as const;

const FEATURES = [
  'Facturacion electronica multi-pais',
  'Control de inventario en tiempo real',
  'Punto de venta integrado',
  'Reportes y analiticas avanzadas',
  'Multi-empresa y multi-sucursal',
];

export default function WelcomePage() {
  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <Box sx={{ bgcolor: COLORS.darkPrimary, py: 2, textAlign: 'center' }}>
        <Typography sx={{ color: COLORS.accent, fontWeight: 900, fontSize: 24, letterSpacing: 3 }}>
          ZENTTO
        </Typography>
      </Box>

      <Box sx={{ flex: 1, display: 'flex', alignItems: 'center', py: 4 }}>
        <Container maxWidth="sm">
          <Paper elevation={3} sx={{ p: { xs: 3, sm: 5 }, borderRadius: 3, textAlign: 'center' }}>
            <CelebrationIcon sx={{ fontSize: 64, color: COLORS.accent, mb: 2 }} />

            <Typography variant="h4" fontWeight={800} gutterBottom>
              Bienvenido a Zentto
            </Typography>

            <Typography color="text.secondary" sx={{ mb: 3 }}>
              Tu cuenta ha sido creada exitosamente. Ya puedes comenzar a configurar tu empresa.
            </Typography>

            <List sx={{ textAlign: 'left', mb: 3 }}>
              {FEATURES.map((feat) => (
                <ListItem key={feat} sx={{ py: 0.5 }}>
                  <ListItemIcon sx={{ minWidth: 36 }}>
                    <CheckIcon sx={{ color: COLORS.green }} />
                  </ListItemIcon>
                  <ListItemText primary={feat} />
                </ListItem>
              ))}
            </List>

            <Button
              variant="contained"
              size="large"
              href="https://zentto.net"
              endIcon={<ArrowForwardIcon />}
              sx={{
                bgcolor: COLORS.accent,
                color: COLORS.darkPrimary,
                fontWeight: 700,
                px: 4,
                py: 1.5,
                '&:hover': { bgcolor: '#e68a00' },
              }}
            >
              Comenzar ahora
            </Button>
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
