'use client';

import {
  Box,
  Container,
  Typography,
  Grid,
  Paper,
  Button,
} from '@mui/material';
import NewspaperOutlined from '@mui/icons-material/NewspaperOutlined';
import DownloadOutlined from '@mui/icons-material/DownloadOutlined';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import CalendarTodayOutlined from '@mui/icons-material/CalendarTodayOutlined';

const pressReleases = [
  {
    date: '15 Mar 2026',
    title: 'Zentto lanza su plataforma de comercio electronico integrada con ERP',
    excerpt:
      'La nueva solucion permite a las PYMEs latinoamericanas gestionar su tienda en linea, inventarios y contabilidad desde una unica plataforma, eliminando la necesidad de multiples herramientas desconectadas.',
  },
  {
    date: '28 Feb 2026',
    title: 'Zentto supera las 1,000 empresas activas en 14 paises',
    excerpt:
      'El ERP de origen latinoamericano alcanza un hito significativo con presencia en Venezuela, Colombia, Mexico, Espana, Chile, Peru, Argentina, Ecuador, Panama, Republica Dominicana, Costa Rica, Uruguay, Bolivia y Paraguay.',
  },
  {
    date: '10 Ene 2026',
    title: 'Zentto migra su infraestructura a PostgreSQL para mayor escalabilidad',
    excerpt:
      'La compania anuncia soporte dual de base de datos (SQL Server y PostgreSQL), ofreciendo a los clientes mayor flexibilidad y reduciendo costos de licenciamiento para pequenas empresas.',
  },
];

export default function PrensaPage() {
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
          <NewspaperOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography variant="h3" fontWeight={700} gutterBottom>
            Prensa
          </Typography>
          <Typography variant="h6" sx={{ color: '#ccc', maxWidth: 550, mx: 'auto' }}>
            Zentto en los medios
          </Typography>
        </Container>
      </Box>

      {/* Comunicados de prensa */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          fontWeight={700}
          textAlign="center"
          gutterBottom
          sx={{ color: '#131921', mb: 4 }}
        >
          Comunicados de prensa
        </Typography>
        <Grid container spacing={3}>
          {pressReleases.map((pr) => (
            <Grid item xs={12} md={4} key={pr.title}>
              <Paper
                elevation={1}
                sx={{
                  p: 3,
                  borderRadius: 3,
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.2s',
                  '&:hover': { transform: 'translateY(-4px)', boxShadow: 4 },
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                  <CalendarTodayOutlined sx={{ fontSize: 18, color: '#ff9900' }} />
                  <Typography variant="caption" sx={{ color: '#888', fontWeight: 600 }}>
                    {pr.date}
                  </Typography>
                </Box>
                <Typography variant="h6" fontWeight={600} sx={{ color: '#131921', mb: 1.5 }}>
                  {pr.title}
                </Typography>
                <Typography variant="body2" sx={{ color: '#555', lineHeight: 1.7, flex: 1 }}>
                  {pr.excerpt}
                </Typography>
                <Button
                  sx={{
                    mt: 2,
                    color: '#ff9900',
                    textTransform: 'none',
                    fontWeight: 600,
                    alignSelf: 'flex-start',
                    p: 0,
                    '&:hover': { bgcolor: 'transparent', textDecoration: 'underline' },
                  }}
                >
                  Leer mas
                </Button>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Kit de prensa */}
      <Box sx={{ bgcolor: '#fff', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <DownloadOutlined sx={{ fontSize: 56, color: '#ff9900', mb: 2 }} />
          <Typography variant="h4" fontWeight={700} gutterBottom sx={{ color: '#131921' }}>
            Kit de prensa
          </Typography>
          <Typography variant="body1" sx={{ color: '#555', mb: 3 }}>
            Descarga nuestro kit de prensa con logotipos, guia de marca, fotografias del equipo
            y datos clave de la empresa.
          </Typography>
          <Button
            variant="contained"
            disabled
            startIcon={<DownloadOutlined />}
            sx={{
              bgcolor: '#ff9900',
              color: '#131921',
              fontWeight: 700,
              textTransform: 'none',
              px: 4,
              py: 1.5,
              '&.Mui-disabled': {
                bgcolor: '#ccc',
                color: '#888',
              },
            }}
          >
            Descargar kit de prensa (proximamente)
          </Button>
        </Container>
      </Box>

      {/* Contacto de prensa */}
      <Box sx={{ py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Paper elevation={0} sx={{ p: 4, borderRadius: 3, bgcolor: '#232f3e', color: '#fff' }}>
            <EmailOutlined sx={{ fontSize: 48, color: '#ff9900', mb: 2 }} />
            <Typography variant="h5" fontWeight={600} gutterBottom>
              Contacto de prensa
            </Typography>
            <Typography variant="body1" sx={{ color: '#ccc', mb: 3 }}>
              Para consultas de medios, entrevistas o informacion adicional, contactanos en:
            </Typography>
            <Button
              variant="contained"
              href="mailto:prensa@zentto.net"
              sx={{
                bgcolor: '#ff9900',
                color: '#131921',
                fontWeight: 700,
                textTransform: 'none',
                px: 4,
                py: 1.5,
                '&:hover': { bgcolor: '#e88a00' },
              }}
            >
              prensa@zentto.net
            </Button>
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
