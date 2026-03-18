'use client';

import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
} from '@mui/material';
import {
  StorefrontOutlined,
  InventoryOutlined,
  LocalShippingOutlined,
  PaymentsOutlined,
} from '@mui/icons-material';

const steps = [
  {
    number: '1',
    title: 'Crea tu cuenta de vendedor',
    description:
      'Regístrate en minutos con tus datos básicos y la información de tu negocio.',
    icon: <StorefrontOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '2',
    title: 'Publica tus productos',
    description:
      'Sube fotos, descripciones y precios. Nuestro sistema optimiza tus listados automáticamente.',
    icon: <InventoryOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '3',
    title: 'Recibe pedidos y cobra',
    description:
      'Gestiona tus ventas desde el panel de vendedor y recibe tus pagos de forma segura.',
    icon: <PaymentsOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
];

const benefits = [
  {
    title: 'Sin cuota mensual',
    description:
      'No pagas nada por tener tu tienda activa. Solo comisiones por venta realizada.',
    icon: <PaymentsOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
  },
  {
    title: 'Panel de vendedor completo',
    description:
      'Estadísticas en tiempo real, gestión de inventario y herramientas de marketing incluidas.',
    icon: <StorefrontOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
  },
  {
    title: 'Logística integrada',
    description:
      'Conectamos con los principales operadores logísticos de Latinoamérica para que tus envíos sean sencillos.',
    icon: <LocalShippingOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
  },
  {
    title: 'Pagos seguros',
    description:
      'Procesamos los pagos de tus clientes y te transferimos tus ganancias de forma segura y puntual.',
    icon: <PaymentsOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
  },
];

export default function VendePage() {
  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh' }}>
      {/* Hero */}
      <Box
        sx={{
          bgcolor: '#131921',
          color: '#fff',
          py: { xs: 6, md: 10 },
          textAlign: 'center',
        }}
      >
        <Container maxWidth="md">
          <Typography
            variant="h3"
            component="h1"
            sx={{ fontWeight: 700, mb: 2, fontSize: { xs: '1.8rem', md: '3rem' } }}
          >
            Vende tus productos en Zentto Store
          </Typography>
          <Typography
            variant="h6"
            sx={{ color: '#ccc', fontWeight: 400, fontSize: { xs: '1rem', md: '1.25rem' } }}
          >
            Llega a miles de clientes en toda Latinoamérica
          </Typography>
        </Container>
      </Box>

      {/* Cómo funciona */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          component="h2"
          sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}
        >
          ¿Cómo funciona?
        </Typography>
        <Grid container spacing={4}>
          {steps.map((step) => (
            <Grid item xs={12} md={4} key={step.number}>
              <Card
                sx={{
                  textAlign: 'center',
                  height: '100%',
                  borderRadius: 3,
                  boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                }}
              >
                <CardContent sx={{ p: 4 }}>
                  <Box
                    sx={{
                      width: 48,
                      height: 48,
                      borderRadius: '50%',
                      bgcolor: '#ff9900',
                      color: '#fff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      mx: 'auto',
                      mb: 2,
                      fontWeight: 700,
                      fontSize: '1.25rem',
                    }}
                  >
                    {step.number}
                  </Box>
                  {step.icon}
                  <Typography
                    variant="h6"
                    sx={{ fontWeight: 600, mt: 2, mb: 1, color: '#131921' }}
                  >
                    {step.title}
                  </Typography>
                  <Typography variant="body2" sx={{ color: '#555' }}>
                    {step.description}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Beneficios */}
      <Box sx={{ bgcolor: '#232f3e', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="lg">
          <Typography
            variant="h4"
            component="h2"
            sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#fff' }}
          >
            Beneficios
          </Typography>
          <Grid container spacing={4}>
            {benefits.map((benefit) => (
              <Grid item xs={12} md={3} key={benefit.title}>
                <Card
                  sx={{
                    textAlign: 'center',
                    height: '100%',
                    borderRadius: 3,
                    bgcolor: '#131921',
                    color: '#fff',
                  }}
                >
                  <CardContent sx={{ p: 3 }}>
                    {benefit.icon}
                    <Typography
                      variant="h6"
                      sx={{ fontWeight: 600, mt: 2, mb: 1 }}
                    >
                      {benefit.title}
                    </Typography>
                    <Typography variant="body2" sx={{ color: '#ccc' }}>
                      {benefit.description}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* CTA */}
      <Box sx={{ textAlign: 'center', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm">
          <Typography
            variant="h5"
            sx={{ fontWeight: 700, mb: 3, color: '#131921' }}
          >
            Empieza a vender hoy
          </Typography>
          <Button
            variant="contained"
            size="large"
            disabled
            sx={{
              bgcolor: '#ff9900',
              color: '#131921',
              fontWeight: 700,
              px: 5,
              py: 1.5,
              fontSize: '1rem',
              '&.Mui-disabled': {
                bgcolor: '#ff990080',
                color: '#131921',
              },
            }}
          >
            Comenzar a vender
          </Button>
          <Typography variant="body2" sx={{ mt: 2, color: '#777' }}>
            Próximamente disponible
          </Typography>
        </Container>
      </Box>
    </Box>
  );
}
