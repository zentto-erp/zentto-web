'use client';

import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Grid,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Link,
} from '@mui/material';
import {
  AssignmentReturnOutlined,
  CheckCircleOutline,
  CancelOutlined,
  InventoryOutlined,
  LooksOneOutlined,
  LooksTwoOutlined,
  Looks3Outlined,
  Looks4Outlined,
} from '@mui/icons-material';

const timelineSteps = [
  {
    number: <LooksOneOutlined sx={{ fontSize: 32, color: '#ff9900' }} />,
    title: 'Solicita la devolución desde "Mis pedidos"',
    description:
      'Ingresa a tu cuenta, selecciona el pedido y haz clic en "Solicitar devolución". Indica el motivo y los productos que deseas devolver.',
  },
  {
    number: <LooksTwoOutlined sx={{ fontSize: 32, color: '#ff9900' }} />,
    title: 'Empaca el producto en su empaque original',
    description:
      'Asegúrate de que el producto esté en las mismas condiciones en que lo recibiste, con todos sus accesorios y empaque original.',
  },
  {
    number: <Looks3Outlined sx={{ fontSize: 32, color: '#ff9900' }} />,
    title: 'Envíalo usando la etiqueta prepagada',
    description:
      'Te enviaremos una etiqueta de envío prepagada a tu correo. Imprímela, pégala en el paquete y llévalo al punto de envío más cercano.',
  },
  {
    number: <Looks4Outlined sx={{ fontSize: 32, color: '#ff9900' }} />,
    title: 'Recibe tu reembolso en 5-7 días hábiles',
    description:
      'Una vez que recibamos y verifiquemos el producto, procesaremos tu reembolso al método de pago original en un plazo de 5 a 7 días hábiles.',
  },
];

const conditions = [
  'El producto debe estar sin uso y en su estado original',
  'Debe incluir el empaque original sin daños',
  'La solicitud debe realizarse dentro de los 30 días posteriores a la entrega',
  'Debe presentarse la factura o comprobante de compra',
];

const exceptions = [
  'Productos perecederos o con fecha de vencimiento',
  'Software que haya sido activado o cuyo sello esté roto',
  'Productos personalizados o hechos a medida',
];

