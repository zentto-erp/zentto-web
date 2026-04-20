'use client';

import { use } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  CircularProgress,
  Chip,
  Stack,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CalendarTodayOutlined from '@mui/icons-material/CalendarTodayOutlined';
import Link from 'next/link';
import { usePressRelease, renderMarkdown } from '@zentto/module-ecommerce';

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
          <Button
            component={Link}
            href="/prensa"
            startIcon={<ArrowBackIcon />}
            sx={{ color: '#ff9900', textTransform: 'none', mb: 2 }}
          >
            Volver a prensa
          </Button>
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
        </Container>
      </Box>
    </Box>
  );
}
