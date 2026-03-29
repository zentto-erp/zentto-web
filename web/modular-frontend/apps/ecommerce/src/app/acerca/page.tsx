'use client';

import {
  Box,
  Container,
  Typography,
  Grid,
  Paper,
} from '@mui/material';
import RocketLaunchOutlined from '@mui/icons-material/RocketLaunchOutlined';
import GroupsOutlined from '@mui/icons-material/GroupsOutlined';
import SecurityOutlined from '@mui/icons-material/SecurityOutlined';
import SpeedOutlined from '@mui/icons-material/SpeedOutlined';
import LightbulbOutlined from '@mui/icons-material/LightbulbOutlined';
import AccessibilityNewOutlined from '@mui/icons-material/AccessibilityNewOutlined';
import VerifiedOutlined from '@mui/icons-material/VerifiedOutlined';
import TuneOutlined from '@mui/icons-material/TuneOutlined';
import BusinessOutlined from '@mui/icons-material/BusinessOutlined';
import PublicOutlined from '@mui/icons-material/PublicOutlined';
import ScheduleOutlined from '@mui/icons-material/ScheduleOutlined';
import SupportAgentOutlined from '@mui/icons-material/SupportAgentOutlined';

const valores = [
  {
    icon: <LightbulbOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
    title: 'Innovacion',
    description:
      'Buscamos constantemente nuevas formas de resolver problemas empresariales con tecnologia de vanguardia.',
  },
  {
    icon: <AccessibilityNewOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
    title: 'Accesibilidad',
    description:
      'Creemos que las herramientas empresariales de calidad deben estar al alcance de todos, sin importar el tamano del negocio.',
  },
  {
    icon: <VerifiedOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
    title: 'Confianza',
    description:
      'Construimos relaciones duraderas basadas en la transparencia, la seguridad y el cumplimiento de nuestras promesas.',
  },
  {
    icon: <TuneOutlined sx={{ fontSize: 48, color: '#ff9900' }} />,
    title: 'Simplicidad',
    description:
      'Simplificamos lo complejo. Nuestras soluciones son potentes por dentro y sencillas por fuera.',
  },
];

const stats = [
  {
    icon: <BusinessOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    value: '1,000+',
    label: 'Empresas confian en Zentto',
  },
  {
    icon: <PublicOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    value: '14',
    label: 'Paises en Latinoamerica',
  },
  {
    icon: <ScheduleOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    value: '99.9%',
    label: 'Uptime garantizado',
  },
  {
    icon: <SupportAgentOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    value: '24/7',
    label: 'Soporte disponible',
  },
];

export default function AcercaPage() {
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
          <RocketLaunchOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography variant="h3" fontWeight={700} gutterBottom>
            Acerca de Zentto
          </Typography>
          <Typography variant="h6" sx={{ color: '#ccc', maxWidth: 600, mx: 'auto' }}>
            Transformar la gestion empresarial con tecnologia accesible
          </Typography>
        </Container>
      </Box>

      {/* Nuestra Historia */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Grid container spacing={4} alignItems="center">
          <Grid item xs={12} md={6}>
            <Typography variant="h4" fontWeight={700} gutterBottom sx={{ color: '#131921' }}>
              Nuestra Historia
            </Typography>
            <Typography variant="body1" sx={{ color: '#555', lineHeight: 1.8 }}>
              Zentto nacio con una vision clara: ayudar a las empresas latinoamericanas a
              digitalizarse sin fricciones. Desde nuestros inicios, entendimos que la region
              necesitaba herramientas empresariales adaptadas a su realidad — no traducciones
              de software pensado para otros mercados.
            </Typography>
            <Typography variant="body1" sx={{ color: '#555', lineHeight: 1.8, mt: 2 }}>
              Combinamos un ERP robusto con una plataforma de comercio electronico integrada
              (Zentto Store), permitiendo a los negocios gestionar inventarios, ventas,
              contabilidad y su tienda en linea desde un solo lugar.
            </Typography>
          </Grid>
          <Grid item xs={12} md={6}>
            <Paper
              elevation={0}
              sx={{
                bgcolor: '#232f3e',
                color: '#fff',
                p: 4,
                borderRadius: 3,
                textAlign: 'center',
              }}
            >
              <GroupsOutlined sx={{ fontSize: 80, color: '#ff9900', mb: 2 }} />
              <Typography variant="h5" fontWeight={600}>
                Hecho en Latinoamerica, para Latinoamerica
              </Typography>
              <Typography variant="body2" sx={{ color: '#ccc', mt: 1 }}>
                Entendemos los desafios unicos de hacer negocios en la region
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>

      {/* Nuestra Mision */}
      <Box sx={{ bgcolor: '#fff', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="md" sx={{ textAlign: 'center' }}>
          <Typography variant="h4" fontWeight={700} gutterBottom sx={{ color: '#131921' }}>
            Nuestra Mision
          </Typography>
          <Typography variant="h6" sx={{ color: '#555', lineHeight: 1.8 }}>
            Hacer que la gestion empresarial de clase mundial sea accesible para pequenas y
            medianas empresas. Creemos que cada negocio, sin importar su tamano, merece
            herramientas que le permitan crecer, competir y prosperar en la economia digital.
          </Typography>
        </Container>
      </Box>

      {/* Nuestros Valores */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          fontWeight={700}
          textAlign="center"
          gutterBottom
          sx={{ color: '#131921', mb: 4 }}
        >
          Nuestros Valores
        </Typography>
        <Grid container spacing={3}>
          {valores.map((v) => (
            <Grid item xs={12} sm={6} md={3} key={v.title}>
              <Paper
                elevation={1}
                sx={{
                  p: 3,
                  textAlign: 'center',
                  borderRadius: 3,
                  height: '100%',
                  transition: 'transform 0.2s',
                  '&:hover': { transform: 'translateY(-4px)', boxShadow: 4 },
                }}
              >
                {v.icon}
                <Typography variant="h6" fontWeight={600} sx={{ mt: 2, color: '#131921' }}>
                  {v.title}
                </Typography>
                <Typography variant="body2" sx={{ mt: 1, color: '#555' }}>
                  {v.description}
                </Typography>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Zentto en Numeros */}
      <Box sx={{ bgcolor: '#232f3e', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="lg">
          <Typography
            variant="h4"
            fontWeight={700}
            textAlign="center"
            gutterBottom
            sx={{ color: '#fff', mb: 4 }}
          >
            Zentto en Numeros
          </Typography>
          <Grid container spacing={3}>
            {stats.map((s) => (
              <Grid item xs={6} md={3} key={s.label}>
                <Paper
                  elevation={0}
                  sx={{
                    p: 3,
                    textAlign: 'center',
                    borderRadius: 3,
                    bgcolor: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                  }}
                >
                  {s.icon}
                  <Typography variant="h3" fontWeight={700} sx={{ color: '#ff9900', mt: 1 }}>
                    {s.value}
                  </Typography>
                  <Typography variant="body2" sx={{ color: '#ccc', mt: 1 }}>
                    {s.label}
                  </Typography>
                </Paper>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>
    </Box>
  );
}