export default function DevolucionesPage() {
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
          <AssignmentReturnOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography
            variant="h3"
            component="h1"
            sx={{ fontWeight: 700, mb: 2, fontSize: { xs: '1.8rem', md: '3rem' } }}
          >
            Política de devoluciones
          </Typography>
          <Typography
            variant="h6"
            sx={{ color: '#ccc', fontWeight: 400, fontSize: { xs: '1rem', md: '1.25rem' } }}
          >
            Tu satisfacción es nuestra prioridad
          </Typography>
        </Container>
      </Box>

      {/* Nuestra garantía */}
      <Container maxWidth="md" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          component="h2"
          sx={{ fontWeight: 700, textAlign: 'center', mb: 3, color: '#131921' }}
        >
          Nuestra garantía
        </Typography>
        <Card sx={{ borderRadius: 3, boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
          <CardContent sx={{ p: { xs: 3, md: 4 } }}>
            <Typography variant="body1" sx={{ color: '#333', lineHeight: 1.8 }}>
              En Zentto Store queremos que estés completamente satisfecho con tu compra.
              Si por cualquier motivo no estás conforme con un producto, puedes devolverlo
              dentro de los <strong>30 días posteriores a la fecha de entrega</strong> y
              recibirás un reembolso completo. Nuestro proceso de devolución es sencillo,
              rápido y sin complicaciones. Nos encargamos del envío de retorno para que no
              tengas que preocuparte por nada.
            </Typography>
          </CardContent>
        </Card>
      </Container>

      {/* Proceso de devolución */}
      <Box sx={{ bgcolor: '#232f3e', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="md">
          <Typography
            variant="h4"
            component="h2"
            sx={{ fontWeight: 700, textAlign: 'center', mb: 5, color: '#fff' }}
          >
            Proceso de devolución
          </Typography>
          {timelineSteps.map((step, index) => (
            <Box
              key={index}
              sx={{
                display: 'flex',
                mb: 3,
                position: 'relative',
                '&:not(:last-child)::after': {
                  content: '""',
                  position: 'absolute',
                  left: 20,
                  top: 64,
                  bottom: -12,
                  width: 2,
                  bgcolor: '#ff990050',
                },
              }}
            >
              <Box
                sx={{
                  flexShrink: 0,
                  width: 44,
                  display: 'flex',
                  justifyContent: 'center',
                  pt: 1,
                }}
              >
                {step.number}
              </Box>
              <Card
                sx={{
                  ml: 2,
                  flex: 1,
                  borderRadius: 2,
                  bgcolor: '#131921',
                  color: '#fff',
                }}
              >
                <CardContent sx={{ p: 3 }}>
                  <Typography variant="h6" sx={{ fontWeight: 600, mb: 1 }}>
                    {step.title}
                  </Typography>
                  <Typography variant="body2" sx={{ color: '#ccc' }}>
                    {step.description}
                  </Typography>
                </CardContent>
              </Card>
            </Box>
          ))}
        </Container>
      </Box>

      {/* Condiciones y Excepciones */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Grid container spacing={4}>
          {/* Condiciones */}
          <Grid item xs={12} md={6}>
            <Card
              sx={{
                height: '100%',
                borderRadius: 3,
                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              }}
            >
              <CardContent sx={{ p: { xs: 3, md: 4 } }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                  <InventoryOutlined sx={{ fontSize: 32, color: '#ff9900', mr: 1.5 }} />
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 700, color: '#131921' }}
                  >
                    Condiciones
                  </Typography>
                </Box>
                <List disablePadding>
                  {conditions.map((condition) => (
                    <ListItem key={condition} sx={{ px: 0 }}>
                      <ListItemIcon sx={{ minWidth: 36 }}>
                        <CheckCircleOutline sx={{ color: '#4caf50' }} />
                      </ListItemIcon>
                      <ListItemText
                        primary={condition}
                        primaryTypographyProps={{
                          variant: 'body2',
                          color: '#333',
                        }}
                      />
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>

          {/* Excepciones */}
          <Grid item xs={12} md={6}>
            <Card
              sx={{
                height: '100%',
                borderRadius: 3,
                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              }}
            >
              <CardContent sx={{ p: { xs: 3, md: 4 } }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                  <CancelOutlined sx={{ fontSize: 32, color: '#f44336', mr: 1.5 }} />
                  <Typography
                    variant="h5"
                    sx={{ fontWeight: 700, color: '#131921' }}
                  >
                    Excepciones
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ color: '#555', mb: 2 }}>
                  Los siguientes productos no son elegibles para devolución:
                </Typography>
                <List disablePadding>
                  {exceptions.map((exception) => (
                    <ListItem key={exception} sx={{ px: 0 }}>
                      <ListItemIcon sx={{ minWidth: 36 }}>
                        <CancelOutlined sx={{ color: '#f44336', fontSize: 20 }} />
                      </ListItemIcon>
                      <ListItemText
                        primary={exception}
                        primaryTypographyProps={{
                          variant: 'body2',
                          color: '#333',
                        }}
                      />
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>

      {/* ¿Necesitas ayuda? */}
      <Box
        sx={{
          textAlign: 'center',
          py: { xs: 4, md: 6 },
          bgcolor: '#131921',
          color: '#fff',
        }}
      >
        <Container maxWidth="sm">
          <Typography variant="h5" sx={{ fontWeight: 700, mb: 2 }}>
            ¿Necesitas ayuda?
          </Typography>
          <Typography variant="body1" sx={{ color: '#ccc', mb: 2 }}>
            Si tienes dudas sobre tu devolución o necesitas asistencia, estamos aquí para ayudarte.
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
