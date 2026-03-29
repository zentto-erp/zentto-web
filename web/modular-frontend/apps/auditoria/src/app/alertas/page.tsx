'use client';

import React from 'react';
import {
  Box, Typography, Card, CardContent, Button, Chip, Alert,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper,
  CircularProgress,
} from '@mui/material';
import NotificationsActiveIcon from '@mui/icons-material/NotificationsActive';
import RefreshIcon from '@mui/icons-material/Refresh';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiGet, apiPost } from '@zentto/shared-api';

function useNotificaciones() {
  return useQuery({
    queryKey: ['sistema', 'notificaciones'],
    queryFn: () => apiGet('/v1/sistema/notificaciones'),
    refetchInterval: 30000,
  });
}

function useProcesarAlertas() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => apiPost('/v1/sistema/alertas/procesar', {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sistema', 'notificaciones'] }),
  });
}

const typeColors: Record<string, 'info' | 'success' | 'warning' | 'error'> = {
  info: 'info', success: 'success', warning: 'warning', error: 'error',
};

export default function AlertasPage() {
  const { data, isLoading } = useNotificaciones();
  const procesar = useProcesarAlertas();
  const notificaciones = data?.data ?? [];

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" fontWeight={700} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <NotificationsActiveIcon color="warning" /> Alertas del Sistema
        </Typography>
        <Button
          variant="contained"
          startIcon={<RefreshIcon />}
          onClick={() => procesar.mutate()}
          disabled={procesar.isPending}
        >
          {procesar.isPending ? 'Procesando...' : 'Verificar ahora'}
        </Button>
      </Box>

      {procesar.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Verificación completada: {(procesar.data as any)?.generated ?? 0} alertas generadas
        </Alert>
      )}

      <Card>
        <CardContent>
          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : notificaciones.length === 0 ? (
            <Alert severity="info">No hay alertas pendientes. El sistema está al día.</Alert>
          ) : (
            <TableContainer component={Paper} variant="outlined">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Tipo</TableCell>
                    <TableCell>Título</TableCell>
                    <TableCell>Mensaje</TableCell>
                    <TableCell>Fecha</TableCell>
                    <TableCell>Estado</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {notificaciones.map((n: any) => (
                    <TableRow key={n.id} sx={{ bgcolor: n.read ? 'transparent' : 'action.hover' }}>
                      <TableCell>
                        <Chip label={n.type} color={typeColors[n.type] || 'default'} size="small" />
                      </TableCell>
                      <TableCell sx={{ fontWeight: n.read ? 400 : 700 }}>{n.title}</TableCell>
                      <TableCell>{n.message}</TableCell>
                      <TableCell sx={{ whiteSpace: 'nowrap' }}>
                        {n.time ? new Date(n.time).toLocaleString('es') : '—'}
                      </TableCell>
                      <TableCell>
                        <Chip label={n.read ? 'Leída' : 'Nueva'} size="small"
                          color={n.read ? 'default' : 'warning'} variant={n.read ? 'outlined' : 'filled'} />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
