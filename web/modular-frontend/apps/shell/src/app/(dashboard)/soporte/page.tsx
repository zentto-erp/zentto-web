'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardActionArea from '@mui/material/CardActionArea';
import Chip from '@mui/material/Chip';
import Skeleton from '@mui/material/Skeleton';
import AddIcon from '@mui/icons-material/Add';
import BugReportIcon from '@mui/icons-material/BugReport';
import LightbulbIcon from '@mui/icons-material/Lightbulb';
import HelpIcon from '@mui/icons-material/Help';
import SmartToyIcon from '@mui/icons-material/SmartToy';
import { useQuery } from '@tanstack/react-query';
import { apiGet } from '@zentto/shared-api';

interface Ticket {
  number: number;
  title: string;
  state: string;
  labels: string[];
  createdAt: string;
  updatedAt: string;
  comments: number;
}

const LABEL_COLORS: Record<string, 'error' | 'warning' | 'info' | 'success' | 'secondary' | 'primary'> = {
  bug: 'error',
  feature: 'info',
  question: 'secondary',
  urgent: 'error',
  'ai-fix': 'warning',
  'ai-pr': 'success',
};

function typeIcon(labels: string[]) {
  if (labels.includes('bug')) return <BugReportIcon fontSize="small" />;
  if (labels.includes('feature')) return <LightbulbIcon fontSize="small" />;
  return <HelpIcon fontSize="small" />;
}

export default function SoportePage() {
  const router = useRouter();
  const [tab, setTab] = useState(0);
  const state = tab === 0 ? 'open' : 'closed';

  const { data, isLoading } = useQuery({
    queryKey: ['support-tickets', state],
    queryFn: () => apiGet(`/v1/support/tickets?state=${state}`),
  });

  const tickets: Ticket[] = data?.tickets || [];

  return (
    <Box sx={{ p: 3, maxWidth: 900, mx: 'auto' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>Soporte Técnico</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push('/soporte/nuevo')}
        >
          Nuevo Ticket
        </Button>
      </Box>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
        <Tab label="Abiertos" />
        <Tab label="Cerrados" />
      </Tabs>

      {isLoading && Array.from({ length: 3 }).map((_, i) => (
        <Skeleton key={i} variant="rounded" height={90} sx={{ mb: 1.5 }} />
      ))}

      {!isLoading && tickets.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 6, color: 'text.secondary' }}>
          <Typography>No hay tickets {state === 'open' ? 'abiertos' : 'cerrados'}</Typography>
        </Box>
      )}

      {tickets.map((t) => (
        <Card key={t.number} sx={{ mb: 1.5 }}>
          <CardActionArea onClick={() => router.push(`/soporte/${t.number}`)}>
            <CardContent sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              {typeIcon(t.labels)}
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography fontWeight={600} noWrap>
                  #{t.number} — {t.title}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {new Date(t.createdAt).toLocaleDateString('es')} · {t.comments} comentario{t.comments !== 1 ? 's' : ''}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                {t.labels.map((l) => (
                  <Chip
                    key={l}
                    label={l}
                    size="small"
                    color={LABEL_COLORS[l] || 'default'}
                    icon={l === 'ai-fix' || l === 'ai-pr' ? <SmartToyIcon /> : undefined}
                    variant={l.startsWith('modulo:') ? 'outlined' : 'filled'}
                  />
                ))}
              </Box>
            </CardContent>
          </CardActionArea>
        </Card>
      ))}
    </Box>
  );
}
