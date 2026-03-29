'use client';

import {
  Box,
  Container,
  Typography,
  Grid,
  Paper,
  Button,
  Chip,
} from '@mui/material';
import WorkOutlineOutlined from '@mui/icons-material/WorkOutlineOutlined';
import HomeOutlined from '@mui/icons-material/HomeOutlined';
import AccessTimeOutlined from '@mui/icons-material/AccessTimeOutlined';
import TrendingUpOutlined from '@mui/icons-material/TrendingUpOutlined';
import CodeOutlined from '@mui/icons-material/CodeOutlined';
import GroupsOutlined from '@mui/icons-material/GroupsOutlined';
import FavoriteOutlined from '@mui/icons-material/FavoriteOutlined';
import BrushOutlined from '@mui/icons-material/BrushOutlined';
import SupportAgentOutlined from '@mui/icons-material/SupportAgentOutlined';
import StorageOutlined from '@mui/icons-material/StorageOutlined';
import BarChartOutlined from '@mui/icons-material/BarChartOutlined';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import ArrowForwardOutlined from '@mui/icons-material/ArrowForwardOutlined';

const benefits = [
  {
    icon: <HomeOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Trabajo remoto',
    description: 'Trabaja desde donde quieras. Somos un equipo 100% distribuido en Latinoamerica.',
  },
  {
    icon: <AccessTimeOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Horario flexible',
    description: 'Organizate como mejor te funcione. Nos enfocamos en resultados, no en horarios.',
  },
  {
    icon: <TrendingUpOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Crecimiento profesional',
    description: 'Presupuesto para cursos, conferencias y certificaciones. Tu crecimiento es nuestra inversion.',
  },
  {
    icon: <CodeOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Tecnologia de punta',
    description: 'Trabajamos con React, Next.js, Node.js, TypeScript, PostgreSQL y mas.',
  },
  {
    icon: <GroupsOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Equipo multicultural',
    description: 'Colabora con profesionales de Venezuela, Colombia, Mexico, Espana y mas.',
  },
  {
    icon: <FavoriteOutlined sx={{ fontSize: 40, color: '#ff9900' }} />,
    title: 'Impacto real',
    description: 'Tu trabajo ayuda directamente a miles de PYMEs en Latinoamerica a crecer.',
  },
];

const positions = [
  {
    title: 'Desarrollador Full Stack',
    icon: <CodeOutlined />,
    area: 'Ingenieria',
    location: 'Remoto',
    type: 'Tiempo completo',
    tech: ['Node.js', 'React', 'TypeScript', 'PostgreSQL'],
  },
  {
    title: 'Disenador UX/UI',
    icon: <BrushOutlined />,
    area: 'Diseno',
    location: 'Remoto',
    type: 'Tiempo completo',
    tech: ['Figma', 'MUI', 'Design Systems'],
  },
  {
    title: 'Customer Success Manager',
    icon: <SupportAgentOutlined />,
    area: 'Soporte',
    location: 'Remoto',
    type: 'Tiempo completo',
    tech: ['CRM', 'Onboarding', 'Espanol'],
  },
  {
    title: 'DevOps Engineer',
    icon: <StorageOutlined />,
    area: 'Infraestructura',
    location: 'Remoto',
    type: 'Tiempo completo',
    tech: ['Docker', 'GitHub Actions', 'Linux', 'Nginx'],
  },
  {
    title: 'Data Analyst',
    icon: <BarChartOutlined />,
    area: 'Datos',
    location: 'Remoto',
    type: 'Tiempo completo',
    tech: ['SQL', 'Python', 'Metabase', 'ETL'],
  },
];

