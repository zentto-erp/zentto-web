'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Paper from '@mui/material/Paper';
import Chip from '@mui/material/Chip';
import Divider from '@mui/material/Divider';
import TextField from '@mui/material/TextField';
import Alert from '@mui/material/Alert';
import Skeleton from '@mui/material/Skeleton';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import SendIcon from '@mui/icons-material/Send';
import LockIcon from '@mui/icons-material/Lock';
import SmartToyIcon from '@mui/icons-material/SmartToy';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost, apiPatch } from '@zentto/shared-api';

const LABEL_COLORS: Record<string, 'error' | 'warning' | 'info' | 'success' | 'secondary'> = {
  bug: 'error',
  feature: 'info',
  question: 'secondary',
  urgent: 'error',
  'ai-fix': 'warning',
  'ai-pr': 'success',
};

interface TicketDetail {
  number: number;
  title: string;
  body: string;
  state: string;
  labels: string[];
  createdAt: string;
  updatedAt: string;
  closedAt: string | null;
}

interface Comment {
  author: string;
  body: string;
  createdAt: string;
}

export default function TicketDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const number = params.number as string;

  const [comment, setComment] = useState('');
  const [sending, setSending] = useState(false);
  const [closing, setClosing] = useState(false);
  const [error, setError] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['support-ticket', number],
    queryFn: () => apiGet(`/v1/support/tickets/${number}`),
  });

  const ticket: TicketDetail | undefined = data?.ticket;
  const comments: Comment[] = data?.comments || [];
  const isOpen = ticket?.state === 'open';
  const hasAiFix = ticket?.labels?.includes('ai-fix');
  const hasAiPr = ticket?.labels?.includes('ai-pr');

  const handleComment = async () => {
    if (!comment.trim()) return;
    setSending(true);
    setError('');
    try {
      const res = await apiPost(`/v1/support/tickets/${number}/comment`, { message: comment });
      if (res?.ok) {
        setComment('');
        queryClient.invalidateQueries({ queryKey: ['support-ticket', number] });
      } else {
        setError(res?.message || 'Error al enviar comentario');
      }
    } catch {
      setError('Error de conexión');
    } finally {
      setSending(false);
    }
  };

  const handleClose = async () => {
    setClosing(true);
    try {
      await apiPatch(`/v1/support/tickets/${number}/close`, {});
      queryClient.invalidateQueries({ queryKey: ['support-ticket', number] });
      queryClient.invalidateQueries({ queryKey: ['support-tickets'] });
    } catch {
      setError('Error al cerrar el ticket');
    } finally {
      setClosing(false);
    }
  };

  if (isLoading) {
    return (
      <Box sx={{ p: 3, maxWidth: 800, mx: 'auto' }}>
        <Skeleton variant="text" width={200} height={40} />
        <Skeleton variant="rounded" height={200} sx={{ mt: 2 }} />
        <Skeleton variant="rounded" height={100} sx={{ mt: 2 }} />
      </Box>
    );
  }

  if (!ticket) {
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Typography color="error">Ticket no encontrado</Typography>
        <Button onClick={() => router.push('/soporte')} sx={{ mt: 2 }}>Volver</Button>
      </Box>
    );
  }

  // Parse the body: extract description (after "## Descripción" header)
  const descMatch = ticket.body?.match(/## Descripción\s*\n\n([\s\S]*?)(\n\n---|$)/);
  const description = descMatch?.[1]?.trim() || ticket.body || '';

  return (
    <Box sx={{ p: 3, maxWidth: 800, mx: 'auto' }}>
      <Button startIcon={<ArrowBackIcon />} onClick={() => router.push('/soporte')} sx={{ mb: 2 }}>
        Volver a tickets
      </Button>

      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2, mb: 3 }}>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h5" fontWeight={700}>
            #{ticket.number} — {ticket.title}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Creado el {new Date(ticket.createdAt).toLocaleDateString('es', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
            {ticket.closedAt && ` · Cerrado el ${new Date(ticket.closedAt).toLocaleDateString('es', { day: 'numeric', month: 'long', year: 'numeric' })}`}
          </Typography>
        </Box>
        <Chip
          label={isOpen ? 'Abierto' : 'Cerrado'}
          color={isOpen ? 'success' : 'default'}
          variant="filled"
        />
      </Box>

      {/* Labels */}
      <Box sx={{ display: 'flex', gap: 0.5, mb: 2, flexWrap: 'wrap' }}>
        {ticket.labels.map((l) => (
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

      {/* AI Status Banner */}
      {hasAiPr && (
        <Alert severity="success" icon={<SmartToyIcon />} sx={{ mb: 2 }}>
          Nuestro agente de IA ha creado una propuesta de corrección. El equipo la está revisando.
        </Alert>
      )}
      {hasAiFix && !hasAiPr && (
        <Alert severity="info" icon={<SmartToyIcon />} sx={{ mb: 2 }}>
          Este ticket está siendo analizado por nuestro agente de IA.
        </Alert>
      )}

      {/* Description */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap' }}>
          {description}
        </Typography>
      </Paper>

      {/* Comments */}
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Comentarios ({comments.length})
      </Typography>

      {comments.map((c, i) => (
        <Paper key={i} sx={{ p: 2, mb: 1.5 }} variant="outlined">
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
            <Typography variant="subtitle2" fontWeight={600}>{c.author}</Typography>
            <Typography variant="caption" color="text.secondary">
              {new Date(c.createdAt).toLocaleDateString('es', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
            </Typography>
          </Box>
          <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>{c.body}</Typography>
        </Paper>
      ))}

      {comments.length === 0 && (
        <Typography color="text.secondary" sx={{ mb: 2 }}>Sin comentarios aún</Typography>
      )}

      <Divider sx={{ my: 3 }} />

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {/* Add Comment */}
      {isOpen && (
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'flex-start' }}>
          <TextField
            fullWidth
            multiline
            rows={2}
            placeholder="Escribe un comentario..."
            value={comment}
            onChange={(e) => setComment(e.target.value)}
          />
          <Button
            variant="contained"
            onClick={handleComment}
            disabled={sending || !comment.trim()}
            startIcon={<SendIcon />}
            sx={{ minWidth: 120 }}
          >
            {sending ? 'Enviando...' : 'Enviar'}
          </Button>
        </Box>
      )}

      {/* Close Ticket */}
      {isOpen && (
        <Box sx={{ mt: 3, textAlign: 'right' }}>
          <Button
            variant="outlined"
            color="error"
            startIcon={<LockIcon />}
            onClick={handleClose}
            disabled={closing}
          >
            {closing ? 'Cerrando...' : 'Cerrar Ticket'}
          </Button>
        </Box>
      )}
    </Box>
  );
}
