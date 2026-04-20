'use client';

import {
  Box,
  Container,
  Typography,
  Grid,
  Paper,
  Button,
  CircularProgress,
  Stack,
  Chip,
} from '@mui/material';
import NewspaperOutlined from '@mui/icons-material/NewspaperOutlined';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import CalendarTodayOutlined from '@mui/icons-material/CalendarTodayOutlined';
import Link from 'next/link';
import { usePressReleases } from '@zentto/module-ecommerce';

function formatDate(iso: string | null): string {
  if (!iso) return '';
  try {
    const d = new Date(iso);
    return d.toLocaleDateString('es', { day: '2-digit', month: 'short', year: 'numeric' });
  } catch {
    return '';
  }
}

export default function PrensaPage() {
  const { data, isLoading, error } = usePressReleases(1, 20);

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
            Comunicados oficiales, noticias y contacto para medios.
          </Typography>
        </Container>
      </Box>

      {/* Comunicados */}
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

        {isLoading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
            <CircularProgress />
          </Box>
        )}

        {error && (
          <Typography variant="body1" color="text.secondary" textAlign="center">
            No se pudieron cargar los comunicados.
          </Typography>
        )}

        {!isLoading && !error && (data?.items?.length ?? 0) === 0 && (
          <Typography variant="body1" color="text.secondary" textAlign="center">
            No hay comunicados publicados todavía.
          </Typography>
        )}

        <Grid container spacing={3}>
          {(data?.items ?? []).map((pr) => (
            <Grid item xs={12} md={4} key={pr.pressReleaseId}>
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
                    {formatDate(pr.publishedAt)}
                  </Typography>
                </Box>
                <Typography variant="h6" fontWeight={600} sx={{ color: '#131921', mb: 1.5 }}>
                  {pr.title}
                </Typography>
                {pr.excerpt && (
                  <Typography variant="body2" sx={{ color: '#555', lineHeight: 1.7, flex: 1 }}>
                    {pr.excerpt}
                  </Typography>
                )}
                {pr.tags && pr.tags.length > 0 && (
                  <Stack direction="row" spacing={1} sx={{ mt: 2, flexWrap: 'wrap', gap: 1 }}>
                    {pr.tags.slice(0, 3).map((t) => (
                      <Chip key={t} label={t} size="small" variant="outlined" />
                    ))}
                  </Stack>
                )}
                <Button
                  component={Link}
                  href={`/prensa/${pr.slug}`}
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
                  Leer más
                </Button>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>

      {/* Contacto de prensa */}
      <Box sx={{ py: { xs: 4, md: 8 } }}>
        <Container maxWidth="sm" sx={{ textAlign: 'center' }}>
          <Paper
            elevation={0}
            sx={{ p: 4, borderRadius: 3, bgcolor: '#232f3e', color: '#fff' }}
          >
            <EmailOutlined sx={{ fontSize: 48, color: '#ff9900', mb: 2 }} />
            <Typography variant="h5" fontWeight={600} gutterBottom>
              Contacto de prensa
            </Typography>
            <Typography variant="body1" sx={{ color: '#ccc', mb: 3 }}>
              Para consultas de medios, entrevistas o información adicional, contáctanos:
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
