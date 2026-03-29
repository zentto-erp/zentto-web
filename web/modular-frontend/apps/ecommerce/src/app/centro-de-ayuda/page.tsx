'use client';

import { useState, useMemo } from 'react';
import {
  Box,
  Container,
  Typography,
  TextField,
  Card,
  CardContent,
  Grid,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  InputAdornment,
  Link,
} from '@mui/material';
import {
  SearchOutlined,
  PersonOutline,
  LocalShippingOutlined,
  PaymentOutlined,
  SecurityOutlined,
  HelpOutlineOutlined,
  ShoppingBagOutlined,
  ExpandMore as ExpandMoreIcon,
} from '@mui/icons-material';

const topics = [
  { title: 'Mi cuenta', icon: <PersonOutline sx={{ fontSize: 40 }} /> },
  { title: 'Pedidos', icon: <ShoppingBagOutlined sx={{ fontSize: 40 }} /> },
  { title: 'Pagos', icon: <PaymentOutlined sx={{ fontSize: 40 }} /> },
  { title: 'Envíos', icon: <LocalShippingOutlined sx={{ fontSize: 40 }} /> },
  { title: 'Devoluciones', icon: <HelpOutlineOutlined sx={{ fontSize: 40 }} /> },
  { title: 'Seguridad', icon: <SecurityOutlined sx={{ fontSize: 40 }} /> },
];

const faqGroups = [
  {
    group: 'Cuenta',
    questions: [
      {
        question: '¿Cómo creo una cuenta?',
        answer:
          'Para crear una cuenta, haz clic en "Registrarse" en la parte superior de la página. Completa el formulario con tu nombre, correo electrónico y una contraseña segura. Recibirás un correo de confirmación para activar tu cuenta.',
      },
      {
        question: '¿Cómo recupero mi contraseña?',
        answer:
          'Haz clic en "¿Olvidaste tu contraseña?" en la página de inicio de sesión. Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña. El enlace es válido por 24 horas.',
      },
    ],
  },
  {
    group: 'Pedidos',
    questions: [
      {
        question: '¿Cómo hago seguimiento a mi pedido?',
        answer:
          'Ingresa a "Mis pedidos" en tu cuenta. Allí verás el estado actualizado de cada pedido con su número de seguimiento. También recibirás notificaciones por correo electrónico con cada actualización.',
      },
      {
        question: '¿Puedo cancelar un pedido?',
        answer:
          'Sí, puedes cancelar un pedido siempre que no haya sido enviado. Ve a "Mis pedidos", selecciona el pedido y haz clic en "Cancelar". Si el pedido ya fue enviado, deberás solicitar una devolución.',
      },
    ],
  },
  {
    group: 'Pagos',
    questions: [
      {
        question: '¿Qué métodos de pago aceptan?',
        answer:
          'Aceptamos tarjetas de crédito y débito (Visa, Mastercard, American Express), transferencias bancarias, y pagos a través de plataformas digitales. Los métodos disponibles pueden variar según tu país.',
      },
      {
        question: '¿Es seguro pagar en Zentto Store?',
        answer:
          'Absolutamente. Utilizamos encriptación SSL de 256 bits y cumplimos con los estándares PCI DSS. Tus datos de pago nunca se almacenan en nuestros servidores y todas las transacciones son procesadas por pasarelas de pago certificadas.',
      },
    ],
  },
  {
    group: 'Envíos',
    questions: [
      {
        question: '¿Cuánto tarda el envío?',
        answer:
          'El tiempo de envío varía según tu ubicación. Envíos nacionales tardan entre 2 y 5 días hábiles. Para envíos internacionales, el plazo es de 7 a 15 días hábiles dependiendo del país de destino.',
      },
      {
        question: '¿Hacen envíos internacionales?',
        answer:
          'Sí, realizamos envíos a toda Latinoamérica. Los costos y tiempos de entrega varían según el país de destino. Puedes consultar el costo estimado antes de confirmar tu compra.',
      },
    ],
  },
];

