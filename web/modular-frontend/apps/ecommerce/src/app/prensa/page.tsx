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
  Pagination,
} from '@mui/material';
import { useState } from 'react';
import NewspaperOutlined from '@mui/icons-material/NewspaperOutlined';
import EmailOutlined from '@mui/icons-material/EmailOutlined';
import CalendarTodayOutlined from '@mui/icons-material/CalendarTodayOutlined';
import ArrowForwardOutlined from '@mui/icons-material/ArrowForwardOutlined';
import Link from 'next/link';
import { usePressReleases } from '@zentto/module-ecommerce';

const PAGE_SIZE = 12;

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
  const [page, setPage] = useState(1);
  const { data, isLoading, error } = usePressReleases(page, PAGE_SIZE);
  const items = data?.items ?? [];
  const totalCount = data?.totalCount ?? 0;
  const pageCount = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));
  // Post destacado en la primera página: el más reciente (primer item).
  const featured = page === 1 ? items[0] : undefined;
  const rest = page === 1 ? items.slice(1) : items;

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

        {!isLoading && !error && items.length === 0 && (
          <Typography variant="body1" color="text.secondary" textAlign="center">
            No hay comunicados publicados todavía.
          </Typography>
        )}

        {/* Post destacado (solo en página 1) */}
        {featured && (
          <Paper
            elevation={1}
            sx={{
              mb: 4,
              borderRadius: 3,
              overflow: 'hidden',
              display: 'grid',
              gridTemplateColumns: { xs: '1fr', md: '45% 55%' },
              transition: 'all 0.2s',
              '&:hover': { transform: 'translateY(-2px)', boxShadow: 6 },
            }}
          >
            <Box
              sx={{
                bgcolor: '#131921',
                minHeight: { xs: 220, md: 340 },
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundImage: featured.coverImageUrl ? `url(${featured.coverImageUrl})` : undefined,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
              }}
            >
              {!featured.coverImageUrl && (
                <NewspaperOutlined sx={{ fontSize: 80, color: '#ff9900' }} />
              )}
            </Box>
            <Box sx={{ p: { xs: 3, md: 5 }, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
              <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1.5 }}>
                <Chip label="Destacado" size="small" sx={{ bgcolor: '#ff9900', color: '#131921', fontWeight: 700 }} />
                <CalendarTodayOutlined sx={{ fontSize: 16, color: '#ff9900' }} />
                <Typography variant="caption" sx={{ color: '#888', fontWeight: 600 }}>
                  {formatDate(featured.publishedAt)}
                </Typography>
              </Stack>
              <Typography variant="h4" fontWeight={700} sx={{ color: '#131921', mb: 2, lineHeight: 1.2 }}>
                {featured.title}
              </Typography>
              {featured.excerpt && (
                <Typography variant="body1" sx={{ color: '#555', lineHeight: 1.7, mb: 3 }}>
                  {featured.excerpt}
                </Typography>
              )}
              <Button
                component={Link}
                href={`/prensa/${featured.slug}`}
                endIcon={<ArrowForwardOutlined />}
                variant="contained"
                sx={{
                  alignSelf: 'flex-start',
                  bgcolor: '#ff9900',
                  color: '#131921',
                  fontWeight: 700,
                  textTransform: 'none',
                  px: 3,
                  py: 1.25,
                  '&:hover': { bgcolor: '#e88a00' },
                }}
              >
                Leer nota completa
              </Button>
            </Box>
          </Paper>
        )}

        <Grid container spacing={3}>
          {rest.map((pr) => (
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
                <Typography
                  variant="h6"
                  fontWeight={600}
                  sx={{
                    color: '#131921',
                    mb: 1.5,
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    overflow: 'hidden',
                  }}
                >
                  {pr.title}
                </Typography>
                {pr.excerpt && (
                  <Typography
                    variant="body2"
                    sx={{
                      color: '#555',
                      lineHeight: 1.7,
                      flex: 1,
                      display: '-webkit-box',
                      WebkitLineClamp: 3,
                      WebkitBoxOrient: 'vertical',
                      overflow: 'hidden',
                    }}
                  >
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

        {pageCount > 1 && (
          <Stack direction="row" justifyContent="center" sx={{ mt: 5 }}>
            <Pagination
              count={pageCount}
              page={page}
              onChange={(_, v) => {
                setPage(v);
                if (typeof window !== 'undefined') window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              color="primary"
              shape="rounded"
            />
          </Stack>
        )}
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
