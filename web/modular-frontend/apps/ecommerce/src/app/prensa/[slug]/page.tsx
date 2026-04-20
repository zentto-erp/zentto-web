'use client';

import { use, useState } from 'react';
import {
  Box,
  Breadcrumbs,
  Container,
  Typography,
  Button,
  CircularProgress,
  Chip,
  Grid,
  IconButton,
  Paper,
  Stack,
  Tooltip,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CalendarTodayOutlined from '@mui/icons-material/CalendarTodayOutlined';
import NavigateNextOutlined from '@mui/icons-material/NavigateNextOutlined';
import LinkedInIcon from '@mui/icons-material/LinkedIn';
import XIcon from '@mui/icons-material/X';
import WhatsAppIcon from '@mui/icons-material/WhatsApp';
import ContentCopyOutlined from '@mui/icons-material/ContentCopyOutlined';
import CheckOutlined from '@mui/icons-material/CheckOutlined';
import Link from 'next/link';
import { usePressRelease, usePressReleases, renderMarkdown } from '@zentto/module-ecommerce';

function formatDate(iso: string | null): string {
  if (!iso) return '';
  try {
    const d = new Date(iso);
    return d.toLocaleDateString('es', { day: '2-digit', month: 'long', year: 'numeric' });
  } catch {
    return '';
  }
}

export default function PressReleaseDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = use(params);
  const { data, isLoading, error } = usePressRelease(slug);
  // Relacionados: primeros 3 de la primera página, excluyendo el actual.
  const { data: listData } = usePressReleases(1, 4);
  const related = (listData?.items ?? []).filter((p) => p.slug !== slug).slice(0, 3);

  const [copied, setCopied] = useState(false);
  const shareUrl =
    typeof window !== 'undefined' ? window.location.href : `https://zentto.net/prensa/${slug}`;
  const shareTitle = data?.item?.title || 'Press release Zentto';
  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* noop */
    }
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !data?.item) {
    return (
      <Container maxWidth="md" sx={{ py: 8, textAlign: 'center' }}>
        <Typography variant="h5" gutterBottom>
          Comunicado no encontrado
        </Typography>
        <Button component={Link} href="/prensa" startIcon={<ArrowBackIcon />} sx={{ mt: 2 }}>
          Volver a prensa
        </Button>
      </Container>
    );
  }

  const pr = data.item;

  return (
    <Box sx={{ bgcolor: '#eaeded', minHeight: '100vh' }}>
      {/* Header */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #131921 0%, #232f3e 100%)',
          color: '#fff',
          py: { xs: 5, md: 8 },
        }}
      >
        <Container maxWidth="md">
          {/* Breadcrumb */}
          <Breadcrumbs
            separator={<NavigateNextOutlined sx={{ color: '#888', fontSize: 18 }} />}
            aria-label="breadcrumb"
            sx={{ mb: 2, '& .MuiBreadcrumbs-ol': { color: '#ccc' } }}
          >
            <Link href="/" style={{ color: '#ccc', textDecoration: 'none' }}>
              Inicio
            </Link>
            <Link href="/prensa" style={{ color: '#ff9900', textDecoration: 'none' }}>
              Prensa
            </Link>
            <Typography variant="body2" sx={{ color: '#fff', fontWeight: 600 }}>
              {pr.title.length > 60 ? `${pr.title.slice(0, 57)}…` : pr.title}
            </Typography>
          </Breadcrumbs>
          <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2, color: '#ccc' }}>
            <CalendarTodayOutlined sx={{ fontSize: 18 }} />
            <Typography variant="body2">{formatDate(pr.publishedAt)}</Typography>
          </Stack>
          <Typography variant="h3" fontWeight={700} gutterBottom>
            {pr.title}
          </Typography>
          {pr.excerpt && (
            <Typography variant="h6" sx={{ color: '#ccc', lineHeight: 1.6 }}>
              {pr.excerpt}
            </Typography>
          )}
          {pr.tags && pr.tags.length > 0 && (
            <Stack direction="row" spacing={1} sx={{ mt: 2, flexWrap: 'wrap', gap: 1 }}>
              {pr.tags.map((t) => (
                <Chip
                  key={t}
                  label={t}
                  size="small"
                  sx={{ bgcolor: '#37475a', color: '#ff9900' }}
                />
              ))}
            </Stack>
          )}
        </Container>
      </Box>

      {/* Body */}
      <Box sx={{ bgcolor: '#fff', py: { xs: 4, md: 6 } }}>
        <Container maxWidth="md">
          {pr.body ? (
            renderMarkdown(pr.body)
          ) : (
            <Typography variant="body1" color="text.secondary">
              (Sin contenido)
            </Typography>
          )}

          {/* Share buttons */}
          <Box sx={{ mt: 5, pt: 3, borderTop: '1px solid #e0e0e0' }}>
            <Typography variant="subtitle2" fontWeight={700} sx={{ color: '#131921', mb: 1.5 }}>
              Compartir
            </Typography>
            <Stack direction="row" spacing={1}>
              <Tooltip title="Compartir en LinkedIn">
                <IconButton
                  component="a"
                  href={`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(shareUrl)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  sx={{ bgcolor: '#0A66C2', color: '#fff', '&:hover': { bgcolor: '#084f99' } }}
                >
                  <LinkedInIcon />
                </IconButton>
              </Tooltip>
              <Tooltip title="Compartir en X">
                <IconButton
                  component="a"
                  href={`https://twitter.com/intent/tweet?url=${encodeURIComponent(shareUrl)}&text=${encodeURIComponent(shareTitle)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  sx={{ bgcolor: '#000', color: '#fff', '&:hover': { bgcolor: '#222' } }}
                >
                  <XIcon />
                </IconButton>
              </Tooltip>
              <Tooltip title="Compartir por WhatsApp">
                <IconButton
                  component="a"
                  href={`https://api.whatsapp.com/send?text=${encodeURIComponent(`${shareTitle} ${shareUrl}`)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  sx={{ bgcolor: '#25D366', color: '#fff', '&:hover': { bgcolor: '#1dab52' } }}
                >
                  <WhatsAppIcon />
                </IconButton>
              </Tooltip>
              <Tooltip title={copied ? 'Link copiado' : 'Copiar link'}>
                <IconButton onClick={copyLink} sx={{ bgcolor: '#eaeded', '&:hover': { bgcolor: '#d0d4d4' } }}>
                  {copied ? <CheckOutlined sx={{ color: '#4caf50' }} /> : <ContentCopyOutlined />}
                </IconButton>
              </Tooltip>
            </Stack>
          </Box>

          <Box sx={{ mt: 4 }}>
            <Button
              component={Link}
              href="/prensa"
              startIcon={<ArrowBackIcon />}
              sx={{ color: '#ff9900', textTransform: 'none', fontWeight: 600 }}
            >
              Volver a prensa
            </Button>
          </Box>
        </Container>
      </Box>

      {/* Relacionados */}
      {related.length > 0 && (
        <Box sx={{ bgcolor: '#eaeded', py: { xs: 4, md: 6 } }}>
          <Container maxWidth="md">
            <Typography variant="h5" fontWeight={700} sx={{ color: '#131921', mb: 3 }}>
              Más noticias
            </Typography>
            <Grid container spacing={2}>
              {related.map((r) => (
                <Grid item xs={12} sm={6} md={4} key={r.pressReleaseId}>
                  <Paper
                    component={Link}
                    href={`/prensa/${r.slug}`}
                    elevation={0}
                    sx={{
                      display: 'block',
                      p: 2.5,
                      borderRadius: 2,
                      height: '100%',
                      textDecoration: 'none',
                      border: '1px solid #e0e0e0',
                      transition: 'all 150ms',
                      '&:hover': { borderColor: '#ff9900', transform: 'translateY(-2px)' },
                    }}
                  >
                    <Typography
                      variant="caption"
                      sx={{ color: '#ff9900', fontWeight: 700, display: 'block', mb: 1 }}
                    >
                      {formatDate(r.publishedAt)}
                    </Typography>
                    <Typography
                      variant="subtitle1"
                      fontWeight={700}
                      sx={{
                        color: '#131921',
                        display: '-webkit-box',
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                      }}
                    >
                      {r.title}
                    </Typography>
                  </Paper>
                </Grid>
              ))}
            </Grid>
          </Container>
        </Box>
      )}
    </Box>
  );
}
