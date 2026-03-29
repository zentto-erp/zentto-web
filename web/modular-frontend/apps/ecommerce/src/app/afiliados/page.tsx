'use client';

import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from '@mui/material';
import {
  MonetizationOnOutlined,
  LinkOutlined,
  TrendingUpOutlined,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';

const steps = [
  {
    number: '1',
    title: 'Regístrate como afiliado',
    description:
      'Crea tu cuenta de afiliado de forma gratuita en menos de 2 minutos.',
    icon: <MonetizationOnOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '2',
    title: 'Comparte tu enlace personalizado',
    description:
      'Obtén tu enlace único y compártelo en redes sociales, blogs o tu sitio web.',
    icon: <LinkOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
  {
    number: '3',
    title: 'Gana comisión por cada venta',
    description:
      'Cada vez que alguien compre a través de tu enlace, recibirás una comisión.',
    icon: <TrendingUpOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
  },
];

const commissions = [
  { category: 'Electrónica', rate: '3%' },
  { category: 'Ropa', rate: '5%' },
  { category: 'Hogar', rate: '7%' },
  { category: 'Software', rate: '10%' },
];

const faqs = [
  {
    question: '¿Cuándo recibo mis comisiones?',
    answer:
      'Las comisiones se liquidan de forma mensual. El pago se realiza los primeros 5 días hábiles del mes siguiente, siempre que hayas alcanzado el mínimo de pago.',
  },
  {
    question: '¿Necesito ser empresa?',
    answer:
      'No. Cualquier persona mayor de 18 años puede registrarse como afiliado. Aceptamos tanto personas naturales como jurídicas.',
  },
  {
    question: '¿Hay mínimo de pago?',
    answer:
      'Sí, el mínimo de pago es de $10 USD. Si tu saldo acumulado no alcanza este monto, se acumula para el siguiente período.',
  },
];

export default function AfiliadosPage() {
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
          <MonetizationOnOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography
            variant="h3"
            component="h1"
            sx={{ fontWeight: 700, mb: 2, fontSize: { xs: '1.8rem', md: '3rem' } }}
          >
            Gana dinero recomendando Zentto
          </Typography>
          <Typography
            variant="h6"
            sx={{ color: '#ccc', fontWeight: 400, fontSize: { xs: '1rem', md: '1.25rem' } }}
          >
            Únete a nuestro programa de afiliados y genera ingresos pasivos
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

      {/* Comisiones */}
      <Box sx={{ bgcolor: '#232f3e', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm">
          <Typography
            variant="h4"
            component="h2"
            sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#fff' }}
          >
            Comisiones
          </Typography>
          <TableContainer
            component={Paper}
            sx={{ borderRadius: 3, overflow: 'hidden' }}
          >
            <Table>
              <TableHead>
                <TableRow sx={{ bgcolor: '#131921' }}>
                  <TableCell sx={{ color: '#fff', fontWeight: 700, fontSize: '1rem' }}>
                    Categoría
                  </TableCell>
                  <TableCell
                    align="center"
                    sx={{ color: '#ff9900', fontWeight: 700, fontSize: '1rem' }}
                  >
                    Comisión
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {commissions.map((row) => (
                  <TableRow key={row.category}>
                    <TableCell sx={{ fontWeight: 500 }}>{row.category}</TableCell>
                    <TableCell
                      align="center"
                      sx={{ fontWeight: 700, color: '#ff9900', fontSize: '1.1rem' }}
                    >
                      {row.rate}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Container>
      </Box>

      {/* FAQ */}
      <Container maxWidth="md" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          component="h2"
          sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}
        >
          Preguntas frecuentes
        </Typography>
        {faqs.map((faq) => (
          <Accordion
            key={faq.question}
            sx={{
              mb: 2,
              borderRadius: '8px !important',
              '&:before': { display: 'none' },
              boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
            }}
          >
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
              <Typography sx={{ fontWeight: 600, color: '#131921' }}>
                {faq.question}
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Typography variant="body2" sx={{ color: '#555' }}>
                {faq.answer}
              </Typography>
            </AccordionDetails>
          </Accordion>
        ))}
      </Container>

      {/* CTA */}
      <Box sx={{ textAlign: 'center', py: { xs: 4, md: 8 }, bgcolor: '#eaeded' }}>
        <Container maxWidth="sm">
          <Typography
            variant="h5"
            sx={{ fontWeight: 700, mb: 3, color: '#131921' }}
          >
            Comienza a ganar hoy
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
            Únete al programa
          </Button>
          <Typography variant="body2" sx={{ mt: 2, color: '#777' }}>
            Próximamente disponible
          </Typography>
        </Container>
      </Box>
    </Box>
  );
}
