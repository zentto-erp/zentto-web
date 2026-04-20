'use client';

import {
  Box, Container, Typography, Button, Card, CardContent, Grid, Stack,
} from '@mui/material';
import {
  StorefrontOutlined, InventoryOutlined, LocalShippingOutlined, PaymentsOutlined,
  VerifiedUserOutlined, SupportAgentOutlined,
} from '@mui/icons-material';
import { useRouter } from 'next/navigation';
import { useCartStore, useSellerDashboard } from '@zentto/module-ecommerce';

const steps = [
  {
    number: '1',
    title: 'Aplica como vendedor',
    description: 'Completa el formulario con tu razón social, tax ID y método de pago. Revisamos en 24-48h.',
    icon: <StorefrontOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '2',
    title: 'Publica tus productos',
    description: 'Envíalos a revisión. Nuestro equipo valida calidad y los publica en el catálogo de la tienda.',
    icon: <InventoryOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '3',
    title: 'Cobra tus ventas',
    description: 'Gestionamos el pago del cliente. Te transferimos el neto (85%) al final de cada periodo.',
    icon: <PaymentsOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
];

const requirements = [
  { icon: <VerifiedUserOutlined />, text: 'Ser persona natural o jurídica con Tax ID / RIF / CUIT' },
  { icon: <InventoryOutlined />,     text: 'Stock mínimo o capacidad de producción verificable' },
  { icon: <LocalShippingOutlined />, text: 'Disponibilidad para envíos en 24-72h' },
  { icon: <SupportAgentOutlined />,  text: 'Atención a consultas de clientes dentro de 24h' },
];

export default function VendePage() {
  const router = useRouter();
  const customerToken = useCartStore((s) => s.customerToken);
  const { data: seller } = useSellerDashboard();

  const handleCta = () => {
    if (!customerToken) {
      router.push('/login?next=/vender/aplicar');
      return;
    }
    if (seller?.sellerId) router.push('/vender/dashboard');
    else router.push('/vender/aplicar');
  };

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh' }}>
      {/* Hero */}
      <Box sx={{ bgcolor: '#131921', color: '#fff', py: { xs: 6, md: 10 }, textAlign: 'center' }}>
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
            sx={{ color: '#ccc', fontWeight: 400, mb: 3, fontSize: { xs: '1rem', md: '1.25rem' } }}
          >
            Llega a miles de clientes en toda Latinoamérica · Comisión 15% · Sin cuota mensual
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={handleCta}
            sx={{
              bgcolor: '#ff9900', color: '#131921', fontWeight: 700,
              px: 5, py: 1.5, fontSize: '1rem',
              '&:hover': { bgcolor: '#e68a00' },
            }}
          >
            {seller?.sellerId ? 'Ir a mi tienda' : 'Comenzar a vender'}
          </Button>
        </Container>
      </Box>

      {/* Cómo funciona */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography variant="h4" component="h2" sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}>
          ¿Cómo funciona?
        </Typography>
        <Grid container spacing={4}>
          {steps.map((step) => (
            <Grid item xs={12} md={4} key={step.number}>
              <Card sx={{ textAlign: 'center', height: '100%', borderRadius: 3, boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                <CardContent sx={{ p: 4 }}>
                  <Box
                    sx={{
                      width: 48, height: 48, borderRadius: '50%', bgcolor: '#ff9900', color: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      mx: 'auto', mb: 2, fontWeight: 700, fontSize: '1.25rem',
                    }}
                  >
                    {step.number}
                  </Box>
                  {step.icon}
                  <Typography variant="h6" sx={{ fontWeight: 600, mt: 2, mb: 1, color: '#131921' }}>
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

      {/* Comisión 15% banner */}
      <Box sx={{ bgcolor: '#ff9900', py: { xs: 4, md: 6 }, textAlign: 'center' }}>
        <Container maxWidth="md">
          <Typography variant="h4" sx={{ fontWeight: 700, color: '#131921' }}>
            Comisión 15% sobre cada venta
          </Typography>
          <Typography variant="body1" sx={{ color: '#131921', mt: 1 }}>
            Sin cuotas mensuales, sin costos ocultos. Solo pagas cuando vendes. Tú recibes el 85% neto.
          </Typography>
        </Container>
      </Box>

      {/* Requisitos */}
      <Container maxWidth="md" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography variant="h4" component="h2" sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}>
          Requisitos
        </Typography>
        <Stack spacing={2}>
          {requirements.map((r, i) => (
            <Card key={i} sx={{ borderRadius: 2 }}>
              <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2, py: 2 }}>
                <Box sx={{ color: '#ff9900' }}>{r.icon}</Box>
                <Typography variant="body1" sx={{ color: '#131921' }}>{r.text}</Typography>
              </CardContent>
            </Card>
          ))}
        </Stack>
      </Container>

      {/* CTA */}
      <Box sx={{ textAlign: 'center', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm">
          <Typography variant="h5" sx={{ fontWeight: 700, mb: 3, color: '#131921' }}>
            Empieza a vender hoy
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={handleCta}
            sx={{
              bgcolor: '#ff9900', color: '#131921', fontWeight: 700,
              px: 5, py: 1.5, fontSize: '1rem',
              '&:hover': { bgcolor: '#e68a00' },
            }}
          >
            {seller?.sellerId ? 'Ir a mi tienda' : customerToken ? 'Aplicar ahora' : 'Registrarme y aplicar'}
          </Button>
        </Container>
      </Box>
    </Box>
  );
}
