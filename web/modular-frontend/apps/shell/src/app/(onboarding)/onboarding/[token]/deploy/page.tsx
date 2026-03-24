'use client';

import React, { useEffect, useRef, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  LinearProgress,
  Stack,
  Alert,
  CircularProgress,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { useRouter } from 'next/navigation';
import { useByocDeploy } from '@/hooks/useByocDeploy';

const ErrorOutlineIcon = dynamic(() => import('@mui/icons-material/ErrorOutline'), { ssr: false });
const RefreshIcon = dynamic(() => import('@mui/icons-material/Refresh'), { ssr: false });

// ─── Paso 5: Deploy en tiempo real ───────────────────────────────────────────

export default function DeployPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const router = useRouter();
  const { startDeploy, connectToStream, logs, status, progress, jobId } = useByocDeploy();

  const [token, setToken] = useState('');
  const [deployError, setDeployError] = useState('');
  const [started, setStarted] = useState(false);
  const terminalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    params.then(p => setToken(p.token));
  }, [params]);

  // Iniciar el deploy cuando el token este listo y no se haya iniciado
  useEffect(() => {
    if (!token || started) return;

    // Si ya hay un jobId guardado (refresh de pagina), conectar directamente al stream
    if (jobId) {
      setStarted(true);
      connectToStream(jobId, token, (tenantUrl) => {
        router.push(`/onboarding/${token}/complete?url=${encodeURIComponent(tenantUrl)}`);
      });
      return;
    }

    // Deploy nuevo
    setStarted(true);
    setDeployError('');

    startDeploy(token)
      .then(newJobId => {
        connectToStream(newJobId, token, (tenantUrl) => {
          router.push(`/onboarding/${token}/complete?url=${encodeURIComponent(tenantUrl)}`);
        });
      })
      .catch(err => {
        const msg = err instanceof Error ? err.message : 'Error al iniciar el deploy.';
        setDeployError(msg);
        setStarted(false);
      });
  }, [token, started, jobId, startDeploy, connectToStream, router]);

  // Auto-scroll del terminal al ultimo log
  useEffect(() => {
    if (terminalRef.current) {
      terminalRef.current.scrollTop = terminalRef.current.scrollHeight;
    }
  }, [logs]);

  const handleRetry = () => {
    setDeployError('');
    setStarted(false);
  };

  // ─── Status labels ────────────────────────────────────────────────────────

  const statusLabel: Record<string, string> = {
    PENDING: 'Iniciando deploy...',
    RUNNING: 'Instalando Zentto...',
    SUCCESS: 'Instalacion completada',
    FAILED: 'Error en la instalacion',
  };

  const progressColor = status === 'FAILED' ? 'error' : 'warning';

  return (
    <Box sx={{ flex: 1, py: 6, px: { xs: 2, sm: 4, md: 8 } }}>
      <Box sx={{ maxWidth: 720, mx: 'auto' }}>
        {/* Titulo */}
        <Box sx={{ mb: 4, textAlign: 'center' }}>
          <Typography variant="h5" fontWeight={800} sx={{ color: '#1a1a2e', mb: 1 }}>
            {status === 'FAILED' ? 'Error en la instalacion' : 'Instalando tu Zentto'}
          </Typography>
          <Typography color="text.secondary">
            {status === 'FAILED'
              ? 'Ocurrio un error durante el proceso. Puedes reintentar.'
              : 'Este proceso tarda entre 5 y 10 minutos. No cierres esta pagina.'}
          </Typography>
        </Box>

        {/* Error de inicio de deploy */}
        {deployError && (
          <Alert
            severity="error"
            sx={{ mb: 3 }}
            action={
              <Button
                color="error"
                size="small"
                startIcon={<RefreshIcon />}
                onClick={handleRetry}
                sx={{ textTransform: 'none' }}
              >
                Reintentar
              </Button>
            }
          >
            {deployError}
          </Alert>
        )}

        {/* Progress bar */}
        <Paper
          elevation={0}
          sx={{ p: 3, mb: 3, border: '1px solid #e0e0e0', borderRadius: 3 }}
        >
          <Stack direction="row" alignItems="center" spacing={2} sx={{ mb: 2 }}>
            {status === 'RUNNING' || (status === 'PENDING' && started && !deployError) ? (
              <CircularProgress size={20} sx={{ color: '#ff9900' }} />
            ) : null}
            <Typography variant="subtitle2" fontWeight={700} sx={{ color: '#1a1a2e' }}>
              {statusLabel[status] || 'Procesando...'}
            </Typography>
            <Typography
              variant="body2"
              sx={{ ml: 'auto !important', color: '#666', fontWeight: 600 }}
            >
              {progress}%
            </Typography>
          </Stack>

          <LinearProgress
            variant="determinate"
            value={progress}
            color={progressColor}
            sx={{
              height: 8,
              borderRadius: 4,
              bgcolor: '#e0e0e0',
              '& .MuiLinearProgress-bar': {
                borderRadius: 4,
                bgcolor: status === 'FAILED' ? '#f44336' : '#ff9900',
              },
            }}
          />
        </Paper>

        {/* Terminal de logs */}
        <Paper
          elevation={0}
          sx={{
            border: '1px solid #1a1a2e',
            borderRadius: 2,
            overflow: 'hidden',
          }}
        >
          {/* Barra de titulo del terminal */}
          <Box
            sx={{
              bgcolor: '#1a1a2e',
              px: 2,
              py: 1,
              display: 'flex',
              alignItems: 'center',
              gap: 1,
            }}
          >
            {/* Botones decorativos de terminal */}
            <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#f44336' }} />
            <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#ff9900' }} />
            <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: '#4caf50' }} />
            <Typography
              variant="caption"
              sx={{ color: 'rgba(255,255,255,0.5)', ml: 1, fontFamily: 'monospace' }}
            >
              zentto-deploy — log de instalacion
            </Typography>
          </Box>

          {/* Contenido del terminal */}
          <Box
            ref={terminalRef}
            sx={{
              bgcolor: '#0d1117',
              p: 2,
              minHeight: 320,
              maxHeight: 400,
              overflowY: 'auto',
              fontFamily: '"Courier New", Courier, monospace',
              fontSize: 13,
              lineHeight: 1.6,
              '&::-webkit-scrollbar': { width: 6 },
              '&::-webkit-scrollbar-track': { bgcolor: 'transparent' },
              '&::-webkit-scrollbar-thumb': { bgcolor: '#333', borderRadius: 3 },
            }}
          >
            {logs.length === 0 ? (
              <Typography
                sx={{
                  color: '#666',
                  fontFamily: 'monospace',
                  fontSize: 13,
                }}
              >
                {started ? 'Conectando con el servidor de deploy...' : 'Esperando inicio...'}
              </Typography>
            ) : (
              logs.map((line, i) => (
                <Box key={i} sx={{ mb: 0.25 }}>
                  <Typography
                    component="span"
                    sx={{
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: line.includes('ERROR') || line.includes('FALLO')
                        ? '#f44336'
                        : line.includes('EXITOSAMENTE') || line.includes('✅')
                        ? '#4caf50'
                        : line.includes('⏳') || line.includes('📦') || line.includes('🚀')
                        ? '#ff9900'
                        : '#e0e0e0',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-all',
                    }}
                  >
                    {line}
                  </Typography>
                </Box>
              ))
            )}

            {/* Cursor parpadeante cuando esta corriendo */}
            {(status === 'RUNNING' || (status === 'PENDING' && started)) && (
              <Box
                component="span"
                sx={{
                  display: 'inline-block',
                  width: 8,
                  height: 14,
                  bgcolor: '#ff9900',
                  ml: 0.5,
                  animation: 'blink 1s step-end infinite',
                  '@keyframes blink': {
                    '0%, 100%': { opacity: 1 },
                    '50%': { opacity: 0 },
                  },
                }}
              />
            )}
          </Box>
        </Paper>

        {/* Acciones en caso de fallo */}
        {status === 'FAILED' && (
          <Stack direction="row" spacing={2} justifyContent="center" sx={{ mt: 4 }}>
            <Button
              variant="outlined"
              startIcon={<RefreshIcon />}
              onClick={handleRetry}
              sx={{
                textTransform: 'none',
                borderColor: '#1a1a2e',
                color: '#1a1a2e',
              }}
            >
              Reintentar deploy
            </Button>
            <Button
              variant="text"
              href="mailto:soporte@zentto.net"
              sx={{ textTransform: 'none', color: '#666' }}
            >
              Contactar soporte
            </Button>
          </Stack>
        )}

        {/* Nota de no cerrar */}
        {(status === 'RUNNING' || status === 'PENDING') && !deployError && (
          <Alert severity="warning" sx={{ mt: 3, fontSize: 13 }}>
            <strong>No cierres esta pagina.</strong> El proceso de instalacion tomara entre
            5 y 10 minutos. Seras redirigido automaticamente cuando termine.
          </Alert>
        )}
      </Box>
    </Box>
  );
}
