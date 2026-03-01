'use client';

import React from 'react';
import {
  Box,
  Card,
  CardContent,
  CardHeader,
  Grid,
  Typography,
  Button,
  Stack,
  useTheme,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { useAuth } from '@/app/authentication/AuthContext';

const DashboardIcon = dynamic(() => import('@mui/icons-material/Dashboard'), { ssr: false });
const TrendingUpIcon = dynamic(() => import('@mui/icons-material/TrendingUp'), { ssr: false });
const ShoppingCartIcon = dynamic(() => import('@mui/icons-material/ShoppingCart'), { ssr: false });
const PeopleIcon = dynamic(() => import('@mui/icons-material/People'), { ssr: false });

interface StatCard {
  title: string;
  value: string;
  icon: React.ReactNode;
  color: string;
}

const StatCard: React.FC<StatCard> = ({ title, value, icon, color }) => {
  const theme = useTheme();
  return (
    <Card
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        background: `linear-gradient(135deg, ${color}15 0%, ${color}05 100%)`,
        border: `1px solid ${color}30`,
        borderRadius: 2,
      }}
    >
      <CardContent sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flex: 1 }}>
        <Box>
          <Typography color="textSecondary" variant="body2" sx={{ mb: 1 }}>
            {title}
          </Typography>
          <Typography variant="h5" sx={{ fontWeight: 600, color }}>
            {value}
          </Typography>
        </Box>
        <Box sx={{ fontSize: '2.5rem', color: color, opacity: 0.7 }}>
          {icon}
        </Box>
      </CardContent>
    </Card>
  );
};

export default function DashboardPage() {
  const theme = useTheme();
  const { userName, isAdmin } = useAuth();

  const stats: StatCard[] = [
    {
      title: 'Facturación Mensual',
      value: '$45,231',
      icon: <ShoppingCartIcon sx={{ fontSize: 'inherit' }} />,
      color: theme.palette.primary.main,
    },
    {
      title: 'Clientes Activos',
      value: '328',
      icon: <PeopleIcon sx={{ fontSize: 'inherit' }} />,
      color: '#3498db',
    },
    {
      title: 'Productos en Stock',
      value: '1,247',
      icon: <TrendingUpIcon sx={{ fontSize: 'inherit' }} />,
      color: '#27ae60',
    },
    {
      title: 'Órdenes Pendientes',
      value: '42',
      icon: <DashboardIcon sx={{ fontSize: 'inherit' }} />,
      color: '#e67e22',
    },
  ];

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Bienvenido, {userName || 'Usuario'}
        </Typography>
        <Typography variant="body1" color="textSecondary">
          Aquí puede ver un resumen de su actividad comercial
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={2} sx={{ mb: 4 }}>
        {stats.map((stat, index) => (
          <Grid item key={index} xs={12} sm={6} lg={3}>
            <StatCard {...stat} />
          </Grid>
        ))}
      </Grid>

      {/* Content Sections */}
      <Grid container spacing={2}>
        {/* Últimas Facturas */}
        <Grid item xs={12} lg={6}>
          <Card sx={{ height: '100%' }}>
            <CardHeader
              title="Últimas Facturas"
              subheader="Transacciones recientes"
              sx={{ borderBottom: '1px solid', borderColor: 'divider' }}
            />
            <CardContent>
              <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
                No hay facturas recientes aún
              </Typography>
              <Stack direction="row" justifyContent="center">
                <Button variant="contained" color="primary" size="small">
                  Ver todas las facturas
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        {/* Actividad Reciente */}
        <Grid item xs={12} lg={6}>
          <Card sx={{ height: '100%' }}>
            <CardHeader
              title="Actividad Reciente"
              subheader="Últimos cambios en el sistema"
              sx={{ borderBottom: '1px solid', borderColor: 'divider' }}
            />
            <CardContent>
              <Typography variant="body2" color="textSecondary" sx={{ py: 3, textAlign: 'center' }}>
                No hay actividad registrada aún
              </Typography>
              <Stack direction="row" justifyContent="center">
                <Button variant="contained" color="primary" size="small">
                  Ver más
                </Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Admin Section */}
      {isAdmin && (
        <Card sx={{ mt: 4, backgroundColor: '#f8f9fa', border: '1px solid #e0e0e0' }}>
          <CardHeader
            title="Sección de Administrador"
            subheader="Opciones de configuración avanzada"
            sx={{ borderBottom: '1px solid', borderColor: 'divider' }}
          />
          <CardContent>
            <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
              Tienes acceso a funciones administrativas del sistema
            </Typography>
            <Stack direction="row" gap={1}>
              <Button variant="outlined" color="primary" size="small">
                Configuración General
              </Button>
              <Button variant="outlined" color="primary" size="small">
                Usuarios del Sistema
              </Button>
              <Button variant="outlined" color="primary" size="small">
                Reportes Avanzados
              </Button>
            </Stack>
          </CardContent>
        </Card>
      )}
    </Box>
  );
}
