'use client';

import React, { useEffect, useState, useCallback } from 'react';
import {
  Box, Container, Typography, Paper, CircularProgress, Chip,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ErrorIcon from '@mui/icons-material/Error';
import WarningIcon from '@mui/icons-material/Warning';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api.zentto.net';

const COLORS = {
  darkPrimary: '#131921',
  accent: '#ff9900',
  bg: '#f0f2f5',
  green: '#4caf50',
  yellow: '#ff9800',
  red: '#f44336',
} as const;

interface ServiceStatus {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  latencyMs?: number;
  detail?: string;
}

interface StatusResponse {
  ok: boolean;
  overall: 'operational' | 'degraded' | 'down';
  version: string;
  uptime: string;
  timestamp: string;
  services: ServiceStatus[];
}

const SERVICE_LABELS: Record<string, string> = {
  api: 'API',
  database: 'Base de datos',
  redis: 'Cache (Redis)',
};

function getStatusColor(status: string): string {
  switch (status) {
    case 'operational': return COLORS.green;
    case 'degraded': return COLORS.yellow;
    case 'down': return COLORS.red;
    default: return COLORS.yellow;
  }
}

function getStatusLabel(status: string): string {
  switch (status) {
    case 'operational': return 'Operativo';
    case 'degraded': return 'Degradado';
    case 'down': return 'Caido';
    default: return status;
  }
}

function StatusIcon({ status }: { status: string }) {
  const color = getStatusColor(status);
  switch (status) {
    case 'operational':
      return <CheckCircleIcon sx={{ fontSize: 28, color }} />;
    case 'degraded':
      return <WarningIcon sx={{ fontSize: 28, color }} />;
    case 'down':
      return <ErrorIcon sx={{ fontSize: 28, color }} />;
    default:
      return <WarningIcon sx={{ fontSize: 28, color }} />;
  }
}

export default function StatusPage() {
  const [data, setData] = useState<StatusResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState(false);

  const fetchStatus = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/v1/status`);
      if (res.ok) {
        const json = await res.json();
        setData(json);
        setFetchError(false);
      } else {
        setFetchError(true);
      }
    } catch {
      setFetchError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 30_000);
    return () => clearInterval(interval);
  }, [fetchStatus]);

  const overall = fetchError ? 'down' : (data?.overall || 'operational');

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: COLORS.bg, display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <Box sx={{ bgcolor: COLORS.darkPrimary, py: 2, textAlign: 'center' }}>
        <Typography sx={{ color: COLORS.accent, fontWeight: 900, fontSize: 24, letterSpacing: 3 }}>
          ZENTTO
        </Typography>
        <Typography sx={{ color: 'rgba(255,255,255,0.5)', fontSize: 11, letterSpacing: 2, textTransform: 'uppercase', mt: 0.25 }}>
          Estado del sistema
        </Typography>
      </Box>

      <Box sx={{ flex: 1, py: 4 }}>
        <Container maxWidth="md">
          {/* Overall status banner */}
          <Paper
            elevation={3}
            sx={{
              p: 3,
              mb: 3,
              borderRadius: 3,
              borderLeft: `6px solid ${getStatusColor(overall)}`,
              display: 'flex',
              alignItems: 'center',
              gap: 2,
            }}
          >
            {loading ? (
              <CircularProgress size={28} sx={{ color: COLORS.accent }} />
            ) : (
              <StatusIcon status={overall} />
            )}
            <Box sx={{ flex: 1 }}>
              <Typography variant="h6" fontWeight={700}>
                {loading
                  ? 'Verificando...'
                  : fetchError
                    ? 'Sistema no disponible'
                    : overall === 'operational'
                      ? 'Todos los sistemas operativos'
                      : overall === 'degraded'
                        ? 'Rendimiento degradado'
                        : 'Interrupcion del servicio'}
              </Typography>
              {data && (
                <Typography variant="caption" color="text.secondary">
                  Ultima actualizacion: {new Date(data.timestamp).toLocaleString()}
                </Typography>
              )}
            </Box>
            {data && (
              <Chip
                label={getStatusLabel(overall)}
                size="small"
                sx={{
                  bgcolor: getStatusColor(overall),
                  color: '#fff',
                  fontWeight: 600,
                }}
              />
            )}
          </Paper>

          {/* Services */}
          {data?.services.map((svc) => (
            <Paper
              key={svc.name}
              elevation={1}
              sx={{
                p: 2.5,
                mb: 1.5,
                borderRadius: 2,
                display: 'flex',
                alignItems: 'center',
                gap: 2,
              }}
            >
              <StatusIcon status={svc.status} />
              <Box sx={{ flex: 1 }}>
                <Typography fontWeight={600}>
                  {SERVICE_LABELS[svc.name] || svc.name}
                </Typography>
                {svc.detail && (
                  <Typography variant="caption" color="text.secondary">
                    {svc.detail}
                  </Typography>
                )}
              </Box>
              {svc.latencyMs !== undefined && (
                <Typography variant="caption" color="text.secondary" sx={{ mr: 1 }}>
                  {svc.latencyMs}ms
                </Typography>
              )}
              <Chip
                label={getStatusLabel(svc.status)}
                size="small"
                variant="outlined"
                sx={{
                  borderColor: getStatusColor(svc.status),
                  color: getStatusColor(svc.status),
                  fontWeight: 600,
                  fontSize: 11,
                }}
              />
            </Paper>
          ))}

          {/* If fetch error, show fallback */}
          {fetchError && !loading && (
            <Paper elevation={1} sx={{ p: 2.5, mb: 1.5, borderRadius: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
              <ErrorIcon sx={{ fontSize: 28, color: COLORS.red }} />
              <Box sx={{ flex: 1 }}>
                <Typography fontWeight={600}>API</Typography>
                <Typography variant="caption" color="text.secondary">
                  No se pudo conectar con el servidor
                </Typography>
              </Box>
              <Chip label="Caido" size="small" sx={{ bgcolor: COLORS.red, color: '#fff', fontWeight: 600 }} />
            </Paper>
          )}

          {/* Footer info */}
          {data && (
            <Box sx={{ mt: 3, textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary">
                Version: {data.version} &middot; Uptime: {data.uptime}
              </Typography>
            </Box>
          )}
        </Container>
      </Box>

      {/* Footer */}
      <Box sx={{ textAlign: 'center', py: 2 }}>
        <Typography variant="caption" sx={{ color: '#9e9e9e' }}>
          &copy; {new Date().getFullYear()} Zentto ERP
        </Typography>
      </Box>
    </Box>
  );
}