export default function CentroDeAyudaPage() {
  const [search, setSearch] = useState('');

  const filteredGroups = useMemo(() => {
    if (!search.trim()) return faqGroups;
    const term = search.toLowerCase();
    return faqGroups
      .map((group) => ({
        ...group,
        questions: group.questions.filter(
          (q) =>
            q.question.toLowerCase().includes(term) ||
            q.answer.toLowerCase().includes(term)
        ),
      }))
      .filter((group) => group.questions.length > 0);
  }, [search]);

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
          <HelpOutlineOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography
            variant="h3"
            component="h1"
            sx={{ fontWeight: 700, mb: 3, fontSize: { xs: '1.8rem', md: '3rem' } }}
          >
            ¿En qué podemos ayudarte?
          </Typography>
          <TextField
            fullWidth
            placeholder="Busca tu pregunta..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchOutlined sx={{ color: '#999' }} />
                </InputAdornment>
              ),
            }}
            sx={{
              maxWidth: 500,
              mx: 'auto',
              bgcolor: '#fff',
              borderRadius: 2,
              '& .MuiOutlinedInput-root': {
                borderRadius: 2,
              },
            }}
          />
        </Container>
      </Box>

      {/* Temas populares */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          component="h2"
          sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}
        >
          Temas populares
        </Typography>
        <Grid container spacing={3}>
          {topics.map((topic) => (
            <Grid item xs={6} md={2} key={topic.title}>
              <Card
                sx={{
                  textAlign: 'center',
                  cursor: 'pointer',
                  borderRadius: 3,
                  transition: 'transform 0.2s, box-shadow 0.2s',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                  },
                }}
              >
                <CardContent sx={{ p: 3 }}>
                  <Box sx={{ color: '#ff9900', mb: 1 }}>{topic.icon}</Box>
                  <Typography
                    variant="body1"
                    sx={{ fontWeight: 600, color: '#131921' }}
                  >
                    {topic.title}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* FAQ */}
      <Box sx={{ bgcolor: '#fff', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="md">
          <Typography
            variant="h4"
            component="h2"
            sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#131921' }}
          >
            Preguntas frecuentes
          </Typography>
          {filteredGroups.map((group) => (
            <Box key={group.group} sx={{ mb: 4 }}>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 700,
                  mb: 2,
                  color: '#232f3e',
                  borderLeft: '4px solid #ff9900',
                  pl: 2,
                }}
              >
                {group.group}
              </Typography>
              {group.questions.map((faq) => (
                <Accordion
                  key={faq.question}
                  sx={{
                    mb: 1.5,
                    borderRadius: '8px !important',
                    '&:before': { display: 'none' },
                    boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
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
            </Box>
          ))}
          {filteredGroups.length === 0 && (
            <Typography
              variant="body1"
              sx={{ textAlign: 'center', color: '#777', py: 4 }}
            >
              No se encontraron resultados para &quot;{search}&quot;
            </Typography>
          )}
        </Container>
      </Box>

      {/* No encontraste */}
      <Box sx={{ textAlign: 'center', py: { xs: 4, md: 6 } }}>
        <Container maxWidth="sm">
          <Typography
            variant="h5"
            sx={{ fontWeight: 700, mb: 2, color: '#131921' }}
          >
            ¿No encontraste lo que buscas?
          </Typography>
          <Typography variant="body1" sx={{ color: '#555', mb: 2 }}>
            Nuestro equipo de soporte está listo para ayudarte.
          </Typography>
          <Link
            href="/contacto"
            sx={{
              color: '#ff9900',
              fontWeight: 600,
              fontSize: '1.1rem',
              textDecoration: 'none',
              '&:hover': { textDecoration: 'underline' },
            }}
          >
            Contáctanos
          </Link>
        </Container>
      </Box>
    </Box>
  );
}