export default function TrabajaConNosotrosPage() {
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
          <WorkOutlineOutlined sx={{ fontSize: 64, color: '#ff9900', mb: 2 }} />
          <Typography variant="h3" fontWeight={700} gutterBottom>
            Trabaja con nosotros
          </Typography>
          <Typography variant="h6" sx={{ color: '#ccc', maxWidth: 650, mx: 'auto' }}>
            Unete al equipo que esta transformando los negocios en Latinoamerica
          </Typography>
        </Container>
      </Box>

      {/* Por que Zentto */}
      <Container maxWidth="lg" sx={{ py: { xs: 4, md: 8 } }}>
        <Typography
          variant="h4"
          fontWeight={700}
          textAlign="center"
          gutterBottom
          sx={{ color: '#131921', mb: 4 }}
        >
          ¿Por que Zentto?
        </Typography>
        <Grid container spacing={3}>
          {benefits.map((b) => (
            <Grid item xs={12} sm={6} md={4} key={b.title}>
              <Paper
                elevation={1}
                sx={{
                  p: 3,
                  borderRadius: 3,
                  height: '100%',
                  transition: 'transform 0.2s',
                  '&:hover': { transform: 'translateY(-4px)', boxShadow: 4 },
                }}
              >
                {b.icon}
                <Typography variant="h6" fontWeight={600} sx={{ mt: 2, color: '#131921' }}>
                  {b.title}
                </Typography>
                <Typography variant="body2" sx={{ mt: 1, color: '#555' }}>
                  {b.description}
                </Typography>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Posiciones abiertas */}
      <Box sx={{ bgcolor: '#fff', py: { xs: 4, md: 8 } }}>
        <Container maxWidth="lg">
          <Typography
            variant="h4"
            fontWeight={700}
            textAlign="center"
            gutterBottom
            sx={{ color: '#131921', mb: 4 }}
          >
            Posiciones abiertas
          </Typography>
          <Grid container spacing={3}>
            {positions.map((p) => (
              <Grid item xs={12} md={6} key={p.title}>
                <Paper
                  elevation={1}
                  sx={{
                    p: 3,
                    borderRadius: 3,
                    height: '100%',
                    border: '1px solid #e0e0e0',
                    transition: 'border-color 0.2s',
                    '&:hover': { borderColor: '#ff9900' },
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <Box sx={{ color: '#ff9900' }}>{p.icon}</Box>
                    <Typography variant="h6" fontWeight={600} sx={{ color: '#131921' }}>
                      {p.title}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
                    <Chip label={p.area} size="small" sx={{ bgcolor: '#eaeded' }} />
                    <Chip label={p.location} size="small" sx={{ bgcolor: '#eaeded' }} />
                    <Chip label={p.type} size="small" sx={{ bgcolor: '#eaeded' }} />
                  </Box>
                  <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                    {p.tech.map((t) => (
                      <Chip
                        key={t}
                        label={t}
                        size="small"
                        variant="outlined"
                        sx={{ fontSize: '0.75rem', borderColor: '#ff9900', color: '#232f3e' }}
                      />
                    ))}
                  </Box>
                  <Button
                    endIcon={<ArrowForwardOutlined />}
                    sx={{
                      mt: 2,
                      color: '#ff9900',
                      textTransform: 'none',
                      fontWeight: 600,
                      '&:hover': { bgcolor: 'rgba(255,153,0,0.08)' },
                    }}
                  >
                    Ver detalles
                  </Button>
                </Paper>
              </Grid>
            ))}
          </Grid>
        </Container>
      </Box>

      {/* No ves tu posicion */}
      <Box sx={{ py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Paper elevation={0} sx={{ p: 4, borderRadius: 3, bgcolor: '#232f3e', color: '#fff' }}>
            <EmailOutlined sx={{ fontSize: 48, color: '#ff9900', mb: 2 }} />
            <Typography variant="h5" fontWeight={600} gutterBottom>
              ¿No ves tu posicion?
            </Typography>
            <Typography variant="body1" sx={{ color: '#ccc', mb: 3 }}>
              Siempre estamos buscando talento excepcional. Enviaanos tu CV y cuentanos que te
              apasiona.
            </Typography>
            <Button
              variant="contained"
              href="mailto:careers@zentto.net"
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
              careers@zentto.net
            </Button>
          </Paper>
        </Container>
      </Box>
    </Box>
  );
}
