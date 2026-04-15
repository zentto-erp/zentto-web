'use client';

import * as React from 'react';
import {
  Box,
  CircularProgress,
  Fab,
  IconButton,
  Link,
  Paper,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import ChatOutlinedIcon from '@mui/icons-material/ChatOutlined';
import CloseIcon from '@mui/icons-material/Close';
import SendRoundedIcon from '@mui/icons-material/SendRounded';
import { usePathname } from 'next/navigation';

type ChatSource = {
  title: string;
  url: string;
  excerpt: string;
};

type ChatMessage = {
  id: string;
  role: 'assistant' | 'user';
  text: string;
  sources?: ChatSource[];
  meta?: string;
};

type SupportContext = {
  key: string;
  label: string;
  description: string;
};

const SUPPORT_API = process.env.NEXT_PUBLIC_NOTIFY_API_URL || 'https://notify.zentto.net';
const SESSION_STORAGE_PREFIX = 'zentto-support-chat-session';
const PUBLIC_HOSTS = new Set(['zentto.net', 'www.zentto.net', 'docs.zentto.net']);

const CONTEXTS: Record<string, SupportContext> = {
  inicio: {
    key: 'inicio',
    label: 'Inicio',
    description: 'navegación general, primeros pasos y flujo principal',
  },
  contabilidad: {
    key: 'contabilidad',
    label: 'Contabilidad',
    description: 'asientos, fiscal, cuentas y cierres',
  },
  bancos: {
    key: 'bancos',
    label: 'Bancos',
    description: 'conciliaciones, caja chica y movimientos bancarios',
  },
  inventario: {
    key: 'inventario',
    label: 'Inventario',
    description: 'artículos, almacenes, lotes y movimientos',
  },
  ventas: {
    key: 'ventas',
    label: 'Ventas',
    description: 'facturación, cotizaciones, pedidos y clientes',
  },
  compras: {
    key: 'compras',
    label: 'Compras',
    description: 'proveedores, órdenes de compra y cuentas por pagar',
  },
  nomina: {
    key: 'nomina',
    label: 'Nómina',
    description: 'empleados, vacaciones, liquidaciones y RRHH',
  },
  crm: {
    key: 'crm',
    label: 'CRM',
    description: 'leads, oportunidades y pipeline',
  },
  logistica: {
    key: 'logistica',
    label: 'Logística',
    description: 'recepciones, despachos y transportistas',
  },
  ecommerce: {
    key: 'ecommerce',
    label: 'Ecommerce',
    description: 'catálogo, tienda y pedidos web',
  },
  auditoria: {
    key: 'auditoria',
    label: 'Auditoría',
    description: 'bitácora, alertas y trazabilidad',
  },
  configuracion: {
    key: 'configuracion',
    label: 'Configuración',
    description: 'usuarios, roles, empresa y parámetros',
  },
  backoffice: {
    key: 'backoffice',
    label: 'Backoffice',
    description: 'planes, recursos, respaldos y administración interna',
  },
  reportes: {
    key: 'reportes',
    label: 'Reportes',
    description: 'reportes, diseñador y report studio',
  },
  notify: {
    key: 'notify',
    label: 'Notify',
    description: 'email, sms, push, otp y automatizaciones',
  },
  soporte: {
    key: 'soporte',
    label: 'Soporte',
    description: 'tickets y seguimiento de casos',
  },
};

function resolveContext(pathname: string): SupportContext {
  const matches: Array<[prefix: string, key: keyof typeof CONTEXTS]> = [
    ['/contabilidad', 'contabilidad'],
    ['/bancos', 'bancos'],
    ['/inventario', 'inventario'],
    ['/ventas', 'ventas'],
    ['/compras', 'compras'],
    ['/nomina', 'nomina'],
    ['/crm', 'crm'],
    ['/logistica', 'logistica'],
    ['/ecommerce', 'ecommerce'],
    ['/auditoria', 'auditoria'],
    ['/configuracion', 'configuracion'],
    ['/backoffice', 'backoffice'],
    ['/reportes', 'reportes'],
    ['/report-studio', 'reportes'],
    ['/studio-designer', 'reportes'],
    ['/notificaciones', 'notify'],
    ['/soporte', 'soporte'],
  ];

  for (const [prefix, key] of matches) {
    if (pathname === prefix || pathname.startsWith(`${prefix}/`)) {
      return CONTEXTS[key];
    }
  }

  return CONTEXTS.inicio;
}

function createAssistantMessage(text: string, sources?: ChatSource[], meta?: string): ChatMessage {
  return {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    role: 'assistant',
    text,
    sources,
    meta,
  };
}

function getInitialMessage(context: SupportContext): string {
  return `Hola. Soy el asistente de soporte de ${context.label}. Puedo ayudarte con documentación pública sobre ${context.description}.`;
}

function isEnabledHost(hostname: string): boolean {
  if (hostname === 'app.zentto.net' || hostname === 'appdev.zentto.net' || hostname === 'localhost') {
    return true;
  }

  if (PUBLIC_HOSTS.has(hostname)) return false;

  return hostname.endsWith('.zentto.net');
}

export function SupportChatWidget() {
  const pathname = usePathname() || '/';
  const context = React.useMemo(() => resolveContext(pathname), [pathname]);
  const sessionStorageKey = `${SESSION_STORAGE_PREFIX}:${context.key}`;

  const [enabled, setEnabled] = React.useState(false);
  const [open, setOpen] = React.useState(false);
  const [loading, setLoading] = React.useState(false);
  const [input, setInput] = React.useState('');
  const [sessionId, setSessionId] = React.useState('');
  const [messages, setMessages] = React.useState<ChatMessage[]>([
    createAssistantMessage(getInitialMessage(context)),
  ]);

  React.useEffect(() => {
    setMessages([createAssistantMessage(getInitialMessage(context))]);
  }, [context]);

  React.useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!isEnabledHost(window.location.hostname)) return;

    const existingSession = window.localStorage.getItem(sessionStorageKey);
    setSessionId(existingSession || '');
    setEnabled(true);
  }, [sessionStorageKey]);

  const handleSend = React.useCallback(async () => {
    const message = input.trim();
    if (!message || loading) return;

    const outgoing: ChatMessage = {
      id: `${Date.now()}-user`,
      role: 'user',
      text: message,
    };

    setMessages((current) => [...current, outgoing]);
    setInput('');
    setLoading(true);

    try {
      const response = await fetch(`${SUPPORT_API}/api/support/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sessionId,
          message,
          locale: 'es',
          pageUrl: typeof window !== 'undefined' ? window.location.href : undefined,
          visitorType: 'authenticated',
          appContext: context.key,
        }),
      });

      const payload = await response.json();
      if (!response.ok || !payload?.ok) {
        throw new Error(payload?.error || 'support_chat_failed');
      }

      if (payload.sessionId && typeof window !== 'undefined') {
        window.localStorage.setItem(sessionStorageKey, payload.sessionId);
        setSessionId(payload.sessionId);
      }

      const meta =
        payload.status === 'answered'
          ? `${payload.mode === 'fallback' ? 'Respuesta verificada con fallback' : 'Respuesta local'} · confianza ${Math.round((payload.confidence || 0) * 100)}%`
          : 'Escalado sugerido';

      setMessages((current) => [
        ...current,
        createAssistantMessage(payload.answer, payload.sources || [], meta),
      ]);
    } catch {
      setMessages((current) => [
        ...current,
        createAssistantMessage(
          `No pude responder sobre ${context.label} en este momento. Puedes revisar la documentación o escalar con soporte humano.`,
          [],
          'Escalado sugerido',
        ),
      ]);
    } finally {
      setLoading(false);
    }
  }, [context, input, loading, sessionId, sessionStorageKey]);

  if (!enabled) return null;

  return (
    <>
      {open && (
        <Paper
          elevation={10}
          sx={{
            position: 'fixed',
            right: 20,
            bottom: 92,
            width: { xs: 'calc(100vw - 24px)', sm: 380 },
            maxWidth: 'calc(100vw - 24px)',
            height: 540,
            borderRadius: 4,
            overflow: 'hidden',
            zIndex: 1400,
            display: 'flex',
            flexDirection: 'column',
            border: '1px solid rgba(15,23,42,0.08)',
          }}
        >
          <Box
            sx={{
              px: 2,
              py: 1.5,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              background: 'linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%)',
              color: '#fff',
            }}
          >
            <Box>
              <Typography variant="subtitle1" fontWeight={700}>
                Soporte {context.label}
              </Typography>
              <Typography variant="caption" sx={{ opacity: 0.84 }}>
                Documentación pública y orientación inicial
              </Typography>
            </Box>
            <IconButton size="small" onClick={() => setOpen(false)} sx={{ color: '#fff' }}>
              <CloseIcon fontSize="small" />
            </IconButton>
          </Box>

          <Stack spacing={1.25} sx={{ flex: 1, px: 2, py: 2, overflowY: 'auto', bgcolor: '#f8fafc' }}>
            {messages.map((message) => (
              <Box
                key={message.id}
                sx={{
                  alignSelf: message.role === 'user' ? 'flex-end' : 'flex-start',
                  maxWidth: '88%',
                }}
              >
                <Paper
                  elevation={0}
                  sx={{
                    px: 1.5,
                    py: 1.25,
                    borderRadius: 3,
                    bgcolor: message.role === 'user' ? '#1d4ed8' : '#ffffff',
                    color: message.role === 'user' ? '#fff' : '#0f172a',
                    border: message.role === 'user' ? 'none' : '1px solid rgba(15,23,42,0.08)',
                  }}
                >
                  <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
                    {message.text}
                  </Typography>
                  {message.meta && (
                    <Typography variant="caption" sx={{ mt: 0.75, display: 'block', opacity: 0.78 }}>
                      {message.meta}
                    </Typography>
                  )}
                  {message.sources && message.sources.length > 0 && (
                    <Stack spacing={0.5} sx={{ mt: 1 }}>
                      {message.sources.map((source) => (
                        <Link
                          key={`${message.id}-${source.url}`}
                          href={source.url}
                          target="_blank"
                          rel="noreferrer"
                          underline="hover"
                          color={message.role === 'user' ? '#dbeafe' : '#1d4ed8'}
                          sx={{ fontSize: 12 }}
                        >
                          {source.title}
                        </Link>
                      ))}
                    </Stack>
                  )}
                </Paper>
              </Box>
            ))}

            {loading && (
              <Box sx={{ alignSelf: 'flex-start', display: 'flex', alignItems: 'center', gap: 1, color: '#334155' }}>
                <CircularProgress size={18} />
                <Typography variant="body2">Buscando en la documentación de {context.label.toLowerCase()}…</Typography>
              </Box>
            )}
          </Stack>

          <Box sx={{ p: 1.5, borderTop: '1px solid rgba(15,23,42,0.08)', bgcolor: '#fff' }}>
            <Stack direction="row" spacing={1} alignItems="flex-end">
              <TextField
                size="small"
                fullWidth
                multiline
                maxRows={4}
                placeholder={`Pregunta sobre ${context.description}`}
                value={input}
                onChange={(event) => setInput(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault();
                    void handleSend();
                  }
                }}
              />
              <IconButton
                color="primary"
                onClick={() => void handleSend()}
                disabled={!input.trim() || loading}
                sx={{
                  bgcolor: '#1d4ed8',
                  color: '#fff',
                  '&:hover': { bgcolor: '#1e40af' },
                  '&.Mui-disabled': { bgcolor: '#cbd5e1', color: '#fff' },
                }}
              >
                <SendRoundedIcon fontSize="small" />
              </IconButton>
            </Stack>
          </Box>
        </Paper>
      )}

      <Fab
        color="primary"
        onClick={() => setOpen((current) => !current)}
        sx={{
          position: 'fixed',
          right: 20,
          bottom: 20,
          zIndex: 1400,
          background: 'linear-gradient(135deg, #1d4ed8 0%, #0f172a 100%)',
        }}
      >
        <ChatOutlinedIcon />
      </Fab>
    </>
  );
}

export default SupportChatWidget;
