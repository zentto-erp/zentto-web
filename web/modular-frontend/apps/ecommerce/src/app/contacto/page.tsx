'use client';

import { useState, type FormEvent } from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Paper,
  TextField,
  Button,
  MenuItem,
  Alert,
} from '@mui/material';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import AccessTimeOutlined from '@mui/icons-material/AccessTimeOutlined';
import LocationOnOutlined from '@mui/icons-material/LocationOnOutlined';
import SendOutlined from '@mui/icons-material/SendOutlined';
import ChatOutlined from '@mui/icons-material/ChatOutlined';

const subjects = [
  'Soporte tecnico',
  'Facturacion',
  'Alianzas comerciales',
  'Otro',
];

const contactInfo = [
  {
    icon: <EmailOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Email',
    detail: 'soporte@zentto.net',
  },
  {
    icon: <AccessTimeOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Horario',
    detail: 'Lun - Vie, 8:00 AM - 6:00 PM',
  },
  {
    icon: <LocationOnOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Ubicacion',
    detail: '100% remoto, Latinoamerica',
  },
];

export default function ContactoPage() {
  const [submitted, setSubmitted] = useState(false);
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [asunto, setAsunto] = useState('');
  const [mensaje, setMensaje] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    setNombre('');
    setEmail('');
    setAsunto('');
    setMensaje('');
  };

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh' }}>
      {/* Hero */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #131921 0%, #232f3e 100%)',
          color: '#fff',
          py: { xs: 6, md: 10 },
          textAlign: 'center',
        }}
      >
        <Container maxWidth="md">
          <ChatOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography variant="h3" fontWeight={700} gutterBottom>
            Contacto
          </Typography>
          <Typography variant="h6" sx={{ color: '#ccc', maxWidth: 500, mx: 'auto' }}>
            ¿Como podemos ayudarte?
          </Typography>
        </Container>
      </Box>

      {/* Formulario + Info */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Grid container spacing={4}>
          {/* Formulario */}
          <Grid item xs={12} md={7}>
            <Paper elevation={1} sx={{ p: { xs: 3, md: 4 }, borderRadius: 3 }}>
              <Typography variant="h5" fontWeight={700} gutterBottom sx={{ color: '#131921' }}>
                Enviaanos un mensaje
              </Typography>

              {submitted && (
                <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSubmitted(false)}>
                  ¡Mensaje enviado con exito! Nos pondremos en contacto contigo pronto.
                </Alert>
              )}

              <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
                <TextField
                  label="Nombre"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  required
                  fullWidth
                  variant="outlined"
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      '&.Mui-focused fieldset': { borderColor: '#ff9900' },
                    },
                    '& .MuiInputLabel-root.Mui-focused': { color: '#ff9900' },
                  }}
                />
                <TextField
                  label="Email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  fullWidth
                  variant="outlined"
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      '&.Mui-focused fieldset': { borderColor: '#ff9900' },
                    },
                    '& .MuiInputLabel-root.Mui-focused': { color: '#ff9900' },
                  }}
                />
                <TextField
                  label="Asunto"
                  select
                  value={asunto}
                  onChange={(e) => setAsunto(e.target.value)}
                  required
                  fullWidth
                  variant="outlined"
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      '&.Mui-focused fieldset': { borderColor: '#ff9900' },
                    },
                    '& .MuiInputLabel-root.Mui-focused': { color: '#ff9900' },
                  }}
                >
                  {subjects.map((s) => (
                    <MenuItem key={s} value={s}>
                      {s}
                    </MenuItem>
                  ))}
                </TextField>
                <TextField
                  label="Mensaje"
                  value={mensaje}
                  onChange={(e) => setMensaje(e.target.value)}
                  required
                  fullWidth
                  multiline
                  rows={5}
                  variant="outlined"
                  sx={{
                    '& .MuiOutlinedInput-root': {
                      '&.Mui-focused fieldset': { borderColor: '#ff9900' },
                    },
                    '& .MuiInputLabel-root.Mui-focused': { color: '#ff9900' },
                  }}
                />
                <Button
                  type="submit"
                  variant="contained"
                  endIcon={<SendOutlined />}
                  sx={{
                    bgcolor: '#ff9900',
                    color: '#131921',
                    fontWeight: 700,
                    textTransform: 'none',
                    py: 1.5,
                    alignSelf: { xs: 'stretch', md: 'flex-start' },
                    px: 5,
                    '&:hover': { bgcolor: '#e88a00' },
                  }}
                >
                  Enviar mensaje
                </Button>
              </Box>
            </Paper>
          </Grid>

          {/* Info de contacto */}
          <Grid item xs={12} md={5}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              {contactInfo.map((info) => (
                <Paper
                  key={info.title}
                  elevation={1}
                  sx={{
                    p: 3,
                    borderRadius: 3,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 2,
                    transition: 'transform 0.2s',
                    '&:hover': { transform: 'translateX(4px)', boxShadow: 4 },
                  }}
                >
                  {info.icon}
                  <Box>
                    <Typography variant="subtitle1" fontWeight={600} sx={{ color: '#131921' }}>
                      {info.title}
                    </Typography>
                    <Typography variant="body2" sx={{ color: '#555' }}>
                      {info.detail}
                    </Typography>
                  </Box>
                </Paper>
              ))}

              {/* Mapa placeholder */}
              <Paper
                elevation={0}
                sx={{
                  p: 4,
                  borderRadius: 3,
                  bgcolor: '#232f3e',
                  color: '#fff',
                  textAlign: 'center',
                }}
              >
                <LocationOnOutlined sx={{ fontSize: 48, color: '#ff9900', mb: 1 }} />
                <Typography variant="h6" fontWeight={600}>
                  Equipo 100% remoto
                </Typography>
                <Typography variant="body2" sx={{ color: '#ccc', mt: 1 }}>
                  Nuestro equipo trabaja desde distintos paises de Latinoamerica y Espana.
                  No tenemos oficina fisica — nuestra oficina es el mundo.
                </Typography>
              </Paper>
            </Box>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}
